@testitem "Census URL" begin
	using CensoBR
	# testing the URL resolution for different years
	@test CensoBR._census_url(2000, "RJ") ==
		  "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/RJ.zip"

	@test CensoBR._census_url(2010, :RJ) ==
		  "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/RJ.zip"
	# testing the URL resolution for lowercase UF codes
	@test CensoBR._census_url(2000, "rj") ==
		  CensoBR._census_url(2000, "RJ")

	# testing invalid year and UF code
	@test_throws ArgumentError CensoBR._census_url(1990, "RJ")
	@test_throws ArgumentError CensoBR._census_url(2000, "XX")

	# Special IBGE distribution case
	@test_throws ArgumentError CensoBR._census_url(2010, "SP")
end

@testitem "Default cache directory" begin
	using CensoBR

	cache_dir = CensoBR._default_cache_dir()

	@test cache_dir isa AbstractString
	@test basename(cache_dir) == "CensoBR"
	@test !isempty(cache_dir)
end

@testitem "Extract Census archive" begin
	using CensoBR
	using ZipFile

	mktempdir() do tmpdir
		# write test ZIP archive
		zip_path = joinpath(tmpdir, "RJ.zip")
		archive = ZipFile.Writer(zip_path)
		try
			file1 = ZipFile.addfile(archive, "DOM33.TXT")
			write(file1, "domicile data")

			file2 = ZipFile.addfile(archive, "nested/PES33.TXT")
			write(file2, "person data")
		finally
			close(archive)
		end
		
		# extract the contents of the ZIP archive
		destination = CensoBR._extract_census(zip_path)

		# check that the extracted files exist
		@test destination == joinpath(tmpdir, "RJ")
		@test isdir(destination)

		# check that the root file exists
		@test read(joinpath(destination, "DOM33.TXT"), String) == "domicile data"

		# check that the nested file exists
		@test read(joinpath(destination, "nested", "PES33.TXT"), String) == "person data"

		# extraction reuses existing directory
		write(joinpath(destination, "DOM33.TXT"), "modified")
		destination2 = CensoBR._extract_census(zip_path)
		@test destination2 == destination
		@test read(joinpath(destination, "DOM33.TXT"), String) == "modified"

		# forced extraction replaces existing directory
		destination3 = CensoBR._extract_census(zip_path; force = true)
		@test destination3 == destination
		@test read(joinpath(destination, "DOM33.TXT"), String) == "domicile data"

		# extraction rejects missing ZIP
		@test_throws ArgumentError CensoBR._extract_census(joinpath(tmpdir, "MISSING.zip"))
	end
end

