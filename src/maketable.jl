using Tables, Parquet2

struct CensusTable
  path::String
  layout::CensusLayout
  names::Tuple{Vararg{Symbol}}
end

function CensusTable(path::AbstractString, layout::CensusLayout)
  names = Tuple(Symbol(field.name) for field in layout.fields)
  CensusTable(String(path), layout, names)
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

const CENSUS_RECORDS =
  Dict(2000 => (:household, :family, :person), 2010 => (:household, :person, :emigration, :mortality))

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

  # entire field is beyond the physical end of the record.
  field.start > length(bytes) && return missing

  # field starts in the record but is truncated.
  stop > length(bytes) && throw(
    ArgumentError(
      "Field $(field.name) is truncated: " *
      "starts at byte $(field.start), ends at byte $stop, " *
      "record has $(length(bytes)) bytes"
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

  field.ischaracter && return String(copy(valuebytes))

  value = _parseint(valuebytes, field.name)

  field.decimals == 0 && return value

  value / 10^field.decimals
end

function _parseint(bytes::AbstractVector{UInt8}, fieldname::AbstractString)
  isempty(bytes) && return nothing

  i = firstindex(bytes)
  last = lastindex(bytes)
  sign = 1
  if bytes[i] == UInt8('-')
    sign = -1
    i += 1
  elseif bytes[i] == UInt8('+')
    i += 1
  end

  i > last && throw(ArgumentError("Could not parse numeric field $fieldname"))

  value = 0
  while i <= last
    byte = bytes[i]
    UInt8('0') <= byte <= UInt8('9') || throw(ArgumentError("Could not parse numeric field $fieldname"))
    value = 10value + Int(byte - UInt8('0'))
    i += 1
  end

  sign * value
end

"""
	_parseline(layout, bytes)

Parse a raw fixed-width Census record represented as bytes.

Returns a `NamedTuple` whose field names correspond to the variables defined in
`layout`.
"""
function _parseline(layout::CensusLayout, names::Tuple{Vararg{Symbol}}, bytes::AbstractVector{UInt8})
  values = Tuple(_parsefield(field, bytes) for field in layout.fields)
  NamedTuple{names}(values)
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

  (_parseline(table.layout, table.names, codeunits(line)), io)
end

function Base.iterate(table::CensusTable, state::IOStream)
  io = state

  if eof(io)
    close(io)
    return nothing
  end

  line = readline(io)
  (_parseline(table.layout, table.names, codeunits(line)), io)
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

function _parquetpath(year::Integer, uf, record::Symbol; cachedir::AbstractString=_defaultcachedir())
  uf = uppercase(String(uf))
  joinpath(cachedir, "parquet", string(year), uf, "$(record).parquet")
end

function _clearraw(year::Integer, uf; cachedir::AbstractString=_defaultcachedir())
  # get paths
  rawdir = joinpath(cachedir, "raw", string(year))

  # removing the raw zip file and the extracted directory
  rm(joinpath(rawdir, "$uf.zip"); force=true)
  rm(joinpath(rawdir, uf); recursive=true, force=true)
end

function _processcensus(
  year::Integer,
  uf;
  cachedir::AbstractString=_defaultcachedir(),
  force::Bool=false,
  showprogress::Bool=true
)
  # prepare the Census data directory and paths
  censusdir = _preparecensus(year, uf; cachedir=cachedir, force=force, showprogress=showprogress)

  # process each record for the given year and UF
  Threads.@threads for record in CENSUS_RECORDS[year]
    # determine the path for the processed Parquet file
    parquetpath = _parquetpath(year, uf, record; cachedir=cachedir)
    # reuse the processed cache
    if isfile(parquetpath) && !force
      continue
    end
    # load the layout and find the raw file for this record
    layout = _loadlayout(year, record)
    path = _findrawfile(censusdir, layout)

    # make table
    table = CensusTable(String(path), layout)
    mkpath(dirname(parquetpath))

    # avoid leaving a corrupt final cache entry if writing fails.
    temporary = parquetpath * ".part"
    isfile(temporary) && rm(temporary; force=true)
    try
      Parquet2.writefile(temporary, table)
      mv(temporary, parquetpath; force=true)
    catch
      isfile(temporary) && rm(temporary; force=true)
      rethrow()
    end
  end
  # raw files are no longer necessary once the Parquet cache is complete.
  _clearraw(year, uf; cachedir=cachedir)
end

"""
	opencensus(year, uf, record; cachedir=_defaultcachedir(),
			   force=false, showprogress=true)

Open IBGE Census microdata as a Parquet2 dataset.

If a processed Parquet file is not already cached, CensoBR downloads and
extracts the corresponding Census archive, parses the fixed-width microdata,
writes the result to Parquet, and removes the temporary raw files.
"""
function opencensus(
  year::Integer,
  uf::Union{String,Symbol},
  record::Symbol;
  cachedir::AbstractString=_defaultcachedir(),
  force::Bool=false,
  showprogress::Bool=true
)

  # checks
  haskey(CENSUS_RECORDS, year) || throw(ArgumentError("Unsupported census year: $year"))
  record in CENSUS_RECORDS[year] || throw(ArgumentError("Unsupported record `$record` for Census $year"))

  # setup
  uf = uppercase(String(uf))

  parquetpath = _parquetpath(year, uf, record; cachedir=cachedir)

  if !isfile(parquetpath) || force
    _processcensus(year, uf; cachedir=cachedir, force=force, showprogress=showprogress)
  end

  Parquet2.Dataset(parquetpath)
end
