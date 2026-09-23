using TOML

struct LayoutField
  name::String
  start::Int
  width::Int
  decimals::Int
  ischaracter::Bool
  label::Union{Nothing,String}
  values::Dict{String,String}
  notes::Vector{String}
end

struct CensusLayout
  year::Int
  record::Symbol
  lrecl::Int
  fields::Vector{LayoutField}
end

const LAYOUT_FILES = Dict(
  (2000, :household) => "household.toml",
  (2000, :family) => "family.toml",
  (2000, :person) => "person.toml",
  (2010, :household) => "household.toml",
  (2010, :person) => "person.toml",
  (2010, :emigration) => "emigration.toml",
  (2010, :mortality) => "mortality.toml"
)

function _loadlayout(year::Integer, record::Symbol)

  # retrieve the filename for the given year and record from the LAYOUT_FILES dictionary.
  haskey(LAYOUT_FILES, (year, record)) || throw(ArgumentError("Unsupported Census layout: year=$year, record=$record"))
  filename = LAYOUT_FILES[(year, record)]

  # construct the full path to the layout file within the package's data directory.
  path = joinpath(pkgdir(CensoBR), "data", "layouts", string(year), filename)
  isfile(path) || error("Bundled Census layout not found: $path")

  data = TOML.parsefile(path)

  fields = LayoutField[]

  for field in data["fields"]
    values = Dict{String,String}(string(k) => string(v) for (k, v) in get(field, "values", Dict()))

    notes = String.(get(field, "notes", String[]))

    push!(
      fields,
      LayoutField(
        field["name"],
        field["start"],
        field["width"],
        get(field, "decimals", 0),
        field["character"],
        get(field, "label", nothing),
        values,
        notes
      )
    )
  end

  CensusLayout(year, record, data["lrecl"], fields)
end

function _validatelayout(layout::CensusLayout)
  isempty(layout.fields) && error("Layout contains no fields")

  maximum(field.start + field.width - 1 for field in layout.fields) ≤ layout.lrecl ||
    error("Layout fields extend beyond LRECL")

  true
end
