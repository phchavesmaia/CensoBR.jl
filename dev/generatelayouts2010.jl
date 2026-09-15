using TOML
using OdsIO

include(joinpath(@__DIR__, "download.jl"))

const ODSLAYOUTFILE = "Layout_microdados_Amostra.ods"

const ODS_SHEETS = Dict(
    :household => "DOMI",
    :person => "PESS",
    :emigration => "EMIG",
    :mortality => "MORT",
)

const OUTPUT_FILES = Dict(
    :household => "household.toml",
    :person => "person.toml",
    :emigration => "emigration.toml",
    :mortality => "mortality.toml",
)

"""
	_findfile(root, filename)

Recursively find exactly one file named `filename` below `root`.
"""
function _findfile(root::AbstractString, filename::AbstractString)
    matches = String[]

    for (dir, _, files) in walkdir(root)
        filename in files && push!(matches, joinpath(dir, filename))
    end

    isempty(matches) && error("Could not find `$filename` below `$root`")

    length(matches) == 1 ||
        error("Found multiple copies of `$filename` below `$root`: " * join(matches, ", "))

    only(matches)
end

"""
	_parselayoutmetadata(text)

Parse an IBGE layout description into a variable label, coded value labels,
and free-form notes.

Continuation lines following a coded value are appended to that value's
description. Other lines are retained as notes.
"""
function _parselayoutmetadata(text::AbstractString)
    text = strip(text)
    text = strip(text, ['"', ' ', '\t', '\n', '\r'])

    lines = split(text, '\n')
    lines = strip.(lines)
    lines = filter(!isempty, lines)

    isempty(lines) &&
        return (label = nothing, values = Dict{String,String}(), notes = String[])

    label = strip(first(lines), ['"', ':', ' ', '\t'])
    values = Dict{String,String}()
    notes = String[]

    # 2010 uses numeric, alphabetic, "Branco", and occasionally range-like codes.
    valueregex = r"^((?:\d+(?:\s+a\s+\d+)?)|(?:[A-Z])|(?:Branco))\s*-\s*(.+)$"

    lastkind = :none
    lastkey = nothing

    for rawline in Iterators.drop(lines, 1)
        line = strip(rawline, ['"', ' ', '\t', '\r'])
        isempty(line) && continue

        m = match(valueregex, line)

        if !isnothing(m)
            code = strip(m.captures[1])
            value = strip(m.captures[2])

            values[code] = value
            lastkind = :value
            lastkey = code
            continue
        end

        if lastkind == :value && !isnothing(lastkey)
            values[lastkey] *= " " * line
        else
            push!(notes, line)
            lastkind = :note
            lastkey = nothing
        end
    end

    (label = isempty(label) ? nothing : label, values = values, notes = notes)
end

"""
	_toint(value; default=nothing)

Convert a spreadsheet cell to `Int`, optionally returning `default` for an
empty cell.
"""
function _toint(value; default = nothing)
    if isnothing(value) ||
       ismissing(value) ||
       (value isa AbstractString && isempty(strip(value)))

        isnothing(default) &&
            throw(ArgumentError("Expected an integer value, found an empty cell"))

        return default
    end

    value isa Integer && return Int(value)

    if value isa AbstractFloat
        isinteger(value) || throw(ArgumentError("Expected an integer value, found $value"))
        return Int(value)
    end

    parse(Int, strip(String(value)))
end

"""
	_parsespreadsheetlayout(path, record)

Parse one record sheet from the official Census 2010 ODS layout and return a
TOML-friendly dictionary.
"""
function _parsespreadsheetlayout(path::AbstractString, record::Symbol)
    isfile(path) || throw(ArgumentError("ODS layout file does not exist: $path"))

    sheet = get(ODS_SHEETS, record, nothing)

    isnothing(sheet) && throw(ArgumentError("Unsupported Census 2010 record type: $record"))

    # Row 1 is a title, row 2 contains headers, row 3 onward contains variables.
    data = ods_read(path; sheetName = sheet, retType = "Matrix")

    size(data, 2) >= 12 || error(
        "Unexpected layout structure in sheet `$sheet`: " *
        "expected at least 12 columns, found $(size(data, 2))",
    )

    fields = Vector{Dict{String,Any}}()

    for row = 3:size(data, 1)
        var = data[row, 1]

        (isnothing(var) || ismissing(var)) && continue

        name = strip(String(var))
        isempty(name) && continue

        description = data[row, 2]
        description =
            (isnothing(description) || ismissing(description)) ? "" : String(description)

        metadata = _parselayoutmetadata(description)

        # In the official workbook these columns are:
        # 8  POSIÇÃO INICIAL
        # 9  POSIÇÃO FINAL
        # 10 INT
        # 11 DEC
        # 12 TIPO
        start = _toint(data[row, 8])
        stop = _toint(data[row, 9])
        intwidth = _toint(data[row, 10]; default = 0)
        decimals = _toint(data[row, 11]; default = 0)

        tipo = data[row, 12]
        tipo = (isnothing(tipo) || ismissing(tipo)) ? "" : uppercase(strip(String(tipo)))

        width = stop - start + 1
        ischaracter = tipo in ("A", "C")

        width > 0 || error("Invalid width for `$name`: start=$start, stop=$stop")

        if !ischaracter && intwidth + decimals != width
            error(
                "Numeric width mismatch for `$name`: " *
                "positions imply width=$width, but INT+DEC=$(intwidth + decimals)",
            )
        end

        field = Dict{String,Any}(
            "name" => name,
            "start" => start,
            "width" => width,
            "decimals" => decimals,
            "character" => ischaracter,
        )

        !isnothing(metadata.label) && (field["label"] = metadata.label)

        !isempty(metadata.values) && (field["values"] = metadata.values)

        !isempty(metadata.notes) && (field["notes"] = metadata.notes)

        push!(fields, field)
    end

    isempty(fields) && error("No fields were parsed from sheet `$sheet` in `$path`")

    sort!(fields; by = field -> field["start"])

    lrecl = maximum(field["start"] + field["width"] - 1 for field in fields)

    Dict{String,Any}(
        "record" => String(record),
        "lrecl" => lrecl,
        "source_file" => basename(path),
        "source_sheet" => sheet,
        "fields" => fields,
    )
end

"""
	_generatelayouts2010(documentationdir, outputdir)

Generate normalized TOML layouts for the Census 2010 household, person,
emigration, and mortality records from the official IBGE ODS layout workbook.
"""
function _generatelayouts2010(documentationdir::AbstractString, outputdir::AbstractString)
    isdir(documentationdir) ||
        throw(ArgumentError("Documentation directory does not exist: $documentationdir"))

    sourcepath = _findfile(documentationdir, ODSLAYOUTFILE)

    mkpath(outputdir)

    mktempdir() do tmpdir
        # OdsIO uses Python internally, which can fail on the legacy
        # filename encoding present in the original IBGE archive.
        # Copy the workbook to a UTF-8-safe temporary path first.
        odspath = joinpath(tmpdir, "layout.ods")
        cp(sourcepath, odspath)

        for record in (:household, :person, :emigration, :mortality)
            layout = _parsespreadsheetlayout(odspath, record)

            outputpath = joinpath(outputdir, OUTPUT_FILES[record])

            open(outputpath, "w") do io
                TOML.print(io, layout; sorted = true)
            end

            nfields = length(layout["fields"])

            println(
                "Generated $(basename(outputpath)): ",
                "$nfields fields, LRECL=$(layout["lrecl"])",
            )
        end
    end

    outputdir
end

function main(args)
    length(args) <= 1 ||
        error("Usage:\n" * "  julia --project=dev dev/generatelayouts2010.jl [outputdir]")

    documentationdir = preparedocumentation(2010)

    outputdir =
        isempty(args) ? joinpath(dirname(@__DIR__), "data", "layouts", "2010") :
        expanduser(only(args))

    _generatelayouts2010(documentationdir, outputdir)
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main(ARGS)
end
