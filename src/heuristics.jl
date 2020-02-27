"""
Three greedy-based heuristics for the **Diffusion on Hypergraphs** problem,
i.e. finding the minimum influence target set *S in V* of a hypergraph *H=(V,E)*
able to influence the whole network.
"""

"""
    bisect(h, metaV, metaE)

Compute the target set exploiting a binary search approach.

Also referred to as *StaticGreedy*.
"""
function bisect(h, metaV, metaE)
    degrees = length.(h.v2he)
    sortedVind = sortperm(degrees, rev=true)

    left = 1
    @assert length(sortedVind) == length(degrees)
    right = length(sortedVind)
    while left < right
        location = Int(ceil( (left + right)/2))
        actE = zeros(Bool, nhe(h))
        actV = zeros(Bool, nhv(h))
        # up to the first location true and remainder zeros
        actV[sortedVind[1:location]] .= true
        sres = simulate!(h,actV, actE, metaV, metaE; printme = false)
        if sres.actvs != nhv(h)
            left = location
        else
            right = location-1
        end
    end
    left+1
end


"""
    greedy_tss(H, metaV, metaE)

Compute the target set according to the following algorithm.

Initially, all nodes are added to the candidates set *U*.
At each stage, the node of maximum degree is added to the target set *S* and removed from *U*.
At this point, some nodes and/or hyperedges become infected.

The algorithm simulates the diffusion process, and the influenced edges are pruned from the network.
Consequentially, the degree of nodes δ(v) is updated.

Also referred to as *DynamicGreedy(H)*.
"""
function greedy_tss(h, metaV, metaE)

    S = Dict{Int,Int}()
    U = Dict{Int,Int}()

    #init U set
    for v=1:nhv(h)
        heus = gethyperedges(h,v)
        d = 0
        for he in heus
                d+=1
        end
        push!(U, v => d)
    end

    while length(U) != 0
         max = sort(collect(U), by=x->x[2], rev = true)[1]

         delete!(U, max.first)
         push!(S, max)
         actE = zeros(Bool, nhe(h))
         actV = zeros(Bool, nhv(h))

         for s in S
              actV[s.first] = true
         end

         simres = simulate!(h, actV, actE, metaV, metaE; printme = false)

         if simres.actvs == nhv(h)
             break
         end

         for he in gethyperedges(h,max.first)
             for nv in getvertices(h,he.first)
                 if !haskey(U,nv.first)
                     continue
                 end
                 d = 0
                 for he2 in gethyperedges(h, nv.first)
                     if ! actE[he2.first]
                         d+=1
                     end
                 end

                 push!(U, nv.first => d)

             end
         end


    end

    actE = zeros(Bool, nhe(h))
    actV = zeros(Bool, nhv(h))

    for s in S
         actV[s.first] = true
    end

    simres = simulate!(h, actV, actE, metaV, metaE; printme = false)

    if simres.actvs != nhv(h)
        println("ARGGGG ", simres.actvs, " ", nhv(h))
    end

    length(S)
end


"""
    greedy_tss_2section(H, metaV, metaE)

Compute the target set according to the following algorithm.

The degree of nodes is computed on the [H]₂ of the residual hypergraph Hⁱ of *H*.
Hⁱ is the hypergraph obtained by removing all hyperedges that are already influenced
by the nodes in *S* at stage *i*.

Also referred to as *DynamicGreedy([H]₂)*.
"""
function greedy_tss_2section(h, metaV, metaE)

    S = Dict{Int,Int}()
    U = Dict{Int,Int}()

    #init U set
    for v=1:nhv(h)
        heus = gethyperedges(h,v)
        d = []
        for he in heus
            append!(d,keys(getvertices(h,he.first)))
        end
        d = unique(d)
        push!(U, v => length(d))
    end

    while length(U) != 0
         max = sort(collect(U), by=x->x[2], rev = true)[1]

         delete!(U, max.first)
         push!(S, max)
         actE = zeros(Bool, nhe(h))
         actV = zeros(Bool, nhv(h))
         for s in S
              actV[s.first] = true
         end
         simres = simulate!(h, actV, actE, metaV, metaE; printme = false)

         if simres.actvs == nhv(h)
             break
         end

         visited = []
         for he in gethyperedges(h, max.first)

             for nv in getvertices(h,he.first)

                 if !haskey(U,nv.first) || nv.first in visited
                     continue
                 end
                 push!(visited, nv.first)

                 d = []
                 for he2 in gethyperedges(h, nv.first)
                     if ! actE[he2.first]
                         append!(d, keys(getvertices(h, he2.first)))
                     end
                 end

                 push!(U, nv.first => length(unique(d)))
             end
         end


    end
    length(S)
end



function sub_tss(h, metaV, metaE)

    Vsub = Dict{Int,Tuple{Int,Int}}()
    Esub = Dict{Int,Tuple{Int,Int}}()

    for v=1:nhv(h)
        push!(Vsub, v => (length( gethyperedges(h,v)),metaV[v]))
    end

    for e=1:nhe(h)
        push!(Esub, e => (length(getvertices(h,e)), metaE[e]))
    end

    S = []
    U = deepcopy(Vsub)
    HU = deepcopy(Esub)

    while length(U) != 0 || length(HU)!=0

    #    println(U, ".........",HU)

        #case 1 sort the vertices in U for thresholds
        minny = nothing
        if length(U) > 0
            minny = sort(collect(U), by=x->x[2][2], rev = false)[1]
        end
        if minny != nothing && minny[2][2] == 0
            #case 1
            #remove minny from U and update U
        #    println("CASE1a ", minny[1])
            delete!(U, minny[1])
            updateHU!(h, minny[1], HU)
        else
            candidatedge = nothing
            if length(HU) > 0
                candidatedge = sort(collect(HU), by=x->x[2][2], rev = false)[1]
            end
            if candidatedge != nothing && candidatedge[2][2] == 0
                #println("CASE1b ", candidatedge[1])
                delete!(HU, candidatedge[1])
                updateU!(h, candidatedge[1],U)
            else
                upsidedown = filter(x -> x[2][2] > x[2][1], collect(U))
                    if length(upsidedown) > 0
                    #case 2
                    #add upsidedown[1] to S and remove it from U and update U
                #    println("CASE2a ", upsidedown[1][1])
                    push!(S, upsidedown[1][1])
                    delete!(U, upsidedown[1][1])
                    updateHU!(h, upsidedown[1][1], HU)
                else
                    upsidedown2 = filter(x -> x[2][2] > x[2][1], collect(HU))
                    if  length(upsidedown2) > 0
                        candidate = keys(getvertices(h,upsidedown2[1][1]))
                        #toput2 = filter(x -> haskey(U, x) , candidate)
                        toput2 = filter(x -> !(x in S) , candidate)
                        Uc = keys(U)
                        toput3 = filter(x -> !(x in Uc) , toput2)
                        toput = sort(collect(toput3), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = false)[1]
                    #    println("CASE2b ",collect(toput)[1] )
                        push!(S, toput)

                        updateHUThOnly!(h, toput, HU)


                    else


                        #case 3
                        mickey = sort(collect(U), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = true)[1]
                        mickey2 = sort(collect(HU), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = true)[1]
                    #    println("CASE3 ", mickey[1])
                        if (mickey[2][2] / (mickey[2][1] * (mickey[2][2]+1))) >
                            (mickey2[2][2] / (mickey2[2][1] * (mickey2[2][2]+1)))
                            delete!(U, mickey[1])
                            updateHUDegreeOnly!(h, mickey[1], HU)
                        else
                            delete!(HU, mickey2[1])
                            updateUDegreeOnly!(h, mickey2[1], U)
                        end
                    end
                end
            end
        end
    end


    actE = zeros(Bool, nhe(h))
    actV = zeros(Bool, nhv(h))


    for s in S
         actV[s] = true
    end
    simres = simulate!(h, actV, actE, metaV, metaE; printme = false)


    if simres.actvs != nhv(h)
        println("ARGGGG ", simres.actvs, " ", nhv(h))
    end

    length(S)
end


function updateUDegreeOnly!(h, e, U)
    for w in getvertices(h,e)
        if haskey(U, w.first)
            push!(U, w.first => (U[w.first][1]-1, U[w.first][2]))
        end
    end
end


function updateHUDegreeOnly!(h, v, Esub)
    for he in gethyperedges(h, v)
        if haskey(Esub,he.first)
            push!(Esub, he.first => (Esub[he.first][1]-1, Esub[he.first][2]))
        end
    end
end


function updateHUThOnly!(h, v, Esub)
    for he in gethyperedges(h, v)
        if haskey(Esub,he.first)
            push!(Esub, he.first => (Esub[he.first][1], max(0,Esub[he.first][2]-1)))
        end
    end
end


function updateHU!(h, v, Esub)
    for he in gethyperedges(h, v)
        if haskey(Esub,he.first)
                push!(Esub, he.first => (Esub[he.first][1]-1, max(0,Esub[he.first][2]-1)))
        end
    end
end


function updateU!(h,e,U)
    for w in getvertices(h,e)
        if haskey(U, w.first)
            push!(U, w.first => (U[w.first][1]-1, max(0,U[w.first][2]-1)))
        end
    end
end
