function _parseauxiliarymetropolitantext(text::AbstractString)
  values = Dict{String,String}()
  collecting = false

  for line in eachline(IOBuffer(text))
    line = replace(line, '\ufeff' => "")
    if !collecting
      section = match(r"^\s*V1004\s+\d+\s+\d+\s+REGI[ÃA]O\s+METROPOLITANA\s*(.*)$"i, line)
      isnothing(section) && continue
      collecting = true
      line = section.captures[1]
    elseif occursin(r"^\s*AREAP\b"i, line)
      break
    end

    matchrow = match(r"^\s*((?:\d{2})|(?:Branco))\s*[-–—]\s*(.+?)\s*$"i, line)
    isnothing(matchrow) && continue
    code, label = strip.(matchrow.captures)
    haskey(values, code) && values[code] != label && error("Conflicting labels for metropolitan-region code $code")
    values[code] = label
  end

  expectedcodes = union(Set(lpad(string(code), 2, '0') for code in 1:28), Set(["Branco"]))
  Set(keys(values)) == expectedcodes || error("Expected metropolitan-region codes 01–28, found $(length(values)) codes")
  values
end

_parseauxiliarymetropolitan(path::AbstractString) = _parseauxiliarymetropolitantext(read(path, String))

function _parseauxiliarymetropolitan2000text(text::AbstractString)
  values = Dict{String,String}()

  for line in eachline(IOBuffer(text))
    line = replace(line, '\ufeff' => "")
    matchrow = match(r"^\s*(\d{2})\s*[-–—]\s*(.+?)\s*$", line)
    isnothing(matchrow) && continue
    code, label = strip.(matchrow.captures)
    haskey(values, code) && values[code] != label && error("Conflicting labels for 2000 metropolitan-region code $code")
    values[code] = label
  end

  expectedcodes = Set(lpad(string(code), 2, '0') for code in 0:28)
  Set(keys(values)) == expectedcodes ||
    error("Expected 2000 metropolitan-region codes 00–28, found $(length(values)) codes")
  values
end

_parseauxiliarymetropolitan2000(path::AbstractString) = _parseauxiliarymetropolitan2000text(read(path, String))

function _parseauxiliarymetropolitan2010text(text::AbstractString)
  values = Dict{String,String}()

  for line in eachline(IOBuffer(text))
    line = replace(line, '\ufeff' => "")
    matchrow = match(r"^\s*(\d{2})\s*[-–—]\s*(.+?)\s*$", line)
    isnothing(matchrow) && continue
    code, label = strip.(matchrow.captures)
    haskey(values, code) && values[code] != label && error("Conflicting labels for 2010 metropolitan-region code $code")
    values[code] = label
  end

  expectedcodes = Set(lpad(string(code), 2, '0') for code in 0:42)
  Set(keys(values)) == expectedcodes || error("Expected metropolitan-region codes 00–42, found $(length(values)) codes")
  values
end

_parseauxiliarymetropolitan2010(path::AbstractString) = _parseauxiliarymetropolitan2010text(read(path, String))
