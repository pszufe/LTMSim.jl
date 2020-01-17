using Test, LTMSim 
using SimpleHypergraphs, StatsBase
using Random
using DataStructures
import LightGraphs

h1 = Hypergraph{Float64}(5,4)
h1[1:3,1] .= 1.5
h1[3,4] = 2.5
h1[2,3] = 3.5
h1[4,3:4] .= 4.5
h1[5,4] = 5.5
h1[5,2] = 6.5


@testset "some test" begin
	@test 2+2 == 4
	@test 1+1 == 2
end;
