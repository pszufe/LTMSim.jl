using Pkg
Pkg.activate(".")
using LTMSim
using SimpleHypergraphs
using Random
using Plots
using DataFrames
using TableView

#metaV .= 1
#metaE .= 1
h, actV, actE, metaV, metaE = generateHypergraph();
bisect(h, metaV, metaE)


res = DataFrame(id=Int[],meanV=Float64[],tsssize=Int[])
for id in 1:1000
    h = randomH(8,6)
    metaV = randMetaV(h)
    metaE = proportionalMetaE(h,0.5)
    r = bisect(h,metaV,metaE)
    push!(res, Dict(
        :id => id,
        :meanV => mean(metaV),
        :tsssize => r,
    ))
end
using Plots
Plots.gr()

Plots.scatter(res.meanV .+ (rand(length(res.tsssize))*0.07) ,res.tsssize .+ (rand(length(res.tsssize)).*0.5), markersize=1)


using PyPlot
pygui(:qt)
plot(1:5,[1,4,1,5,1])
gcf()


using PyCall
using PyPlot
pygui(:qt)
hnx = pyimport("hypernetx")


function plotH(h, metaV, metaE, actV, actE)
    H = hnx.Hypergraph()

    edges = [ hnx.Entity("E$e [$(metaE[e])] $(actE[e] ? "X" : "_")",
        elements=["V$v [$(metaV[v])]$(actV[v] ? "X" : "_")"  for v in keys(h.he2v[e])])
        for e in 1:nhe(h)  ]
    H.add_edges_from(edges)
    clf()
    vs = ["V$v [$(metaV[v])]$(actV[v] ? "X" : "_")"  for v in 1:nhv(h)]
    Random.seed!(0)
    hnx.draw(H, pos=Dict(
        vs .=> [(3,0),(0,3),(4,3),(0,0),(3,1.5)] ) )
    gcf()
end

h, actV, actE, metaV, metaE = generateHypergraph();
plotH(h,metaV,metaE, actV, actE)
simulate!(h,actV, actE, metaV, metaE;max_step=1)
plotH(h,metaV,metaE, actV, actE)

bisect(h, metaV, metaE)


#H.incidence_dict


res = DataFrame(id=Int[],meanV=Float64[],propMetaV=Float64[],tsssize=Int[])
for id in 1:1000
    h = randomH(30,15)
    for propMetaV in 0.1:0.1:0.9
        metaV = proportionalMetaV(h,propMetaV)
        metaE = proportionalMetaE(h,0.5)
        r = bisect(h,metaV,metaE)
        push!(res, Dict(
            :id => id,
            #:meanV => mean(something.(h,0)),
            :meanV => std(length.(h.he2v)),
            :propMetaV => propMetaV,
            :tsssize => r,
        ))
    end
end
using Plots
Plots.gr()

Plots.scatter(res.meanV .+ (rand(length(res.tsssize))*0.07) ,res.tsssize .+ (rand(length(res.tsssize)).*0.5), markersize=1)


unique(res.tsssize)

matplotlib_cm = pyimport("matplotlib.cm")
matplotlib_colors = pyimport("matplotlib.colors")
cmap = matplotlib_cm.get_cmap("cool");

res.meanV

getColor(x) = RGB(cmap(x)[1:3]...)

using TableView
TableView.showtable(res)

maxmv = maximum(res.meanV)
minmv = minimum(res.meanV)

Plots.scatter(
    res.propMetaV.+ rand(nrow(res)).*0.06,
    res.tsssize.+ rand(nrow(res)).*0.4,
    markersize=1,
    color=getColor.((res.meanV.-minmv)./(maxmv-minmv) ))

using Statistics
cor(Matrix(res[:,[:meanV,:propMetaV,:tsssize]]))



data_to_plot = Vector{Array{Any, 1}}()

for propMetaV in unique(res, :propMetaV).propMetaV
    series = filter(x->x.propMetaV == propMetaV, res).tsssize

    push!(data_to_plot, series)
end

clf()
fig = plt.figure(figsize=(12, 5))
ax = fig.add_subplot(111)
ax.boxplot(data_to_plot)

xlabels = unique(res, :propMetaV).propMetaV
xticks(1:length(xlabels), xlabels, rotation=0)

ylabel("TSS size")
xlabel("Vertices thresholds")

gcf()

plt.tight_layout(.5)

PyPlot.savefig("/Users/carminespagnuolo/Dropbox/LTMSim.jl/res/scemek.png")
