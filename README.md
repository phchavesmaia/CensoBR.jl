# CensoBR.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://phchavesmaia.github.io/CensoBR.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://phchavesmaia.github.io/CensoBR.jl/dev/)
[![Build Status](https://github.com/phchavesmaia/CensoBR.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/phchavesmaia/CensoBR.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/phchavesmaia/CensoBR.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/phchavesmaia/CensoBR.jl)

**CensoBR.jl** is a Julia package for working with Brazilian Population
Census microdata from the Instituto Brasileiro de Geografia e
Estatística (IBGE).

It downloads official Census microdata, interprets the fixed-width files
using bundled layouts derived from official IBGE documentation, and
exposes the data through the Tables.jl interface.

CensoBR currently focuses on the **2000** and **2010** Population
Censuses.

> **Note:** CensoBR is under active development. The public API may
> change before the first stable release.

## Features

-   Downloads Census microdata directly from IBGE.
-   Caches downloaded and extracted files locally.
-   Supports 2000 and 2010 fixed-width Census microdata.
-   Uses layouts generated from official IBGE documentation.
-   Parses records lazily instead of loading the complete dataset into
    memory.
-   Implements the Tables.jl row-table interface.
-   Preserves variable labels, value codes, and documentation notes.
-   Keeps identifiers and categorical variables as their original Census
    codes.
-   Handles blank fields as `missing` and implied decimal places
    according to the official layouts.

## Installation

CensoBR is currently under development. Install it from its repository:

``` julia
using Pkg
Pkg.add(url="https://github.com/<USER>/CensoBR.jl")
```

For local development:

``` julia
pkg> dev https://github.com/<USER>/CensoBR.jl
```

Replace `<USER>` with the repository owner.

## Quick start

``` julia
using CensoBR

table = opencensus(2000, :rj, :household)
first(table)
```

On the first call, CensoBR downloads and extracts the corresponding IBGE
archive. Subsequent calls reuse the local cache unless preparation is
explicitly forced.

`opencensus` returns a lazy `CensusTable`: Census records are parsed
only when requested.

## Supported data

| Census | Record      | Example                                 |
|--------|-------------|-----------------------------------------|
| 2000   | Household   | `opencensus(2000, :rj, :household)`     |
| 2000   | Family      | `opencensus(2000, :rj, :family)`        |
| 2000   | Person      | `opencensus(2000, :rj, :person)`        |
| 2010   | Household   | `opencensus(2010, :rj, :household)`     |
| 2010   | Person      | `opencensus(2010, :rj, :person)`        |
| 2010   | Emigration  | `opencensus(2010, :rj, :emigration)`    |
| 2010   | Mortality   | `opencensus(2010, :rj, :mortality)`     |

State availability follows the corresponding IBGE releases. Support for
special archive structures may vary while the package is under
development.

## Lazy tables

Census microdata can be large, so `opencensus` does not materialize the
complete file in memory.

``` julia
table = opencensus(2000, :rj, :household)
```

The returned object stores the path to the extracted fixed-width file
together with its Census layout. Iteration opens the file and parses one
record at a time.

``` julia
for row in table
    # work with one Census record
end
```

Because `CensusTable` implements Tables.jl, compatible packages can
consume it. For example:

``` julia
using DataFrames
df = DataFrame(table)
```

`DataFrame(table)` materializes the complete dataset in memory even
though the underlying `CensusTable` is lazy.

## Metadata

CensoBR preserves variable labels, coded-value definitions, and
documentation notes from the Census layouts.

``` julia
table = opencensus(2000, :rj, :household)

fieldmetadata(table, :V0102)
```

Metadata components can also be accessed directly:

``` julia
labels(table)[:V0102]
valuecodes(table, :V0102)
notes(table, :V0102)
```

For example:

``` julia
valuecodes(table, :V0102)["33"]
# "Rio de Janeiro"
```

CensoBR keeps the original Census code in the data rather than
automatically replacing codes with labels. This preserves the raw IBGE
representation while keeping definitions available as metadata.

## Parsing

IBGE Census microdata are distributed as fixed-width text files. CensoBR
uses the official layouts to determine each variable's byte position,
width, type, and implied decimal places.

Parsing follows these conventions:

-   blank fields become `missing`;
-   character fields become `String`;
-   integer numeric fields become `Int`;
-   numeric fields with implied decimal places become `Float64`;
-   character identifiers retain leading zeroes.

For example, `00345` in a numeric field with two implied decimal places
becomes `3.45`.

## Census layouts

Runtime parsing does not depend on the original SAS or ODS documentation
files. CensoBR includes normalized TOML layouts:

``` text
data/
└── layouts/
    ├── 2000/
    │   ├── household.toml
    │   ├── family.toml
    │   └── person.toml
    └── 2010/
        ├── household.toml
        ├── person.toml
        ├── emigration.toml
        └── mortality.toml
```

These layouts are generated from official IBGE documentation and
committed to the repository. Developer scripts used to regenerate them
are kept under `dev/`.

## Cache

By default, downloaded and extracted Census files are stored in
CensoBR's platform-appropriate cache directory.

A different cache can be supplied with `cachedir`:

``` julia
table = opencensus(
    2000,
    :rj,
    :household;
    cachedir="/path/to/cache",
)
```

Preparation can be forced again with `force=true`, and download progress
can be disabled with `showprogress=false`.

## Data provenance

CensoBR does not redistribute Census microdata. Source files are
downloaded from official IBGE Census repositories.

The bundled layouts are derived from documentation distributed by IBGE
with the corresponding Census releases. Users should consult IBGE
documentation for authoritative variable definitions, methodology,
sampling procedures, and conditions of use.

## Development

The project separates runtime code from developer tooling:

``` text
CensoBR/
├── src/
│   ├── CensoBR.jl
│   ├── download.jl
│   ├── layouts.jl
│   └── maketable.jl
├── data/
│   └── layouts/
├── dev/
│   ├── Project.toml
│   ├── download.jl
│   ├── generatelayouts2000.jl
│   └── generatelayouts2010.jl
└── test/
```

Run the package tests with:

``` julia
pkg> test
```

Developer scripts use their separate environment:

``` sh
julia --project=dev dev/generatelayouts2000.jl
julia --project=dev dev/generatelayouts2010.jl
```

## Roadmap

Planned work includes efficient Parquet materialization and caching,
DuckDB integration for querying Census microdata, broader geographic and
Census coverage, and higher-level tools for coded variables and Census
metadata.

## Acknowledgements

Census microdata and documentation are produced and distributed by the
**Instituto Brasileiro de Geografia e Estatística (IBGE)**.

CensoBR is an independent Julia package and is not affiliated with or
endorsed by IBGE.

## License

See the repository's `LICENSE` file for licensing information.