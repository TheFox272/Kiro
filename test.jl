using JSON, OrderedCollections

function test()    
    train1 = OrderedCollections.OrderedDict(
        "0" => OrderedCollections.OrderedDict(
            "voieAQuai" => "V2",
            "itineraire" => "0"
        ),
        "1" => OrderedCollections.OrderedDict(
            "voieAQuai" => "11",
            "itineraire" => "1"
        )
    )
    open("test.json", "w") do f
        JSON.print(f, train1)
    end
end
