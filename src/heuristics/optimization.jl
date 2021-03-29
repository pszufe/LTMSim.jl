"""
    optimize_seed_set(h::Hypergraph, S::Set{Int}, metaV, metaE; printme::Bool=true)

Remove all unnecessary nodes from the evaluated seed set.    
"""
function optimize_seed_set(h::Hypergraph, S::Set{Int}, metaV, metaE; printme::Bool=true)
    seed = deepcopy(S)

    degrees = Dict{Int, Int}([v => length(gethyperedges(h, v)) for v in S])
    s_degrees = sort(collect(degrees), by = x -> x[2])

    ids = [pair[1] for pair in s_degrees]

    for v in ids
        actE = zeros(Bool, nhe(h))
        actV = zeros(Bool, nhv(h))

        # remove v
        delete!(seed, v)

        # activate all nodes in seed\v
        for s in seed
           actV[s] = true
        end

        #simulate diffusion using seed\v
        simres = simulate!(h, actV, actE, metaV, metaE; printme = false)

        # cannot activate all nodes
        if simres.actvs != nhv(h)
            # re-add v to seed
            push!(seed, v)
        end
    end

    printme && println("S $(length(S)) -- new seed set $(length(seed))")

    seed
end