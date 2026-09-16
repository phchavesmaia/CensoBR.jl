using Tables, Parquet2

struct CensusChunks
  path::String
  layout::CensusLayout
  names::Tuple
  chunksize::Int
end

function CensusChunks(path::AbstractString, layout::CensusLayout; chunksize::Integer=100_000)
  names = Tuple(Symbol(field.name) for field in layout.fields)
  CensusChunks(String(path), layout, names, chunksize)
end

function Base.iterate(chunks::CensusChunks)
  io = open(chunks.path, "r")
  chunk = _parsechunk!(io, chunks.layout, chunks.names; chunksize=chunks.chunksize)
  if isnothing(chunk)
    close(io)
    return nothing
  end
  chunk, io
end

function Base.iterate(chunks::CensusChunks, io::IOStream)
  chunk = _parsechunk!(io, chunks.layout, chunks.names; chunksize=chunks.chunksize)
  if isnothing(chunk)
    close(io)
    return nothing
  end
  chunk, io
end

Base.IteratorSize(::Type{CensusChunks}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{CensusChunks}) = Base.EltypeUnknown()

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

function _columneltype(field::LayoutField)
  if field.ischaracter
    Union{Missing,String}
  elseif field.decimals == 0
    Union{Missing,Int}
  else
    Union{Missing,Float64}
  end
end

function _makecolumns(layout::CensusLayout, capacity::Integer)
  Tuple(Vector{_columneltype(field)}(undef, capacity) for field in layout.fields)
end

function _parsechunk!(io::IO, layout::CensusLayout, names::Tuple; chunksize::Integer=100_000)
  # create empty columns for the chunk
  columns = _makecolumns(layout, chunksize)

  # read lines from the input IO until the chunk is full or EOF is reached
  nrows = 0
  while nrows < chunksize && !eof(io)
    line = readline(io)
    bytes = codeunits(line)

    nrows += 1
    for (j, field) in enumerate(layout.fields)
      columns[j][nrows] = _parsefield(field, bytes)
    end
  end

  # return nothing if no rows were read
  nrows == 0 && return nothing

  # trim the columns to the number of rows actually read
  nrows == chunksize && return NamedTuple{names}(columns)
  trimmed = map(column -> column[1:nrows], columns)
  NamedTuple{names}(trimmed)
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
  cachedir::AbstractString,
  force::Bool=false,
  showprogress::Bool=true,
  chunksize::Integer
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

    # create an iterable of chunks from the raw file
    chunks = CensusChunks(path, layout; chunksize=chunksize)
    mkpath(dirname(parquetpath))

    # avoid leaving a corrupt final cache entry if writing fails
    temporary = parquetpath * ".part"
    isfile(temporary) && rm(temporary; force=true)
    try
      open(temporary, "w") do io
        fw = Parquet2.FileWriter(io, temporary)
        Parquet2.writeiterable!(fw, chunks)
      end
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

See also [`fieldmetadata`](@ref), [`fieldlabel`](@ref), [`fieldvalues`](@ref), and [`fieldnotes`](@ref)
"""
function opencensus(
  year::Integer,
  uf::Union{String,Symbol},
  record::Symbol;
  cachedir::AbstractString=_defaultcachedir(),
  force::Bool=false,
  showprogress::Bool=true,
  chunksize::Integer=5_000
)

  # checks
  haskey(CENSUS_RECORDS, year) || throw(ArgumentError("Unsupported census year: $year"))
  record in CENSUS_RECORDS[year] || throw(ArgumentError("Unsupported record `$record` for Census $year"))

  # setup
  uf = uppercase(String(uf))

  parquetpath = _parquetpath(year, uf, record; cachedir=cachedir)

  if !isfile(parquetpath) || force
    _processcensus(year, uf; cachedir=cachedir, force=force, showprogress=showprogress, chunksize=chunksize)
  end

  Parquet2.Dataset(parquetpath)
end

"""
    fieldmetadata(year::Integer, record::Symbol, variable::Symbol)

Return metadata for `variable` in the specified Census `year` and `record`.

The returned named tuple contains:

- `labels`: descriptive label for the variables, or `nothing` if unavailable.
- `values`: mapping from coded values to their descriptions.
- `notes`: additional notes associated with the variable.

See also [`fieldlabel`](@ref), [`fieldvalues`](@ref), and [`fieldnotes`](@ref).
"""
function fieldmetadata(year::Integer, record::Symbol, variable::Symbol)
  layout = _loadlayout(year, record)

  for field in layout.fields
    if Symbol(field.name) == variable
      return (label=field.label, values=field.values, notes=field.notes)
    end
  end

  throw(ArgumentError("Variable `$variable` not found in Census $year $record layout"))
end

"""
    fieldlabel(year::Integer, record::Symbol, variable::Symbol)

Return the descriptive label for `variable` in the specified Census `year` and
`record`.

Returns `nothing` if the variable has no label.

See also [`fieldmetadata`](@ref), [`fieldvalues`](@ref), and [`fieldnotes`](@ref), and [`fieldlabel`](@ref).
"""
function fieldlabel(year::Integer, record::Symbol, variable::Symbol)
  fieldmetadata(year, record, variable).label
end

"""
    fieldvalues(year::Integer, record::Symbol, variable::Symbol)

Return the coded values and their descriptions for `variable` in the specified
Census `year` and `record`.

The result is a `Dict{String,String}` mapping the codes used in the raw Census
data to their corresponding descriptions. Returns an empty dictionary when no
coded values are defined.

See also [`fieldmetadata`](@ref), [`fieldlabel`](@ref), and [`fieldnotes`](@ref).
"""
function fieldvalues(year::Integer, record::Symbol, variable::Symbol)
  fieldmetadata(year, record, variable).values
end

"""
    fieldnotes(year::Integer, record::Symbol, variable::Symbol)

Return additional notes for `variable` in the specified Census `year` and
`record`.

The result is a `Vector{String}`. Returns an empty vector when no notes are
available.

See also [`fieldmetadata`](@ref), [`fieldlabel`](@ref), and [`fieldvalues`](@ref).
"""
function fieldnotes(year::Integer, record::Symbol, variable::Symbol)
  fieldmetadata(year, record, variable).notes
end
