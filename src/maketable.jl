using Tables

struct CensusTable
  path::String
  layout::CensusLayout
end

struct CensusRowState
  io::IOStream
  line::Int
end

const RAW_FILE_PREFIXES = Dict(
  (2000, :household) => "DOM",
  (2000, :family) => "FAMI",
  (2000, :person) => "PES",
  (2010, :household) => "AMOSTRA_DOMICILIOS_",
  (2010, :person) => "AMOSTRA_PESSOAS_",
  (2010, :emigration) => "AMOSTRA_EMIGRACAO_",
  (2010, :mortality) => "AMOSTRA_MORTALIDADE_"
)

"""
	_findrawfile(censusdir, layout)

Find the fixed-width microdata file corresponding to `record` inside an
extracted Census directory.
"""
function _findrawfile(censusdir::AbstractString, layout::CensusLayout)
  # ensure that the requested Census file is supported.
  key = (layout.year, layout.record)
  !haskey(RAW_FILE_PREFIXES, key) &&
    throw(ArgumentError("Unsupported Census file: year=$(layout.year), record=$(layout.record)"))
  key = (layout.year, layout.record)

  # retrieve the file prefix for the requested Census file.
  prefix = RAW_FILE_PREFIXES[key]

  # search for files matching the prefix in the Census directory.
  matches = String[]
  for (root, _, files) in walkdir(censusdir)
    for file in files
      startswith(uppercase(file), prefix) && push!(matches, joinpath(root, file))
    end
  end

  isempty(matches) && error("Could not find $(layout.record) microdata for Census $(layout.year) " * "in: $censusdir")

  length(matches) == 1 ||
    error("Found multiple $(layout.record) microdata files for Census " * "$(layout.year) in: $censusdir")

  only(matches)
end

"""
	_parsefield(field, bytes)

Parse a single fixed-width field from a raw Census record represented as bytes.

Blank fields are returned as `missing`. Character fields are returned as
strings. Numeric fields are parsed as integers or scaled floating-point values
according to `field.decimals`.
"""
function _parsefield(field::LayoutField, bytes::AbstractVector{UInt8})
  stop = field.start + field.width - 1

  stop <= length(bytes) || throw(
    ArgumentError(
      "Field $(field.name) extends beyond record length: " *
      "field ends at byte $stop, record has $(length(bytes)) bytes"
    )
  )

  rawbytes = @view bytes[field.start:stop]

  # Remove ASCII spaces surrounding the field without converting the whole record to a String.
  firstbyte = firstindex(rawbytes)
  lastbyte = lastindex(rawbytes)

  while firstbyte <= lastbyte && isspace(Char(rawbytes[firstbyte]))
    firstbyte += 1
  end

  while lastbyte >= firstbyte && isspace(Char(rawbytes[lastbyte]))
    lastbyte -= 1
  end

  firstbyte > lastbyte && return missing

  valuebytes = @view rawbytes[firstbyte:lastbyte]
  raw = String(copy(valuebytes))

  field.ischaracter && return raw

  value = tryparse(Int, raw)

  isnothing(value) && throw(ArgumentError("Could not parse numeric field $(field.name) " * "from value `$raw`"))

  field.decimals == 0 && return value

  value / 10^field.decimals
end

"""
	_parseline(layout, bytes)

Parse a raw fixed-width Census record represented as bytes.

Returns a `NamedTuple` whose field names correspond to the variables defined in
`layout`.
"""
function _parseline(layout::CensusLayout, bytes::AbstractVector{UInt8})
  length(bytes) >= layout.lrecl || throw(
    ArgumentError(
      "Record is shorter than expected for Census $(layout.year) $(layout.record): " *
      "got $(length(bytes)) bytes, expected at least $(layout.lrecl)"
    )
  )

  names = Tuple(Symbol(field.name) for field in layout.fields)

  values = Tuple(_parsefield(field, bytes) for field in layout.fields)

  NamedTuple{names}(values)
end

"""
	_parsefile(path, layout)

Return a lazy Tables.jl-compatible view of a fixed-width Census file.

Rows are parsed on demand using `layout`; the entire file is not loaded into
memory.
"""
function _parsefile(path::AbstractString, layout::CensusLayout)
  isfile(path) || throw(ArgumentError("Census file does not exist: $path"))

  CensusTable(String(path), layout)
end

Tables.istable(::Type{CensusTable}) = true
Tables.rowaccess(::Type{CensusTable}) = true
Tables.rows(table::CensusTable) = table

Base.IteratorSize(::Type{CensusTable}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{CensusTable}) = Base.EltypeUnknown()

function Base.iterate(table::CensusTable)
  io = open(table.path, "r")

  eof(io) && begin
    close(io)
    return nothing
  end

  line = readline(io)

  (_parseline(table.layout, codeunits(line)), CensusRowState(io, 1))
end

function Base.iterate(table::CensusTable, state::CensusRowState)
  io = state.io

  if eof(io)
    close(io)
    return nothing
  end

  line = readline(io)
  linenumber = state.line + 1

  (_parseline(table.layout, codeunits(line)), CensusRowState(io, linenumber))
end

function Tables.schema(table::CensusTable)
  names = Tuple(Symbol(field.name) for field in table.layout.fields)

  types = Tuple(if field.ischaracter
    Union{Missing,String}
  elseif field.decimals == 0
    Union{Missing,Int}
  else
    Union{Missing,Float64}
  end for field in table.layout.fields)

  Tables.Schema(names, types)
end

"""
	fieldmetadata(table, variable)

Return variable metadata for all fields in a Census table.
"""
function fieldmetadata(table::CensusTable, variable::Symbol)
  for field in table.layout.fields
    if Symbol(field.name) == variable
      return (label=field.label, values=field.values, notes=field.notes)
    end
  end

  throw(ArgumentError("Variable `$variable` not found in Census table"))
end

label(table::CensusTable) = Dict(Symbol(field.name) => field.label for field in table.layout.fields)

valuecodes(table::CensusTable, variable::Symbol) = fieldmetadata(table, variable).values

notes(table::CensusTable, variable::Symbol) = fieldmetadata(table, variable).notes

"""
	opencensus(year, uf, record; cachedir=_defaultcachedir(),
			   force=false, showprogress=true)

Return a lazy Tables.jl-compatible view of IBGE Census microdata.

The corresponding Census archive is downloaded and extracted if necessary.
CensoBR then loads the bundled layout for `year` and `record`, locates the
matching fixed-width microdata file, and parses records on demand.
"""
function opencensus(
  year::Integer,
  uf::Union{String,Symbol},
  record::Symbol;
  cachedir::AbstractString=_defaultcachedir(),
  force::Bool=false,
  showprogress::Bool=true
)
  censusdir = _preparecensus(year, uf; cachedir=cachedir, force=force, showprogress=showprogress)

  layout = _loadlayout(year, record)

  path = _findrawfile(censusdir, layout)

  _parsefile(path, layout)
end
