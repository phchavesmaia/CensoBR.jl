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
	using p7zip_jll

	mktempdir() do tmpdir
		# write test ZIP archive
		zip_path = joinpath(tmpdir, "RJ.zip")
		source_dir = joinpath(tmpdir, "source")
		mkpath(joinpath(source_dir, "nested"))
		write(joinpath(source_dir, "DOM33.TXT"), "domicile data")
		write(joinpath(source_dir, "nested", "PES33.TXT"), "person data")
		cd(source_dir) do
			run(
				pipeline(
					`$(p7zip_jll.p7zip()) a -tzip $zip_path DOM33.TXT nested/PES33.TXT`,
					stdout = devnull,
					stderr = devnull,
				),
			)
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

@testitem "Download Census documentation" tags=[:integration] begin
	using CensoBR

	# download Census documentation year 2000
	mktempdir() do tmpdir
		path = CensoBR._download_documentation(2000; cache_dir = tmpdir, show_progress = false)

		@test isfile(path)
		@test basename(path) == "1_Documentacao_20170908.zip"
		@test filesize(path) > 0

		expected = joinpath(tmpdir, "raw", "2000", "1_Documentacao_20170908.zip")

		@test path == expected

		# second call should reuse the cached file
		mtime_before = mtime(path)

		path2 = CensoBR._download_documentation(2000; cache_dir = tmpdir, show_progress = false)

		@test path2 == path
		@test mtime(path2) == mtime_before
	end

	# download Census documentation 2010
	mktempdir() do tmpdir
		path = CensoBR._download_documentation(2010; cache_dir = tmpdir, show_progress = false)

		@test isfile(path)
		@test basename(path) == "Documentacao.zip"
		@test filesize(path) > 0

		expected = joinpath(tmpdir, "raw", "2010", "Documentacao.zip")

		@test path == expected
	end

	# documentation download rejects unsupported year
	mktempdir() do tmpdir
		@test_throws ArgumentError CensoBR._download_documentation(1990; cache_dir = tmpdir, show_progress = false)
	end

end

@testitem "Prepare Census documentation and data" tags=[:integration] begin
	using CensoBR

	mktempdir() do tmpdir
		prepared = CensoBR._prepare_census(2000, "RJ"; cache_dir = tmpdir, show_progress = false)

		@test prepared isa NamedTuple
		@test haskey(prepared, :census)
		@test haskey(prepared, :documentation)

		@test isdir(prepared.census)
		@test isdir(prepared.documentation)
	end
end
