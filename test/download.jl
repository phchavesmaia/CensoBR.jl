@testitem "Census URL" begin
  using CensoBR
  # testing the URL resolution for different years
  @test CensoBR._censusurl(2000, "RJ") == ["https://ftp.ibge.gov.br/Censos/Censo_Demografico_2000/Microdados/RJ.zip"]

  @test CensoBR._censusurl(2010, :RJ) ==
        ["https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_Gerais_da_Amostra/Microdados/RJ.zip"]
  # testing the URL resolution for lowercase UF codes
  @test CensoBR._censusurl(2000, "rj") == CensoBR._censusurl(2000, "RJ")
  @test length(CensoBR._censusurl(2010, :sp)) == 2
  @test endswith.(CensoBR._censusurl(2010, :sp), ["SP1.zip", "SP2_RM.zip"]) == [true, true]

  # testing invalid year and UF code
  @test_throws ArgumentError CensoBR._censusurl(1990, "RJ")
  @test_throws ArgumentError CensoBR._censusurl(2000, "XX")
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
    zippath = joinpath(tmpdir, "RJ.zip")
    sourcedir = joinpath(tmpdir, "source")
    mkpath(joinpath(sourcedir, "nested"))
    write(joinpath(sourcedir, "DOM33.TXT"), "domicile data")
    write(joinpath(sourcedir, "nested", "PES33.TXT"), "person data")
    cd(sourcedir) do
      run(pipeline(`$(p7zip_jll.p7zip()) a -tzip $zippath DOM33.TXT nested/PES33.TXT`, stdout=devnull, stderr=devnull))
    end

    # extract the contents of the ZIP archive
    destinations = CensoBR._extractarchive([zippath])

    # check that the extracted files exist
    @test destinations[1] == joinpath(tmpdir, "RJ")
    @test isdir(destinations[1])

    # check that the root file exists
    @test read(joinpath(destinations[1], "DOM33.TXT"), String) == "domicile data"

    # check that the nested file exists
    @test read(joinpath(destinations[1], "nested", "PES33.TXT"), String) == "person data"

    # extraction reuses existing directory
    write(joinpath(destinations[1], "DOM33.TXT"), "modified")
    destination2 = CensoBR._extractarchive([zippath])
    @test destination2 == destinations
    @test read(joinpath(destinations[1], "DOM33.TXT"), String) == "modified"

    # forced extraction replaces existing directory
    destination3 = CensoBR._extractarchive([zippath]; force=true)
    @test destination3[1] == destinations[1]
    @test read(joinpath(destinations[1], "DOM33.TXT"), String) == "domicile data"

    # extraction rejects missing ZIP
    @test_throws ArgumentError CensoBR._extractarchive([joinpath(tmpdir, "MISSING.zip")])

    invalid = joinpath(tmpdir, "invalid.zip")
    write(invalid, "not a zip archive")
    @test_throws ProcessFailedException CensoBR._extractarchive([invalid])
    @test !isdir(joinpath(tmpdir, "invalid"))
  end
end

@testitem "Download file cache and replacement" begin
  using CensoBR

  mktempdir() do tmpdir
    source = joinpath(tmpdir, "source.txt")
    destination = joinpath(tmpdir, "cached", "data.txt")
    write(source, "original")
    url = "file://" * source

    @test CensoBR._downloadfile(url, destination; showprogress=false) == destination
    @test read(destination, String) == "original"
    @test !isfile(destination * ".part")

    write(source, "updated")
    @test CensoBR._downloadfile(url, destination; showprogress=false) == destination
    @test read(destination, String) == "original"

    @test CensoBR._downloadfile(url, destination; force=true, showprogress=false) == destination
    @test read(destination, String) == "updated"
  end

  # download rejects unsupported year
  mktempdir() do tmpdir
    @test_throws ArgumentError CensoBR._downloadcensus(1990, :rj; cachedir=tmpdir, showprogress=false)
  end
end
