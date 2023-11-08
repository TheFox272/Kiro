using JuMP
using GLPK

function ex4(n::Int64)    
    m = Model(GLPK.Optimizer)
    @variable(m, z[1:n]>=0, Int)
    @variable(m, y>=0)
    @constraint(m, [i in 1:floor(Int,n/2)], z[i]+z[n-i+1]<=n)
    @constraint(m, z[1]+y>=4)
    @constraint(m, sum(z[i] for i in 1:n if rem(i, 3) == 0) <= 1)
    @objective(m, Max, sum(z[i] for i in 1:n)-y)

    # Limitation du temps de résolution à 60 secondes
    set_time_limit_sec(m, 60.0)
    # Résolution d’un modèle
    optimize!(m)
    vz = JuMP.value.(z)
    vy = JuMP.value.(y)
    obj = objective_value(m)
    return vz, vy, obj
end
