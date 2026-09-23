# These tests use the IBGE archives, so they are excluded from ordinary Pkg.test().
# Run with CENSOBR_INTEGRATION_TESTS=true. Add CENSOBR_SP_INTEGRATION_TESTS=true
# to include the much larger, split 2010 São Paulo archives.
@testitem "Real IBGE census conversion" tags=[:integration] begin
  using CensoBR
  using Parquet2
  using Tables

  function check_census(year, uf, uf_code, region, cachedir; split=false)
    rawdirs = CensoBR._preparecensus(year, uf; cachedir=cachedir, showprogress=false)
    @test length(rawdirs) == (split ? 2 : 1)

    expected_rows = Dict{Symbol,Int}()
    layouts = Dict{Symbol,CensoBR.CensusLayout}()
    for record in CensoBR.CENSUS_RECORDS[year]
      layout = CensoBR._loadlayout(year, record)
      layouts[record] = layout
      paths = CensoBR._findrawfiles(rawdirs, layout)
      @test length(paths) >= (split ? 2 : 1)
      expected_rows[record] = sum(countlines, paths)
      @test expected_rows[record] > 0

      # Check the source itself before conversion; the first field is the UF code.
      for path in paths
        open(path) do io
          @test strip(readline(io)[1:2]) == uf_code
        end
      end
    end

    # Ensure the test exercises conversion even if this cache has been used before.
    parquetdir = joinpath(cachedir, "parquet", string(year), uf)
    for record in keys(expected_rows)
      rm(joinpath(parquetdir, "$(record).parquet"); force=true)
    end

    requested = CensoBR.CENSUS_RECORDS[year][1]
    requested_path = fetchcensus(year, uf, requested; cachedir=cachedir, showprogress=false)
    @test requested_path == joinpath(parquetdir, "$(requested).parquet")

    for record in CensoBR.CENSUS_RECORDS[year]
      path = joinpath(parquetdir, "$(record).parquet")
      @test isfile(path)
      @test filesize(path) > 0

      dataset = Parquet2.Dataset(path)
      try
        @test Tables.columnnames(dataset) == Tuple(Symbol(field.name) for field in layouts[record].fields)
        nrows = 0
        for group in dataset
          uf_values = Tables.getcolumn(group, Symbol(year == 2000 ? "V0102" : "V0001"))
          region_values = Tables.getcolumn(group, :V1001)
          @test all(==(uf_code), uf_values)
          @test all(==(region), region_values)
          nrows += length(uf_values)
        end
        @test nrows == expected_rows[record]
      finally
        close(dataset)
      end
    end
  end

  mktempdir() do cachedir
    @testset "Acre 2000" begin
      check_census(2000, "AC", "12", "1", cachedir)
    end
  end

  mktempdir() do cachedir
    @testset "Acre 2010" begin
      check_census(2010, "AC", "12", "1", cachedir)
    end
  end

  if get(ENV, "CENSOBR_SP_INTEGRATION_TESTS", "false") == "true"
    mktempdir() do cachedir
      @testset "São Paulo 2010 split archives" begin
        check_census(2010, "SP", "35", "3", cachedir; split=true)
      end
    end
  end
end
