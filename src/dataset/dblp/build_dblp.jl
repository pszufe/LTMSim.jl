using Pkg
Pkg.activate(".");
using CSV
using DataFrames
using SimpleHypergraphs
using LightGraphs
using Plots
using JSON
using Dates

# download the data from
# https://data.mendeley.com/datasets/ct8f9skv97/1
df = DataFrame()

nodes = Dict{String, Int}()
edges = Vector{Vector{String}}()
nodeid = 1
max_year = 0

df = DateFormat("y-m-d")

papers_per_year = Dict{Int, Int}()

for line in readlines("data/json/dblp.json")
    jsonline = JSON.parse(line)    
    edge = Vector{String}()
    
    !haskey(jsonline,"year") && continue;
    !haskey(jsonline,"author") && continue;
   
    year = typeof(jsonline["year"]) != Array{Any,1} ?
                 parse(Int, string(jsonline["year"])) : 
                    parse(Int, strip(jsonline["year"][1],'"'))
    if max_year < year
        global max_year = year
    end

    year <= 2016 && continue; 

    dt = Date(jsonline["mdate"], df)
    Dates.month(dt) <= 5 && continue

    papers_per_year[year] = get!(papers_per_year, year, 0) + 1
    
    authors = typeof(jsonline["author"]) == Array{Any,1} ?
                        jsonline["author"] : 
                        [jsonline["author"][1]]

    length(authors) <= 0 && continue;

    for author in authors
        push!(edge, author)
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

papers_per_year

h = Hypergraph(length(nodes), 0)
edges_distribution = []
for edge in edges
    d = Dict{Int, Bool}()
    for v in edge        
        push!(d, get!(nodes, string(v), nothing) => true)
    end
    add_hyperedge!(h;vertices=d)
    push!(edges_distribution, length(edge))
end

edges_distribution = []
for edge in edges
    if length(edge) == 0
        println("error size he is zero")
    end
    push!(edges_distribution, length(edge))
end

nodes_distribution = []
for v in 1:nhv(h)
    if length(gethyperedges(h,v)) == 0
        println("error degree v is zero")
    end
    push!(nodes_distribution, length(gethyperedges(h,v)))
end

h

savefig(histogram(nodes_distribution), "data/dblp.nodes.png")
savefig(histogram(edges_distribution), "data/dblp.edges.png")

#hg_save("data/dblp.hgf", h)


