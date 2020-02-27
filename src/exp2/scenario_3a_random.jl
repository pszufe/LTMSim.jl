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
using LaTeXStrings

h = randomH(500, 500)

nvalues = range(0.1, stop=0.9, step=0.1)
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
        metaV = proportionalMetaV(h, n)
        metaE = proportionalMetaE(h, 0.5)

        r1 = greedy_tss_2section(h, metaV, metaE)
        r2 = bisect(h,metaV,metaE)
        r3 = greedy_tss(h,metaV,metaE)

        push!(results1, r1)
        push!(results2, r2)
        push!(results3, r3)

    end
    push!(data["Greedy([H]₂)"], results1)
    push!(data["BinarySearch(H)"], results2)
    push!(data["Greedy(H)"], results3)

    println("end ", n)

end


### data
#serialize("res/paper/exp2/random-500.data", data)
data = deserialize("res/paper/exp2/random-500.data")

labels_dict = Dict{String, String}(
    "BinarySearch(H)" => "StaticGreedy",
    "Greedy(H)" => "DynamicGreedy",
    "Greedy([H]₂)" => L"DynamicGreedy_{[H]_2}"
)

### plotting

ticks = nvalues

clf()

plt.figure(figsize=(7,5))

val = -0.4
c = 1

colorz=["#2C7BB6", "#D7191C", "#FF8900"]

labels = Array{String, 1}()

for algo in ["BinarySearch(H)", "Greedy([H]₂)", "Greedy(H)"]#keys(data)
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

PyPlot.savefig("res/paper/exp2/random-500.png")
