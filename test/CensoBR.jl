@testitem "Read Census" begin
  using CensoBR

  @test_throws ArgumentError CensoBR.opencensus(1990, :rj, :household)

  @test_throws ArgumentError CensoBR.opencensus(2000, :xx, :household)
end

@testitem "Public API" begin
  using CensoBR

  @test isdefined(CensoBR, :opencensus)
end

@testitem "Read Census end-to-end" tags=[:integration] begin
  using CensoBR
  using Tables

  mktempdir() do tmpdir
    table = CensoBR.opencensus(2000, :rr, :household; cachedir=tmpdir, showprogress=false)

    @test table isa CensoBR.CensusTable
    @test Tables.istable(typeof(table))
    @test Tables.rowaccess(typeof(table))

    row = first(Tables.rows(table))

    @test row isa NamedTuple
    @test row.V0102 == "14"
  end
end
