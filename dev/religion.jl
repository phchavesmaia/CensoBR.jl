function _parseauxiliaryreligiontext(text::AbstractString)
  values = Dict{String,String}()

  for line in eachline(IOBuffer(text))
    line = strip(replace(line, '\ufeff' => ""))
    matchrow = match(r"^(\d{3})\s+(.+?)\s*$", line)
    isnothing(matchrow) && continue
    code, label = strip.(matchrow.captures)
    haskey(values, code) && values[code] != label && error("Conflicting labels for religion code $code")
    values[code] = label
  end

  length(values) == 143 || error("Expected 143 religion codes, found $(length(values))")
  values
end

_parseauxiliaryreligion(path::AbstractString) = _parseauxiliaryreligiontext(read(path, String))

function _parseauxiliaryreligionoverrides(path::AbstractString)
  values = Dict{String,String}()

  for line in eachline(path)
    line = strip(line)
    (isempty(line) || startswith(line, "#")) && continue
    columns = split(line, '\t')
    length(columns) == 2 || error("Expected tab-separated code and label in `$path`: $line")
    code, label = strip.(columns)
    occursin(r"^\d{3}$", code) || error("Invalid religion override code `$code` in `$path`")
    isempty(label) && error("Empty religion override label for code $code in `$path`")
    haskey(values, code) && error("Duplicate religion override code $code in `$path`")
    values[code] = label
  end

  length(values) == 41 || error("Expected 41 religion label overrides, found $(length(values))")
  values
end

function _parseauxiliaryreligion2010text(text::AbstractString)
  values = Dict{String,String}()
  sourcewidths = Dict{String,Int}()

  for line in eachline(IOBuffer(text))
    line = strip(replace(line, '\ufeff' => ""))
    # The document contains two- and three-digit category rows. Normalize
    # numerically because leading zeroes are omitted. When a hierarchy heading
    # collides with a leaf code, keep the longer, more specific source code.
    matchrow = match(r"^(\d{2,3})\s+(.+?)\s*$", line)
    isnothing(matchrow) && continue
    code, label = strip.(matchrow.captures)
    normalizedcode = string(parse(Int, code))
    if haskey(values, normalizedcode)
      if values[normalizedcode] != label
        length(code) < sourcewidths[normalizedcode] && continue
        length(code) == sourcewidths[normalizedcode] &&
          error("Conflicting labels for 2010 religion code $normalizedcode")
      end
      length(code) <= sourcewidths[normalizedcode] && continue
    end
    values[normalizedcode] = label
    sourcewidths[normalizedcode] = length(code)
  end

  length(values) == 201 || error("Expected 201 religion codes for 2010, found $(length(values))")
  values
end

_parseauxiliaryreligion2010(path::AbstractString) = _parseauxiliaryreligion2010text(read(path, String))
