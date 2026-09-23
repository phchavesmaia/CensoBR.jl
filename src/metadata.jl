struct FieldMetadata
  label::Union{Nothing,String}
  values::Dict{String,String}
  notes::Vector{String}
end

function Base.show(io::IO, ::MIME"text/plain", metadata::FieldMetadata)
  println(io, "\nLabel:")
  println(io, "  ", something(metadata.label, "—"))

  println(io, "\nValues:")

  if isempty(metadata.values)
    println(io, "  —")
  else
    for (code, description) in sort!(collect(metadata.values); by=first)
      println(io, "  ", code, " ⇒ ", description)
    end
  end

  println(io, "\nNotes:")

  if isempty(metadata.notes)
    print(io, "  —")
  else
    for note in metadata.notes
      println(io, "  ", note)
    end
  end
end

"""
	fieldmetadata(year::Integer, record::Symbol, variable::Symbol)

Return metadata for `variable` in the specified Census `year` and `record`.

The returned named tuple contains:

- `labels`: descriptive label for the variables, or `nothing` if unavailable.
- `values`: mapping from coded values to their descriptions.
- `notes`: additional notes associated with the variable.

See also [`fieldlabel`](@ref), [`fieldvalues`](@ref), and [`fieldnotes`](@ref).
"""
function fieldmetadata(year::Integer, record::Symbol, variable::Symbol)
  layout = _loadlayout(year, record)

  for field in layout.fields
    if Symbol(field.name) == variable
      return FieldMetadata(field.label, field.values, field.notes)
    end
  end

  throw(ArgumentError("Variable `$variable` not found in Census $year $record layout"))
end

"""
	fieldlabel(year::Integer, record::Symbol, variable::Symbol)

Return the descriptive label for `variable` in the specified Census `year` and
`record`.

Returns `nothing` if the variable has no label.

See also [`fieldmetadata`](@ref), [`fieldvalues`](@ref), and [`fieldnotes`](@ref), and [`fieldlabel`](@ref).
"""
function fieldlabel(year::Integer, record::Symbol, variable::Symbol)
  fieldmetadata(year, record, variable).label
end

"""
	fieldvalues(year::Integer, record::Symbol, variable::Symbol)

Return the coded values and their descriptions for `variable` in the specified
Census `year` and `record`.

The result is a `Dict{String,String}` mapping the codes used in the raw Census
data to their corresponding descriptions. Returns an empty dictionary when no
coded values are defined.

See also [`fieldmetadata`](@ref), [`fieldlabel`](@ref), and [`fieldnotes`](@ref).
"""
function fieldvalues(year::Integer, record::Symbol, variable::Symbol)
  fieldmetadata(year, record, variable).values
end

"""
	fieldnotes(year::Integer, record::Symbol, variable::Symbol)

Return additional notes for `variable` in the specified Census `year` and
`record`.

The result is a `Vector{String}`. Returns an empty vector when no notes are
available.

See also [`fieldmetadata`](@ref), [`fieldlabel`](@ref), and [`fieldvalues`](@ref).
"""
function fieldnotes(year::Integer, record::Symbol, variable::Symbol)
  fieldmetadata(year, record, variable).notes
end
