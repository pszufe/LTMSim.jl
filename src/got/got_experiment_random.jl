using Pkg
Pkg.activate(".")
using LTMSim
using DataFrames
using SimpleHypergraphs
using Statistics
using Plots
using PyPlot
using Random
using Serialization

h = hg_load("/Users/carminespagnuolo/Dropbox/LTMSim.jl/data/got.hgf")

nvalues = [nhv(h)]
runs = 10
data = Dict{String, Array{Array{Int}}}()

push!(data, "BinarySearch(H)"=>Array{Array{Int,1},1}())
push!(data, "Greedy(H)"=>Array{Array{Int,1},1}())
push!(data, "Greedy([H]₂)"=>Array{Array{Int,1},1}())

for n=nvalues

    results1 = Array{Int,1}()
    results2 = Array{Int,1}()
    results3 = Array{Int,1}()

    for run=1:runs
        metaV = randMetaV(h)
        metaE = proportionalMetaE(h, 0.5)

        r1 = greedy_tss_2section(h, metaV, metaE)
        r2 = bisect(h, metaV, metaE)
        r3 = greedy_tss(h, metaV, metaE)

        push!(results1, r1)
        push!(results2, r2)
        push!(results3, r3)

    end
    push!(data["Greedy([H]₂)"], results1)
    push!(data["BinarySearch(H)"], results2)
    push!(data["Greedy(H)"], results3)

    println("end ", n)

end

#serialize("res/paper/got/got-random.data", data)
data = deserialize("res/paper/got/got-random.data")

labels = Dict{String, String}(
    "BinarySearch(H)" => "StaticGreedy",
    "Greedy(H)" => "DynamicGreedy",
    "Greedy([H]₂)" => L"DynamicGreedy_{[H]_2}"
)

ticks = [1]

function set_box_color(bp, color)
    plt.setp(bp["boxes"], color=color)
    plt.setp(bp["whiskers"], color=color)
    plt.setp(bp["caps"], color=color)
    plt.setp(bp["medians"], color=color)
end

clf()

plt.figure(figsize=(7,5))

val = -0.8
c = 1
pos = 1.5

colorz=["#2C7BB6", "#D7191C", "#FF8900"]

for algo in ["BinarySearch(H)", "Greedy([H]₂)", "Greedy(H)"]#keys(data)
    global val, c
    b = plt.boxplot(
        data[algo],
        #positions=collect(range(0, stop=length(data[algo])-1)).*2.0.+val,
        positions = [pos+val],
        sym="",
        widths=0.2
    )
    set_box_color(b, colorz[c])
    c+=1
    val+=0.8
end


# draw temporary red and blue lines and use them to create a legend
plt.plot([], c="#2C7BB6", label=labels["BinarySearch(H)"])#label=collect(keys(data))[1])
plt.plot([], c="#D7191C", label=labels["Greedy([H]₂)"])#label=collect(keys(data))[2])
plt.plot([], c="#FF8900", label=labels["Greedy(H)"])#label=collect(keys(data))[3])
plt.legend(fontsize="x-large") #, loc = "lower right"

plt.xticks(range(0.7, 3, step=.8), [1,2,3], fontsize="large", color="#FFFFFF")
plt.yticks(fontsize="x-large")

tick_params(length=0)

#plt.xlim(-2, length(ticks)*2)
plt.ylim(0, 600)

ylabel("Influence set size", fontstyle = "italic", fontsize="xx-large", labelpad=10) #fontweight="semibold",
#xlabel("Thresholds", color="#FFFFFF", fontsize="x-large", fontweight="semibold", labelpad=10)

plt.tight_layout()

gcf()

PyPlot.savefig("res/paper/got/got-random.png")