function _layout_path(year::Integer, record::Symbol)
    key = (Int(year), record)

    haskey(LAYOUT_FILES, key) ||
        throw(ArgumentError(
            "Unsupported Census layout: year=$year, record=$record"
        ))

    path = joinpath(
        pkgdir(CensoBR),
        "data",
        "layouts",
        string(year),
        LAYOUT_FILES[key],
    )

    isfile(path) ||
        error("Bundled Census layout not found: $path")

    return path
end