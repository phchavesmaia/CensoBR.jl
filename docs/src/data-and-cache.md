# Data and cache

## Available data

CensoBr.jl supports the 2000 and 2010 censuses for Brazilian states and the Federal District. Use `:br` to stack all 27 federative units into a country-level file.

| Census | Record types |
|:--|:--|
| 2000 | `:household`, `:family`, `:person` |
| 2010 | `:household`, `:person`, `:emigration`, `:mortality` |

## Where files go

By default, `fetchcensus` uses an operating-system cache directory. Set `cachedir` if you want a specific location:

```julia
path = fetchcensus(2010, :ac, :household; cachedir="/path/to/cache")
country_path = fetchcensus(2010, :br, :person; cachedir="/path/to/cache")
```

Processed files follow this layout:

```text
<cachedir>/parquet/<year>/<UF>/<record>.parquet
```

For the example above, the path ends in
`parquet/2010/AC/household.parquet`.
Country-level files use `parquet/<year>/BR/<record>.parquet`.

## What happens on the first call

CensoBr.jl downloads the IBGE archive for the requested year and state, extracts it, and converts the available record types to Parquet. A request for `:household` therefore also prepares the other record types for that year and state. For `:br`, it processes each UF in turn and appends each record's rows to a national Parquet file. The initial call can take time and temporarily needs space for the archive, extracted text files, and Parquet output.

After a successful conversion, CensoBr.jl removes the downloaded archive and extracted text files. It keeps the Parquet files for later calls. The 2010 São Paulo data comes from two IBGE archives; CensoBr.jl combines the matching files during conversion.

## Reusing or rebuilding data

If the requested Parquet file already exists, `fetchcensus` returns its path without downloading or converting again.

Use `force=true` to download and convert the requested year and UF again:

```julia
path = fetchcensus(2010, :ac, :household; cachedir="/path/to/cache", force=true)
```

`fetchcensus` returns a file path, so the size of the resulting dataset does not require that dataset to fit in memory. Memory use in later analysis depends on the tool and query you use to read the Parquet file.
