# LTMSim.jl

Software accompying the paper:
*Social Influence Maximization in Hypergraphs*

by

- Alessia Antelmi
- Gennaro Cordasco
- Carmine Spagnuolo
- Przemyslaw Szufel

In case you use the software, please cite:

> Antelmi A., Cordasco G., Spagnuolo C., Szufel P. (2020) Information Diffusion in Complex Networks: A Model Based on Hypergraphs and Its Analysis. In: Kamiński B., Prałat P., Szufel P. (eds) Algorithms and Models for the Web Graph. WAW 2020. Lecture Notes in Computer Science, vol 12091. Springer, Cham. https://doi.org/10.1007/978-3-030-48478-1_3



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

Once the simulation package with its dependencies is installed, you get the `experiments.sh` file to actually run all the experimental scenarios. You can also run a single experiment (located under `src/experiments/ `). For instance, running
```bash
julia -p 4 benchmark_randV_randE.jl
```
The parameter `-p` allows to run the script over multiple processes (4 in this case).

You might want to edit the number of processes to parallelize the simulation over the amount of CPU cores on your machine (we recommend running the simulation on a server having at least 32 CPU/vCPU cores - in that case the simulation will take few hours to complete). 


[docs-latest-img]: https://img.shields.io/badge/docs-latest-blue.svg
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-dev-url]: https://pszufe.github.io/LTMSim.jll/dev
[docs-stable-url]: https://pszufe.github.io/LTMSim.jl/stable

[travis-img]: https://travis-ci.org/pszufe/LTMSim.jl.svg?branch=master
[travis-url]: https://travis-ci.org/pszufe/LTMSim.jl

[codecov-img]: https://coveralls.io/repos/github/pszufe/LTMSim.jl/badge.svg?branch=master
[codecov-url]: https://coveralls.io/github/pszufe/LTMSim.jl?branch=master
