using Distributed, Pkg
@everywhere using Distributed, Pkg
Pkg.activate(".")
@everywhere Pkg.activate(".")
using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Plots, PyPlot, Random, Serialization, LaTeXStrings
@everywhere using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Random, Serialization


metav = range(0.1, stop = 0.9, step = 0.1)
runs = 2
N = 50
M = 50
r = 1
# hr = randomH(N, M)
# hk = randomHkuniform(N, M, r)
# hd = randomHduniform(N, M, r)
# hp = randomHpreferential(N, 0.5)
# hg = hg_load("data/got.hgf")

# graphs = [("Random", hr),
# 		  ("RandomK", hk),
# 		  ("RandomD", hd),
# 		  ("RandomP", hp)
# 		  ,("GoT", hg)]
graphs = [("NBA", hg_load("data/nba.hgf")),
		  ("DBLP-2017", hg_load("data/dblp.hgf"))]

gres = Dict{String,Any}()

for metae = [0.2,0.5,0.8]
	for g in graphs
		data = Dict{String,Vector{Vector{Int}}}()

		data["BinarySearch(H)"] = Vector{Vector{Int}}()
		data["Greedy(H)"] = Vector{Vector{Int}}()
		data["Greedy([H]₂)"] = Vector{Vector{Int}}()
		data["SubTSS(H)"] = Vector{Vector{Int}}()

		for n = metav

			println("n=$n")
		    results = @distributed (append!) for run = 1:runs
		        metaV = proportionalMetaV(g[2], n)
		        metaE = proportionalMetaE(g[2], metae)
				println("greedy_tss_2section $(size(g))")
				r1 = greedy_tss_2section(g[2], metaV, metaE)
				println("bisect $(size(g))")
				r2 = bisect(g[2], metaV, metaE)
				println("greedy_tss $(size(g))")
				r3 = greedy_tss(g[2], metaV, metaE)
				println("sub_tss_opt2 $(size(g))")
				r4 = sub_tss_opt2(g[2], metaV, metaE)

				[(r1, r2, r3, r4[1])]

		    end
		    push!(data["Greedy([H]₂)"], [r[1] for r in results])
		    push!(data["BinarySearch(H)"], [r[2] for r in results])
		    push!(data["Greedy(H)"], [r[3] for r in results])
			push!(data["SubTSS(H)"], [r[4][1] for r in results])

		    println("end ", n)

		end
		push!(gres, "graph-$(g[1])-meta-e-$metae" => data)
		# here the result are for one metae e a particular graph
	end
end
### data
serialize("res/paper/exp3/scenario3.data", gres)

results = deserialize("res/paper/exp3/scenario3.data")

for metae = [0.2,0.5,0.8]
	for g in graphs

		data = results["graph-$(g[1])-meta-e-$metae"]

		labels_dict = Dict{String,String}(
		    "BinarySearch(H)" => "StaticGreedy",
		    "Greedy(H)" => "DynamicGreedy",
		    "Greedy([H]₂)" => L"DynamicGreedy_{[H]_2}",
			"SubTSS(H)" => "SubTSS"
		)

		### plotting
		ticks = metav
		clf()
		plt.figure(figsize = (7, 5))
		val = -0.4
		c = 1
		colorz = ["#2C7BB6", "#D7191C", "#FF8900", "#33CC33"]
		labels = Array{String,1}()
		for algo in ["BinarySearch(H)", "Greedy([H]₂)", "Greedy(H)", "SubTSS(H)"]# keys(data)
		    val, c

		    y = Array{Float64,1}()

		    for v = 1:length(collect((metav)))
		        push!(y, mean(data[algo][v]))
		    end

		    push!(
		        labels,
		        labels_dict[algo]
		    )

		    b = plt.plot(collect(metav), y, color = colorz[c])

		    c += 1
		end
		plt.title("graph-$(g[1])-meta-e-$metae")
		plt.legend(labels, fontsize = "x-large", loc = "lower right")

		# plt.xlim(-2, length(ticks)*2)
		# plt.ylim(0, 280)

		plt.xticks(ticks, fontsize = "x-large") # range(0, length(ticks) * 2, step=2),
		plt.yticks(fontsize = "x-large")

		ylabel("Influence set size", fontstyle = "italic", fontsize = "xx-large", labelpad = 10) # fontweight="semibold",
		# xlabel("Thresholds", fontsize="x-large", fontweight="semibold", labelpad=10)

		plt.tight_layout()

		gcf()

		PyPlot.savefig("res/paper/exp3/graph-$(g[1])-meta-e-$metae.png")
		println("res/paper/exp3/graph-$(g[1])-meta-e-$metae.png")

		plt.clf()
	end
end

