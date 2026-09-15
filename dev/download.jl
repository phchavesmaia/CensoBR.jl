pushfirst!(LOAD_PATH, dirname(@__DIR__))

using CensoBR

const DOCUMENTATION_FILES =
    Dict(2000 => "1_Documentacao_20170908.zip", 2010 => "Documentacao.zip")

function downloaddocumentation(
    year::Integer;
    cachedir::AbstractString = CensoBR._defaultcachedir(),
    force::Bool = false,
    showprogress::Bool = true,
)

    haskey(DOCUMENTATION_FILES, year) ||
        throw(ArgumentError("Unsupported census year: $year"))

    filename = DOCUMENTATION_FILES[year]
    url = "$(CensoBR.IBGE_URLS[year])/$filename"

    destination = joinpath(cachedir, "raw", string(year), filename)

    CensoBR._downloadfile(
        url,
        destination;
        force = force,
        showprogress = showprogress,
        description = "Downloading documentation $year",
    )

    destination
end

function preparedocumentation(
    year::Integer;
    cachedir::AbstractString = CensoBR._defaultcachedir(),
    force::Bool = false,
    showprogress::Bool = true,
)

    zippath = downloaddocumentation(
        year;
        cachedir = cachedir,
        force = force,
        showprogress = showprogress,
    )

    CensoBR._extractarchive(zippath; force = force)
end
