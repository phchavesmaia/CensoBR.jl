using CensoBR
using Documenter

DocMeta.setdocmeta!(CensoBR, :DocTestSetup, :(using CensoBR); recursive=true)

makedocs(;
  modules=[CensoBR],
  authors="Pedro H. Chaves Maia",
  sitename="CensoBR.jl",
  format=Documenter.HTML(; canonical="https://phchavesmaia.github.io/CensoBR.jl", edit_link="main", assets=String[]),
  pages=[
    "Home" => "index.md",
    "Getting started" => "getting-started.md",
    "Data and cache" => "data-and-cache.md",
    "API" => "api.md"
  ],
  checkdocs=:exports
)

deploydocs(; repo="github.com/phchavesmaia/CensoBR.jl", devbranch="main")
