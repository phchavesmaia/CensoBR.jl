@testitem "Resolve 2000 RJ URL" begin
	using CensoBR

	@test CensoBR.census_url(2000, "RJ") ==
		  "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/RJ.zip"
end

@testitem "Resolve 2010 RJ URL" begin
	using CensoBR

	@test CensoBR.census_url(2010, :RJ) ==
		  "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/RJ.zip"
end

@testitem "Reject invalid census year" begin
	using CensoBR

	@test_throws ArgumentError CensoBR.census_url(1999, "RJ")
end
