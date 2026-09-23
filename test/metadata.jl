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

  @test metadata isa CensoBR.FieldMetadata
  @test metadata.label !== nothing
  @test metadata.values isa Dict{String,String}
  @test metadata.notes isa Vector{String}
end

@testitem "Display field metadata" begin
  using CensoBR

  metadata = CensoBR.FieldMetadata(
    "REGIÃO GEOGRÁFICA",
    Dict(
      "4" => "Região Sul",
      "1" => "Região Norte",
      "5" => "Região Centro-Oeste",
      "2" => "Região Nordeste",
      "3" => "Região Sudeste"
    ),
    ["Example note"]
  )

  output = sprint(show, MIME"text/plain"(), metadata)

  @test output ==
        "\n" *
        "Label:\n" *
        "  REGIÃO GEOGRÁFICA\n" *
        "\n" *
        "Values:\n" *
        "  1 ⇒ Região Norte\n" *
        "  2 ⇒ Região Nordeste\n" *
        "  3 ⇒ Região Sudeste\n" *
        "  4 ⇒ Região Sul\n" *
        "  5 ⇒ Região Centro-Oeste\n" *
        "\n" *
        "Notes:\n" *
        "  Example note\n"
end

@testitem "Display empty field metadata" begin
  using CensoBR

  metadata = CensoBR.FieldMetadata(nothing, Dict{String,String}(), String[])

  output = sprint(show, MIME"text/plain"(), metadata)

  expected = "\n" * "Label:\n" * "  —\n" * "\n" * "Values:\n" * "  —\n" * "\n" * "Notes:\n" * "  —"

  @test output == expected
end
