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
