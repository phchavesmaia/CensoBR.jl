using CensoBR
using BenchmarkTools

# Prepare the real RR 2000 person file.
layout = CensoBR._loadlayout(2000, :person)

censusdir = CensoBR._preparecensus(2000, :rr; showprogress=false)

path = CensoBR._findrawfile(censusdir, layout)

# Construct the optimized Tables.jl adapter.
table = CensoBR.CensusTable(path, layout)

# Grab one physical line for microbenchmarking.
line = open(readline, path)
bytes = codeunits(line)

println("=== Single row ===")

@btime CensoBR._parseline($layout, $(table.names), $bytes)

println()
println("=== Entire file through CensusTable ===")

@time begin
  n = 0

  for row in table
    n += 1
  end

  println("Rows parsed: ", n)
end

println()
println("=== Allocations for entire file ===")

stats = @timed begin
  n = 0

  for row in table
    n += 1
  end

  n
end

println("Rows: ", stats.value)
println("Time: ", stats.time, " seconds")
println("Allocated: ", Base.format_bytes(stats.bytes))

using Parquet2

println()
println("=== Parquet conversion ===")

mktempdir() do tmpdir
  parquetpath = joinpath(tmpdir, "person.parquet")

  @time Parquet2.writefile(parquetpath, table)

  println("Parquet size: ", Base.format_bytes(filesize(parquetpath)))
end

using Tables
using Parquet2
using BenchmarkTools

rows = collect(table)

mktempdir() do tmpdir
  path = joinpath(tmpdir, "person.parquet")

  @time Parquet2.writefile(path, rows)
end

cols = Tables.columntable(table)
mktempdir() do tmpdir
  path = joinpath(tmpdir, "person.parquet")

  @time Parquet2.writefile(path, cols)
end

println("=== Build column table ===")

cols_stats = @timed Tables.columntable(table)

println("Time: ", cols_stats.time)
println("Allocated: ", Base.format_bytes(cols_stats.bytes))

cols = cols_stats.value

println()
println("=== Write column table ===")

mktempdir() do tmpdir
  path = joinpath(tmpdir, "person.parquet")

  # First run warms compilation.
  Parquet2.writefile(path, cols)

  rm(path)

  # Second run is the useful timing.
  stats = @timed Parquet2.writefile(path, cols)

  println("Time: ", stats.time)
  println("Allocated: ", Base.format_bytes(stats.bytes))
end
