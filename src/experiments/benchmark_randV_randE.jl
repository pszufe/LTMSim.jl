"""
    Execution time comparison.

    As for the first experimental scenario, we fixed
    random thresholds for both nodes and hyperedges.

    For each heuristic, we consider the average time (in seconds) 
    required to complete the task.
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
res_path = joinpath(project_path, "..", "res", "journal", "benchmark_randV_randE.data")

hg_files = readdir(data_path)
hgs = [prune_hypergraph!(hg_load(joinpath(data_path, hg_file))) for hg_file in hg_files]

runs = 50
data = Dict{String, Vector{Vector{Float64}}}()

push!(data, "BinarySearch(H)" => Vector{Float64}[])
push!(data, "Greedy(H)" => Vector{Float64}[])
push!(data, "Greedy([H]₂)" => Vector{Float64}[])
push!(data, "SubTSS(H)" => Vector{Float64}[])

push!(data, "BinarySearch(H)-noOpt" => Vector{Float64}[])
push!(data, "Greedy(H)-noOpt" => Vector{Float64}[])
push!(data, "Greedy([H]₂)-noOpt" => Vector{Float64}[])
push!(data, "SubTSS(H)-noOpt" => Vector{Float64}[])

for index in 1:length(hgs)
    println("Index=$index, $(hg_files[index])")

    h = hgs[index]
    
    results = @distributed (append!) for run=1:runs
		println("run=$run at proc $(myid())")
        Random.seed!(run)
        
        metaV = randMetaV(h)
        metaE = randMetaE(h) 

        r1 = @belapsed greedy_tss_2section($h, $metaV, $metaE; opt=true)
        r2 = @belapsed bisect($h, $metaV, $metaE; opt=true)
        r3 = @belapsed greedy_tss($h, $metaV, $metaE; opt=true)
        r4 = @belapsed sub_tss($h, $metaV, $metaE; opt=true)

        #no-opt
        r5 = @belapsed greedy_tss_2section($h, $metaV, $metaE; opt=false)
        r6 = @belapsed bisect($h, $metaV, $metaE; opt=false)
        r7 = @belapsed greedy_tss($h, $metaV, $metaE; opt=false)
        r8 = @belapsed sub_tss($h, $metaV, $metaE; opt=false)

        [(r1,r2,r3,r4,r5,r6,r7,r8)]
    end

    push!(data["Greedy([H]₂)"], [r[1] for r in results])
    push!(data["BinarySearch(H)"], [r[2] for r in results])
    push!(data["Greedy(H)"], [r[3] for r in results])
    push!(data["SubTSS(H)"], [r[4] for r in results])

    #no-opt
    push!(data["Greedy([H]₂)-noOpt"], [r[5] for r in results])
    push!(data["BinarySearch(H)-noOpt"], [r[6] for r in results])
    push!(data["Greedy(H)-noOpt"], [r[7] for r in results])
    push!(data["SubTSS(H)-noOpt"], [r[8] for r in results])
end


serialize(res_path, data)

