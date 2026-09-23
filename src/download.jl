using Downloads, p7zip_jll
using ProgressMeter: Progress, update!, finish!

const IBGE_URLS = Dict(
  2000 => "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados",
  2010 => "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados"
)

const VALID_UFS = Set([
  "AC",
  "AL",
  "AM",
  "AP",
  "BA",
  "CE",
  "DF",
  "ES",
  "GO",
  "MA",
  "MG",
  "MS",
  "MT",
  "PA",
  "PB",
  "PE",
  "PI",
  "PR",
  "RJ",
  "RN",
  "RO",
  "RR",
  "RS",
  "SC",
  "SE",
  "SP",
  "TO"
])

function _censusurl(year::Integer, uf::Union{String,Symbol})
  # checking if the year is supported
  year in keys(IBGE_URLS) || throw(ArgumentError("Unsupported census year: $year"))

  # converting the UF code to an uppercase string
  uf = uppercase(String(uf))

  # checking if the UF code is valid
  uf in VALID_UFS || throw(ArgumentError("Invalid UF code: $uf"))

  # 2010 São Paulo is a special case in the IBGE distribution.
  if year == 2010 && uf == "SP"
    return ["$(IBGE_URLS[year])/SP1.zip", "$(IBGE_URLS[year])/SP2_RM.zip"]
  end

  ["$(IBGE_URLS[year])/$uf.zip"]
end

function _defaultcachedir()
  if Sys.iswindows()
    base = get(ENV, "LOCALAPPDATA", joinpath(homedir(), "AppData", "Local"))
  elseif Sys.isapple()
    base = joinpath(homedir(), "Library", "Caches")
  else
    base = get(ENV, "XDG_CACHE_HOME", joinpath(homedir(), ".cache"))
  end
  joinpath(base, "CensoBR")
end

"""
	_downloadfile(url, destination; force=false, showprogress=true, description="Downloading")

Download a file to `destination`, optionally displaying a progress bar.

Downloads are first written to a temporary `.part` file and moved to the final
destination only after a successful transfer. If `destination` already exists
and `force=false`, the existing file is returned.

Returns the path to the downloaded file.
"""
function _downloadfile(
  url::String,
  destination::String;
  force::Bool=false,
  showprogress::Bool=true,
  description::String="Downloading"
)

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
    total ≤ 0 && return
    finished[] && return
    if isnothing(progress[])
      progress[] = Progress(total; desc=description, dt=0.1, showspeed=false)
    end
    current = min(now, total)
    update!(progress[], current)
    if current ≥ total
      finished[] = true
    end
  end

  # remove a stale partial download, if one exists
  isfile(temporary) && rm(temporary)

  # downloading the ZIP file from the IBGE server
  try
    if showprogress
      Downloads.download(url, temporary; progress=progress_callback)
      if !isnothing(progress[]) && !finished[]
        finish!(progress[])
      end
    else
      Downloads.download(url, temporary)
    end
    mv(temporary, destination; force=true)
  catch
    isfile(temporary) && rm(temporary)
    rethrow()
  end

  destination
end

function _downloadcensus(
  year::Integer,
  uf;
  cachedir::String=_defaultcachedir(),
  force::Bool=false,
  showprogress::Bool=true
)
  # determining the URL for the Census archive
  urls = _censusurl(year, uf)

  # ensuring the cache directory exists
  raw_dir = joinpath(cachedir, "raw", string(year))
  mkpath(raw_dir)

  # downloading with the helper function
  [
    _downloadfile(
      url,
      joinpath(raw_dir, basename(url));
      force=force,
      showprogress=showprogress,
      description="Downloading $(basename(url))"
    ) for url in urls
  ]
end

function _extractarchive(zippaths::Vector{String}; force::Bool=false)
  destinations = String[]
  for zippath in zippaths
    # verifying that the ZIP file exists
    isfile(zippath) || throw(ArgumentError("ZIP file does not exist: $zippath"))

    # ensuring the destination directory is set
    destination = splitext(zippath)[1]
    push!(destinations, destination)
    if isdir(destination)
      if !force
        continue
      end
      rm(destination; recursive=true)
    end
    mkpath(destination)

    # extract archive with 7-Zip
    try
      run(pipeline(`$(p7zip_jll.p7zip()) x $zippath -o$destination -y`, stdout=devnull, stderr=devnull))
    catch
      rm(destination; recursive=true, force=true)
      rethrow()
    end
  end
  destinations
end

function _preparecensus(
  year::Integer,
  uf;
  cachedir::String=_defaultcachedir(),
  force::Bool=false,
  showprogress::Bool=true
)
  # downloading the ZIP file for the specified year and UF
  zippaths = _downloadcensus(year, uf; cachedir=cachedir, force=force, showprogress=showprogress)

  # extracting the downloaded ZIP file
  _extractarchive(zippaths; force=force)
end
