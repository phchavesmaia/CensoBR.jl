using Downloads
using p7zip_jll
using ProgressMeter: Progress, update!, finish!

const IBGE_URLS = Dict(
	2000 => "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados",
	2010 => "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados",
)

const DOCUMENTATION_FILES = Dict(
    2000 => "1_Documentacao_20170908.zip",
    2010 => "Documentacao.zip",
)

const VALID_UFS = Set([
	"AC", "AL", "AM", "AP", "BA", "CE", "DF", "ES", "GO",
	"MA", "MG", "MS", "MT", "PA", "PB", "PE", "PI", "PR",
	"RJ", "RN", "RO", "RR", "RS", "SC", "SE", "SP", "TO",
])

"""
	_census_url(year, uf)

Return the official IBGE URL for a Census microdata archive.

# Examples

```julia
_census_url(2000, "RJ")
_census_url(2010, :RJ)
```
"""
function _census_url(year::Integer, uf::Union{String, Symbol})
	# checking if the year is supported
	year in keys(IBGE_URLS) || throw(ArgumentError("Unsupported census year: $year"))

	# converting the UF code to an uppercase string
	uf = uppercase(String(uf))

	# checking if the UF code is valid
	uf in VALID_UFS || throw(ArgumentError("Invalid UF code: $uf"))

	# 2010 São Paulo is a special case in the IBGE distribution.
	if year == 2010 && uf == "SP"
		throw(ArgumentError("Census 2010 SP is split into multiple archives; support for SP should be handled separately."))
	end

	"$(IBGE_URLS[year])/$uf.zip"
end

"""
_default_cache_dir()

Default location for downloaded CensoBR files.
"""
function _default_cache_dir()
	if Sys.iswindows()
		base = get(
			ENV,
			"LOCALAPPDATA",
			joinpath(homedir(), "AppData", "Local"),
		)
	elseif Sys.isapple()
		base = joinpath(homedir(), "Library", "Caches")
	else
		base = get(
			ENV,
			"XDG_CACHE_HOME",
			joinpath(homedir(), ".cache"),
		)
	end
	joinpath(base, "CensoBR")
end

"""
    _download_file(url, destination; force=false, show_progress=true, description="Downloading")

Download a file to `destination`, optionally displaying a progress bar.

Downloads are first written to a temporary `.part` file and moved to the final
destination only after a successful transfer. If `destination` already exists
and `force=false`, the existing file is returned.

Returns the path to the downloaded file.
"""
function _download_file(url::AbstractString, destination::AbstractString; force::Bool = false,
    show_progress::Bool = true, description::AbstractString = "Downloading")

	# determining the destination path for the downloaded ZIP file
    mkpath(dirname(destination))
    temporary = destination * ".part"

	# checking if the file already exists and if we should force a re-download
    if isfile(destination) && !force
        return destination
    end

	# defining the progress bar for the download
    progress = Ref{Union{Nothing,Progress}}(nothing)
    finished = Ref(false)
    function progress_callback(total, now)
        total <= 0 && return
        finished[] && return
        if isnothing(progress[])
            progress[] = Progress(total; desc = description, dt = 0.1, showspeed = false)
        end
        current = min(now, total)
        update!(progress[], current)
        if current >= total
            finished[] = true
        end
    end

	# remove a stale partial download, if one exists
    isfile(temporary) && rm(temporary)

	# downloading the ZIP file from the IBGE server
    try
        if show_progress
            Downloads.download(url, temporary; progress = progress_callback)
            if !isnothing(progress[]) && !finished[]
                finish!(progress[])
            end
        else
            Downloads.download(url, temporary)
        end
        mv(temporary, destination; force = true)
    catch
        isfile(temporary) && rm(temporary)
        rethrow()
    end

    destination
end

"""
_download_census(year, uf; cache_dir=_default_cache_dir(), force=false, show_progress=true)

Download an official IBGE Census microdata archive.

Returns the path to the cached ZIP file.
"""
function _download_census(year::Integer, uf; cache_dir::AbstractString = _default_cache_dir(), force::Bool = false, show_progress::Bool = true)
	# determining the URL for the Census archive
	url = _census_url(year, uf)

	# converting the UF code to an uppercase string
	uf = uppercase(String(uf))

	# ensuring the cache directory exists
	raw_dir = joinpath(cache_dir, "raw", string(year))
	mkpath(raw_dir)

	# determining the destination path for the downloaded ZIP file
	destination = joinpath(raw_dir, "$uf.zip")
	
	# downloading the file using the helper function
	_download_file(url, destination; force = force, show_progress = show_progress, description = "Downloading $uf $year")
end

"""
    _download_documentation(year; cache_dir=_default_cache_dir(),
                            force=false, show_progress=true)

Download the official IBGE documentation archive for a Census year.

Returns the path to the cached ZIP file.
"""
function _download_documentation(year::Integer; cache_dir::AbstractString = _default_cache_dir(), 
	force::Bool = false,show_progress::Bool = true)

    haskey(DOCUMENTATION_FILES, year) || throw(ArgumentError("Unsupported census year: $year"))

    filename = DOCUMENTATION_FILES[year]
    url = "$(IBGE_URLS[year])/$filename"

    destination = joinpath(cache_dir, "raw", string(year), filename,)

    _download_file(url, destination; force = force, show_progress = show_progress, description = "Downloading documentation $year")
end

"""
extract_census(zip_path; destination=nothing, force=false)

Extract a Census ZIP archive with 7-Zip.

Returns the extraction directory.
"""
function _extract_census(zip_path::AbstractString; force::Bool = false)
	# verifying that the ZIP file exists
	isfile(zip_path) || throw(ArgumentError("ZIP file does not exist: $zip_path"))

	# ensuring the destination directory is set
	destination = splitext(zip_path)[1]
	if isdir(destination)
		if !force
			return destination
		end
		rm(destination; recursive = true)
	end
	mkpath(destination)

	# extract archive with 7-Zip
	run(pipeline(`$(p7zip_jll.p7zip()) x $zip_path -o$destination -y`, stdout = devnull, stderr = devnull))
	
	destination
end

"""
_prepare_census(year, uf; cache_dir=_default_cache_dir(), force=false)

Download and extract an IBGE Census archive.

Returns the directory containing the extracted raw files.
"""
function _prepare_census(year::Integer, uf; cache_dir::AbstractString = _default_cache_dir(), force::Bool = false, show_progress::Bool = true)
	# downloading the ZIP file for the specified year and UF
	zip_path = _download_census(year, uf; cache_dir = cache_dir, force = force, show_progress = show_progress)
	documentation_zip = _download_documentation(year; cache_dir = cache_dir, force = force, show_progress = show_progress)

	# extracting the downloaded ZIP file
	census_dir = _extract_census(zip_path; force = force)
	documentation_dir = _extract_census(documentation_zip; force = force)

	(census = census_dir, documentation = documentation_dir)
end