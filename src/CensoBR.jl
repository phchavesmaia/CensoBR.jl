module CensoBR

# core module for handling Brazilian Census data
include("download.jl")
include("layouts.jl")
include("process.jl")

"""
	opencensus(year, uf, record; cachedir=_defaultcachedir(),
			   force=false, showprogress=true)

Return a lazy Tables.jl-compatible view of IBGE Census microdata.

The corresponding Census archive is downloaded and extracted if necessary.
CensoBR then loads the bundled layout for `year` and `record`, locates the
matching fixed-width microdata file, and parses records on demand.
"""
function opencensus(year::Integer, uf::Union{String, Symbol}, record::Symbol;
	cachedir::AbstractString = _defaultcachedir(), force::Bool = false,
	showprogress::Bool = true)

	censusdir = _preparecensus(year, uf; cachedir = cachedir, force = force, showprogress = showprogress)

	layout = _loadlayout(year, record)

	path = _findrawfile(censusdir, layout)

	_parsefile(path, layout)
end

export opencensus

end
