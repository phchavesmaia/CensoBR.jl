@testitem "Find raw Census files" begin
  using CensoBR

  mktempdir() do tmpdir
    # Census 2000
    dir2000 = joinpath(tmpdir, "2000")
    mkpath(joinpath(dir2000, "RJ"))

    write(joinpath(dir2000, "RJ", "Dom33.txt"), "")
    write(joinpath(dir2000, "RJ", "FAMI33.TXT"), "")
    write(joinpath(dir2000, "RJ", "Pes33.txt"), "")

    household2000 = CensoBR._loadlayout(2000, :household)
    family2000 = CensoBR._loadlayout(2000, :family)
    person2000 = CensoBR._loadlayout(2000, :person)

    @test basename(CensoBR._findrawfile(dir2000, household2000)) == "Dom33.txt"

    @test basename(CensoBR._findrawfile(dir2000, family2000)) == "FAMI33.TXT"

    @test basename(CensoBR._findrawfile(dir2000, person2000)) == "Pes33.txt"

    # Census 2010
    dir2010 = joinpath(tmpdir, "2010")
    mkpath(dir2010)

    write(joinpath(dir2010, "Amostra_Domicilios_33.txt"), "")
    write(joinpath(dir2010, "Amostra_Pessoas_33.txt"), "")
    write(joinpath(dir2010, "Amostra_Emigracao_33.txt"), "")
    write(joinpath(dir2010, "Amostra_Mortalidade_33.txt"), "")

    household2010 = CensoBR._loadlayout(2010, :household)
    person2010 = CensoBR._loadlayout(2010, :person)
    emigration2010 = CensoBR._loadlayout(2010, :emigration)
    mortality2010 = CensoBR._loadlayout(2010, :mortality)

    @test basename(CensoBR._findrawfile(dir2010, household2010)) == "Amostra_Domicilios_33.txt"

    @test basename(CensoBR._findrawfile(dir2010, person2010)) == "Amostra_Pessoas_33.txt"

    @test basename(CensoBR._findrawfile(dir2010, emigration2010)) == "Amostra_Emigracao_33.txt"

    @test basename(CensoBR._findrawfile(dir2010, mortality2010)) == "Amostra_Mortalidade_33.txt"
  end
end

@testitem "Find raw Census file errors" begin
  using CensoBR

  mktempdir() do tmpdir
    layout = CensoBR._loadlayout(2000, :household)

    @test_throws ErrorException CensoBR._findrawfile(tmpdir, layout)

    write(joinpath(tmpdir, "Dom33.txt"), "")
    write(joinpath(tmpdir, "DOM99.TXT"), "")

    @test_throws ErrorException CensoBR._findrawfile(tmpdir, layout)
  end

  layout = CensoBR.CensusLayout(1990, :household, 10, CensoBR.LayoutField[])

  mktempdir() do tmpdir
    @test_throws ArgumentError CensoBR._findrawfile(tmpdir, layout)
  end
end

@testitem "Parse fixed-width field" begin
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

@testitem "Parse fixed-width Census line" begin
  using CensoBR

  fields = [
    CensoBR.LayoutField("UF", 1, 2, 0, true, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("COUNT", 3, 3, 0, false, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("WEIGHT", 6, 4, 2, false, nothing, Dict{String,String}(), String[])
  ]

  layout = CensoBR.CensusLayout(2000, :household, 9, fields)

  row = CensoBR._parseline(layout, codeunits("330120345"))

  @test row isa NamedTuple
  @test row.UF == "33"
  @test row.COUNT == 12
  @test row.WEIGHT == 3.45
  @test propertynames(row) == (:UF, :COUNT, :WEIGHT)

  @test_throws ArgumentError CensoBR._parseline(layout, codeunits("33012"))
end

@testitem "Census table adapter" begin
  using CensoBR
  using Tables

  fields = [
    CensoBR.LayoutField("UF", 1, 2, 0, true, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("COUNT", 3, 3, 0, false, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("WEIGHT", 6, 4, 2, false, nothing, Dict{String,String}(), String[])
  ]

  layout = CensoBR.CensusLayout(2000, :household, 9, fields)

  mktempdir() do tmpdir
    path = joinpath(tmpdir, "test.txt")

    write(path, "330120345\n" * "350070125\n" * "41042    \n")

    table = CensoBR.CensusTable(path, layout)

    @test table.path == path
    @test table.layout === layout

    @test Tables.istable(typeof(table))
    @test Tables.rowaccess(typeof(table))
    @test Tables.rows(table) === table

    @test Base.IteratorSize(typeof(table)) == Base.SizeUnknown()
    @test Base.IteratorEltype(typeof(table)) == Base.EltypeUnknown()

    rows = collect(table)

    @test length(rows) == 3
    @test rows[1] == (UF="33", COUNT=12, WEIGHT=3.45)
    @test rows[2] == (UF="35", COUNT=7, WEIGHT=1.25)
    @test isequal(rows[3], (UF="41", COUNT=42, WEIGHT=missing))
  end
end

@testitem "Census table schema" begin
  using CensoBR
  using Tables

  fields = [
    CensoBR.LayoutField("UF", 1, 2, 0, true, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("COUNT", 3, 3, 0, false, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("WEIGHT", 6, 4, 2, false, nothing, Dict{String,String}(), String[])
  ]

  layout = CensoBR.CensusLayout(2000, :household, 9, fields)
  table = CensoBR.CensusTable("dummy.txt", layout)
  schema = Tables.schema(table)

  @test schema.names == (:UF, :COUNT, :WEIGHT)
  @test schema.types == (Union{Missing,String}, Union{Missing,Int}, Union{Missing,Float64})
end

@testitem "Parquet cache path" begin
  using CensoBR

  mktempdir() do tmpdir
    path = CensoBR._parquetpath(2000, :rj, :household; cachedir=tmpdir)

    @test path == joinpath(tmpdir, "parquet", "2000", "RJ", "household.parquet")
  end
end

@testitem "Clear raw Census files" begin
  using CensoBR

  mktempdir() do tmpdir
    rawdir = joinpath(tmpdir, "raw", "2000")

    extracteddir = joinpath(rawdir, "RJ")
    zippath = joinpath(rawdir, "RJ.zip")

    mkpath(extracteddir)
    write(zippath, "archive")
    write(joinpath(extracteddir, "Dom33.txt"), "data")

    CensoBR._clearraw(2000, "RJ"; cachedir=tmpdir)

    @test !isfile(zippath)
    @test !isdir(extracteddir)
  end
end

@testitem "Open Census errors" begin
  using CensoBR

  @test_throws ArgumentError CensoBR.opencensus(1990, :rj, :household)
  @test_throws ArgumentError CensoBR.opencensus(2000, :rj, :mortality)
  @test_throws ArgumentError CensoBR.opencensus(2000, :xx, :household)
end

@testitem "Public API" begin
  using CensoBR

  @test isdefined(CensoBR, :opencensus)
end

@testitem "Reject truncated Census field" begin
  using CensoBR

  field = CensoBR.LayoutField("A", 2, 3, 0, true, nothing, Dict{String,String}(), String[])

  @test_throws ArgumentError CensoBR._parsefield(field, codeunits("12"))
end

@testitem "Parse short Census line" begin
  using CensoBR

  fields = [
    CensoBR.LayoutField("A", 1, 2, 0, true, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("B", 5, 2, 0, true, nothing, Dict{String,String}(), String[])
  ]

  layout = CensoBR.CensusLayout(2000, :household, 6, fields)

  row = CensoBR._parseline(layout, codeunits("33"))

  @test row.A == "33"
  @test ismissing(row.B)
end

@testitem "Process Census" begin
  using CensoBR
  using Parquet2

  mktempdir() do tmpdir
    CensoBR._processcensus(2000, "RR"; cachedir=tmpdir, showprogress=false)

    # Every record was converted to Parquet.
    for record in CensoBR.CENSUS_RECORDS[2000]
      parquetpath = CensoBR._parquetpath(2000, "RR", record; cachedir=tmpdir)

      @test isfile(parquetpath)
      @test Parquet2.Dataset(parquetpath) isa Parquet2.Dataset
    end

    # Raw archive and extracted data were removed.
    rawdir = joinpath(tmpdir, "raw", "2000")

    @test !isfile(joinpath(rawdir, "RR.zip"))
    @test !isdir(joinpath(rawdir, "RR"))
  end
end
