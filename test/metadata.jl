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

@testitem "Auxiliary field dictionaries" begin
  using CensoBR

  root = pkgdir(CensoBR)
  include(joinpath(root, "dev", "auxiliary.jl"))
  religionartifact = joinpath(root, "data", "auxiliary", "V4090_religion_2000.txt")
  religionvalues = _parseauxiliaryreligion(religionartifact)
  religionoverrides =
    _parseauxiliaryreligionoverrides(joinpath(root, "data", "auxiliary", "V4090_religion_2000_censobr.tsv"))
  merge!(religionvalues, religionoverrides)
  metropolitanartifact = joinpath(root, "data", "auxiliary", "V1004_metropolitan_2000.txt")
  metropolitanvalues = _parseauxiliarymetropolitan(metropolitanartifact)
  metropolitanhouseholdartifact = joinpath(root, "data", "auxiliary", "V1004_metropolitan_2000_household_person.txt")
  metropolitanhouseholdvalues = _parseauxiliarymetropolitan2000(metropolitanhouseholdartifact)
  religion2010artifact = joinpath(root, "data", "auxiliary", "V6121_religion_2010.txt")
  religion2010values = _parseauxiliaryreligion2010(religion2010artifact)
  metropolitan2010artifact = joinpath(root, "data", "auxiliary", "V1004_metropolitan_2010.txt")
  metropolitan2010values = _parseauxiliarymetropolitan2010(metropolitan2010artifact)

  @test length(religionvalues) == 143
  @test religionvalues["000"] == "SEM RELIGIÃO"
  @test religionvalues["990"] == "SEM DECLARAÇAO"
  @test length(religionoverrides) == 41
  @test religionvalues["519"] == "Outras (Igreja De Jesus Cristo Dos Santos Dos Últimos Dias)"
  @test fieldvalues(2000, :person, :V4090) == religionvalues
  @test length(metropolitanvalues) == 29
  @test metropolitanvalues["01"] == "Belém"
  @test metropolitanvalues["28"] == "RIDE (Região Integrada de Desenvolvimento do Distrito Federal e Entorno)"
  @test metropolitanvalues["Branco"] == "Não aplicável"
  @test fieldvalues(2000, :family, :V1004) == Dict(k => v for (k, v) in metropolitanvalues if k != "Branco")
  @test !haskey(fieldvalues(2000, :family, :V1004), "Branco")
  @test "Branco — Não aplicável" in fieldnotes(2000, :family, :V1004)
  @test length(metropolitanhouseholdvalues) == 29
  @test metropolitanhouseholdvalues["00"] == "Sem Área de Ponderação"
  @test fieldvalues(2000, :household, :V1004) == metropolitanhouseholdvalues
  @test fieldvalues(2000, :person, :V1004) == metropolitanhouseholdvalues
  @test !haskey(metropolitanhouseholdvalues, "Branco")
  @test length(metropolitan2010values) == 43
  @test metropolitan2010values["00"] == "Município não pertencente a estrutura de RM"
  @test metropolitan2010values["42"] == "RIDE Petrolina/Juazeiro Reg Adm Int Desen do Pólo Petrolina/PE e Juazeiro/BA"
  for record in (:household, :person, :emigration, :mortality)
    @test fieldvalues(2010, record, :V1004) == metropolitan2010values
  end
  @test length(religion2010values) == 201
  @test religion2010values["0"] == "Sem religião"
  @test religion2010values["110"] == "Católica Apostólica Romana"
  @test fieldvalues(2010, :person, :V6121) == religion2010values
  occupations2010 = fieldvalues(2010, :person, :V6461)
  @test length(occupations2010) == 603
  @test occupations2010["0001"] == "DIRETORES E GERENTES"
  @test !haskey(occupations2010, "0110")
  @test !haskey(occupations2010, "0210")
  @test fieldvalues(2010, :household, :V0701)["2"] == "Não"
  @test "Branco" in fieldnotes(2010, :household, :V0701)

  occupationvalues = _normalizeauxiliaryvalues(
    Dict{String,Any}("name" => "V6461", "width" => 4),
    Dict(
      "01" => "MILITARY GROUP",
      "1" => "DIRECTORS",
      "1111" => "LEGISLATORS",
      "0110" => "OFFICERS",
      "0210" => "SOLDIERS"
    ),
    2010
  )
  @test occupationvalues == Dict("0001" => "DIRECTORS", "1111" => "LEGISLATORS")

  mktempdir() do fixturedir
    layout = Dict{String,Any}(
      "record" => "person",
      "fields" =>
        [Dict{String,Any}("name" => "V1004", "width" => 2), Dict{String,Any}("name" => "V6121", "width" => 3)]
    )
    _integrateauxiliaryvalues!(layout, fixturedir, 2010)
    integrated = Dict(field["name"] => field["values"] for field in layout["fields"])
    @test integrated["V1004"] == metropolitan2010values
    @test integrated["V6121"] == religion2010values
  end

  mesoregions2000 = fieldvalues(2000, :person, :V1002)
  microregions2000 = fieldvalues(2000, :person, :V1003)
  metropolitanareas = fieldvalues(2000, :person, :V1004)
  ponderationareas = fieldvalues(2000, :person, :AREAP)

  @test length(mesoregions2000) == 137
  @test mesoregions2000["1101"] == "Madeira-Guaporé"
  @test length(microregions2000) == 558
  @test microregions2000["11001"] == "Porto Velho"
  @test length(metropolitanareas) == 29
  @test metropolitanareas["00"] == "Sem Área de Ponderação"
  @test length(ponderationareas) == 9336
  @test ponderationareas["1100015001001"] == "Município ALTA FLORESTA D'OESTE"

  ufcodes2010 = fieldvalues(2010, :person, :V6222)
  municipalitycodes2010 = fieldvalues(2010, :person, :V6254)

  @test length(ufcodes2010) == 30
  @test ufcodes2010["1100000"] == "RÔNDONIA"
  @test length(municipalitycodes2010) == 5590
  @test municipalitycodes2010["1100015"] == "ALTA FLORESTA D'OESTE"
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
