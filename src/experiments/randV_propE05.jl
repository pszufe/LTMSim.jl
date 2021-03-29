"""
    Second experimental scenario.
    
    In this experimental scenario, we fixed each node threshold 
    to a random value between 1 and its degree, varying it at each run of the experiment. 
    We used a majority policy for the hyperedge thresholds, instead.
"""
using Pkg, Distributed
#addprocs(4)
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
res_path = joinpath(project_path, "..", "res", "journal", "randV_propE05.data")

hg_files = readdir(data_path)
hgs = [prune_hypergraph!(hg_load(joinpath(data_path, hg_file))) for hg_file in hg_files]

runs = 50
data = Dict{String, Vector{Vector{Int}}}()

push!(data, "BinarySearch(H)" => Vector{Int}[])
push!(data, "Greedy(H)" => Vector{Int}[])
push!(data, "Greedy([H]₂)" => Vector{Int}[])
push!(data, "SubTSS(H)" => Vector{Int}[])

for index in 1:length(hgs)
    println("Index=$index, $(hg_files[index])")

    h = hgs[index]
    
    results = @distributed (append!) for run=1:runs
		println("run=$run at proc $(myid())")
        Random.seed!(run)
        
        metaV = randMetaV(h)
        metaE = proportionalMetaE(h,0.5)

        r1 = greedy_tss_2section(h,metaV,metaE; opt=true)
        r2 = bisect(h,metaV,metaE; opt=true)
        r3 = greedy_tss(h,metaV,metaE; opt=true)
        r4 = sub_tss(h,metaV,metaE; opt=true)

        [(r1,r2,r3,r4)]
    end

    push!(data["Greedy([H]₂)"], [r[1] for r in results])
    push!(data["BinarySearch(H)"], [r[2] for r in results])
    push!(data["Greedy(H)"], [r[3] for r in results])
    push!(data["SubTSS(H)"], [r[4][1] for r in results])
end


serialize(res_path, data)
