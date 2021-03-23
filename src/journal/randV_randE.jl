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
res_path = joinpath(project_path, "..", "res", "journal", "randV_randE.data")

hg_files = readdir(data_path)
hgs = [prune_hypergraph!(hg_load(joinpath(data_path, hg_file))) for hg_file in hg_files]

runs = 50
data = Dict{String, Vector{Vector{Int}}}()

push!(data, "BinarySearch(H)"=>Vector{Vector{Int}}())
push!(data, "Greedy(H)"=>Vector{Vector{Int}}())
push!(data, "Greedy([H]₂)"=>Vector{Vector{Int}}())
push!(data, "SubTSS(H)"=>Vector{Vector{Int}}())

for index in 1:length(hgs)
    println("Index=$index, $(hg_files[index])")

    h = hgs[index]
    
    results = @distributed (append!) for run=1:runs
		println("run=$run at proc $(myid())")
        Random.seed!(run)

        metaV = randMetaV(h)
        metaE = randMetaE(h) 

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
