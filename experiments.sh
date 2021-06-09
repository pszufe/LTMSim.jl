nohup julia -p 4 src/experiments/randV_randE.jl 1>f_sc1.out 2>f_sc1.err &
nohup julia -p 4 src/experiments/randV_propE05.jl 1>f_sc2.out 2>f_sc2.err &
nohup julia -p 4 src/experiments/propV_randE.jl 1>f_sc3.out 2>f_sc3.err &
nohup julia -p 4 src/experiments/propV_propE05.jl 1>f_sc4.out 2>f_sc4.err &