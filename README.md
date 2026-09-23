# CensoBR.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://phchavesmaia.github.io/CensoBR.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://phchavesmaia.github.io/CensoBR.jl/dev/)
[![Build Status](https://github.com/phchavesmaia/CensoBR.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/phchavesmaia/CensoBR.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/phchavesmaia/CensoBR.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/phchavesmaia/CensoBR.jl)

**CensoBR.jl** is a Julia package for downloading and processing microdata from the Brazilian Population Census (Censo Demográfico). 

In specific, this package:
1. Downloads census data directly from the IBGE servers
2. Process these data using the IBGE's data dictionary
3. Saves the proceesed data as a `.parquet` file at a pre-selected `cachedir` folder
4. Further calls of using the same `cachedir` folder reuse the processed data

CensoBR currently supports the **2000** and **2010** Population Censuses.

This project is heavily inspired by the R package [{censobr}](https://github.com/ipea/censobr/), bringing a similar workflow to the Julia ecosystem.

> **Note:** CensoBR is under active development. The public API may change before the first stable release.

## Usage

The main entry point is `fetchcensus`, which downloads, processes, and caches Census microdata. By default, CensoBR uses the operating system's standard cache directory. A different directory can be specified with the `cachedir` keyword argument.

```julia
using CensoBR

dataset = fetchcensus(2000, :rj, :household)
```

The returned object is a `String` indicating the resulting `.parquet` file path.

### Larger-than-memory queries with DuckDB

Because **CensoBR.jl** caches processed data as `.parquet`, the files can be queried directly with tools such as [DuckDB.jl](https://github.com/duckdb/duckdb), without first loading the entire Census dataset into memory.

```julia
using CensoBR
using DuckDB, DBInterface, DataFrames

parquetpath = fetchcensus(2000, :rj, :household; cachedir="path/to/cache")

con = DBInterface.connect(DuckDB.DB())

results = DBInterface.execute(
    con,
    """
    SELECT V1002, V0211, M0213
    FROM read_parquet('$parquetpath')
    WHERE V0211 = '4'
    """
)

df = DataFrame(results)
```

Here, `DuckDB` performs the filtering and column selection directly against the `.parquet` file. Only the query result is materialized as a `DataFrame`.

## Variable metadata

**CensoBR.jl** includes variable metadata derived from the official IBGE documentation. Metadata can be accessed with `fieldlabel`, `fieldvalues`, and `fieldnotes`, or retrieved together with `fieldmetadata`.

For example:

```julia
julia> fieldmetadata(2000, :household, :V0211)
(label = "TIPO DE ESCOADOURO",
 values = Dict(
     "1" => "Rede geral de esgoto ou pluvial",
     "2" => "Fossa séptica",
     "3" => "Fossa rudimentar",
     "4" => "Vala",
     "5" => "Rio, lago ou mar",
     "6" => "Outro escoadouro",
     "Branco" => "para domicílio particular improvisado, domicílio coletivo e domicílio particular permanente que tinha banheiro(s) ou sanitário",
 ),
 notes = String[])
```

Individual components can be retrieved with:

```julia
fieldlabel(2000, :household, :V0211)
fieldvalues(2000, :household, :V0211)
fieldnotes(2000, :household, :V0211)
```

Metadata access does not require downloading the Census microdata.

## Supported data

| Census | Record | Example |
|-------:|--------|---------|
| 2000 | Household | `fetchcensus(2000, :rj, :household)` |
| 2000 | Family | `fetchcensus(2000, :rj, :family)` |
| 2000 | Person | `fetchcensus(2000, :rj, :person)` |
| 2010 | Household | `fetchcensus(2010, :rj, :household)` |
| 2010 | Person | `fetchcensus(2010, :rj, :person)` |
| 2010 | Emigration | `fetchcensus(2010, :rj, :emigration)` |
| 2010 | Mortality | `fetchcensus(2010, :rj, :mortality)` |

**CensoBR.jl** supports Census microdata for all Brazilian states and the Federal District. National-level (`Brazil`) queries are not currently supported.

## Parsing

IBGE Census microdata are distributed as fixed-width text files. **CensoBR.jl** uses bundled layouts derived from official IBGE documentation to determine each variable's byte position, width, type, and implied decimal places.

The parser follows these conventions:

- blank fields become `missing`;
- character fields become `String`;
- integer numeric fields become `Int`;
- numeric fields with implied decimal places become `Float64`; and
- character identifiers retain leading zeroes.

Parsing is performed internally as part of the conversion pipeline. Users normally interact with the resulting Parquet datasets rather than the original fixed-width files.