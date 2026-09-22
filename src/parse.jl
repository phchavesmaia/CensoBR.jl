struct CensusChunks
  path::String
  layout::CensusLayout
  names::Tuple
  chunksize::Int
end

function CensusChunks(path::String, layout::CensusLayout; chunksize::Integer=100_000)
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

function _parseint(bytes::AbstractVector{UInt8}, fieldname::String)
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
