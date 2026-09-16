# CensoBR.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://phchavesmaia.github.io/CensoBR.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://phchavesmaia.github.io/CensoBR.jl/dev/)
[![Build Status](https://github.com/phchavesmaia/CensoBR.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/phchavesmaia/CensoBR.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/phchavesmaia/CensoBR.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/phchavesmaia/CensoBR.jl)

**CensoBR.jl** is a Julia package for working with Brazilian Population
Census microdata from the Instituto Brasileiro de Geografia e Estatística
(IBGE).

It downloads official Census microdata, interprets the fixed-width files
using bundled layouts derived from official IBGE documentation, and converts
the data to Parquet for efficient subsequent access.

CensoBR currently focuses on the **2000** and **2010** Population Censuses.

> **Note:** CensoBR is under active development. The public API may change
> before the first stable release.

## Features

- Downloads Census microdata directly from IBGE.
- Supports 2000 and 2010 fixed-width Census microdata.
- Uses layouts generated from official IBGE documentation.
- Streams fixed-width records without loading the complete source file into memory.
- Converts Census microdata to Parquet using Parquet2.jl.
- Caches processed Parquet files for faster subsequent access.
- Removes downloaded archives and extracted raw files after successful processing.
- Keeps identifiers and categorical variables as their original Census codes.
- Handles blank fields as `missing` and implied decimal places according to the official layouts.
- Exposes processed data through the Tables.jl-compatible Parquet2 interface.

## To-do list

- [ ] Handle the SP-2010 special case (multiple files for one UF).
- [x] Cache processed Census data as Parquet and remove temporary raw files.
- [ ] Add a `:brazil` option to open the complete Census.
- [ ] *(Far future)* Standardize variables across Census years.

## Installation

CensoBR is currently under development. Install it directly from GitHub:

```julia
using Pkg

Pkg.add(url="https://github.com/phchavesmaia/CensoBR.jl")
```

For local development:

```julia
pkg> dev https://github.com/phchavesmaia/CensoBR.jl
```

## Quick start

```julia
using CensoBR

dataset = opencensus(2000, :rj, :household)

first(dataset)
```

On the first call for a state and Census year, CensoBR downloads and extracts
the corresponding IBGE archive. The fixed-width files are parsed and converted
to Parquet.

Because a single IBGE archive contains multiple record types, CensoBR processes
all supported record types for that Census year before removing the downloaded
archive and extracted files.

For example:

```julia
dataset = opencensus(2000, :rj, :household)
```

creates the following processed cache:

```text
parquet/
└── 2000/
    └── RJ/
        ├── household.parquet
        ├── family.parquet
        └── person.parquet
```

A later call such as:

```julia
people = opencensus(2000, :rj, :person)
```

reuses the existing Parquet file without downloading or parsing the Census
microdata again.

`opencensus` returns a `Parquet2.Dataset`.

## Supported data

| Census | Record     | Example |
|-------:|------------|---------|
| 2000 | Household | `opencensus(2000, :rj, :household)` |
| 2000 | Family | `opencensus(2000, :rj, :family)` |
| 2000 | Person | `opencensus(2000, :rj, :person)` |
| 2010 | Household | `opencensus(2010, :rj, :household)` |
| 2010 | Person | `opencensus(2010, :rj, :person)` |
| 2010 | Emigration | `opencensus(2010, :rj, :emigration)` |
| 2010 | Mortality | `opencensus(2010, :rj, :mortality)` |

State availability follows the corresponding IBGE releases. Support for
special archive structures, such as São Paulo in the 2010 Census, is still
under development.

## Parsing

IBGE Census microdata are distributed as fixed-width text files. CensoBR uses
bundled layouts derived from official IBGE documentation to determine each
variable's byte position, width, type, and implied decimal places.

Parsing follows these conventions:

- blank fields become `missing`;
- character fields become `String`;
- integer numeric fields become `Int`;
- numeric fields with implied decimal places become `Float64`;
- character identifiers retain leading zeroes.

The fixed-width parser is an internal part of the conversion pipeline. Users
normally interact with the resulting Parquet datasets rather than the original
text files.