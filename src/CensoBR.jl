module CensoBR

# core module for handling Brazilian Census data
include("download.jl")
include("layouts.jl")
include("maketable.jl")

export opencensus, fieldmetadata, fieldlabel, fieldvalues, fieldnotes

end
