using Distributed, Pkg
addprocs(8)
@everywhere using Distributed, Pkg
Pkg.activate(".")
@everywhere Pkg.activate(".")
using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Plots, PyPlot, Random, Serialization, LaTeXStrings
@everywhere using LTMSim, DataFrames, SimpleHypergraphs, Statistics, Random, Serialization

nvalues = [10, 20, 40, 80]
runs = 10
data = Dict{String, Vector{Vector{Int}}}()

data["BinarySearch(H)"]=Vector{Vector{Int}}()
data["Greedy(H)"]=Vector{Vector{Int}}()
data["Greedy([H]₂)"]=Vector{Vector{Int}}()
data["SubTSS(H)"]=Vector{Vector{Int}}()

for n=nvalues
	println("n=$n")
    results1 = Vector{Int}()
    results2 = Vector{Int}()
    results3 = Vector{Int}()

    results = @distributed (append!) for run=1:runs
        h = randomHkuniform(500, 500, n)
        metaV = randMetaV(h)
        metaE = proportionalMetaE(h,0.5)

        r1 = greedy_tss_2section(h,metaV,metaE)
        r2 = bisect(h,metaV,metaE)
		r3 = greedy_tss(h,metaV,metaE)
		r4 = sub_tss_opt2(h,metaV,metaE)
		[(r1,r2,r3,r4)]

    end
    push!(data["Greedy([H]₂)"], [r[1] for r in results])
    push!(data["BinarySearch(H)"], [r[2] for r in results])
    push!(data["Greedy(H)"], [r[3] for r in results])
	push!(data["SubTSS(H)"], [r[4][1] for r in results])
    println("end ",n)

end

serialize("res/paper/exp1/random-k.data", data)
data = deserialize("res/paper/exp1/random-k.data")

labels = Dict{String, String}(
    "BinarySearch(H)" => "StaticGreedy",
    "Greedy(H)" => "DynamicGreedy",
    "Greedy([H]₂)" => L"DynamicGreedy_{[H]_2}",
	"SubTSS(H)" => "SubTSS"
)

ticks = nvalues

function set_box_color(bp, color)
    plt.setp(bp["boxes"], color=color)
    plt.setp(bp["whiskers"], color=color)
    plt.setp(bp["caps"], color=color)
    plt.setp(bp["medians"], color=color)
end

clf()

plt.figure(figsize=(7,5))

val = -0.4
c = 1

colorz=["#2C7BB6", "#D7191C", "#FF8900", "#33CC33"]

for algo in ["BinarySearch(H)", "Greedy([H]₂)", "Greedy(H)", "SubTSS(H)"]#keys(data)
    global val, c
    b = plt.boxplot(
        data[algo],
        positions=collect(range(0, stop=length(data[algo])-1)).*2.0.+val,
        sym="",
        widths=0.2
    )
    set_box_color(b, colorz[c])
    c+=1
    val+=0.4
end


# draw temporary red and blue lines and use them to create a legend
plt.plot([], c="#2C7BB6", label=labels["BinarySearch(H)"])#label=collect(keys(data))[1])
plt.plot([], c="#D7191C", label=labels["Greedy([H]₂)"])#label=collect(keys(data))[2])
plt.plot([], c="#FF8900", label=labels["Greedy(H)"])#label=collect(keys(data))[3])
plt.plot([], c="#33CC33", label=labels["SubTSS(H)"])#label=collect(keys(data))[3])
plt.legend(fontsize="x-large", loc = "lower right")

plt.xticks(range(0, length(ticks) * 2, step=2), ticks, fontsize="x-large")
plt.yticks(fontsize="x-large")

#plt.xlim(-2, length(ticks)*2)
#plt.ylim(0, 8)
plt.ylim(0, 230)

ylabel("Influence set size", fontstyle = "italic", fontsize="xx-large", labelpad=10) #fontweight="semibold",
xlabel(L"$k$", fontsize="xx-large", fontweight="semibold", labelpad=10)

plt.tight_layout()

gcf()

PyPlot.savefig("res/paper/exp1/random-k.pdf")
