using Pkg
Pkg.activate(".")
using LTMSim
using SimpleHypergraphs
#, DataFrames, SimpleHypergraphs, Statistics, Plots, PyPlot, Random, Serialization, LaTeXStrings

#
# Count the number of edges
# in the corresponding clique-expansion
# of each hypergraph
#
project_path = dirname(pathof(LTMSim))
data_path = joinpath(project_path, "..", "data", "hgs")

hg_files = readdir(data_path)

hgs = [prune_hypergraph!(hg_load(joinpath(data_path, hg_file))) for hg_file in hg_files]


for (index, hg) in enumerate(hgs)
    s = 0

    for he in 1:nhe(hg)
        vs = length(getvertices(hg, he))
        s += (vs * (vs-1)) / 2
    end

    println(hg_files[index], " ", size(hg), " ", s)
end

