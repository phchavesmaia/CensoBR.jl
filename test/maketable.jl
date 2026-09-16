@testitem "Find raw Census files" begin
  using CensoBR

  mktempdir() do tmpdir
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

@testitem "Chunked Parquet write" begin
  using CensoBR
  using Parquet2
  using Tables

  fields = [
    CensoBR.LayoutField("UF", 1, 2, 0, true, nothing, Dict{String,String}(), String[]),
    CensoBR.LayoutField("COUNT", 3, 3, 0, false, nothing, Dict{String,String}(), String[])
  ]

  layout = CensoBR.CensusLayout(2000, :household, 5, fields)

  mktempdir() do tmpdir
    rawpath = joinpath(tmpdir, "data.txt")
    parquetpath = joinpath(tmpdir, "data.parquet")

    write(rawpath, "33012\n" * "35007\n" * "41042\n")

    chunks = CensoBR.CensusChunks(rawpath, layout; chunksize=2)

    open(parquetpath, "w") do io
      writer = Parquet2.FileWriter(io, parquetpath)

      Parquet2.writeiterable!(writer, chunks)
    end

    @test isfile(parquetpath)

    dataset = Parquet2.Dataset(parquetpath)
    rows = collect(Tables.rows(dataset))

    @test length(rows) == 3

    @test rows[1].UF == "33"
    @test rows[1].COUNT == 12

    @test rows[2].UF == "35"
    @test rows[2].COUNT == 7

    @test rows[3].UF == "41"
    @test rows[3].COUNT == 42
  end
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

@testitem "Open Census" begin
  using CensoBR
  using Parquet2

  mktempdir() do tmpdir
    dataset = CensoBR.opencensus(2000, "RR", :household; cachedir=tmpdir, showprogress=false, chunksize=5_000)

    @test dataset isa Parquet2.Dataset

    for record in CensoBR.CENSUS_RECORDS[2000]
      parquetpath = CensoBR._parquetpath(2000, "RR", record; cachedir=tmpdir)

      @test isfile(parquetpath)
      @test Parquet2.Dataset(parquetpath) isa Parquet2.Dataset
    end

    rawdir = joinpath(tmpdir, "raw", "2000")

    @test !isfile(joinpath(rawdir, "RR.zip"))
    @test !isdir(joinpath(rawdir, "RR"))
  end
end

@testitem "Reuse Census Parquet cache" begin
  using CensoBR
  using Parquet2

  mktempdir() do tmpdir
    first = opencensus(2000, "RR", :household; cachedir=tmpdir, showprogress=false, chunksize=5_000)

    second = opencensus(2000, "RR", :person; cachedir=tmpdir, showprogress=false, chunksize=5_000)

    @test first isa Parquet2.Dataset
    @test second isa Parquet2.Dataset

    @test !isdir(joinpath(tmpdir, "raw", "2000", "RR"))
    @test !isfile(joinpath(tmpdir, "raw", "2000", "RR.zip"))
  end
end

@testitem "Census field metadata" begin
  using CensoBR

  metadata = fieldmetadata(2000, :household, :V0102)

  @test metadata.label == "UNIDADE DA FEDERAÇÃO"
  @test metadata.values["33"] == "Rio de Janeiro"
  @test metadata.values["35"] == "São Paulo"
  @test isempty(metadata.notes)
end

@testitem "Census value codes" begin
  using CensoBR

  values = fieldvalues(2000, :household, :V0102)

  @test values["33"] == "Rio de Janeiro"
  @test values["35"] == "São Paulo"
  @test values["14"] == "Roraima"
end

@testitem "Census field notes" begin
  using CensoBR

  notes = fieldnotes(2000, :household, :V1002)

  @test !isempty(notes)
  @test any(occursin("Divisão Territorial Brasileira"), notes[1])
end

@testitem "Census label" begin
  using CensoBR

  @test fieldlabel(2000, :household, :V0102) == "UNIDADE DA FEDERAÇÃO"
  @test fieldlabel(2000, :household, :V0300) == "CONTROLE"
end

@testitem "Empty Census metadata" begin
  using CensoBR

  @test isempty(fieldvalues(2000, :household, :V0300))
  @test isempty(fieldnotes(2000, :household, :V0300))
end

@testitem "Census metadata errors" begin
  using CensoBR

  @test_throws ArgumentError fieldmetadata(2000, :household, :DOES_NOT_EXIST)
  @test_throws ArgumentError fieldvalues(2000, :household, :DOES_NOT_EXIST)
  @test_throws ArgumentError fieldnotes(2000, :household, :DOES_NOT_EXIST)
end

@testitem "Census 2010 metadata" begin
  using CensoBR

  metadata = fieldmetadata(2010, :person, :V0001)

  @test metadata.label !== nothing
  @test metadata.values isa Dict{String,String}
  @test metadata.notes isa Vector{String}
end
