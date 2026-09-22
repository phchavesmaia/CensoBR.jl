@testitem "Find raw Census files" begin
  using CensoBR

  mktempdir() do tmpdir
    dir2000 = joinpath(tmpdir, "2000", "RJ")
    dir2010 = joinpath(tmpdir, "2010", "RJ")
    mkpath(dir2000)
    mkpath(dir2010)

    for name in ("Dom33.txt", "FAMI33.TXT", "Pes33.txt")
      write(joinpath(dir2000, name), "")
    end

    household2000 = CensoBR._loadlayout(2000, :household)
    family2000 = CensoBR._loadlayout(2000, :family)
    person2000 = CensoBR._loadlayout(2000, :person)

    @test basename.(CensoBR._findrawfiles([dir2000], household2000)) == ["Dom33.txt"]
    @test basename.(CensoBR._findrawfiles([dir2000], family2000)) == ["FAMI33.TXT"]
    @test basename.(CensoBR._findrawfiles([dir2000], person2000)) == ["Pes33.txt"]

    for name in ("Amostra_Domicilios_33.txt", "Amostra_Pessoas_33.txt", "Amostra_Emigracao_33.txt", "Amostra_Mortalidade_33.txt")
      write(joinpath(dir2010, name), "")
    end

    household2010 = CensoBR._loadlayout(2010, :household)
    person2010 = CensoBR._loadlayout(2010, :person)
    emigration2010 = CensoBR._loadlayout(2010, :emigration)
    mortality2010 = CensoBR._loadlayout(2010, :mortality)

    @test basename.(CensoBR._findrawfiles([dir2010], household2010)) == ["Amostra_Domicilios_33.txt"]
    @test basename.(CensoBR._findrawfiles([dir2010], person2010)) == ["Amostra_Pessoas_33.txt"]
    @test basename.(CensoBR._findrawfiles([dir2010], emigration2010)) == ["Amostra_Emigracao_33.txt"]
    @test basename.(CensoBR._findrawfiles([dir2010], mortality2010)) == ["Amostra_Mortalidade_33.txt"]

    # The 2010 SP archive is split. All matching files must be used in order.
    second = joinpath(tmpdir, "2010", "SP2")
    mkpath(second)
    write(joinpath(second, "amostra_pessoas_35_b.txt"), "")
    write(joinpath(dir2010, "amostra_pessoas_35_a.txt"), "")
    @test basename.(CensoBR._findrawfiles([second, dir2010], person2010)) ==
          ["Amostra_Pessoas_33.txt", "amostra_pessoas_35_a.txt", "amostra_pessoas_35_b.txt"]
  end
end

@testitem "Find raw Census file errors" begin
  using CensoBR

  mktempdir() do tmpdir
    layout = CensoBR._loadlayout(2000, :household)

    @test_throws ErrorException CensoBR._findrawfiles([tmpdir], layout)
  end

  layout = CensoBR.CensusLayout(1990, :household, 10, CensoBR.LayoutField[])

  mktempdir() do tmpdir
    @test_throws ArgumentError CensoBR._findrawfiles([tmpdir], layout)
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

@testitem "Open Census validation" begin
  using CensoBR

  @test_throws ArgumentError opencensus(1990, :rj, :household)
  @test_throws ArgumentError opencensus(2000, :rj, :mortality)
  @test_throws ArgumentError opencensus(2000, :xx, :household)
  @test_throws ArgumentError opencensus(2000, :rj, :household; chunksize=0)
  @test_throws ArgumentError opencensus(2000, :rj, :household; chunksize=-1)
end

@testitem "Open Census from a local archive" begin
  using CensoBR
  using Parquet2
  using Tables
  using p7zip_jll

  mktempdir() do tmpdir
    source = joinpath(tmpdir, "source")
    raw = joinpath(tmpdir, "raw", "2000")
    mkpath(source)
    mkpath(raw)

    filenames = Dict(:household => "DOM33.TXT", :family => "FAMI33.TXT", :person => "PES33.TXT")
    for record in CensoBR.CENSUS_RECORDS[2000]
      layout = CensoBR._loadlayout(2000, record)
      bytes = fill(UInt8(' '), layout.lrecl)
      for field in layout.fields
        fill!(view(bytes, field.start:(field.start + field.width - 1)), field.ischaracter ? UInt8('A') : UInt8('0'))
      end
      write(joinpath(source, filenames[record]), vcat(bytes, UInt8('\n'), bytes, UInt8('\n')))
    end

    zippath = joinpath(raw, "RJ.zip")
    cd(source) do
      run(pipeline(`$(p7zip_jll.p7zip()) a -tzip $zippath DOM33.TXT FAMI33.TXT PES33.TXT`, stdout=devnull, stderr=devnull))
    end

    dataset = opencensus(2000, :rj, :household; cachedir=tmpdir, showprogress=false, chunksize=1)
    @test dataset isa Parquet2.Dataset
    @test length(collect(Tables.rows(dataset))) == 2

    for record in CensoBR.CENSUS_RECORDS[2000]
      path = CensoBR._parquetpath(2000, :rj, record; cachedir=tmpdir)
      @test isfile(path)
      @test length(collect(Tables.rows(Parquet2.Dataset(path)))) == 2
    end
    @test !isfile(zippath)
    @test !isdir(joinpath(raw, "RJ"))

    # A second record is served from Parquet without the deleted archive.
    @test opencensus(2000, :rj, :person; cachedir=tmpdir, showprogress=false) isa Parquet2.Dataset
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
  @test occursin("Divisão Territorial Brasileira", notes[1])
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
