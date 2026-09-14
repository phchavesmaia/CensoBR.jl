module CensoBR

using Downloads
using ZipFile

include("download.jl")

export download_census
export prepare_census

end
