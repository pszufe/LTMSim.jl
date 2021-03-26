using Pkg
Pkg.activate(".")
using LTMSim
using SimpleHypergraphs
using PyPlot
using Statistics
using Serialization
using LaTeXStrings


project_path = dirname(pathof(LTMSim))

fname = "propV_propE05.data" #"propV_randE.data"  
data_path = joinpath(project_path, "..", "res", "journal", fname)
res_path = joinpath(project_path, "..", "res", "journal", "plot", "propV_propE05") #propV_randE

hg_files = readdir(joinpath(project_path, "..", "data", "hgs"))
hg_names = [split(file, ".")[1] for file in hg_files]

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

labels_dict = Dict{String, String}(
    "BinarySearch(H)" => "StaticGreedy",
    "Greedy(H)" => "DynamicGreedy",
    "Greedy([H]₂)" => L"DynamicGreedy_{[H]_2}",
	"SubTSS(H)" => "SubTSS"
)


#
# LINEPLOT 
#
nvalues = range(0.2, stop=0.8, step=0.1)

colorz=["#2C7BB6", "#D7191C", "#FF8900", "#33CC33", "#cc0099", "#4d4dff", "#008080", "#2C7BB6"]


for (index, hg_name) in enumerate(hg_names)
    println(hg_name)

    clf()
    plt.figure(figsize=(7,5))

    val = -0.4
    c = 1

    labels = Array{String, 1}()

    for algo in algorithms 
        y = Array{Float64, 1}()

        for v=1:length(collect((nvalues)))
            yval = mean(data[algo][hg_name][v] / nhv(hgs[index]))
            push!(y, yval)
        end

        push!(
            labels,
            labels_dict[algo]
        )

        b = plt.plot(collect(nvalues), y, color=colorz[c])

        c+=1
    end

    plt.legend(labels)#, fontsize="x-large")

    plt.xticks(nvalues, fontsize="x-large") #range(0, length(ticks) * 2, step=2),
    plt.yticks(fontsize="x-large")

    #plt.xlim(-2, length(ticks)*2)
    plt.ylim(0, 0.8)

    ylabel("Seed set size / n", fontstyle = "italic", fontsize="xx-large", labelpad=10) #fontweight="semibold",
    xlabel("Thresholds", fontstyle = "italic", fontsize="xx-large", labelpad=10) #, fontweight="semibold"

    title("propV_propE_$hg_name", fontstyle = "italic", fontsize="xx-large")

    plt.tight_layout()
    gcf()

    PyPlot.savefig(joinpath(res_path, "propV_propE_$hg_name.png"))

    close()

end


h = hgs[5]

w3c_v_dist = [length(gethyperedges(h, v)) for v in 1:nhv(h)]

sum(w3c_v_dist[w3c_v_dist .== 1]) * 100 / length(w3c_v_dist)