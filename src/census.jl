
const CENSUS_RECORDS =
  Dict(2000 => (:household, :family, :person), 2010 => (:household, :person, :emigration, :mortality))

"""
	opencensus(year, uf, record; cachedir=_defaultcachedir(),
			   force=false, showprogress=true)

Open IBGE Census microdata as a Parquet2 dataset.

If a processed Parquet file is not already cached, CensoBR downloads and
extracts the corresponding Census archive, parses the fixed-width microdata,
writes the result to Parquet, and removes the temporary raw files.

See also [`fieldmetadata`](@ref), [`fieldlabel`](@ref), [`fieldvalues`](@ref), and [`fieldnotes`](@ref)
"""
function opencensus(
  year::Integer,
  uf::Union{String,Symbol},
  record::Symbol;
  cachedir::String=_defaultcachedir(),
  force::Bool=false,
  showprogress::Bool=true,
  chunksize::Integer=5_000
)

  # checks
  haskey(CENSUS_RECORDS, year) || throw(ArgumentError("Unsupported census year: $year"))
  record in CENSUS_RECORDS[year] || throw(ArgumentError("Unsupported record `$record` for Census $year"))
  chunksize > 0 || throw(ArgumentError("chunksize must be positive"))

  # setup
  uf = uppercase(String(uf))
  _censusurl(year, uf) # validate UF before returning a cached dataset

  parquetpath = joinpath(cachedir, "parquet", string(year), uppercase(String(uf)), "$(record).parquet")

  if !isfile(parquetpath) || force
    _processcensus(year, uf; cachedir=cachedir, force=force, showprogress=showprogress, chunksize=chunksize)
  end

  Parquet2.Dataset(parquetpath)
end
