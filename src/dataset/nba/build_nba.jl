using Pkg
Pkg.activate(".");
using CSV
using Dates
using DataFrames
using SimpleHypergraphs
using LightGraphs
using Plots
using JSON

# download the data from 
# https://data.mendeley.com/datasets/ct8f9skv97/1
df = DataFrame()

nodes = Dict{String, Int}()
edges = Vector{Vector{String}}()
nodeid = 1

df = DateFormat("y-m-dTH:M:S.000+0000")

matches_per_year = Dict{Int, Int}()

for line in readlines("data/json/nbagames.json")
    jsonline = JSON.parse(line)
    edge = Vector{String}()

    strdate = collect(values(jsonline["date"]))[1]
    dt = Date(strdate, df)
    year = Dates.year(dt)

    year < 2012 && continue

    matches_per_year[year] = get!(matches_per_year, year, 0) + 1

    for player in values(jsonline["teams"][1]["players"])
        push!(edge, player["player"])
    end
    for player in values(jsonline["teams"][2]["players"])
        push!(edge, player["player"])
    end

    push!(edges, edge)
 
    global nodeid
    for v in edge
        if !haskey(nodes, string(v))
            push!(nodes, string(v)=> nodeid)
            nodeid += 1
        end
    end
end
matches_per_year


h = Hypergraph{Bool}(length(nodes), 0)

for edge in edges
    d = Dict{Int, Bool}()
    for v in edge        
        push!(d, get!(nodes, v, nothing) => true)
    end
    add_hyperedge!(h; vertices=d)
end

for e in 1:nhe(h)
    if length(getvertices(h,e)) == 0
     println("covid")
    end
 end

edges_distribution = []
for edge in edges
    if  length(edge) == 0
        println("error edge size is zero")
    end
    push!(edges_distribution, length(edge))
end

nodes_distribution = []
for v in 1:nhv(h)
    if  length(gethyperedges(h,v)) == 0
        println("error degree of v is zero")
    end
    push!(nodes_distribution, length(gethyperedges(h,v)))
end

h

savefig(histogram(nodes_distribution), "data/nba.nodes.png")
savefig(histogram(edges_distribution), "data/nba.edges.png")

hg_save("data/nba.hgf",h)

