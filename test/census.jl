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
      run(
        pipeline(
          `$(p7zip_jll.p7zip()) a -tzip $zippath DOM33.TXT FAMI33.TXT PES33.TXT`,
          stdout=devnull,
          stderr=devnull
        )
      )
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

@testitem "Stack the 2010 Census from local UF archives" begin
  using CensoBR
  using Parquet2
  using Tables
  using p7zip_jll

  uf_codes = Dict(
    "AC" => "12",
    "AL" => "27",
    "AM" => "13",
    "AP" => "16",
    "BA" => "29",
    "CE" => "23",
    "DF" => "53",
    "ES" => "32",
    "GO" => "52",
    "MA" => "21",
    "MG" => "31",
    "MS" => "50",
    "MT" => "51",
    "PA" => "15",
    "PB" => "25",
    "PE" => "26",
    "PI" => "22",
    "PR" => "41",
    "RJ" => "33",
    "RN" => "24",
    "RO" => "11",
    "RR" => "14",
    "RS" => "43",
    "SC" => "42",
    "SE" => "28",
    "SP" => "35",
    "TO" => "17"
  )

  @test Set(keys(uf_codes)) == CensoBR.VALID_UFS

  mktempdir() do tmpdir
    source = joinpath(tmpdir, "source")
    raw = joinpath(tmpdir, "raw", "2010")
    mkpath(source)
    mkpath(raw)

    archivefiles = Dict{String,Vector{String}}()
    for uf in sort!(collect(CensoBR.VALID_UFS))
      archives = uf == "SP" ? ("SP1.zip", "SP2_RM.zip") : ("$(uf).zip",)
      for (archive_index, archive) in enumerate(archives)
        filenames = get!(archivefiles, archive, String[])
        for record in CensoBR.CENSUS_RECORDS[2010]
          layout = CensoBR._loadlayout(2010, record)
          bytes = fill(UInt8(' '), layout.lrecl)
          for field in layout.fields
            fill!(view(bytes, field.start:(field.start + field.width - 1)), field.ischaracter ? UInt8('A') : UInt8('0'))
          end

          uf_field = only(filter(field -> field.name == "V0001", layout.fields))
          start = uf_field.start
          stop = start + uf_field.width - 1
          bytes[start:stop] .= codeunits(uf_codes[uf])

          prefix = CensoBR.RAW_FILE_PREFIXES[(2010, record)]
          filename = "$(prefix)$(uf)_$(archive_index).TXT"
          write(joinpath(source, filename), vcat(bytes, UInt8('\n')))
          push!(filenames, filename)
        end
      end
    end

    for (archive, filenames) in archivefiles
      zippath = joinpath(raw, archive)
      cd(source) do
        run(pipeline(`$(p7zip_jll.p7zip()) a -tzip $zippath $filenames`, stdout=devnull, stderr=devnull))
      end
    end

    requested = fetchcensus(2010, :br, :household; cachedir=tmpdir, showprogress=false, chunksize=1)
    @test requested == joinpath(tmpdir, "parquet", "2010", "BR", "household.parquet")

    expected_codes = Set(values(uf_codes))
    expected_rows = length(uf_codes) + 1 # São Paulo contributes one row from each archive.
    for record in CensoBR.CENSUS_RECORDS[2010]
      path = joinpath(tmpdir, "parquet", "2010", "BR", "$(record).parquet")
      @test isfile(path)

      dataset = Parquet2.Dataset(path)
      try
        @test Tables.columnnames(dataset) ==
              Tuple(Symbol(field.name) for field in CensoBR._loadlayout(2010, record).fields)
        codes = Set{String}()
        nrows = 0
        for group in dataset
          values = Tables.getcolumn(group, :V0001)
          union!(codes, string.(values))
          nrows += length(values)
        end
        @test nrows == expected_rows
        @test codes == expected_codes
      finally
        close(dataset)
      end
    end

    for archive in keys(archivefiles)
      zippath = joinpath(raw, archive)
      @test !isfile(zippath)
      @test !isdir(splitext(zippath)[1])
    end

    @test fetchcensus(2010, :br, :person; cachedir=tmpdir, showprogress=false) ==
          joinpath(tmpdir, "parquet", "2010", "BR", "person.parquet")
  end
end
