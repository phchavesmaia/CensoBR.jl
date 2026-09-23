```@meta
CurrentModule = CensoBR
```

# CensoBR.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://phchavesmaia.github.io/CensoBR.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://phchavesmaia.github.io/CensoBR.jl/dev/)
[![Build Status](https://github.com/phchavesmaia/CensoBR.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/phchavesmaia/CensoBR.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/phchavesmaia/CensoBR.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/phchavesmaia/CensoBR.jl)

CensoBR.jl downloads Brazilian Population Census microdata from IBGE, converts the fixed-width files to Parquet, and returns the path to the processed file.

```julia
using CensoBR

path = fetchcensus(2000, :ac, :household)
```

CensoBR supports the **2000** and **2010** censuses for Brazilian states and the Federal District. Processed files are cached, so later calls can reuse them without downloading the data again.

## Where to start

- [Getting started](getting-started.md) shows how to fetch data and use the returned path.
- [Data and cache](data-and-cache.md) explains supported records, storage, and conversion behavior.
- [API reference](api.md) documents `fetchcensus` and the variable metadata functions.

CensoBR also provides census variable labels, value descriptions, and notes without requiring a microdata download:

```julia
fieldmetadata(2000, :household, :V0211)
```

> **Note:** The package is under active development, and its public API may change before the first stable release.
