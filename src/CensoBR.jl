module CensoBR

# core module for handling Brazilian Census data
include("download.jl")
include("layouts.jl")
include("parse.jl")
include("process.jl")
include("census.jl")
include("metadata.jl")

export opencensus, fieldmetadata, fieldlabel, fieldvalues, fieldnotes

end
