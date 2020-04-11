Pkg.activate(".")
using LTMSim
using DataFrames
using SimpleHypergraphs
using Statistics
using PyPlot
using Random

h_random = randomH(100,100)
h_pref = randomHpreferential(500, 0.5)
h_k = randomHkuniform(100, 100, 10)
h_d = randomHduniform(100, 100, 10)

h = hg_load("data/got.hgf")


h = h_pref
metaV = proportionalMetaV(h,0.1) #randMetaV(h)
metaE = proportionalMetaE(h,0.1)
r4 = sub_tss_opt2(h, metaV, metaE)
r1 = greedy_tss_2section(h,metaV,metaE)
r2 = bisect(h,metaV,metaE)
r3 = greedy_tss(h,metaV,metaE)



for i = 1:10
    println("Run----->")
    metaV = proportionalMetaV(h,0.5) #randMetaV(h)
    metaE = proportionalMetaE(h,0.5)

    r4 = sub_tss_opt2(h, metaV, metaE)
#    r1 = greedy_tss_2section(h,metaV,metaE)
#    r2 = bisect(h,metaV,metaE)
#    r3 = greedy_tss(h,metaV,metaE)
end



"""
    remove_vertex!(h::Hypergraph, v::Int)
Removes the vertex `v` from a given hypergraph `h`.
Note that running this function will cause reordering of vertices in the
hypergraph: the vertex `v` will replaced by the last vertex of the hypergraph
and the list of vertices will be shrunk.
"""
function remove_vertex!(h::Hypergraph, v::Int)
    n = nhv(h)
	@assert(v <= n)
    if v < n
        h.v2he[v] = h.v2he[n]
        h.v_meta[v] = h.v_meta[n]
    end

    for hv in h.he2v
        if v < n && haskey(hv, n)
            hv[v] = hv[n]
            delete!(hv, n)
        else
            delete!(hv, v)
        end
    end
    resize!(h.v2he, length(h.v2he) - 1)
    h
end

"""
    remove_hyperedge!(h::Hypergraph, e::Int)
Removes the heyperedge `e` from a given hypergraph `h`.
Note that running this function will cause reordering of hyperedges in the
hypergraph: the hyperedge `e` will replaced by the last hyperedge of the hypergraph
and the list of hyperedges will be shrunk.
"""
function remove_hyperedge!(h::Hypergraph, e::Int)
    ne = nhe(h)
	@assert(e <= ne)
	if e < ne
	    h.he2v[e] = h.he2v[ne]
	    h.he_meta[e] = h.he_meta[ne]
	end

    for he in h.v2he
		if e < ne && haskey(he, ne)
			he[e] = he[ne]
            delete!(he, ne)
		else
			delete!(he, e)
		end
    end
    resize!(h.he2v, length(h.he2v) - 1)
    h
end

"""
	clean!(h)
Removes all verticies with degree 0 and all hyperedges with size 0.
"""

function clean!(h)
	for e in reverse(1:nhe(h))
        length(h.he2v[e]) == 0 && remove_hyperedge!(h,e)
    end
	for v in reverse(1:nhv(h))
    	length(h.v2he[v]) == 0 && 	remove_vertex!(h,v)
    end
	h
end

h = hg_load("data/got.hgf")
clean!(h)

metaV = proportionalMetaV(h,0.5) #randMetaV(h)
metaE = proportionalMetaE(h,0.5)


r4 = sub_tss_opt2(h, metaV, metaE)
