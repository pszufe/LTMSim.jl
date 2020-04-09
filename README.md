# LTMSim.jl

Software accompying the paper:
*Determinants of optimality of Information diffusion on hypergraphs*

by

- Alessia Antelmi
- Gennaro Cordasco
- Carmine Spagnuolo
- Przemyslaw Szufel

| **Documentation** | **Build Status** |
|---------------|--------------|
|[![][docs-latest-img]][docs-dev-url] | [![Build Status][travis-img]][travis-url]  [![Coverage Status][codecov-img]][codecov-url] <br/> Linux and macOS |

## Installation instructions

In order to install the simulation package please run the following julia commnads:
```julia
using Pkg
Pkg.add(PackageSpec(url="https://github.com/pszufe/LTMSim.jl"))
```

## Replicating the simulation experiments results

Once the simulation package with its dependencies is installed get the `experiments.jl` file to actually run the simulations. You might want to edit the addprocs command in that file to pararelize the simulation over the amount of CPU cores on your machine (we recommend running the simulation on a server having at least 32 CPU/vCPU cores - in that case the simulation will take few hours to complete). Once the addprocs line has been edited run the command:
```bash
julia experiments.jl
```

[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-dev-url]: https://pszufe.github.io/LTMSim.jll/dev
[docs-stable-url]: https://pszufe.github.io/LTMSim.jl/stable

[travis-img]: https://travis-ci.org/pszufe/LTMSim.jl.svg?branch=master
[travis-url]: https://travis-ci.org/pszufe/LTMSim.jl

[codecov-img]: https://coveralls.io/repos/github/pszufe/LTMSim.jl/badge.svg?branch=master
[codecov-url]: https://coveralls.io/github/pszufe/LTMSim.jl?branch=master
