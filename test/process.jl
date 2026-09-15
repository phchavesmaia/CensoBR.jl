@testitem "Find raw Census files" begin
  using CensoBR

  mktempdir() do tmpdir
    # Census 2000 structure
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

    # Census 2010 structure
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

    # No matching file
    @test_throws ErrorException CensoBR._findrawfile(tmpdir, layout)

    # More than one matching file
    write(joinpath(tmpdir, "Dom33.txt"), "")
    write(joinpath(tmpdir, "DOM99.TXT"), "")

    @test_throws ErrorException CensoBR._findrawfile(tmpdir, layout)
  end

  # Synthetic unsupported layout
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

  # Invalid numeric contents
  @test_throws ArgumentError CensoBR._parsefield(numeric, codeunits("ABC"))

  # Field extends beyond record
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

@testitem "Parse Census file as table" begin
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

    table = CensoBR._parsefile(path, layout)

    @test table isa CensoBR.CensusTable
    @test table.path == path
    @test table.layout === layout

    @test Tables.istable(typeof(table))
    @test Tables.rowaccess(typeof(table))
    @test Tables.rows(table) === table

    @test Base.IteratorSize(typeof(table)) == Base.SizeUnknown()
    @test Base.IteratorEltype(typeof(table)) == Base.EltypeUnknown()

    rows = collect(Tables.rows(table))

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

  mktempdir() do tmpdir
    path = joinpath(tmpdir, "test.txt")
    write(path, "330120345\n")

    table = CensoBR._parsefile(path, layout)
    schema = Tables.schema(table)

    @test schema.names == (:UF, :COUNT, :WEIGHT)

    @test schema.types == (Union{Missing,String}, Union{Missing,Int}, Union{Missing,Float64})
  end
end

@testitem "Parse Census file errors" begin
  using CensoBR

  layout = CensoBR.CensusLayout(
    2000,
    :household,
    2,
    [CensoBR.LayoutField("UF", 1, 2, 0, true, nothing, Dict{String,String}(), String[])]
  )

  mktempdir() do tmpdir
    @test_throws ArgumentError CensoBR._parsefile(joinpath(tmpdir, "missing.txt"), layout)
  end
end
