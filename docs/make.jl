using CensoBR
using Documenter

DocMeta.setdocmeta!(CensoBR, :DocTestSetup, :(using CensoBR); recursive = true)

makedocs(;
    modules = [CensoBR],
    authors = "Pedro Chaves Maia",
    sitename = "CensoBR.jl",
    format = Documenter.HTML(;
        canonical = "https://phchavesmaia.github.io/CensoBR.jl",
        edit_link = "main",
        assets = String[],
    ),
    pages = ["Home" => "index.md"],
)

deploydocs(; repo = "github.com/phchavesmaia/CensoBR.jl", devbranch = "main")
