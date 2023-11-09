using JSON
using JuMP, Ipopt
using Cbc

Dico = Dict()

function trouver_dict_par_id(Dico, id)
    result = Dict()

    for key in keys(Dico)
        if Dico[key]["id"] == id
            return Dico[key]
        end
    end
end

function cost_n(x,y_land,z,w)
    PiW = trouver_dict_par_id(Dico["wind_scenarios"], w)["power_generation"]
    res = 0

    for v in 1:(size(x)[1])
        add1 = PiW * sum( z[v,:] ) 
        s1 = 0
        add2 = min( sum(trouver_dict_par_id(Dico["substation_types"],s)["rating"]* x[v, s] for s in 1:(size(x)[2])) , sum(trouver_dict_par_id(Dico["land_substation_cable_types"],q)["rating"]*y_land[v, q] for q in 1:(size(y_land)[2])) )
        add = add1 - add2

        res += max(add,0)
    end

    return res
        # e[i] 
        # getindex(inDict["substation_locations"][1],"x" )
end


function cost_f(v,x,y_land,y_inter,z,w)
    PiW = trouver_dict_par_id(Dico["wind_scenarios"], w)["power_generation"]
    add1 = PiW * sum( z[v,:] ) 
    add2 = sum( sum(trouver_dict_par_id(Dico["substation_substation_cable_types"],q)["rating"]*y_inter[v, vb, q] for q in 1:(size(y_inter)[3]) ) for vb in 1:size(y_inter)[2])
    res = max(add1 - add2,0)

    add3 = 0
    for vb in 1:size(x)[1]
        if vb != v
            add3 += max(PiW * sum( z[vb,:] ) + min(sum(trouver_dict_par_id(Dico["substation_substation_cable_types"],q)["rating"]*y_land[vb, q] for q in 1:(size(y_inter)[3])), PiW * sum( z[v,:] )) - min( sum(trouver_dict_par_id(Dico["substation_types"],s)["rating"]* x[vb, s] for s in 1:(size(x)[2])) , sum(trouver_dict_par_id(Dico["land_substation_cable_types"],q)["rating"]*y_land[v, q] for q in 1:(size(y_land)[2]))),0)
        end
    end

    res += add3
    return res 
end

function cost_c(C)
    return C * Dico["general_parameters"]["curtailing_cost"] + Dico["general_parameters"]["curtailing_penalty"] * max(C-Dico["general_parameters"]["maximum_curtailing"],0)
end

function pf(v,x,y_land)
    s1 = 0
    for s in 1:size(x)[2]
        s1 += trouver_dict_par_id(Dico["substation_types"],s)["probability_of_failure"] * x[v, s]
    end

    s2 = 0
    for q in 1:size(y_land)[2]
        s1 += trouver_dict_par_id(Dico["land_substation_cable_types"],q)["probability_of_failure"] * y_land[v, q]
    end

    return s1 + s2
end

function operational_cost(x,y_land,y_inter,z)
    res = 0
    for w in 1:length(Dico["wind_scenarios"])
        s1 = 0
        for v in 1:size(x)[1]
            s1 += pf(v, x, y_land) * cost_c(cost_f(v,x,y_land,y_inter,z,w))
        end
        s2 = 1
        for v in 1:size(x)[1]
            s2 -= pf(v, x, y_land)
        end
        res += trouver_dict_par_id(Dico["wind_scenarios"], w)["probability"] * (s1 + s2 * cost_c(cost_n(x,y_land,z,w)))
    end
    return res
end

function construction_cost(x,y_land,y_inter,z)
    res = 0
    for s in 1:size(x)[2]
        for v in 1:size(x)[1]
            res += trouver_dict_par_id(Dico["substation_types"], s)["cost"] * x[v, s]
        end
    end

    for e in 1:size(y_land)[1]
        x0 = Dico["general_parameters"]["main_land_station"]["x"]
        y0 = Dico["general_parameters"]["main_land_station"]["y"]
        x1 = trouver_dict_par_id(Dico["substation_locations"],e)["x"]
        y1 = trouver_dict_par_id(Dico["substation_locations"],e)["y"]
        le = sqrt((x0 - x1)^2 + (y0 - y1)^2)
        println(trouver_dict_par_id(Dico["land_substation_cable_types"],e))
        ceq = trouver_dict_par_id(Dico["land_substation_cable_types"],e)["fixed_cost"] + trouver_dict_par_id(Dico["land_substation_cable_types"],e)["variable_cost"] * le

        res += sum(ceq * y_land[e, q] for q in 1:(size(y_land)[2]))
    end


    for u in 1:(size(y_inter)[1])
        for v in 1:(size(y_inter)[1])
            x0 = trouver_dict_par_id(Dico["substation_locations"],u)["x"]
            y0 = trouver_dict_par_id(Dico["substation_locations"],u)["y"]
            x1 = trouver_dict_par_id(Dico["substation_locations"],v)["x"]
            y1 = trouver_dict_par_id(Dico["substation_locations"],v)["y"]
            le = sqrt((x0 - x1)^2 + (y0 - y1)^2)

            for q in 1:size(y_inter)[3]
                ceq = trouver_dict_par_id(Dico["substation_substation_cable_types"],q)["fixed_cost"] + trouver_dict_par_id(Dico["substation_substation_cable_types"],q)["variable_cost"] * le
                res += ceq *y_inter[u, v, q]
            end
        end
    end

    for u in 1:(size(z)[1])
        for v in 1:(size(z)[2])
            x0 = trouver_dict_par_id(Dico["substation_locations"],u)["x"]
            y0 = trouver_dict_par_id(Dico["substation_locations"],u)["y"]
            x1 = trouver_dict_par_id(Dico["wind_turbines"],v)["x"]
            y1 = trouver_dict_par_id(Dico["wind_turbines"],v)["y"]
            le = sqrt((x0 - x1)^2 + (y0 - y1)^2)

            ceq = Dico["general_parameters"]["fixed_cost_cable"] + Dico["general_parameters"]["variable_cost_cable"] * le
            res += sum( z[u, v] * ceq)
        end
    end

    return res
end


function total_cost(x, y_land, y_inter, z)
    return construction_cost(x,y_land,y_inter,z) + operational_cost(x,y_land,y_inter,z)
end


function go()
    global Dico

    m = Model(GLPK.Optimizer)

    Dico = Dict()
    open("toy.json", "r") do f
        Dico = JSON.parse(f)  # parse and transform data
    end

    @variable(m, x[1:length(Dico["substation_locations"]), 1:length(Dico["substation_types"])], Bin)

    @variable(m, y_land[1:length(Dico["substation_locations"]), 1:length(Dico["land_substation_cable_types"])], Bin)

    @variable(m, y_inter[1:length(Dico["substation_locations"]), 1:length(Dico["substation_locations"]), 1:length(Dico["land_substation_cable_types"])], Bin)

    @variable(m, z[1:length(Dico["substation_locations"]), 1:length(Dico["wind_turbines"])], Bin)

    for v in 1:size(x)[1]
        @constraint(m, sum(x[v,:]) <= 1)
        @constraint(m, sum(y_land[v,:]) == sum(x[v,:]))
        @constraint(m, sum(y_inter[v,:,:]) <= sum(x[v,:]))
    end

    for t in 1:size(z)[2]
        @constraint(m, sum(z[:,t]) == 1)
    end

    @objective(m, Min, total_cost(x, y_land, y_inter, z))

    optimize!(m)
    vx = JuMP.value.(x)
    vy_land = JuMP.value.(y_land)
    vy_inter = JuMP.value.(y_inter)
    vz = JuMP.value.(z)

    sol = Dict()

    sol["substations"] = []
    n, m = size(vx)
    p = size(vy_land)[2]
    for v in 1:n
        for s in 1:m
            if vx[v, s] == 1
                for q in 1:p
                    if vy_land[v, q] == 1
                        push!(sol["substations"], Dict(
                            "id" => v,
                            "land_cable_type" => q,
                            "substation_type" => s
                        ))
                    end
                end
            end
        end
    end

    sol["substation_substation_cables"] = []
    n, m, p = size(vy_inter)
    
    for v1 in 1:n
        for v2 in 1:m
            for q in 1:p
                if vy_inter[v1, v2, q] == 1
                    push!(sol["substation_substation_cables"], Dict(
                            "substation_id" => v1,
                            "other_substation_id" => v2,
                            "cable_type" => q
                        ))
                end
            end
        end
    end

    sol["turbines"] = []
    n, m = size(vz)
    for v in 1:n
        for t in 1:m
            if vz[v, t] == 1
                push!(sol["turbines"], Dict(
                            "id" => t,
                            "substation_id" => v
                        ))
            end
        end
    end

    open("sol.json", "w") do f
        JSON.print(f, sol, 4) # 4 is the indent
    end

end


