using Pkg, Distributed
addprocs(4)
Pkg.activate(".")
@everywhere using Distributed, Pkg
@everywhere Pkg.activate(".")
using LTMSim, SimpleHypergraphs, Random, Serialization
@everywhere using LTMSim, SimpleHypergraphs, Random, Serialization

#
#
#
project_path = dirname(pathof(LTMSim))
data_path = joinpath(project_path, "..", "data", "hgs")
res_path = joinpath(project_path, "..", "res", "journal", "propV_randE.data")

hg_files = readdir(data_path)
hgs = [prune_hypergraph!(hg_load(joinpath(data_path, hg_file))) for hg_file in hg_files]
hg_names = [split(fname, ".")[1] for fname in hg_files]

algorithms = ["BinarySearch(H)", "Greedy([H]₂)", "Greedy(H)", "SubTSS(H)"]

data = Dict{String, Dict{String, Vector{Vector{Int}}}}()

for algo in algorithms
    for hg in hg_names
        push!(
            get!(data, algo, Dict{String, Vector{Vector{Int}}}()),
            hg => Vector{Vector{Int}}()
        )
    end
end

nvalues = range(0.2, stop=0.8, step=0.1)
runs = 50

for (index, h) in enumerate(hgs)
    println("Index=$index, $(hg_files[index])")
    
    for n=nvalues
        println("n=$n")

        results = @distributed (append!) for run=1:runs
            println("run=$run at proc $(myid())")
            Random.seed!(run)

            metaV = proportionalMetaV(h, n)
            metaE = randMetaE(h) 
    
            r1 = greedy_tss_2section(h,metaV,metaE; opt=true)
            r2 = bisect(h,metaV,metaE; opt=true)
            r3 = greedy_tss(h,metaV,metaE; opt=true)
            r4 = sub_tss(h,metaV,metaE; opt=true)
    
            [(r1,r2,r3,r4)]
    
        end

        push!(data["Greedy([H]₂)"][hg_names[index]], [r[1] for r in results])
        push!(data["BinarySearch(H)"][hg_names[index]], [r[2] for r in results])
        push!(data["Greedy(H)"][hg_names[index]], [r[3] for r in results])
        push!(data["SubTSS(H)"][hg_names[index]], [r[4][1] for r in results])

        println()
    end
    println()
end

serialize(res_path, data)
