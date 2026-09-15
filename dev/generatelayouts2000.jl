using TOML
using StringEncodings

const SAS_LAYOUT_FILES = Dict(
    :household => "LE DOMIC.sas",
    :family    => "LE FAMILIAS.sas",
    :person    => "LE PESSOAS.sas",
)

const OUTPUT_FILES = Dict(
    :household => "household.toml",
    :family    => "family.toml",
    :person    => "person.toml",
)

"""
    _find_file(root, filename)

Recursively find exactly one file named `filename` below `root`.
"""
function _find_file(root::AbstractString, filename::AbstractString)
    matches = String[]

    for (dir, _, files) in walkdir(root)
        filename in files && push!(matches, joinpath(dir, filename))
    end

    isempty(matches) &&
        error("Could not find `$filename` below `$root`")

    length(matches) == 1 ||
        error("Found multiple copies of `$filename` below `$root`: $(join(matches, ", "))")

    return only(matches)
end

"""
    _parse_layout_metadata(text)

Parse an IBGE descriptive comment into a variable label, coded value labels,
and free-form notes.

Continuation lines following a coded value are appended to that value's
description. Lines that are not coded values and do not continue a coded value
are retained as notes.
"""
function _parse_layout_metadata(text::AbstractString)
    text = strip(text)
    text = strip(text, ['"', ' ', '\t', '\n', '\r'])

    lines = split(text, '\n')
    lines = strip.(lines)
    lines = filter(!isempty, lines)

    isempty(lines) && return (
        label = nothing,
        values = Dict{String,String}(),
        notes = String[],
    )

    label = strip(first(lines), ['"', ':', ' ', '\t'])
    values = Dict{String,String}()
    notes = String[]

    # Codes observed in the IBGE layouts include:
    #   1, 11, 00, A, C, Branco, and occasionally numeric ranges.
    value_regex = r"^((?:\d+(?:\s+a\s+\d+)?)|(?:[A-Z])|(?:Branco))\s*-\s*(.+)$"

    last_kind = :none
    last_key = nothing

    for raw_line in Iterators.drop(lines, 1)
        line = strip(raw_line, ['"', ' ', '\t', '\r'])
        isempty(line) && continue

        m = match(value_regex, line)

        if !isnothing(m)
            code = strip(m.captures[1])
            value = strip(m.captures[2])

            values[code] = value
            last_kind = :value
            last_key = code
            continue
        end

        # A physical line can be a continuation of the previous value label.
        if last_kind == :value && !isnothing(last_key)
            values[last_key] *= " " * line
        else
            push!(notes, line)
            last_kind = :note
            last_key = nothing
        end
    end

    return (
        label = isempty(label) ? nothing : label,
        values = values,
        notes = notes,
    )
end

"""
    _parse_sas_layout(path, record)

Parse an official Census 2000 SAS fixed-width input layout and return a
TOML-friendly dictionary.
"""
function _parse_sas_layout(path::AbstractString, record::Symbol)
    isfile(path) ||
        throw(ArgumentError("SAS layout file does not exist: $path"))

    # The 2000 documentation uses a legacy Western encoding.
    text = read(path, String, enc"WINDOWS-1252")

    # Examples:
    #   @1   V0102 $2.   /* ... */
    #   @39  V0300 8.    /* ... */
    #   @121 V7203 3.1   /* ... */
    #
    # The `s` flag lets the comment capture span multiple physical lines,
    # while `m` makes ^ refer to the start of each line.
    field_regex =
        r"(?ms)^\s*@(\d+)\s+([A-Za-z0-9_]+)\s+(\$?)(\d+)\.(\d+)?\s*/\*(.*?)\*/"

    fields = Vector{Dict{String,Any}}()

    for m in eachmatch(field_regex, text)
        start = parse(Int, m.captures[1])
        name = m.captures[2]
        is_character = m.captures[3] == "\$"
        width = parse(Int, m.captures[4])
        decimals = isnothing(m.captures[5]) ? 0 : parse(Int, m.captures[5])

        metadata = _parse_layout_metadata(m.captures[6])

        field = Dict{String,Any}(
            "name" => name,
            "start" => start,
            "width" => width,
            "decimals" => decimals,
            "character" => is_character,
        )

        !isnothing(metadata.label) && (field["label"] = metadata.label)
        !isempty(metadata.values) && (field["values"] = metadata.values)
        !isempty(metadata.notes) && (field["notes"] = metadata.notes)

        push!(fields, field)
    end

    isempty(fields) &&
        error("No fixed-width fields were parsed from `$path`")

    # Prefer the record length explicitly declared by SAS.
    lrecl_match = match(r"LRECL\s*=\s*(\d+)"i, text)
    inferred_lrecl = maximum(
        field["start"] + field["width"] - 1
        for field in fields
    )
    lrecl = isnothing(lrecl_match) ?
        inferred_lrecl :
        parse(Int, lrecl_match.captures[1])

    inferred_lrecl > lrecl &&
        error(
            "Parsed fields extend to column $inferred_lrecl, " *
            "beyond declared LRECL=$lrecl in `$path`"
        )

    sort!(fields; by = field -> field["start"])

    return Dict{String,Any}(
        "record" => String(record),
        "lrecl" => lrecl,
        "source_file" => basename(path),
        "fields" => fields,
    )
end

"""
    generate_layouts_2000(documentation_dir, output_dir)

Generate normalized TOML layouts for the Census 2000 household, family, and
person records from the official IBGE SAS setup files.
"""
function generate_layouts_2000(
    documentation_dir::AbstractString,
    output_dir::AbstractString,
)
    isdir(documentation_dir) ||
        throw(ArgumentError("Documentation directory does not exist: $documentation_dir"))

    mkpath(output_dir)

    for record in (:household, :family, :person)
        source_path = _find_file(
            documentation_dir,
            SAS_LAYOUT_FILES[record],
        )

        layout = _parse_sas_layout(source_path, record)
        output_path = joinpath(output_dir, OUTPUT_FILES[record])

        open(output_path, "w") do io
            TOML.print(io, layout; sorted = true)
        end

        nfields = length(layout["fields"])
        println(
            "Generated $(basename(output_path)): ",
            "$nfields fields, LRECL=$(layout["lrecl"])"
        )
    end

    return output_dir
end

function _main(args)
    length(args) == 2 || error(
        "Usage:\n" *
        "  julia generate_layouts_2000.jl <documentation_dir> <output_dir>\n\n" *
        "Example:\n" *
        "  julia generate_layouts_2000.jl " *
        "~/.cache/CensoBR/raw/2000/1_Documentacao_20170908 " *
        "data/layouts/2000"
    )

    documentation_dir = expanduser(args[1])
    output_dir = expanduser(args[2])

    generate_layouts_2000(documentation_dir, output_dir)
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    _main(ARGS)
end
