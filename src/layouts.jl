abstract type LayoutSource end

struct SASLayout <: LayoutSource end
struct ExcelLayout <: LayoutSource end

struct LayoutField
	name::String
	start::Int
	width::Int
	decimals::Int
	is_character::Bool
	label::Union{Nothing, String}
end

struct CensusLayout
	year::Int
	record::Symbol
	lrecl::Int
	fields::Vector{LayoutField}
end

""" 
Determine the layout source based on the Census year 
"""
function _layout_source(year::Integer)
	year == 2000 && return SASLayout()
	year == 2010 && return ExcelLayout()

	throw(ArgumentError("Unsupported census year: $year"))
end

"""
    _find_layout(source::LayoutSource, record::Symbol, extracted_dir::AbstractString)

Find the official IBGE layout file for `record` in `extracted_dir`.

The method dispatches on `_layout_source` to account for differences in how Census
layout files are distributed. For example, the 2000 Census uses SAS layout
files, while the 2010 Census uses an Excel workbook.

Returns the path to the layout file.

Throws an error if the appropriate layout file cannot be found.
"""
function _find_layout(::SASLayout, record::Symbol, extracted_dir::AbstractString)
	path = _prepare_census(2000, "1_Documentacao_20170908", show_progress = false)
    joinpath(extracted_dir, "")
end

function _find_layout(::ExcelLayout, record::Symbol, extracted_dir::AbstractString)
	# locate the .xls/.xlsx file
end

"""
    _load_layout(year::Integer, record::Symbol, extracted_dir::AbstractString)

Load the official IBGE layout for a Census record.

Determines the layout source associated with `year`, locates the corresponding
layout file in `extracted_dir`, and parses the layout for `record`.

Returns the parsed layout in CensoBR's common internal representation.

Throws an error if `year` is unsupported, the layout file cannot be found,
or the layout cannot be parsed.
"""
function _load_layout(year::Integer, record::Symbol, extracted_dir::AbstractString)
	# Determine the layout source based on the Census year
	source = _layout_source(year)

	# Find the layout file based on the source type
	path = _find_layout(source, record, extracted_dir)

	# Parse the layout file to create a CensusLayout instance
	_parse_layout(source, path, year, record)
end
