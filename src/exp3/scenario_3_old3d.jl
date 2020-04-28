using Distributed, Pkg
addprocs(8)
@everywhere using Distributed, Pkg
Pkg.activate(".")
@everywhere Pkg.activate(".")
using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Plots, PyPlot, Random, Serialization, LaTeXStrings
@everywhere using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Random, Serialization

struct Serie
	x::Vector{Float64}
	y::Vector{Float64}
	z::Vector{Float64}
	Serie() = new(Array{Float64,1}(), Array{Float64,1}(),Array{Float64,1}())
end
	default(size=(600,600), fc=:heat)
N = 200
M = 200
r = 20

hr = randomH(N, M)
hk = randomHkuniform(N, M, r)
hd = randomHduniform(N, M, r)
hp = randomHpreferential(N, 0.5)
hg = hg_load("data/got.hgf")

graphs = [("Random",hr),
		  ("RandomK",hk),
		  ("RandomD",hd),
		  ("RandomP", hp)
		  ,("GoT", hg)]

gres = Dict{String,Any}()
#for all graph -> chart
for g in graphs
	runs = 2
	#map serries to x,y,z where x=metav y=metae, z=tss
	data = Dict{String, Serie}()

	data["BinarySearch(H)"]= Serie()
	data["Greedy(H)"]= Serie()
	data["Greedy([H]₂)"]= Serie()
	data["SubTSS(H)"]= Serie()

	pMetaV = range(0.1, stop=0.9, step=0.1)
	pMetaE = range(0.1, stop=0.9, step=0.1)

	for v in pMetaV
		for e in pMetaE
		    results =  @distributed (append!) for run=1:runs
		        metaV = proportionalMetaV(g[2], v)
		        metaE = proportionalMetaE(g[2], e)

		        r1 = greedy_tss_2section(g[2], metaV, metaE)
		        r2 = bisect(g[2],metaV,metaE)
		        r3 = greedy_tss(g[2],metaV,metaE)
				r4 = sub_tss_opt2(g[2],metaV,metaE)

				[(r1,r2,r3,r4[1])]

		    end
			push!(data["Greedy([H]₂)"].x,v)
			push!(data["Greedy([H]₂)"].y,e)
		    push!(data["Greedy([H]₂)"].z,mean([r[1] for r in results]))

			push!(data["BinarySearch(H)"].x,v)
			push!(data["BinarySearch(H)"].y,e)
		    push!(data["BinarySearch(H)"].z,mean([r[2] for r in results]))

			push!(data["Greedy(H)"].x,v)
			push!(data["Greedy(H)"].y,e)
		    push!(data["Greedy(H)"].z,mean([r[3] for r in results]))

			push!(data["SubTSS(H)"].x,v)
			push!(data["SubTSS(H)"].y,e)
		    push!(data["SubTSS(H)"].z,mean([r[4] for r in results]))

		  	println("graph=$(g[1]) meta-v=$v, meta-e=$e")
		end
	end
	push!(gres, g[1]=> data)
	println(data)

end

default(size=(600,600), fc=:heat)
surface(gres["Random"]["Greedy([H]₂)"].x, gres["Random"]["Greedy([H]₂)"].y,  gres["Random"]["Greedy([H]₂)"].z, linealpha = 0.3)
name = "Greedy([H]₂)-Random.png"
Plots.savefig("res/paper/exp3/$name")

surface(data["BinarySearch(H)"].x, data["BinarySearch(H)"].y,  data["BinarySearch(H)"].y, linealpha = 0.3)
name = "BinarySearch(H)-$(g[1]).png"
Plots.savefig("res/paper/exp3/$name")

surface(data["Greedy(H)"].x, data["Greedy(H)"].y,  data["Greedy(H)"].y, linealpha = 0.3)
name = "Greedy(H)-$(g[1]).png"
Plots.savefig("res/paper/exp3/$name")

surface(data["SubTSS(H)"].x, data["SubTSS(H)"].y,  data["SubTSS(H)"].y, linealpha = 0.3)
name = "SubTSS(H)-$(g[1]).png"
Plots.savefig("res/paper/exp3/$name")
#plot data

default(size=(600,600), fc=:heat)
surface(gres["Random"]["BinarySearch(H)"].x, gres["Random"]["BinarySearch(H)"].y,  gres["Random"]["BinarySearch(H)"].z, linealpha = 0.3)
surface(gres["Random"]["Greedy([H]₂)"].x, gres["Random"]["Greedy([H]₂)"].y,  gres["Random"]["Greedy([H]₂)"].z, linealpha = 0.3)

surface(gres["Random"]["Greedy(H)"].x, gres["Random"]["Greedy(H)"].y,  gres["Random"]["Greedy(H)"].z, linealpha = 0.3)
surface(gres["Random"]["SubTSS(H)"].x, gres["Random"]["SubTSS(H)"].y,  gres["Random"]["SubTSS(H)"].z, linealpha = 0.3)
