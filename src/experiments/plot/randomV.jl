using Pkg
Pkg.activate(".")
using LTMSim
using SimpleHypergraphs
using PyPlot
using Serialization
using LaTeXStrings


project_path = dirname(pathof(LTMSim))

fname = "randV_propE05.data" #"randV_randE.data" 
pname = "randV_propE05.png" #"randV_randE.png"
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
    
    ndata = [elem / nhv(hgs[index]) for (index, elem) in enumerate(data[algo])] 

    b = plt.boxplot(
        ndata,
        #positions=collect(range(0, stop=length(data[algo])-1)).*2.0.+val,
        positions=collect(range(0, stop=length(data[algo])-1)).*2.5.+val,
        #positions = [pos+val],
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

title("randV - propE05", fontstyle = "italic", fontsize="xx-large")

plt.ylim(0, 0.7)
ylabel("Seed set size / n", fontstyle = "italic", fontsize="20", labelpad=10)

plt.tight_layout()
gcf()

PyPlot.savefig(joinpath(project_path, "..", "res", "journal", "plot", pname))


#
# some distribution data
#
amazon = hgs[2]
amazon_he_dist = [length(getvertices(amazon, he)) for he in 1:nhe(amazon)]
amazon_v_dist = [length(gethyperedges(amazon, v)) for v in 1:nhv(amazon)]

sum(amazon_v_dist[amazon_v_dist .== 1]) * 100 / length(amazon_v_dist)

clf()
hist(amazon_v_dist)
gcf()


dblp = hgs[3]
dblp_he_dist = [length(getvertices(dblp, he)) for he in 1:nhe(dblp)]
dblp_v_dist = [length(gethyperedges(dblp, v)) for v in 1:nhv(dblp)]

sum(dblp_v_dist[dblp_v_dist .== 1]) * 100 / length(dblp_v_dist)

clf()
hist(dblp_v_dist)
gcf()



