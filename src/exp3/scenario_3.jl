using Distributed, Pkg
addprocs(8)
@everywhere using Distributed, Pkg
Pkg.activate(".")
@everywhere Pkg.activate(".")
using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Plots, PyPlot, Random, Serialization, LaTeXStrings
@everywhere using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Random, Serialization

N = 10
M = 10
r = 5

hr = randomH(N, M)
hk = randomHkuniform(N, M, r)
hd = randomHduniform(N, M, r)
hp = randomHpreferential(N, 0.5)
hg = hg_load("data/got.hgf")

graphs = [("Random",hr),
		  ("RandomK",hk),
		  ("RandomD",hd),
		  ("RandomP", hp),
		  ("GoT", hg)]

#for all graph -> chart
for g in graphs
	runs = 2
	#map serries to x,y,z where x=metav y=metae, z=tss
	data = Dict{String, Vector{Tuple{Real,Real,Real}}}()

	data["BinarySearch(H)"]= Vector{Tuple{Real,Real,Real}}()
	data["Greedy(H)"]= Vector{Tuple{Real,Real,Real}}()
	data["Greedy([H]₂)"]= Vector{Tuple{Real,Real,Real}}()
	data["SubTSS(H)"]= Vector{Tuple{Real,Real,Real}}()

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

		    push!(data["Greedy([H]₂)"],(v, e, mean([r[1] for r in results])))
		    push!(data["BinarySearch(H)"], (v, e, mean([r[2] for r in results])))
		    push!(data["Greedy(H)"], (v, e, mean([r[3] for r in results])))
			push!(data["SubTSS(H)"], (v, e, mean([r[4] for r in results])))

		  	println("graph=$(g[1]) meta-v=$v, meta-e=$e")
		end
	end
	println(data)
	#plot data
end

### data
serialize("res/paper/exp2/random-500.data", data)
data = deserialize("res/paper/exp2/random-500.data")

labels_dict = Dict{String, String}(
    "BinarySearch(H)" => "StaticGreedy",
    "Greedy(H)" => "DynamicGreedy",
    "Greedy([H]₂)" => L"DynamicGreedy_{[H]_2}",
	"SubTSS(H)" => "SubTSS"
)

### plotting

ticks = nvalues

clf()

plt.figure(figsize=(7,5))

val = -0.4
c = 1

colorz=["#2C7BB6", "#D7191C", "#FF8900", "#33CC33"]

labels = Array{String, 1}()

for algo in ["BinarySearch(H)", "Greedy([H]₂)", "Greedy(H)", "SubTSS(H)"]#keys(data)
    global val, c

    y = Array{Float64, 1}()

    for v=1:length(collect((nvalues)))
        push!(y, mean(data[algo][v]))
    end

    push!(
        labels,
        labels_dict[algo]
    )

    b = plt.plot(collect(nvalues), y, color=colorz[c])

    c+=1
end


# draw temporary red and blue lines and use them to create a legend
# plt.plot([], c="#2C7BB6", label=collect(keys(data))[1])
# plt.plot([], c="#D7191C", label=collect(keys(data))[2])
# plt.plot([], c="#FF8900", label=collect(keys(data))[3])
plt.legend(labels, fontsize="x-large", loc = "lower right")

#plt.xlim(-2, length(ticks)*2)
plt.ylim(0, 280)

plt.xticks(ticks, fontsize="x-large") #range(0, length(ticks) * 2, step=2),
plt.yticks(fontsize="x-large")

ylabel("Influence set size", fontstyle = "italic", fontsize="xx-large", labelpad=10) #fontweight="semibold",
#xlabel("Thresholds", fontsize="x-large", fontweight="semibold", labelpad=10)

plt.tight_layout()

gcf()

PyPlot.savefig("res/paper/exp2/random-500.pdf")
