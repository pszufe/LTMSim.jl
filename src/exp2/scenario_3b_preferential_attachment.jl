using Distributed, Pkg
addprocs(8)
@everywhere using Distributed, Pkg
Pkg.activate(".")
@everywhere Pkg.activate(".")
using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Plots, PyPlot, Random, Serialization, LaTeXStrings
@everywhere using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Random, Serialization

h = randomHpreferential(500, 0.5)

nvalues = range(0.1, stop=0.9, step=0.1)
runs = 10
data = Dict{String, Vector{Vector{Int}}}()

data["BinarySearch(H)"]=Vector{Vector{Int}}()
data["Greedy(H)"]=Vector{Vector{Int}}()
data["Greedy([H]₂)"]=Vector{Vector{Int}}()

for n=nvalues
	println("n=$n")
    results = @distributed (append!) for run=1:runs
        metaV = proportionalMetaV(h, n)
        metaE = proportionalMetaE(h, 0.5)

        r1 = greedy_tss_2section(h, metaV, metaE)
        r2 = bisect(h,metaV,metaE)
        r3 = greedy_tss(h,metaV,metaE)
		r4 = sub_tss_opt2(h,metaV,metaE)
		[(r1,r2,r3,r4)]

    end
    push!(data["Greedy([H]₂)"], [r[1] for r in results])
    push!(data["BinarySearch(H)"], [r[2] for r in results])
    push!(data["Greedy(H)"], [r[3] for r in results])
	push!(data["SubTSS(H)"], [r[4][1] for r in results])

    println("end ", n)

end


### data
serialize("res/paper/exp2/random-p-500.data", data)
data = deserialize("res/paper/exp2/random-p-500.data")

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

#ylabel("Influence set size", fontsize="x-large", fontweight="semibold", labelpad=10)
#xlabel("Thresholds", fontsize="x-large", fontweight="semibold", labelpad=10)

plt.tight_layout()

gcf()

PyPlot.savefig("res/paper/exp2/random-p-500.pdf")
