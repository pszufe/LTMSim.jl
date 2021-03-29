"""
    Script to generate the boxplot graph associated with:
    - benchmark_randV_randE.jl
"""
using Pkg
Pkg.activate(".")
using LTMSim
using SimpleHypergraphs
using PyPlot
using Serialization
using LaTeXStrings

project_path = dirname(pathof(LTMSim))

fname = "benchmark_randV_randE.data"
pname = "benchmark_randV_randE.png"
data_path = joinpath(project_path, "..", "res", "journal", fname)

hg_files = readdir(joinpath(project_path, "..", "data", "hgs"))
hg_names = [split(file, ".")[1] for file in hg_files]

hg_names[8] = "music-rev"
hg_names[10] = "rest.-rev"
hg_names[11] = "bars-rev"

#
# DATA
#
data = deserialize(data_path)
hgs = [prune_hypergraph!(hg_load(joinpath(project_path, "..", "data", "hgs", hg_file))) for hg_file in hg_files]


#
# PLOTTING INFO
#
algorithms = [
    "BinarySearch(H)", "Greedy([H]₂)", "Greedy(H)", "SubTSS(H)"
]

labels = Dict{String, String}(
    "BinarySearch(H)" => "StaticGreedy",
    "Greedy(H)" => "DynamicGreedy",
    "Greedy([H]₂)" => L"DynamicGreedy_{[H]_2}",
	"SubTSS(H)" => "SubTSS"
)


#
# BOXPLOTS
#
ticks = [1]

function set_box_color(bp, color)
    plt.setp(bp["boxes"], color=color)
    plt.setp(bp["whiskers"], color=color)
    plt.setp(bp["caps"], color=color)
    plt.setp(bp["medians"], color=color)
end

clf()
plt.figure(figsize=(20,8))

val = -0.7
c = 1
pos = 1.5

colorz=["#2C7BB6", "#D7191C", "#FF8900", "#33CC33", "#cc0099", "#4d4dff", "#008080", "#2C7BB6"]


for algo in algorithms
    global val, c
    
    println(algo)

    b = plt.boxplot(
        data[algo],
        positions=collect(range(0, stop=length(data[algo])-1)).*2.5.+val,
        sym="",
        widths=0.2
    )

    set_box_color(b, colorz[c])
    plt.plot([], c=colorz[c], label=labels[algo])

    c+=1
    val+=0.3
end

plt.legend(fontsize="20")

plt.xticks(range(0, (length(hg_names))*2.4, step=2.5), hg_names, fontsize="20", rotation=0)
plt.yticks(fontsize="xx-large")

#title("randV - propE05", fontstyle = "italic", fontsize="xx-large")

#plt.ylim(0, 0.7)
ylabel("Execution Time (s)", fontstyle = "italic", fontsize="20", labelpad=10)

plt.tight_layout()
gcf()

PyPlot.savefig(joinpath(project_path, "..", "res", "journal", "plot", pname))