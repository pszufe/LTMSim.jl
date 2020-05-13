using Pkg
Pkg.activate(".")
using LTMSim
using DataFrames
using SimpleHypergraphs
using Statistics
using PyPlot
using Random
using Revise


function dual(h::Hypergraph)
    @assert(nhv(h)>0 || nhe(h)>0)

    T = nhv(h) > 0 ? eltype(values(h.v2he[1])) : eltype(values(h.he2v[1]))
    V = isa(eltype(h.he_meta), Union) ? eltype(h.he_meta).b : Nothing
    E = isa(eltype(h.v_meta), Union) ? eltype(h.v_meta).b : Nothing

    mx = Matrix{Union{Nothing,T}}(nothing, nhe(h), nhv(h))

    for v=1:nhv(h)
        for he in keys(h.v2he[v])
            mx[he, v] = h.v2he[v][he]
        end
    end

    Hypergraph{T, V, E}(mx; v_meta=h.he_meta, he_meta=h.v_meta)
end



h_random = randomH(4165,577)

h_got = hg_load("data/got.hgf")

h = dual(h_got)


metaV = proportionalMetaV(h,0.5) #randMetaV(h)
metaE = proportionalMetaE(h,0.5)

r_greedy = greedy_tss(h,metaV,metaE)

r_sub2 = sub_tss_opt2(h, metaV, metaE)

r_sub3 = sub_tss_opt3(h, metaV, metaE)

r_sub4 = sub_tss_opt4(h, metaV, metaE)