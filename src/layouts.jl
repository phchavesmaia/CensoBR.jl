abstract type LayoutSource end

struct SASLayout <: LayoutSource end
struct OdsLayout <: LayoutSource end

struct LayoutField
	name::String
	start::Int
	width::Int
	decimals::Int
	is_character::Bool
	label::Union{Nothing, String}
	values::Dict{String, String}
	notes::Vector{String}
end

struct CensusLayout
	record::Symbol
	lrecl::Int
	fields::Vector{LayoutField}
end

const LAYOUT_FILES = Dict(
	(2000, :household) => "household.toml",
	(2000, :family)    => "family.toml",
	(2000, :person)    => "person.toml", (2010, :household)  => "household.toml",
	(2010, :person)     => "person.toml",
	(2010, :emigration) => "emigration.toml",
	(2010, :mortality)  => "mortality.toml",
)

"""
	_layoutpath(year, record)

Return the path to the bundled normalized layout for `year` and `record`.
"""
function _layoutpath(year::Integer, record::Symbol)
	# retrieve the filename for the given year and record from the LAYOUT_FILES dictionary.
	filename = get(LAYOUT_FILES, (year, record), nothing)
	isnothing(filename) && throw(ArgumentError("Unsupported Census layout: year=$year, record=$record"))

	# construct the full path to the layout file within the package's data directory.
	path = joinpath(pkgdir(CensoBR), "data", "layouts", string(year), filename)
	isfile(path) || error("Bundled Census layout not found: $path")

	path
end

"""
    _loadlayout(year, record)

Load a bundled Census layout into CensoBR's internal representation.
"""
function _loadlayout(year::Integer, record::Symbol)
    data = TOML.parsefile(_layoutpath(year, record))

    fields = LayoutField[]

    for field in data["fields"]
        values = Dict{String,String}(
            string(k) => string(v)
            for (k, v) in get(field, "values", Dict())
        )

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
                notes,
            ),
        )
    end

    CensusLayout(record, data["lrecl"], fields)
end