Pkg.activate(".")
using LTMSim
using DataFrames
using SimpleHypergraphs
using Statistics
using PyPlot
using Random

h = randomH(1000,1000)

metaV = proportionalMetaV(h,0.2) #randMetaV(h)
metaE = proportionalMetaE(h,0.5)

r4 = sub_tss_opt2(h, metaV, metaE)
r4 = sub_tss_opt1(h, metaV, metaE)
