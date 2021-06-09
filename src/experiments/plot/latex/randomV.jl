"""
    An utility script to store plotting data to be used with LaTex.     
        - Experiment 1 (randV_randE.jl)
        - Experiment 2 (randV_propE05.jl)
"""

using Pkg
Pkg.activate(".")
using LTMSim
using SimpleHypergraphs
using PyPlot
using Serialization
using LaTeXStrings


project_path = dirname(pathof(LTMSim))

fname = "randV_propE05_rev.data" #"randV_propE05.data" #"randV_randE.data" 
type = "randV_propE"
pname = "randV_propE05_rev.png" #"randV_propE05.png" #"randV_randE.png"
data_path = joinpath(project_path, "..", "res", "journal", fname)

hg_files = readdir(joinpath(project_path, "..", "data", "hgs"))
hg_names = [split(file, ".")[1] for file in hg_files]

hg_names[8] = "music-rev"
hg_names[10] = "rest-rev"
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
# BOXPLOTS DATA TO CSV
#
using CSV
using DataFrames

latex_dict = Dict{String, Union{Array{String},Array{Int},Array{Float64}}}(
    "nrow" => Array{Int, 1}(),
    "algo" => Array{String,1}(),
    "dataset" => Array{String,1}(),
    "lower_whisker" => Array{Float64,1}(),
    "lower_quartile" => Array{Float64,1}(), 
    "median" => Array{Float64,1}(), 
    "upper_quartile" => Array{Float64,1}(), 
    "upper_whisker" => Array{Float64,1}()
)

index = 1
nalgo = 8

function get_boxplot_data(algo, hg_names, index, bp, latex_dict)
    global nalgo, labels
    nrow = 0
    new_index = index

    for i in 1:length(hg_names)
        # nrow = i > 1 ? new_index : index 
        nrow = index

        println("index=$index, i=$i, nrow=$nrow")

        push!(
            get!(latex_dict, "nrow", Array{Int,1}()),
            nrow
        )

        push!(
            get!(latex_dict, "algo", Array{String,1}()),
            labels_dict[algo]
        )

        push!(
            get!(latex_dict, "dataset", Array{String,1}()),
            hg_names[i]
        )

        push!(
            get!(latex_dict, "lower_whisker", Array{Float64,1}()),
            bp["whiskers"][(i*2)-1].get_ydata()[2]
        )

        push!(
            get!(latex_dict, "lower_quartile", Array{Float64,1}()),
            bp["boxes"][i].get_ydata()[2]
        )

        push!(
            get!(latex_dict, "median", Array{Float64,1}()),
            bp["medians"][i].get_ydata()[2]
        )

        push!(
            get!(latex_dict, "upper_quartile", Array{Float64,1}()),
            bp["boxes"][i].get_ydata()[3]
        )

        push!(
            get!(latex_dict, "upper_whisker", Array{Float64,1}()),
            bp["whiskers"][i*2].get_ydata()[2]
        )

        new_index = new_index + nalgo
    end
end 


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
    global index, hg_names, latex_dict #tolatex
    
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

    get_boxplot_data(algo, hg_names, index, b, latex_dict)

    set_box_color(b, colorz[c])
    plt.plot([], c=colorz[c], label=labels_dict[algo])

    c+=1
    val+=0.3

    index += 1
end

#
# TO LATEX
#
df = DataFrame(latex_dict)
sort!(df, :nrow)

gdf = groupby(df, :dataset)

for g in gdf
    db_name = g.dataset[1]
    CSV.write(joinpath(project_path, "..", "res", "journal", "plot", "latex", "randV_propE", "$(type)_$(db_name).csv"), g)
end
