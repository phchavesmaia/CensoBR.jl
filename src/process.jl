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

function _processcountrycensus(
  year::Integer;
  cachedir::String,
  force::Bool=false,
  showprogress::Bool=true,
  chunksize::Integer
)
  records = CENSUS_RECORDS[year]
  parquetdir = joinpath(cachedir, "parquet", string(year), "BR")
  mkpath(parquetdir)

  temporary = Dict(record => joinpath(parquetdir, "$(record).parquet.part") for record in records)
  streams = Dict{Symbol,IOStream}()
  writers = Dict{Symbol,Any}()

  try
    for record in records
      isfile(temporary[record]) && rm(temporary[record]; force=true)
      streams[record] = open(temporary[record], "w")
      writers[record] = Parquet2.FileWriter(streams[record], temporary[record])
    end

    # Process one UF at a time so the large extracted source files can be
    # removed before downloading the next state's archives.
    for uf in sort!(collect(VALID_UFS))
      censusdir = _preparecensus(year, uf; cachedir=cachedir, force=force, showprogress=showprogress)
      Threads.@threads for record in records
        layout = _loadlayout(year, record)
        paths = _findrawfiles(censusdir, layout)
        chunks = Iterators.flatten(CensusChunks(path, layout; chunksize=chunksize) for path in paths)
        for chunk in chunks
          Parquet2.writetable!(writers[record], chunk)
        end
      end
      for dir in censusdir
        rm(dir * ".zip"; force=true)
        rm(dir; recursive=true, force=true)
      end
    end

    for record in records
      Parquet2.finalize!(writers[record])
      close(streams[record])
      mv(temporary[record], joinpath(parquetdir, "$(record).parquet"); force=true)
    end
  catch
    for io in values(streams)
      isopen(io) && close(io)
    end
    for path in values(temporary)
      isfile(path) && rm(path; force=true)
    end
    rethrow()
  end
end
