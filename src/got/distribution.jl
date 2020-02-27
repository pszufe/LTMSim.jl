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

h = hg_load("/Users/carminespagnuolo/Dropbox/LTMSim.jl/data/got.hgf")

# he -> degree
degrees = Dict{Int, Int}()

for he=1:nhe(h)
    push!(
        degrees,
        he => length(getvertices(h, he))
    )
end

sorted_degrees = sort(collect(degrees), by=x->x[2], rev=true)

y = map(x->x[2], sorted_degrees)


##############
# distribution fitting
##############
f = fit()


clf()
plt.figure(figsize=(7,3.5))

plt.scatter(range(1, stop=nhe(h)), y, s=.2)

ylabel("Hyperedge size", fontsize="xx-large", fontstyle="italic", labelpad=10) #, fontweight="demibold"
xlabel(L"$n$", fontsize="xx-large", fontweight="bold", labelpad=10, position=(0,100))

plt.xticks(fontsize="x-large") #range(0, length(ticks) * 2, step=2),
plt.yticks(fontsize="x-large")

plt.tight_layout()

gcf()

PyPlot.savefig("res/paper/got/distribution.png")
