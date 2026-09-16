using CensoBR
using Parquet2

year = 2000
uf = :rj
record = :person

println("=== Setup ===")

layout = CensoBR._loadlayout(year, record)

censusdir = CensoBR._preparecensus(year, uf; showprogress=false)

path = CensoBR._findrawfile(censusdir, layout)

names = Tuple(Symbol(field.name) for field in layout.fields)

println("Raw file: ", path)
println("Columns: ", length(layout.fields))

# -------------------------------------------------------------------
# 1. Benchmark parsing only
# -------------------------------------------------------------------

println()
println("=== Parse chunk benchmark ===")

for chunksize in (5_000, 10_000, 25_000, 50_000, 100_000)
  stats = open(path, "r") do io
    GC.gc()

    @timed CensoBR._parsechunk!(io, layout, names; chunksize=chunksize)
  end

  chunk = stats.value

  println(
    "chunksize=$chunksize: ",
    "rows=$(length(first(chunk))), ",
    "time=$(round(stats.time, digits=3)) s, ",
    "gc=$(round(stats.gctime, digits=3)) s, ",
    "allocated=$(Base.format_bytes(stats.bytes))"
  )
end

# -------------------------------------------------------------------
# 2. Benchmark full serial Parquet pipeline
# -------------------------------------------------------------------

println()
println("=== Full chunked Parquet pipeline ===")

for chunksize in (5_000, 10_000, 25_000, 50_000, 100_000)
  mktempdir() do tmpdir
    parquetpath = joinpath(tmpdir, "person.parquet")

    chunks = CensoBR.CensusChunks(path, layout; chunksize=chunksize)

    GC.gc()

    stats = @timed begin
      open(parquetpath, "w") do io
        writer = Parquet2.FileWriter(io, parquetpath)

        Parquet2.writeiterable!(writer, chunks)
      end
    end

    println(
      "chunksize=$chunksize: ",
      "time=$(round(stats.time, digits=3)) s, ",
      "gc=$(round(stats.gctime, digits=3)) s, ",
      "allocated=$(Base.format_bytes(stats.bytes)), ",
      "size=$(Base.format_bytes(filesize(parquetpath)))"
    )
  end
end

# -------------------------------------------------------------------
# 3. Repeat best candidates to reduce noise
# -------------------------------------------------------------------

println()
println("=== Repeated trials ===")

for chunksize in (5_000, 10_000, 25_000)
  println()
  println("chunksize=$chunksize")

  for trial in 1:5
    mktempdir() do tmpdir
      parquetpath = joinpath(tmpdir, "person.parquet")

      chunks = CensoBR.CensusChunks(path, layout; chunksize=chunksize)

      GC.gc()

      stats = @timed begin
        open(parquetpath, "w") do io
          writer = Parquet2.FileWriter(io, parquetpath)

          Parquet2.writeiterable!(writer, chunks)
        end
      end

      println(
        "trial=$trial: ",
        "time=$(round(stats.time, digits=3)) s, ",
        "gc=$(round(stats.gctime, digits=3)) s, ",
        "allocated=$(Base.format_bytes(stats.bytes))"
      )
    end
  end
end

# -------------------------------------------------------------------
# 4. Optional: full user-facing path
# -------------------------------------------------------------------

println()
println("=== Full opencensus path ===")

for chunksize in (5_000, 10_000, 25_000)
  println()
  println("chunksize=$chunksize")

  mktempdir() do tmpdir
    GC.gc()

    stats = @timed CensoBR.opencensus(year, uf, record; cachedir=tmpdir, showprogress=false, chunksize=chunksize)

    println(
      "time=$(round(stats.time, digits=3)) s, ",
      "gc=$(round(stats.gctime, digits=3)) s, ",
      "allocated=$(Base.format_bytes(stats.bytes))"
    )
  end
end
