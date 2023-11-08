using JSON, DataStructures

function test()
    ###################
    ### Write data ####
    ###################
    # dictionary to write
    dict1 = DataStructures.OrderedDict(
        "0" => DataStructures.OrderedDict(
            "voieAQuai" => "V2",
            "itineraire" => "0"
            ),
        "1" => DataStructures.OrderedDict(
            "voieAQuai" => "11",
            "itineraire" => "1"
            )
        )

    # write the file with the stringdata variable information
    open("test.json", "w") do f
        JSON.print(f, dict1, 4) # 4 is the indent
    end

    ###################
    ### Read data #####
    ###################
    # create variable to write the information
    dict2 = DataStructures.OrderedDict()
    open("test.json", "r") do f
        dict2 = JSON.parse(f)  # parse and transform data
    end

    # print both dictionaries
    println(dict1)
    println(dict2)

end
