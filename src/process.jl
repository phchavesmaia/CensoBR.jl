using Parquet2

const RAW_FILE_PREFIXES = Dict(
  (2000, :household) => "DOM",
  (2000, :family) => "FAMI",
  (2000, :person) => "PES",
  (2010, :household) => "AMOSTRA_DOMICILIOS_",
  (2010, :person) => "AMOSTRA_PESSOAS_",
  (2010, :emigration) => "AMOSTRA_EMIGRACAO_",
  (2010, :mortality) => "AMOSTRA_MORTALIDADE_"
)

"""
	_findrawfiles(censusdir, layout)

Find the fixed-width microdata file corresponding to `record` inside an
extracted Census directory.
"""
function _findrawfiles(censusdir::Vector{String}, layout::CensusLayout)
  # ensure that the requested Census file is supported.
  key = (layout.year, layout.record)
  !haskey(RAW_FILE_PREFIXES, key) &&
    throw(ArgumentError("Unsupported Census file: year=$(layout.year), record=$(layout.record)"))

  # retrieve the file prefix for the requested Census file.
  prefix = RAW_FILE_PREFIXES[key]

  # search for files matching the prefix in the Census directory.
  matches = String[]
  for dir in censusdir
    for (root, _, files) in walkdir(dir)
      for file in files
        startswith(uppercase(file), prefix) && push!(matches, joinpath(root, file))
      end
    end
  end

  isempty(matches) && error("Could not find $(layout.record) microdata for Census $(layout.year) " * "in: $censusdir")

  sort!(matches)

  matches
end

function _processcensus(
  year::Integer,
  uf;
  cachedir::String,
  force::Bool=false,
  showprogress::Bool=true,
  chunksize::Integer
)
  # prepare the Census data directory and paths
  censusdir = _preparecensus(year, uf; cachedir=cachedir, force=force, showprogress=showprogress)

  # process each record for the given year and UF
  Threads.@threads for record in CENSUS_RECORDS[year]
    # determine the path for the processed Parquet file
    parquetpath = joinpath(cachedir, "parquet", string(year), uppercase(String(uf)), "$(record).parquet")
    # reuse the processed cache
    if isfile(parquetpath) && !force
      continue
    end
    # load the layout and find the raw file for this record
    layout = _loadlayout(year, record)
    paths = _findrawfiles(censusdir, layout)

    # create an iterable of chunks from the raw file
    chunks = Iterators.flatten(CensusChunks(path, layout; chunksize=chunksize) for path in paths)
    mkpath(dirname(parquetpath))

    # avoid leaving a corrupt final cache entry if writing fails
    temporary = parquetpath * ".part"
    isfile(temporary) && rm(temporary; force=true)
    try
      open(temporary, "w") do io
        fw = Parquet2.FileWriter(io, temporary)
        Parquet2.writeiterable!(fw, chunks)
      end
      mv(temporary, parquetpath; force=true)
    catch
      isfile(temporary) && rm(temporary; force=true)
      rethrow()
    end
  end
  # raw files are no longer necessary once the Parquet cache is complete.
  for dir in censusdir
    rm(dir * ".zip"; force=true)
    rm(dir; recursive=true, force=true)
  end
end
