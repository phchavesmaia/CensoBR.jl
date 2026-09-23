@testitem "Parquet cache path" begin
  using CensoBR

  mktempdir() do tmpdir
    path = joinpath(tmpdir, "parquet", string(2000), uppercase(String(:rj)), "household.parquet")

    @test path == joinpath(tmpdir, "parquet", "2000", "RJ", "household.parquet")
  end
end

@testitem "Open Census validation" begin
  using CensoBR

  @test_throws ArgumentError fetchcensus(1990, :rj, :household)
  @test_throws ArgumentError fetchcensus(2000, :rj, :mortality)
  @test_throws ArgumentError fetchcensus(2000, :xx, :household)
  @test_throws ArgumentError fetchcensus(2000, :rj, :household; chunksize=0)
  @test_throws ArgumentError fetchcensus(2000, :rj, :household; chunksize=-1)
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

    dspath = fetchcensus(2000, :rj, :household; cachedir=tmpdir, showprogress=false, chunksize=1)
    @test dspath isa String
    @test isfile(dspath)
    @test length(collect(Tables.rows(Parquet2.Dataset(dspath)))) == 2

    for record in CensoBR.CENSUS_RECORDS[2000]
      path = joinpath(tmpdir, "parquet", string(2000), uppercase(String(:rj)), "$(record).parquet")
      @test isfile(path)
      @test length(collect(Tables.rows(Parquet2.Dataset(path)))) == 2
    end
    @test !isfile(zippath)
    @test !isdir(joinpath(raw, "RJ"))

    # A second record is served from Parquet without the deleted archive.
    @test Parquet2.Dataset(fetchcensus(2000, :rj, :person; cachedir=tmpdir, showprogress=false)) isa Parquet2.Dataset
  end
end
