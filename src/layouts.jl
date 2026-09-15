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
