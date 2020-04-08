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
         #maxv = sort!(collect(U), by=x->x[2], rev = true)[1]
		 maxv_val, maxv_key = findmax(U)
         delete!(U, maxv_key)
         S[maxv_key] = maxv_val
         actE = zeros(Bool, nhe(h))
         actV = zeros(Bool, nhv(h))

         for s in S
              actV[s.first] = true
         end

         simres = simulate!(h, actV, actE, metaV, metaE; printme = false)

         if simres.actvs == nhv(h)
             break
         end

         for he in gethyperedges(h,maxv_key)
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
        d = Set{Int}()
        for he in heus
            push!.(Ref(d),keys(getvertices(h,he.first)))
        end
        push!(U, v => length(d))
    end

    while length(U) != 0
		 #maxv = sort!(collect(U), by=x->x[2], rev = true)[1]
		 maxv_val, maxv_key = findmax(U)
         delete!(U, maxv_key)
         S[maxv_key] = maxv_val
         actE = zeros(Bool, nhe(h))
         actV = zeros(Bool, nhv(h))
         for s in S
              actV[s.first] = true
         end
	     simres = simulate!(h, actV, actE, metaV, metaE; printme = false)

         if simres.actvs == nhv(h)
             break
         end

         visited = Set{Int}()
         for he in gethyperedges(h, maxv_key)

             for nv in getvertices(h,he.first)

                 if !haskey(U,nv.first) || nv.first in visited
                     continue
                 end
                 push!(visited, nv.first)

                 d = Set{Int}()
                 for he2 in gethyperedges(h, nv.first)
                     if ! actE[he2.first]
                         push!.(Ref(d), keys(getvertices(h, he2.first)))
                     end
                 end
                 U[nv.first] = length(d)
             end
         end


    end
    length(S)
end
function sub_tss(h, metaV, metaE)

    Vsub = Dict{Int,Tuple{Int,Int}}() #map for each node the degree and thresholds
    Esub = Dict{Int,Tuple{Int,Int}}() #map for each edges the size and thresholds
	#init structures
    for v=1:nhv(h)
        push!(Vsub, v => (length( gethyperedges(h,v)),metaV[v]))
    end
    for e=1:nhe(h)
        push!(Esub, e => (length(getvertices(h,e)), metaE[e]))
    end
	#end init

    S = Int[] #the seed set
    U = deepcopy(Vsub) #clone vertices
    HU = deepcopy(Esub) #clone edges

	#whilethe graph is no empty (no nodes or no edges)
    while length(U) != 0 || length(HU)!=0

        #CASE  1
        minny = nothing
        if length(U) > 0
			#sort the vertices in U for thresholds
            minny = sort!(collect(U), by=x->x[2][2], rev = false)[1]
        end
		#if exits a node with threshold 0 it is self-activated and we remove from the current graph
        if minny != nothing && minny[2][2] == 0
			#CASE 1 A
            #remove minny from U and update U
            delete!(U, minny[1])
			#if remove the node we have to reduce the threshold and the size of the containing edges
            updateHU!(h, minny[1], HU)
        else
			#CASE 1 B
			#If no node have threshold 0, we try to find a edge with threshold 0
            candidatedge = nothing
            if length(HU) > 0
                candidatedge = sort!(collect(HU), by=x->x[2][2], rev = false)[1]
            end
			#here we find an edge with threshold 0
            if candidatedge != nothing && candidatedge[2][2] == 0
                #remove the edge from the current graph
                delete!(HU, candidatedge[1])
				#update the nodes inside the selected edge by decreasing threshold and degree
                updateU!(h, candidatedge[1],U)
            else
				# CASE 2
				# NO EDGES AND NODES HAVE threshold equal to 0
				# We look for a node with the threshold value greater than its degree
                upsidedown = filter(x -> x[2][2] > x[2][1], collect(U))#returns a list with this feature
				if length(upsidedown) > 0
					#CASE 2 A
                	#One node has t(v) > d(v), for this reason in order to be activated
					# we have to insert in S because it cannot be activated by its neighbors
					push!(S, upsidedown[1][1])
					#update the current graph by removing this node, same case of CASE 1 A
                    delete!(U, upsidedown[1][1])
                    updateHU!(h, upsidedown[1][1], HU)
                else
					#CASE 2 B
					#In this case we look for  t(e) > size(e)
                    upsidedown2 = filter(x -> x[2][2] > x[2][1], collect(HU))
                    if  length(upsidedown2) > 0
						println("Oh my god!")
                        # candidate = keys(getvertices(h,upsidedown2[1][1]))
                        # toput2 = filter(x -> !(x in S) , candidate)
                        # Uc = keys(U)
                        # toput3 = filter(x -> !(x in Uc) , toput2)
                        # toput = sort!(collect(toput3), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = false)[1]
                        # push!(S, toput)
                        # updateHUThOnly!(h, toput, HU)
                    else
                        #CASE 3
						#max node for a formula value
                        candidate_nodes = sort!(collect(U), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = true)
						candidate_node = nothing
						for u in candidate_nodes
							ok = true
							for he in gethyperedges(h, u.first)
						        if haskey(HU, he.first) && HU[he.first][1] == HU[he.first][2]
									ok = false
									break
						        end
						    end
							if ok
								candidate_node = u
								break
							end
						end
						#max edge for a formula value
                        candidate_edge = sort!(collect(HU), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = true)[1]

                        if (candidate_node != nothing &&
							candidate_node[2][2] / (candidate_node[2][1] * (candidate_node[2][2]+1)))  >
                            (candidate_edge[2][2] / (candidate_edge[2][1] * (candidate_edge[2][2]+1)))
                            delete!(U, candidate_node[1])
                            updateHUSizeOnly!(h, candidate_node[1], HU)
                        else
                            delete!(HU, candidate_edge[1])
                            updateUDegreeOnly!(h, candidate_edge[1], U)
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

function sub_tss_opt1(h, metaV, metaE)

    Vsub = Dict{Int,Tuple{Int,Int}}() #map for each node the degree and thresholds
    Esub = Dict{Int,Tuple{Int,Int}}() #map for each edges the size and thresholds
	#init structures
    for v=1:nhv(h)
        push!(Vsub, v => (length( gethyperedges(h,v)),metaV[v]))
    end
    for e=1:nhe(h)
        push!(Esub, e => (length(getvertices(h,e)), metaE[e]))
    end
	#end init

    S = Int[] #the seed set
    U = deepcopy(Vsub) #clone vertices
    HU = deepcopy(Esub) #clone edges

	upsidedown = Int[]

	#whilethe graph is no empty (no nodes or no edges)
    while length(U) != 0 || length(HU)!=0

        #CASE  1
        minny = nothing
        if length(U) > 0
			#sort the vertices in U for thresholds
            minny = sort!(collect(U), by=x->x[2][2], rev = false)[1]
        end
		#if exits a node with threshold 0 it is self-activated and we remove from the current graph
        if minny != nothing && minny[2][2] == 0
			#CASE 1 A
            #remove minny from U and update U
            delete!(U, minny[1])
			#if remove the node we have to reduce the threshold and the size of the containing edges
            updateHU!(h, minny[1], HU)
        else
			#CASE 1 B
			#If no node have threshold 0, we try to find a edge with threshold 0
            candidatedge = nothing
            if length(HU) > 0
                candidatedge = sort!(collect(HU), by=x->x[2][2], rev = false)[1]
            end
			#here we find an edge with threshold 0
            if candidatedge != nothing && candidatedge[2][2] == 0
                #remove the edge from the current graph
                delete!(HU, candidatedge[1])
				#update the nodes inside the selected edge by decreasing threshold and degree
                updateU!(h, candidatedge[1],U)
            else
				# CASE 2
				# NO EDGES AND NODES HAVE threshold equal to 0
				# We look for a node with the threshold value greater than its degree
                #upsidedown = filter(x -> x[2][2] > x[2][1], collect(U))#returns a list with this feature

				if length(upsidedown) > 0
					#CASE 2 A
                	#One node has t(v) > d(v), for this reason in order to be activated
					# we have to insert in S because it cannot be activated by its neighbors
					while length(upsidedown) > 0
						node = pop!(upsidedown)
						push!(S, node)
						#update the current graph by removing this node, same case of CASE 1 A
						delete!(U, node)
						updateHU!(h, node, HU)
					end
                else
					#CASE 3
					#max node for a formula value
					candidate_nodes = sort!(collect(U), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = true)
					candidate_node = nothing
					for u in candidate_nodes
						ok = true
						for he in gethyperedges(h, u.first)
							if haskey(HU, he.first) && HU[he.first][1] == HU[he.first][2]
								ok = false
								break
							end
						end
						if ok
							candidate_node = u
							break
						end
					end
					#max edge for a formula value
					candidate_edge = sort!(collect(HU), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = true)[1]

					if (candidate_node != nothing &&
						candidate_node[2][2] / (candidate_node[2][1] * (candidate_node[2][2]+1)))  >
						(candidate_edge[2][2] / (candidate_edge[2][1] * (candidate_edge[2][2]+1)))
						delete!(U, candidate_node[1])
						updateHUSizeOnly!(h, candidate_node[1], HU)
					else
						delete!(HU, candidate_edge[1])
						updateUDegreeOnly!(h, candidate_edge[1], U, upsidedown)
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

function sub_tss_opt2(h, metaV, metaE)

    Vsub = Dict{Int,Tuple{Int,Int}}() #map for each node the degree and thresholds
    Esub = Dict{Int,Tuple{Int,Int}}() #map for each edges the size and thresholds
	#init structures
    for v=1:nhv(h)
        push!(Vsub, v => (length( gethyperedges(h,v)),metaV[v]))
    end
    for e=1:nhe(h)
        push!(Esub, e => (length(getvertices(h,e)), metaE[e]))
    end
	#end init

    S = Int[] #the seed set
    U = deepcopy(Vsub) #clone vertices
    HU = deepcopy(Esub) #clone edges

	upsidedown = Int[]

	empty_th_nodes  = Int[]
	empty_th_edges  = Int[]

	case1a = case1b = case2 = case3a =case3b =0

	#whilethe graph is no empty (no nodes or no edges)
    while length(U) != 0

        #CASE  1
		#if exits a node with threshold 0 it is self-activated and we remove from the current graph
        if length(empty_th_nodes) > 0
			#CASE 1 A
			case1a += 1
			while length(empty_th_nodes) != 0
				node_with_th_zero = pop!(empty_th_nodes)
	            #remove minny from U and update U
	            delete!(U, node_with_th_zero)
				#if remove the node we have to reduce the threshold and the size of the containing edges
	            updateHU!(h, node_with_th_zero, HU, empty_th_edges)
			end
        else
			#CASE 1 B

			#here we find an edge with threshold 0
            if length(empty_th_edges) > 0
				case1b += 1
				while length(empty_th_edges) != 0
					candidatedge = pop!(empty_th_edges)
	                #remove the edge from the current graph
	                delete!(HU, candidatedge)
					#update the nodes inside the selected edge by decreasing threshold and degree
	                updateU!(h, candidatedge, U, empty_th_nodes)
				end
            else
				# CASE 2
				# NO EDGES AND NODES HAVE threshold equal to 0
				# We look for a node with the threshold value greater than its degree
                #upsidedown = filter(x -> x[2][2] > x[2][1], collect(U))#returns a list with this feature

				if length(upsidedown) > 0
					case2 += 1
					#CASE 2 A
                	#One node has t(v) > d(v), for this reason in order to be activated
					# we have to insert in S because it cannot be activated by its neighbors
					while length(upsidedown) > 0
						node = pop!(upsidedown)
						push!(S, node)
						#update the current graph by removing this node, same case of CASE 1 A
						delete!(U, node)
						updateHU!(h, node, HU, empty_th_edges)
					end
                else
					#CASE 3
					#max node for a formula value
					candidate_nodes = sort!(collect(U), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = true)
					candidate_node = nothing
					for u in candidate_nodes
						ok = true
						for he in gethyperedges(h, u.first)
							if haskey(HU, he.first) && HU[he.first][1] == HU[he.first][2]
								ok = false
								break
							end
						end
						if ok
							candidate_node = u
							break
						end
					end
					#max edge for a formula value
					candidate_edge = sort!(collect(HU), by=x-> (x[2][2] / (x[2][1] * (x[2][2]+1))), rev = true)[1]

					if (candidate_node != nothing &&
						candidate_node[2][2] / (candidate_node[2][1] * (candidate_node[2][2]+1)))  >
						(candidate_edge[2][2] / (candidate_edge[2][1] * (candidate_edge[2][2]+1)))
						case3b += 1
						delete!(U, candidate_node[1])
						updateHUSizeOnly!(h, candidate_node[1], HU)
					else
						case3a += 1
						delete!(HU, candidate_edge[1])
						updateUDegreeOnly!(h, candidate_edge[1], U, upsidedown)
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

    length(S), case1a, case1b, case2, case3a, case3b
end

function updateUDegreeOnly!(h, e, U, list)
    for w in getvertices(h,e)
        if haskey(U, w.first)
            push!(U, w.first => (max(0, U[w.first][1]-1), U[w.first][2]))
			if U[w.first][1] <  U[w.first][2]
				push!(list, w.first)
			end
        end
    end
end


function updateHUSizeOnly!(h, v, Esub)
    for he in gethyperedges(h, v)
        if haskey(Esub, he.first)
            push!(Esub, he.first => (max(0, Esub[he.first][1]-1), Esub[he.first][2]))
			if Esub[he.first][1] <  Esub[he.first][2]
				println("Oh my God!")
			end
        end
    end
end



#Update the graph by decreasing the size and threshold of edges, due to a new node is removed from the current graph
function updateHU!(h, v, Esub, list)
    for he in gethyperedges(h, v)
		#if the edge is in the current graph
        if haskey(Esub, he.first)
			#we decrese of 1 both size and threshold
            push!(Esub, he.first =>
						(max(0, Esub[he.first][1]-1), max(0, Esub[he.first][2]-1)))
			if  Esub[he.first][2] == 0
				push!(list, he.first)
			end
        end
    end
end

#Update the graph by decreasing the degree and threshold of nodes, due to a removing edge
function updateU!(h, e, U, list)
    for w in getvertices(h,e)
        if haskey(U, w.first)
            push!(U, w.first =>
					(max(0, U[w.first][1]-1), max(0, U[w.first][2]-1)))
			if U[w.first][2] == 0
				push!(list, w.first)
			end
        end
    end
end







#CESTINO

# function updateHUThOnly!(h, v, Esub)
#     for he in gethyperedges(h, v)
#         if haskey(Esub,he.first)
#             push!(Esub, he.first => (Esub[he.first][1], max(0,Esub[he.first][2]-1)))
#         end
#     end
# end
