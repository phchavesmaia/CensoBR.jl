@testitem "Census URL" begin
	using CensoBR
	# testing the URL resolution for different years
	@test CensoBR._censusurl(2000, "RJ") ==
		  "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/RJ.zip"

	@test CensoBR._censusurl(2010, :RJ) ==
		  "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/RJ.zip"
	# testing the URL resolution for lowercase UF codes
	@test CensoBR._censusurl(2000, "rj") ==
		  CensoBR._censusurl(2000, "RJ")

	# testing invalid year and UF code
	@test_throws ArgumentError CensoBR._censusurl(1990, "RJ")
	@test_throws ArgumentError CensoBR._censusurl(2000, "XX")

	# Special IBGE distribution case
	@test_throws ArgumentError CensoBR._censusurl(2010, "SP")
end

@testitem "Default cache directory" begin
	using CensoBR

	cachedir = CensoBR._defaultcachedir()

	@test cachedir isa AbstractString
	@test basename(cachedir) == "CensoBR"
	@test !isempty(cachedir)
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
		destination = CensoBR._extractarchive(zip_path)

		# check that the extracted files exist
		@test destination == joinpath(tmpdir, "RJ")
		@test isdir(destination)

		# check that the root file exists
		@test read(joinpath(destination, "DOM33.TXT"), String) == "domicile data"

		# check that the nested file exists
		@test read(joinpath(destination, "nested", "PES33.TXT"), String) == "person data"

		# extraction reuses existing directory
		write(joinpath(destination, "DOM33.TXT"), "modified")
		destination2 = CensoBR._extractarchive(zip_path)
		@test destination2 == destination
		@test read(joinpath(destination, "DOM33.TXT"), String) == "modified"

		# forced extraction replaces existing directory
		destination3 = CensoBR._extractarchive(zip_path; force = true)
		@test destination3 == destination
		@test read(joinpath(destination, "DOM33.TXT"), String) == "domicile data"

		# extraction rejects missing ZIP
		@test_throws ArgumentError CensoBR._extractarchive(joinpath(tmpdir, "MISSING.zip"))
	end
end

@testitem "Download Census function" begin
	using CensoBR

	# download aux file for year 2000
    mktempdir() do tmpdir
        url = "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/2_Atualizacoes_20170908.txt"
        destination = joinpath(tmpdir, "updates.txt")

        path = CensoBR._downloadfile(url, destination; showprogress = false)

        @test isfile(path)
		@test filesize(path) > 0
		@test path == destination
        @test !isfile(destination * ".part")
    end


	# download aux file for year 2010
	mktempdir() do tmpdir
		url = "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/1_Atualizacoes_20160311.txt"
        destination = joinpath(tmpdir, "updates.txt")

		path = CensoBR._downloadfile(url, destination; showprogress = false)

		@test isfile(path)
		@test filesize(path) > 0
		@test path == destination
        @test !isfile(destination * ".part")
	end

	# `_download_file` uses cache
	mktempdir() do tmpdir
        url = "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/2_Atualizacoes_20170908.txt"
        destination = joinpath(tmpdir, "updates.txt")

        path = CensoBR._downloadfile(url, destination; showprogress = false)

        mtime_before = mtime(path)

        path2 = CensoBR._downloadfile(url, destination; showprogress = false)

        @test path2 == path
        @test mtime(path2) == mtime_before
    end

	# forced download replaces cached file
	mktempdir() do tmpdir
        url = "https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/2_Atualizacoes_20170908.txt"
        destination = joinpath(tmpdir, "updates.txt")

        CensoBR._downloadfile(url, destination; showprogress = false)

        write(destination, "corrupted")

        CensoBR._downloadfile(url, destination; force = true, showprogress = false)

        @test read(destination, String) != "corrupted"
	end

	# download rejects unsupported year
	mktempdir() do tmpdir
		@test_throws ArgumentError CensoBR._downloadcensus(1990, :rj; cachedir = tmpdir, showprogress = false)
	end

end
