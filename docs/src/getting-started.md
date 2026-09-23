# Getting started

CensoBr.jl downloads Brazilian census microdata, converts the fixed-width records to Parquet, and returns the path to the resulting file.

```julia
using CensoBR

path = fetchcensus(2000, :ac, :household)
```

`path` is a `String` pointing to a `.parquet` file. It is not an in-memory table. Pass it to a Parquet reader or query tool of your choice.

To choose where processed files are stored:

```julia
path = fetchcensus(2010, :ac, :person; cachedir="/path/to/census-cache")
```

The first call for a census year and state downloads and converts the data. Calling `fetchcensus` again with the same cache reuses the processed file.

Variable descriptions are available without downloading microdata:

```julia
fieldlabel(2000, :household, :V0211)
fieldvalues(2000, :household, :V0211)
fieldmetadata(2000, :household, :V0211)
```

See [Data and cache](data-and-cache.md) for storage and conversion details, or [API reference](api.md) for all public functions.