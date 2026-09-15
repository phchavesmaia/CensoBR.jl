@testitem "Load Census layout" begin
  using CensoBR

  household = CensoBR._loadlayout(2000, :household)
  person = CensoBR._loadlayout(2010, :person)

  @test household isa CensoBR.CensusLayout
  @test household.record == :household

  @test person isa CensoBR.CensusLayout
  @test person.record == :person

  @test_throws ArgumentError CensoBR._loadlayout(1991, :household)
  @test_throws ArgumentError CensoBR._loadlayout(2000, :mortality)
  @test_throws ArgumentError CensoBR._loadlayout(2010, :family)
end

@testitem "Load bundled Census layouts" begin
  using CensoBR

  supported = [
    (2000, :household),
    (2000, :family),
    (2000, :person),
    (2010, :household),
    (2010, :person),
    (2010, :emigration),
    (2010, :mortality)
  ]

  for (year, record) in supported
    layout = CensoBR._loadlayout(year, record)

    @test layout isa CensoBR.CensusLayout
    @test layout.record == record
    @test layout.lrecl > 0
    @test !isempty(layout.fields)

    @test all(field -> field.start > 0, layout.fields)
    @test all(field -> field.width > 0, layout.fields)

    @test maximum(field.start + field.width - 1 for field in layout.fields) <= layout.lrecl
  end
end

@testitem "Census 2000 layout dimensions" begin
  using CensoBR

  household = CensoBR._loadlayout(2000, :household)
  family = CensoBR._loadlayout(2000, :family)
  person = CensoBR._loadlayout(2000, :person)

  @test household.lrecl == 170
  @test length(household.fields) == 80

  @test family.lrecl == 118
  @test length(family.fields) == 26

  @test person.lrecl == 390
  @test length(person.fields) == 183
end

@testitem "Census 2000 layout metadata" begin
  using CensoBR

  household = CensoBR._loadlayout(2000, :household)

  uf = only(filter(field -> field.name == "V0102", household.fields))

  @test uf.start == 1
  @test uf.width == 2
  @test uf.decimals == 0
  @test uf.ischaracter
  @test uf.label == "UNIDADE DA FEDERAÇÃO"

  @test uf.values["11"] == "Rondônia"
  @test uf.values["33"] == "Rio de Janeiro"
  @test uf.values["53"] == "Distrito Federal"

  situation = only(filter(field -> field.name == "V1006", household.fields))

  @test situation.label == "SITUAÇÃO DO DOMICÍLIO"
  @test situation.values["1"] == "Urbano"
  @test situation.values["2"] == "Rural"
end

@testitem "Validate Census layout" begin
  using CensoBR

  valid = CensoBR.CensusLayout(
    2000,
    :household,
    10,
    [
      CensoBR.LayoutField("A", 1, 5, 0, true, nothing, Dict{String,String}(), String[]),
      CensoBR.LayoutField("B", 6, 5, 0, false, nothing, Dict{String,String}(), String[])
    ]
  )

  @test CensoBR._validatelayout(valid)

  empty = CensoBR.CensusLayout(2000, :household, 10, CensoBR.LayoutField[])

  @test_throws ErrorException CensoBR._validatelayout(empty)

  overflow = CensoBR.CensusLayout(
    2000,
    :household,
    10,
    [CensoBR.LayoutField("A", 8, 5, 0, false, nothing, Dict{String,String}(), String[])]
  )

  @test_throws ErrorException CensoBR._validatelayout(overflow)
end

@testitem "Layout fields are ordered" begin
  using CensoBR

  for (year, record) in [
    (2000, :household),
    (2000, :family),
    (2000, :person),
    (2010, :household),
    (2010, :person),
    (2010, :emigration),
    (2010, :mortality)
  ]
    layout = CensoBR._loadlayout(year, record)

    starts = getfield.(layout.fields, :start)

    @test issorted(starts)
  end
end
