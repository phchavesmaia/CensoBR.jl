using Unicode

include(joinpath(@__DIR__, "religion.jl"))
include(joinpath(@__DIR__, "metropolitan.jl"))

function _auxvalue(value)
  ExcelReaders.isblank(value) && return nothing
  value isa AbstractString && return strip(String(value))
  value isa Real || return nothing
  isinteger(value) || error("Expected an integer auxiliary value, got `$value`")
  string(Int(value))
end

function _auxheader(value)
  value = _auxvalue(value)
  isnothing(value) && return ""
  text = Unicode.normalize(lowercase(value); stripmark=true)
  join(filter(isletter, text))
end

function _auxcodeheader(value)
  header = _auxheader(value)
  any(
    token -> occursin(token, header),
    ("codigo", "codigos", "mesor", "micror", "municip", "distrito", "subdistrito", "classes")
  )
end

function _auxlabelheader(value)
  header = _auxheader(value)
  any(
    token -> occursin(token, header),
    ("nome", "descricao", "denominacao", "titulacao", "continente", "pais", "unidade")
  )
end

function _auxpairvalues(data::AbstractMatrix)
  nrows, ncols = size(data)
  nrows == 0 && return Dict{String,String}()
  ncols < 2 && return Dict{String,String}()

  for row in Iterators.take(axes(data, 1), 30)
    codecols = findall(col -> _auxcodeheader(data[row, col]), axes(data, 2))
    labelcols = findall(col -> _auxlabelheader(data[row, col]), axes(data, 2))
    # Several IBGE tables have adjacent code/name columns for multiple
    # geographic levels. Prefer the closest label column for each code.
    selected = Tuple{Int,Int}[]
    for codecol in codecols
      isempty(labelcols) && continue
      labelcol = labelcols[argmin(abs(labelcol - codecol) for labelcol in labelcols)]
      codecol == labelcol || push!(selected, (codecol, labelcol))
    end
    isempty(selected) && continue

    values = Dict{String,String}()
    rowsafterheader = row - first(axes(data, 1)) + 1
    for (codecol, labelcol) in selected, datarow in Iterators.drop(axes(data, 1), rowsafterheader)
      code = _auxvalue(data[datarow, codecol])
      label = _auxvalue(data[datarow, labelcol])
      (isnothing(code) || isempty(code) || isnothing(label) || isempty(label)) && continue
      values[code] = label
    end
    !isempty(values) && return values
  end

  # Some auxiliary sheets contain only a title followed by code/label rows,
  # with no explicit column headers.
  values = Dict{String,String}()
  for row in axes(data, 1)
    code = _auxvalue(data[row, 1])
    label = _auxvalue(data[row, 2])
    (isnothing(code) || isempty(code) || isnothing(label) || isempty(label)) && continue
    occursin(r"^\d+$", code) || continue
    values[code] = label
  end
  values
end

function _readauxiliaryxls(path::AbstractString)
  workbook = ExcelReaders.openxl(path)
  try
    result = Dict{String,String}()
    for sheet in ExcelReaders.sheetnames(workbook)
      data = ExcelReaders.readxlsheet(workbook, sheet)
      merge!(result, _auxpairvalues(data))
    end
    result
  finally
    close(workbook)
  end
end

function _readterritorialvalues(path::AbstractString, fieldname::AbstractString)
  workbook = ExcelReaders.openxl(path)
  try
    data = ExcelReaders.readxlsheet(workbook, first(ExcelReaders.sheetnames(workbook)))
    codecol, labelcol = fieldname == "V1002" ? (3, 4) : (5, 6)
    values = Dict{String,String}()
    for row in axes(data, 1)
      code = _auxvalue(data[row, codecol])
      label = _auxvalue(data[row, labelcol])
      (isnothing(code) || isempty(code) || isnothing(label) || isempty(label)) && continue
      occursin(r"^\d+$", code) || continue
      values[code] = label
    end
    values
  finally
    close(workbook)
  end
end

function _readareaponderationvalues(path::AbstractString)
  workbook = ExcelReaders.openxl(path)
  try
    data = ExcelReaders.readxlsheet(workbook, "Lista das áreas de ponderação")
    values = Dict{String,String}()
    for row in axes(data, 1)
      code = _auxvalue(data[row, 1])
      label = _auxvalue(data[row, 6])
      (isnothing(code) || isempty(code) || isnothing(label) || isempty(label)) && continue
      occursin(r"^\d+$", code) || continue
      values[code] = label
    end
    values
  finally
    close(workbook)
  end
end

function _normalizeauxiliaryvalues(field::Dict{String,Any}, values::Dict{String,String}, year::Integer)
  name = field["name"]
  width = field["width"]
  if year == 2010 && name in ("V1002", "V1003")
    return values
  elseif year == 2010 && name == "V6461"
    # The occupation workbook includes hierarchy headings alongside response
    # codes. Keep the shortest hierarchy code when padding causes collisions
    # (for example, code `1` wins over `01` for `0001`). The two military
    # headings below are not response categories; censobr omits them.
    normalized = Dict{String,String}()
    sourcewidths = Dict{String,Int}()
    for (code, label) in values
      code in ("0110", "0210") && continue
      normalizedcode = lpad(code, width, '0')
      if !haskey(normalized, normalizedcode) || length(code) < sourcewidths[normalizedcode]
        normalized[normalizedcode] = label
        sourcewidths[normalizedcode] = length(code)
      end
    end
    return normalized
  end

  normalized = Dict{String,String}()
  for (code, label) in values
    normalizedcode = occursin(r"^\d+$", code) && length(code) < width ? lpad(code, width, '0') : code
    normalized[normalizedcode] = label
  end
  normalized
end

function _setauxiliaryvalues!(field::Dict{String,Any}, values::Dict{String,String}; blankasnote=false)
  isempty(values) && return field
  values = copy(values)
  if blankasnote && haskey(values, "Branco")
    note = "Branco — " * pop!(values, "Branco")
    notes = get!(field, "notes", String[])
    note in notes || push!(notes, note)
  end
  isempty(values) && return field
  existing = get!(field, "values", Dict{String,String}())
  merge!(existing, values)

  field
end

function _setauxiliaryvalues!(fields, fieldname::AbstractString, values::Dict{String,String}; blankasnote=false)
  for field in fields
    field["name"] == fieldname && _setauxiliaryvalues!(field, values; blankasnote)
  end
  fields
end

function _filesbelow(root::AbstractString, extensions)
  files = String[]
  for (dir, _, names) in walkdir(root)
    for name in names
      lowercase(splitext(name)[2]) in extensions && push!(files, joinpath(dir, name))
    end
  end
  sort!(files)
end

function _filenametokens(text::AbstractString)
  text = String(filter(isvalid, text))
  normalized = Unicode.normalize(lowercase(text); stripmark=true)
  tokens = split(replace(normalized, r"[^a-z0-9]+" => " "))
  filter(token -> length(token) >= 3 && token != "2010" && !occursin(r"^v\d+$", token), tokens)
end

function _referencedxls(candidates, notes, fieldname::AbstractString)
  isempty(candidates) && return nothing

  fieldmatches = filter(path -> occursin(fieldname, basename(path)), candidates)
  length(fieldmatches) == 1 && return only(fieldmatches)

  aliases = if fieldname in ("V6222", "V6252", "V6262", "V6362", "V6602")
    ("deslocamento _Unidades da Federa",)
  elseif fieldname in ("V3061", "V6224", "V6256", "V6266", "V6366", "V6606")
    ("Paises estrangeiros",)
  elseif fieldname in ("V6254", "V6264", "V6364", "V6604")
    ("_Munic",)
  elseif fieldname == "V6461"
    ("COD 2010",)
  elseif fieldname == "V6471"
    ("CNAE_DOM 2.0 2010",)
  else
    ()
  end
  if !isempty(aliases)
    matches = filter(path -> any(alias -> occursin(alias, basename(path)), aliases), candidates)
    isempty(matches) && error("Could not find the expected auxiliary spreadsheet for $fieldname")
    if length(matches) > 1
      firstvalues = _readauxiliaryxls(first(matches))
      all(path -> _readauxiliaryxls(path) == firstvalues, Iterators.drop(matches, 1)) ||
        error("Ambiguous auxiliary spreadsheet for $fieldname: $(join(basename.(matches), ", "))")
    end
    return first(matches)
  end

  note = join(notes, " ")
  notetokens = Set(_filenametokens(note))
  isempty(notetokens) && return nothing

  scores = map(candidates) do path
    filetokens = Set(_filenametokens(basename(path)))
    count(in(filetokens), notetokens)
  end
  best = maximum(scores)
  best == 0 && return nothing
  winners = findall(==(best), scores)
  length(winners) == 1 || error(
    "Ambiguous auxiliary file reference in notes `$(join(notes, " "))`: $(join(basename.(candidates[winners]), ", "))"
  )
  candidates[only(winners)]
end

function _parseauxiliarytext(text::AbstractString)
  values = Dict{String,String}()
  for line in split(text, '\n')
    matchrow = match(r"^\s*((?:\d{2})|(?:Branco))\s*(?:-|–|—)\s*(\S.*\S|\S)\s*$"i, strip(line))
    isnothing(matchrow) && continue
    code = strip(matchrow.captures[1])
    label = strip(matchrow.captures[2])
    isempty(code) || isempty(label) || (values[code] = label)
  end
  values
end

function _integrateauxiliaryvalues!(layout::Dict{String,Any}, documentationdir::AbstractString, year::Integer)
  year in (2000, 2010) || throw(ArgumentError("Unsupported Census year: $year"))
  fields = layout["fields"]
  auxiliaryfiles = _filesbelow(documentationdir, (".xls", ".xlsx"))

  if year == 2000
    territorial = _findfile(documentationdir, "Divisao Territorial Brasileira.xls")
    workbook = ExcelReaders.openxl(territorial)
    try
      sheetbyfield = Dict(
        "V1002" => "Mesorregião",
        "V1003" => "Microrregião",
        "V0103" => "Município",
        "V1103" => "Município",
        "V0104" => "Distrito",
        "V0105" => "Subdistrito"
      )
      for field in fields
        sheet = get(sheetbyfield, field["name"], nothing)
        isnothing(sheet) && continue
        _setauxiliaryvalues!(field, _auxpairvalues(ExcelReaders.readxlsheet(workbook, sheet)))
      end
    finally
      close(workbook)
    end

    if layout["record"] == "family"
      metropolitan = normpath(joinpath(@__DIR__, "..", "data", "auxiliary", "V1004_metropolitan_2000.txt"))
      isfile(metropolitan) || error("Family metropolitan dictionary artifact not found: $metropolitan")
      metropolitanvalues = _parseauxiliarymetropolitan(metropolitan)
    else
      metropolitan =
        normpath(joinpath(@__DIR__, "..", "data", "auxiliary", "V1004_metropolitan_2000_household_person.txt"))
      isfile(metropolitan) || error("Household/person metropolitan dictionary artifact not found: $metropolitan")
      metropolitanvalues = _parseauxiliarymetropolitan2000(metropolitan)
    end
    _setauxiliaryvalues!(fields, "V1004", metropolitanvalues; blankasnote=layout["record"] == "family")

    areas = only(filter(path -> occursin("Lista das", basename(path)), auxiliaryfiles))
    areavalues = _readareaponderationvalues(areas)
    _setauxiliaryvalues!(fields, "AREAP", areavalues)

    if any(field -> field["name"] == "V4090", fields)
      religion = normpath(joinpath(@__DIR__, "..", "data", "auxiliary", "V4090_religion_2000.txt"))
      isfile(religion) || error("Religion dictionary artifact not found: $religion")
      religionvalues = _parseauxiliaryreligion(religion)
      overrides = normpath(joinpath(@__DIR__, "..", "data", "auxiliary", "V4090_religion_2000_censobr.tsv"))
      isfile(overrides) || error("Censobr religion-label overrides not found: $overrides")
      merge!(religionvalues, _parseauxiliaryreligionoverrides(overrides))
      _setauxiliaryvalues!(fields, "V4090", religionvalues)
    end
  elseif year == 2010
    territorialfields = filter(field -> field["name"] in ("V1002", "V1003"), fields)
    if !isempty(territorialfields)
      territorial = only(filter(path -> occursin("Mesorreg", basename(path)), auxiliaryfiles))
      for field in territorialfields
        _setauxiliaryvalues!(field, _readterritorialvalues(territorial, field["name"]))
      end
    end

    metropolitan = normpath(joinpath(@__DIR__, "..", "data", "auxiliary", "V1004_metropolitan_2010.txt"))
    isfile(metropolitan) || error("Metropolitan-region dictionary artifact not found: $metropolitan")
    metropolitanvalues = _parseauxiliarymetropolitan2010(metropolitan)
    _setauxiliaryvalues!(fields, "V1004", metropolitanvalues)

    if any(field -> field["name"] == "V6121", fields)
      religion = normpath(joinpath(@__DIR__, "..", "data", "auxiliary", "V6121_religion_2010.txt"))
      isfile(religion) || error("2010 religion dictionary artifact not found: $religion")
      religionvalues = _parseauxiliaryreligion2010(religion)
      _setauxiliaryvalues!(fields, "V6121", religionvalues)
    end
  end

  cache = Dict{String,Dict{String,String}}()
  for field in fields
    if year == 2000 && field["name"] in ("V1002", "V1003", "V0103", "V1103", "V0104", "V0105", "V1004", "AREAP")
      continue
    elseif year == 2010 && field["name"] in ("V1002", "V1003")
      continue
    end
    notes = get(field, "notes", String[])
    sourcenotes = filter(note -> !startswith(lowercase(note), "branco"), notes)
    any(note -> occursin(r"\.xls[x]?\b"i, note), sourcenotes) || continue
    path = _referencedxls(auxiliaryfiles, sourcenotes, field["name"])
    isnothing(path) && error("Could not resolve auxiliary spreadsheet for $(field["name"]): $(join(notes, " "))")
    values = get!(cache, path) do
      _readauxiliaryxls(path)
    end
    isempty(values) && error("No code/label pairs found in auxiliary spreadsheet `$path` for $(field["name"])")
    _setauxiliaryvalues!(field, _normalizeauxiliaryvalues(field, values, year))
  end

  layout
end
