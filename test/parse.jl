@testitem "Parse fixed-width fields" begin
  using CensoBR

  character = CensoBR.LayoutField("CODE", 1, 4, 0, true, nothing, Dict{String,String}(), String[])

  integer = CensoBR.LayoutField("COUNT", 5, 4, 0, false, nothing, Dict{String,String}(), String[])

  decimal = CensoBR.LayoutField("VALUE", 9, 5, 2, false, nothing, Dict{String,String}(), String[])

  bytes = codeunits(" 33 001200345")

  @test CensoBR._parsefield(character, bytes) == "33"
  @test CensoBR._parsefield(integer, bytes) == 12
  @test CensoBR._parsefield(decimal, bytes) == 3.45
end

@testitem "Parse blank fixed-width fields" begin
  using CensoBR

  character = CensoBR.LayoutField("CODE", 1, 3, 0, true, nothing, Dict{String,String}(), String[])

  numeric = CensoBR.LayoutField("VALUE", 4, 3, 0, false, nothing, Dict{String,String}(), String[])

  bytes = codeunits("      ")

  @test ismissing(CensoBR._parsefield(character, bytes))
  @test ismissing(CensoBR._parsefield(numeric, bytes))
end

@testitem "Parse fixed-width field errors" begin
  using CensoBR

  numeric = CensoBR.LayoutField("VALUE", 1, 3, 0, false, nothing, Dict{String,String}(), String[])

  @test_throws ArgumentError CensoBR._parsefield(numeric, codeunits("ABC"))

  field = CensoBR.LayoutField("VALUE", 4, 3, 0, false, nothing, Dict{String,String}(), String[])

  @test_throws ArgumentError CensoBR._parsefield(field, codeunits("12345"))
end

@testitem "Parse integer bytes" begin
  using CensoBR

  @test CensoBR._parseint(codeunits("123"), "VALUE") == 123

  @test CensoBR._parseint(codeunits("-123"), "VALUE") == -123

  @test CensoBR._parseint(codeunits("+123"), "VALUE") == 123

  @test_throws ArgumentError CensoBR._parseint(codeunits("12A"), "VALUE")

  @test_throws ArgumentError CensoBR._parseint(codeunits("+"), "VALUE")
end

@testitem "Parse short trailing fields" begin
  using CensoBR

  fields = [
    CensoBR.LayoutField("A", 1, 2, 0, true, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("B", 5, 2, 0, true, nothing, Dict{String,String}(), String[])
  ]

  bytes = codeunits("33")

  @test CensoBR._parsefield(fields[1], bytes) == "33"
  @test ismissing(CensoBR._parsefield(fields[2], bytes))
end

@testitem "Reject truncated Census field" begin
  using CensoBR

  field = CensoBR.LayoutField("A", 2, 3, 0, true, nothing, Dict{String,String}(), String[])

  @test_throws ArgumentError CensoBR._parsefield(field, codeunits("12"))
end

@testitem "Column element types" begin
  using CensoBR

  character = CensoBR.LayoutField("A", 1, 2, 0, true, nothing, Dict{String,String}(), String[])

  integer = CensoBR.LayoutField("B", 3, 2, 0, false, nothing, Dict{String,String}(), String[])

  decimal = CensoBR.LayoutField("C", 5, 2, 1, false, nothing, Dict{String,String}(), String[])

  @test CensoBR._columneltype(character) == Union{Missing,String}
  @test CensoBR._columneltype(integer) == Union{Missing,Int}
  @test CensoBR._columneltype(decimal) == Union{Missing,Float64}
end

@testitem "Make Census columns" begin
  using CensoBR

  fields = [
    CensoBR.LayoutField("UF", 1, 2, 0, true, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("COUNT", 3, 3, 0, false, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("WEIGHT", 6, 4, 2, false, nothing, Dict{String,String}(), String[])
  ]

  layout = CensoBR.CensusLayout(2000, :household, 9, fields)

  columns = CensoBR._makecolumns(layout, 10)

  @test length(columns) == 3

  @test eltype(columns[1]) == Union{Missing,String}
  @test eltype(columns[2]) == Union{Missing,Int}
  @test eltype(columns[3]) == Union{Missing,Float64}

  @test all(length(column) == 10 for column in columns)
end

@testitem "Parse Census chunk" begin
  using CensoBR

  fields = [
    CensoBR.LayoutField("UF", 1, 2, 0, true, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("COUNT", 3, 3, 0, false, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("WEIGHT", 6, 4, 2, false, nothing, Dict{String,String}(), String[])
  ]

  layout = CensoBR.CensusLayout(2000, :household, 9, fields)

  names = (:UF, :COUNT, :WEIGHT)

  mktemp() do path, io
    write(io, "330120345\n" * "350070125\n" * "41042    \n")

    seekstart(io)

    chunk = CensoBR._parsechunk!(io, layout, names; chunksize=10)

    @test propertynames(chunk) == names
    @test length(chunk.UF) == 3

    @test chunk.UF == ["33", "35", "41"]
    @test chunk.COUNT == [12, 7, 42]

    @test isequal(chunk.WEIGHT, Union{Missing,Float64}[3.45, 1.25, missing])

    @test isnothing(CensoBR._parsechunk!(io, layout, names; chunksize=10))
  end
end

@testitem "Parse Census chunk boundaries" begin
  using CensoBR

  fields = [CensoBR.LayoutField("UF", 1, 2, 0, true, nothing, Dict{String,String}(), String[])]

  layout = CensoBR.CensusLayout(2000, :household, 2, fields)

  names = (:UF,)

  mktemp() do path, io
    write(io, "33\n35\n41\n")

    seekstart(io)

    firstchunk = CensoBR._parsechunk!(io, layout, names; chunksize=2)

    secondchunk = CensoBR._parsechunk!(io, layout, names; chunksize=2)

    @test firstchunk.UF == ["33", "35"]
    @test secondchunk.UF == ["41"]

    @test isnothing(CensoBR._parsechunk!(io, layout, names; chunksize=2))
  end
end

@testitem "Census chunk iterator" begin
  using CensoBR

  fields = [CensoBR.LayoutField("UF", 1, 2, 0, true, nothing, Dict{String,String}(), String[])]

  layout = CensoBR.CensusLayout(2000, :household, 2, fields)

  mktempdir() do tmpdir
    path = joinpath(tmpdir, "data.txt")

    write(path, "33\n35\n41\n")

    chunks = CensoBR.CensusChunks(path, layout; chunksize=2)

    collected = collect(chunks)

    @test length(collected) == 2
    @test collected[1].UF == ["33", "35"]
    @test collected[2].UF == ["41"]
  end
end
