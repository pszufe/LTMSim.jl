
function generateHypergraph()
    h = Hypergraph{Bool}(5,3)
    h[[1,2,5],1] .= true;
    h[:, 2] .= true;
    h[[1,3,5],3] .= true;
    metaV = [2,2,1,1,2]
    metaE = [2,2,2]
    actV = zeros(Bool, nhv(h));
    actE = zeros(Bool, nhe(h));
    actV[[1,4]] .= true;
    (h, actV, actE, metaV, metaE)
end

function simulate!(h::Hypergraph{Bool},
                  actV::Vector{Bool}, actE::Vector{Bool},
                  metaV::Vector{Int}, metaE::Vector{Int};
                  printme = true, max_step=1_000_000 )
    step = 0
    while true && step < max_step
        step += 1
        actE_cp = deepcopy(actE)
        #deb = DataFrame(step=Int[], aSum)
        for e in 1:nhe(h)
            aSum = sum(actV[ collect(keys(getvertices(h,e))) ])
            if aSum >= metaE[e]
                actE_cp[e] = true
            end
            printme && println("$step e=$e $aSum $(metaE[e]) $(actE_cp[e])")
        end
        #sum(actE_cp) == sum(actE) && return (actvs = sum(actV), step=step-1)
        actE .= actE_cp
        actV_cp = deepcopy(actV)
        for v in 1:nhv(h)
            aSum = sum(actE[ collect(keys(gethyperedges(h,v))) ])
            if aSum >= metaV[v]
                actV_cp[v] = true
            end
            printme && println("$step v=$v $aSum $(metaV[v]) $(actV_cp[v])")
        end
        sum(actV_cp) == sum(actV) && return (actvs = sum(actV), step=step-1)
        actV .= actV_cp
    end
    step
end


function randMetaV(h)
    metaV = Vector{Int}(undef, nhv(h))
    for v in 1:nhv(h)
        metaV[v] = rand(1:length(h.v2he[v]))
    end
    metaV
end

function randMetaE(h)
    metaE = Vector{Int}(undef, nhe(h))
    for e in 1:nhe(h)
        metaE[e] = rand(1:length(h.he2v[e]))
    end
    metaE
end

function proportionalMetaV(h::Hypergraph,prop)
    @assert 0.0 < prop <= 1.0
    metaV = Vector{Int}(undef, nhv(h))
    for v in 1:nhv(h)
        metaV[v] = ceil(length(h.v2he[v])*prop)
    end
    metaV
end

function proportionalMetaE(h::Hypergraph,prop)
    @assert 0.0 < prop <= 1.0
    metaE = Vector{Int}(undef, nhe(h))
    for e in 1:nhe(h)
        metaE[e] = ceil(length(h.he2v[e])*prop)
    end
    metaE
end


#bisection
function bisect(h, metaV, metaE)
    degrees = length.(h.v2he)
    #location=Int(ceil(length(degrees)/2))
    sortedVind = sortperm(degrees, rev=true)
    left = 1
    @assert length(sortedVind) == length(degrees)
    right = length(sortedVind)
    while left < right
        location = Int(ceil( (left + right)/2))
        #println("left=$left right=$right loc=$location ")
        actE = zeros(Bool, nhe(h))
        actV = zeros(Bool, nhv(h))
        # up to the first location true and remainder zeros
        actV[sortedVind[1:location]] .= true
        sres = simulate!(h,actV, actE, metaV, metaE; printme = false)
        if sres.actvs != nhv(h)
            #println("left=location")
            left = location
        else
            #println("right=location")
            right = location-1
        end
    end
    left+1
end

function randomH(nVertices, nEdges)
    mx = Matrix{Union{Nothing,Bool}}(nothing, nVertices,nEdges)
    for e in 1:size(mx,2)
        nv = rand(2:5)
        mx[sample(1:size(mx,1), nv;replace=false), e] .= true
    end

    h = Hypergraph(mx)
    if all(length.(h.v2he) .> 0)
        return h
    else
        return randomH(nVertices, nEdges)
    end
end


