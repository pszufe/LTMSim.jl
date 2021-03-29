"""
    Script to generate the scatter plot associated with:
    - benchmark_randV_randE.jl
"""
using Pkg
Pkg.activate(".")
using LTMSim
using SimpleHypergraphs
using PyPlot
using Serialization
using Statistics
using LaTeXStrings

project_path = dirname(pathof(LTMSim))

# y-values = Time (s)
fname = "benchmark_randV_randE.data"
data_path = joinpath(project_path, "..", "res", "journal", fname)

# x-values = target set size
fname_tss = "randV_randE_with_noOpt.data"
data_path_tss = joinpath(project_path, "..", "res", "journal", fname_tss)

res_path = joinpath(project_path, "..", "res", "journal", "plot", "benchmark") 

hg_files = readdir(joinpath(project_path, "..", "data", "hgs"))
hg_names = [split(file, ".")[1] for file in hg_files]

hg_names[8] = "music-rev"
hg_names[10] = "restaurants-rev"
hg_names[11] = "bars-rev"

#
# DATA
#
data = deserialize(data_path)
data_tss = deserialize(data_path_tss)
hgs = [prune_hypergraph!(hg_load(joinpath(project_path, "..", "data", "hgs", hg_file))) for hg_file in hg_files]


#
# PLOTTING INFO
#
algorithms = [
    "BinarySearch(H)",
    "BinarySearch(H)-noOpt",
    "Greedy(H)",
    "Greedy(H)-noOpt",
    "Greedy([H]₂)",
    "Greedy([H]₂)-noOpt",
    "SubTSS(H)",
    "SubTSS(H)-noOpt"
]

labels_dict = Dict{String, String}(
    "BinarySearch(H)" => "StaticGreedy",
    "BinarySearch(H)-noOpt" => "StaticGreedy-noOpt",
    "Greedy(H)" => "DynamicGreedy",
    "Greedy(H)-noOpt" => "DynamicGreedy-noOpt",
    "Greedy([H]₂)" => L"DynamicGreedy_{[H]_2}",
    "Greedy([H]₂)-noOpt" => L"DynamicGreedy_{[H]_2}-noOpt",
    "SubTSS(H)" => "SubTSS",
    "SubTSS(H)-noOpt" => "SubTSS-noOpt"
)


#
# SCATTER PLOT
#
colorz = ["#2C7BB6", "#D7191C", "#FF8900", "#33CC33", "#cc0099", "#4d4dff", "#008080", "#2C7BB6"]
markers = ["o", "^", "*", "d", "p", ".", "h", "x"]

for (hg_index, hg_name) in enumerate(hg_names)
    println(hg_name)

    labels = []

    clf()
    plt.figure(figsize=(7,5))

    for (algo_index, algo) in enumerate(algorithms)
        println(algo_index, " ", algo, " ")

        # get execution time (mean)
        y = mean(data[algo][hg_index])

        # get target set size (%)
        x = mean(data_tss[algo][hg_index] / nhv(hgs[hg_index]))

        push!(
            labels,
            labels_dict[algo]
        )

        plt.scatter(x, y, c=colorz[algo_index], marker=markers[algo_index], label=labels_dict[algo])
    end

    plt.legend()

    plt.title("$hg_name")

    plt.xticks(fontsize="x-large") #range(0, length(ticks) * 2, step=2),
    plt.yticks(fontsize="x-large")

    plt.xlim(0, 1)
    xlabel("Seed set size / n", fontstyle = "italic", fontsize="large", labelpad=10) #, fontweight="semibold"

    plt.ylim(bottom=0)
    ylabel("Execution time (s)", fontstyle = "italic", fontsize="large", labelpad=10) #fontweight="semibold",
    
    plt.tight_layout()

    PyPlot.savefig(joinpath(res_path, "$hg_name.png"))
end
