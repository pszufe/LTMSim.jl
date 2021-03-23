"""
    sub_tss(h, metaV, metaE; opt=false)

Compute the target set exploiting a subtractive approach.
"""
function sub_tss(h, metaV, metaE; opt=false, printme=false)
    Vsub = Dict{Int,Tuple{Int,Int}}() # node => (degree, threshold)
    Esub = Dict{Int,Tuple{Int,Int}}() # edge => (size, threshold)

    nCount=0
    eCount=0
    nDegreeSum=0
    nThSum=0
    eSizeSum=0
    eThSum=0

    avg_degree = 0
    avg_size = 0

	#init structures
    for v=1:nhv(h)
        push!(Vsub, v => (length(gethyperedges(h,v)), metaV[v]))
        avg_degree += length(gethyperedges(h,v))
        nDegreeSum += length(gethyperedges(h,v))
        nThSum += metaV[v]
        nCount += 1
    end

    for e=1:nhe(h)
        push!(Esub, e => (length(getvertices(h,e)), metaE[e]))
        avg_size += length(getvertices(h,e))
        eSizeSum += length(getvertices(h,e))
        eThSum += metaE[e]
        eCount += 1
    end

    avg_degree /= nhv(h)
    avg_size /= nhe(h)

    printme && println("avg degree ", avg_degree, " avg size ", avg_size)
    printme && println("Degree sum ", nDegreeSum, " nCount ", nCount, " nThSum ", nThSum)
    printme && println("Size sum ", eSizeSum, " eCount ", eCount, " eThSum ", eThSum)
    
    S = Int[] #the seed set
    LU = Set{Int}() #limbo nodes
    LHU = Set{Int}() #limbo edges
    U = deepcopy(Vsub) #clone vertices
    HU = deepcopy(Esub) #clone edges

	upsidedown = Set{Int}()

	empty_th_nodes  = Set{Int}()
	empty_th_edges  = Set{Int}()

	case1a = case1b = case2 = case3a = case3b = 0

	#while the graph is not empty (no nodes or edges)
    while length(U) != 0
        #CASE  1
		#if exits a node with threshold 0 it is self-activated and we remove from the current graph
        if length(empty_th_nodes) > 0
			#CASE 1 A

			while length(empty_th_nodes) != 0
				case1a += 1
				node_with_th_zero = pop!(empty_th_nodes)

				printme &&  println("Case1A ", node_with_th_zero)
                #remove minny from U and update U
               
				#if remove the node we have to reduce the threshold and the size of the containing edges
	            #updateHU!(h, node_with_th_zero, HU, empty_th_edges)
                eThSum -= local_updateHUThOnly!(h, node_with_th_zero, HU, empty_th_edges, LHU)
                if !(node_with_th_zero in LU)
                    nCount-=1
                    nDegreeSum-= U[node_with_th_zero][1]
                    eSizeSum -= local_updateHUSizeOnly!(h, node_with_th_zero, HU, LHU)
                else
                    delete!(LU, node_with_th_zero)
                end

                delete!(U, node_with_th_zero)

                if (node_with_th_zero in upsidedown)
                    delete!(upsidedown, node_with_th_zero)
                end
            end
        else
			#CASE 1 B
			#here we find an edge with threshold 0
            if length(empty_th_edges) > 0

				while length(empty_th_edges) != 0
					case1b += 1
					candidatedge = pop!(empty_th_edges)

					printme &&  println("Case1B ", candidatedge)
                    #remove the edge from the current graph
	                
					#update the nodes inside the selected edge by decreasing threshold and degree
                    #updateU!(h, candidatedge, U, empty_th_nodes)
                    nThSum -= local_updateUThOnly!(h, candidatedge, U, empty_th_nodes,LU,upsidedown)
                    if !(candidatedge in LHU)
                        eCount-=1
                        eSizeSum-= HU[candidatedge][1]
                        nDegreeSum -=local_updateUDegreeOnly!(h, candidatedge, U, upsidedown, LU)
                    else
                        delete!(LHU, candidatedge)
                    end

                    delete!(HU, candidatedge)
				end
            else
				# CASE 2
				# NO EDGES AND NODES HAVE threshold equal to 0
				# We look for a node with the threshold value greater than its degree
                #upsidedown = filter(x -> x[2][2] > x[2][1], collect(U)) #returns a list with this feature
				if length(upsidedown) > 0
					# CASE 2 A
                	# One node has t(v) > d(v), for this reason in order to be activated
					# we have to insert in S because it cannot be activated by its neighbors
					# while length(upsidedown) != 0
						case2 += 1
						node = pop!(upsidedown)

						printme &&  println("Case2 ", node)

						push!(S, node)
						#update the current graph by removing this node, same case of CASE 1 A
                        
                        nCount-=1
                        nDegreeSum-= U[node][1]
                        nThSum-= U[node][2]

                        delete!(U, node)
                        #updateHU!(h, node, HU, empty_th_edges)
                        eThSum-= local_updateHUThOnly!(h, node, HU, empty_th_edges,LHU)
                        if !(node in LU)
                            eSizeSum -=local_updateHUSizeOnly!(h, node, HU, LHU)
                        else
                            printme &&  printf("maybe there is a problem: removing node from LU!")
                            delete!(LU, node)
                        end
                else
                 
                    avg_degree = nDegreeSum/ nCount
                    avg_nth = nThSum/nCount
                    #nscale= (avg_nth)/(avg_degree*(avg_degree+1))
                    nscale = op(avg_nth, avg_degree)
                    # nscale=(avg_nth)/(avg_degree)
                    avg_size   = eSizeSum/eCount  
                    avg_eth = eThSum/eCount
                    escale = op(avg_eth, avg_size)
                    # escale= (avg_eth)/(avg_size*(avg_size+1))
                    # escale= (avg_eth)/(avg_size)
                  
                    printme && println("avg nscale ",nscale," avg escale ",escale)
                    
					#CASE 3
					#max node for a formula value
                    U_selected = filter(x -> !(x[1] in LU), collect(U))
					candidate_nodes = sort!(collect(U_selected), by= x-> op(x[2][2], x[2][1]), rev = true)
                    
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
                    HU_selected = filter(x -> !(x[1] in LHU), collect(HU)) 
                    candidate_edge = sort!(collect(HU_selected), by=x-> op(x[2][2], x[2][1]), rev = true)[1]
                    
                 #   if ( candidate_node != nothing)
                if !isnothing(candidate_node) && 
                    op(candidate_node[2][2], candidate_node[2][1] * nscale) > op(candidate_edge[2][2], candidate_edge[2][1] * escale)


                # if ( candidate_node !== nothing &&
				# 	((candidate_node[2][2] / (candidate_node[2][1] * (candidate_node[2][1]+1))) * (nscale)  )  >
                #    ((candidate_edge[2][2] / (candidate_edge[2][1] * (candidate_edge[2][1]+1)))  * (escale)  )
                #    ) 
                # if ( candidate_node != nothing &&
                #         ((candidate_node[2][2] / (candidate_node[2][1] )) *  (nscale)  )  >
                #        ((candidate_edge[2][2] / (candidate_edge[2][1] ))  * (escale)  )
                #       ) 

						case3a += 1
						#println("Case 3A ", candidate_node[1])
                        #delete!(U, candidate_node[1])

                        nCount-=1
                        nDegreeSum-= U[candidate_node[1]][1]
                        nThSum-= U[candidate_node[1]][2]

                        push!(LU, candidate_node[1])
                        eSizeSum -= local_updateHUSizeOnly!(h, candidate_node[1], HU, LHU)
					else
						case3b += 1
						printme &&  println("Case 3B ", candidate_edge[1])
                        #delete!(HU, candidate_edge[1])

                        eCount-=1
                        eSizeSum-= HU[candidate_edge[1]][1]
                        eThSum-= HU[candidate_edge[1]][2]

                        push!(LHU, candidate_edge[1])
						nDegreeSum-=local_updateUDegreeOnly!(h, candidate_edge[1], U, upsidedown, LU)
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
        println("There's a problem here ", simres.actvs, " ", nhv(h))
		i = 1
		for v in simres.actvsnodes
			v == false && println(i," ",v, " ", length(gethyperedges(h,i)), " ", metaV[i]," ", gethyperedges(h,i))
			i+=1
		end

    end

    if opt
        new_seed = optimize_seed_set(h, Set(keys(S)), metaV, metaE)
        return length(new_seed), case1a, case1b, case2, case3a, case3b
    end

    length(S), case1a, case1b, case2, case3a, case3b
end


#
# HELPER FUNCTIONS
#

function op(a, b)
    return a / (b * (b+1)) 
end


function local_updateUDegreeOnly!(h, e, U, list, LU)
    s = 0
    for w in getvertices(h,e)
        if haskey(U, w.first) && U[w.first][1] !=0
            if !(w.first in LU) 
                s+=1
            end
            push!(U, w.first => (max(0, U[w.first][1]-1), U[w.first][2]))
            if U[w.first][1] <  U[w.first][2]
                if !(w.first in LU)
                     push!(list, w.first)
                 end
            end
        end
    end
    return s
end


function local_updateHUSizeOnly!(h, v, Esub, LHU)
    s = 0
    for he in gethyperedges(h, v)
        if haskey(Esub, he.first) &&  Esub[he.first][1] != 0
            if !(he.first in LHU) 
                s += 1
            end
            push!(Esub, he.first => (max(0, Esub[he.first][1]-1), Esub[he.first][2]))
			if Esub[he.first][1] <  Esub[he.first][2]
				println("Oh my God!")
			end
        end
    end
    return s
end


#Update the graph by decreasing the size and threshold of edges, due to a new node is removed from the current graph
function local_updateHUThOnly!(h, v, Esub, list, LHU)
    t = 0
    for he in gethyperedges(h, v)
		#if the edge is in the current graph
        if haskey(Esub, he.first) && Esub[he.first][2] != 0
            if !(he.first in LHU) 
                t += 1
            end
			#we decrese of 1 both size and threshold
            push!(Esub, he.first =>
						(Esub[he.first][1], max(0, Esub[he.first][2]-1)))
			if  Esub[he.first][2] == 0
				push!(list, he.first)
			end
        end
    end
    return t
end


#Update the graph by decreasing the degree and threshold of nodes, due to a removing edge
function local_updateUThOnly!(h, e, U, list, LU, list2)
    t = 0
    for w in getvertices(h,e)
        if haskey(U, w.first) && U[w.first][2] != 0
            if !(w.first in LU) 
                t+=1
            end
            push!(U, w.first =>
					(U[w.first][1], max(0, U[w.first][2]-1)))
			if U[w.first][2] == 0
				push!(list, w.first)
            else
                if w.first in list2 && U[w.first][1] >=  U[w.first][2]
                    delete!(list2, w.first) 
                end
            end
        end
    end
    return t
end
