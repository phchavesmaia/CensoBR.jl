module CensoBR

# core module for handling Brazilian Census data
include("download.jl")
include("layouts.jl")
include("maketable.jl")

export opencensus, fieldmetadata, label, valuecodes, notes

end
