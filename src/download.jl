using Downloads
using ZipFile

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
	census_url(year, uf)

Return the official IBGE URL for a Census microdata archive.

# Examples

```julia
census_url(2000, "RJ")
census_url(2010, :RJ)
```
"""
function census_url(year::Integer, uf)
	year in keys(ibge_urls) || throw(ArgumentError("Unsupported census year: $year"))
	uf = uppercase(String(uf))

	uf in valid_ufs || throw(ArgumentError("Invalid UF code: $uf"))

	# 2010 São Paulo is a special case in the IBGE distribution.
	if year == 2010 && uf == "SP"
		throw(ArgumentError("Census 2010 SP is split into multiple archives; support for SP should be handled separately."))
	end

	return "$(ibge_urls[year])/$uf.zip"
end

"""
default_cache_dir()

Default location for downloaded CensoBR files.
"""
default_cache_dir() = joinpath(DEPOT_PATH[1], "censobr")

"""
download_census(year, uf; cache_dir=default_cache_dir(), force=false)

Download an official IBGE Census microdata archive.

Returns the path to the cached ZIP file.
"""
function download_census(year::Integer, uf; cache_dir::AbstractString = default_cache_dir(), force::Bool = false)
	uf = uppercase(String(uf))
	url = census_url(year, uf)
	raw_dir = joinpath(cache_dir, "raw", string(year))
	mkpath(raw_dir)

	destination = joinpath(raw_dir, "$uf.zip")

	if isfile(destination) && !force
		return destination
	end

	Downloads.download(url, destination)

	return destination
end

"""
extract_census(zip_path; destination=nothing, force=false)

Extract a Census ZIP archive.

Returns the extraction directory.
"""
function extract_census(zip_path::AbstractString; destination::Union{Nothing, AbstractString} = nothing, force::Bool = false)
	isfile(zip_path) || throw(ArgumentError("ZIP file does not exist: $zip_path"))
	if destination === nothing
		destination = splitext(zip_path)[1]
	end

	if isdir(destination)
		if !force
			return destination
		end

		rm(destination; recursive = true)
	end

	mkpath(destination)

	ZipFile.Reader(zip_path) do archive
		for entry in archive.files
			outpath = joinpath(destination, entry.name)

			if endswith(entry.name, "/")
				mkpath(outpath)
				continue
			end

			mkpath(dirname(outpath))

			open(outpath, "w") do io
				write(io, read(entry))
			end
		end
	end

	return destination
end

"""
prepare_census(year, uf; cache_dir=default_cache_dir(), force=false)

Download and extract an IBGE Census archive.

Returns the directory containing the extracted raw files.
"""
function prepare_census(year::Integer, uf; cache_dir::AbstractString = default_cache_dir(), force::Bool = false)
	
    zip_path = download_census(year, uf; cache_dir = cache_dir, force = force)
	
    extracted_dir = joinpath(cache_dir, "raw", string(year), uppercase(String(uf)))

	return extract_census( zip_path; destination = extracted_dir, force = force)
end

