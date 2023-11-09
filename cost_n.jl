# ensembles = arrays
#  x,y = array de booleens 
# r = à prendre dans le dico 
# E0 is a set of edges
# y_land pour cable entre land et sub (Q0)
# y_inter
# ligne y = id de v et colonne de y = type de cable

function trouver_dict_par_id(dict, id)
    result = Dict{Any, Dict}()

    for key in keys(dict)
        if dict[key]["id"] == id
            result = dict[key]
        end
    end

    return result
end

function cost_n(x,y_land,z,w,E0,Q0,Dico)
    PiW = trouver_dict_par_id(Dico["wind_scenarios"], w)["power_generation"]
    res = 0

    for v in 1:(length(E0))
        add1 = PiW * sum( z[v,:] ) 
        add2 = min( sum(trouver_dict_par_id(Dico["substation_types"],s)["rating"]* x[v][s] for s in 1:(size(x)[2])) , sum(trouver_dict_par_id(Dico["land_substation_cable_types"],q)["rating"]*y_land[v][q] for q in 1:(size(Q0))) )
        add = add1 - add2

        res += max(add,0)

    return res
        # e[i] 
        # getindex(inDict["substation_locations"][1],"x" )



function cost_f(v,x,y_inter,z,w,E0,ES,Q0,Dico)
    PiW = trouver_dict_par_id(Dico["wind_scenarios"], w)["power_generation"]
    add1 = PiW * sum( z[v,:] ) 
    add2 = sum( sum(trouver_dict_par_id(Dico["substation_substation_cable_types"],q)["rating"]*y_inter[v][vb][q] for q in 1:(size(QS)) ) for vb in 1:length(y_inter)[2])
    res = max(add1 - add2,0)

    add3 = 0
    for vb in 1:length(E0)
        if vb != v
            add3 += max(PiW * sum( z[vb,:] ) + min(sum(trouver_dict_par_id(Dico["substation_substation_cable_types"],q)["rating"]*y_land[vb][q] for q in 1:(size(QS))), PiW * sum( z[v,:] )) - min( sum(trouver_dict_par_id(Dico["substation_types"],s)["rating"]* x[vb][s] for s in 1:(size(x)[2])) , sum(trouver_dict_par_id(Dico["land_substation_cable_types"],q)["rating"]*y_land[v][q] for q in 1:(size(Q0)))),0)

    res += add3
    return res 

function cost_c(C,Dico)
    return C * Dico["general_parameters"]["curtailing_cost"] + Dico["general_parameters"]["curtailing_penalty"] * max(C-Dico["general_parameters"]["maximum_curtailing"],0)

function pf(v,x,y_land)
    return sum(trouver_dict_par_id(Dico["substation_types"],s)["probability_of_failure"]* x[v][s] for s in 1:(size(x)[2])) + sum(trouver_dict_par_id(Dico["land_substation_cable_types"],q)["probability_of_failure"]*y_land[v][q] for q in 1:(size(y_land)[2]))


function construction_cost(x,y_land,y_inter,z,Dico)
    res = sum(sum(trouver_dict_par_id(Dico["substation_types"],s)["cost"]* x[v][s] for s in 1:(size(x)[2])) for v in 1:size(x)[1])

    for e in 1:size(y_land)[1]
        x0 = Dico["general_parameters"]["main_land_station"]["x"]
        y0 = Dico["general_parameters"]["main_land_station"]["y"]
        x1 = trouver_dict_par_id(Dico["substation_locations"],e)["x"]
        y1 = trouver_dict_par_id(Dico["substation_locations"],e)["y"]
        le = sqrt((x0 - x1)^2 + (y0 - y1)^2)
        ceq = trouver_dict_par_id(Dico["land_substation_cable_types"],q)["fixed_cost"] + trouver_dict_par_id(Dico["land_substation_cable_types"],q)["variable_cost"] * le

        res += sum(ceq *y_land[v][q] for q in 1:(size(y_land)[3]))


    for u in 1:(size(y_inter)[1])
        for v in 1:(size(y_inter)[1])
            x0 = trouver_dict_par_id(Dico["substation_locations"],u)["x"]
            y0 = trouver_dict_par_id(Dico["substation_locations"],u)["y"]
            x1 = trouver_dict_par_id(Dico["substation_locations"],v)["x"]
            y1 = trouver_dict_par_id(Dico["substation_locations"],v)["y"]
            le = sqrt((x0 - x1)^2 + (y0 - y1)^2)
            ceq = trouver_dict_par_id(Dico["substation_substation_cable_types"],q)["fixed_cost"] + trouver_dict_par_id(Dico["substation_substation_cable_types"],q)["variable_cost"] * le

            res += sum(ceq *y_inter[u][v][q] for q in 1:(size(y_land)[3]))

    for u in 1:(size(z)[1])
        for v in 1:(size(z)[2])
            x0 = trouver_dict_par_id(Dico["substation_locations"],u)["x"]
            y0 = trouver_dict_par_id(Dico["substation_locations"],u)["y"]
            x1 = trouver_dict_par_id(Dico["wind_turbines"],v)["x"]
            y1 = trouver_dict_par_id(Dico["wind_turbines"],v)["y"]
            le = sqrt((x0 - x1)^2 + (y0 - y1)^2)
            ceq = trouver_dict_par_id(Dico["general_parameters"],q)["fixed_cost_cable"] + trouver_dict_par_id(Dico["general_parameters"],q)["variable_cost_cable"] * le
            
            res += sum( z[u][v] * ceq)