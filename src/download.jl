using Downloads
using ZipFile
using ProgressMeter: Progress, update!, finish!

const ibge_urls = Dict(
	2000 => "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados",
	2010 => "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados",
)

const valid_ufs = Set([
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
function _census_url(year::Integer, uf)
	# checking if the year is supported
	year in keys(ibge_urls) || throw(ArgumentError("Unsupported census year: $year"))
	
	# converting the UF code to an uppercase string
	uf = uppercase(String(uf))

	# checking if the UF code is valid
	uf in valid_ufs || throw(ArgumentError("Invalid UF code: $uf"))

	# 2010 São Paulo is a special case in the IBGE distribution.
	if year == 2010 && uf == "SP"
		throw(ArgumentError("Census 2010 SP is split into multiple archives; support for SP should be handled separately."))
	end

	"$(ibge_urls[year])/$uf.zip"
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
_download_census(year, uf; cache_dir=default_cache_dir(), force=false)

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
	temporary = destination * ".part"

	# checking if the file already exists and if we should force a re-download
	if isfile(destination) && !force
		return destination
	end

	# defining the progress bar for the download
	progress = Ref{Union{Nothing,Progress}}(nothing)
    function progress_callback(total, now)
        total <= 0 && return # the server may initially report total == 0
        if isnothing(progress[])
            progress[] = Progress(total; desc = "Downloading $uf $year", showspeed = true)
        end
        update!(progress[], now)
    end

	# Remove a stale partial download, if one exists
    isfile(temporary) && rm(temporary)

	# downloading the ZIP file from the IBGE server
	try
		if show_progress 
			Downloads.download(url, temporary; progress = progress_callback)
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
extract_census(zip_path; destination=nothing, force=false)

Extract a Census ZIP archive.

Returns the extraction directory.
"""
function _extract_census(zip_path::AbstractString; destination::AbstractString = splitext(zip_path)[1], force::Bool = false)
	# verifying that the ZIP file exists
	isfile(zip_path) || throw(ArgumentError("ZIP file does not exist: $zip_path"))

	# ensuring the destination directory is set
	if isdir(destination)
		if !force
			return destination
		end
		rm(destination; recursive = true)
	end
	mkpath(destination)

	# extracting the contents of the ZIP archive
	ZipFile.Reader(zip_path) do archive
		for entry in archive.files
			outpath = joinpath(destination, entry.name)
			# determining the output path for the current entry
			if endswith(entry.name, "/")
				mkpath(outpath)
				continue
			end
			mkpath(dirname(outpath))
			# creating the output file and writing its contents
			open(outpath, "w") do io
				write(io, read(entry))
			end
		end
	end

	destination
end

"""
_prepare_census(year, uf; cache_dir=_default_cache_dir(), force=false)

Download and extract an IBGE Census archive.

Returns the directory containing the extracted raw files.
"""
function _prepare_census(year::Integer, uf; cache_dir::AbstractString = _default_cache_dir(), force::Bool = false)
	
    zip_path = _download_census(year, uf; cache_dir = cache_dir, force = force)
	
    extracted_dir = joinpath(cache_dir, "raw", string(year), uppercase(String(uf)))

	_extract_census(zip_path; destination = extracted_dir, force = force)
end

