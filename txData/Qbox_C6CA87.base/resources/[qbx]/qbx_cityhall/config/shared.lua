return {
    cityhalls = {
        {
            -- 1: Spawn (Inside Hotel)
            coords = vec3(-262.79, -964.18, 30.22),
            showBlip = true,
            blip = {
                label = 'City Services',
                shortRange = false,
                sprite = 487,
                display = 4,
                scale = 0.65,
                colour = 0,
            },
            enableEmployment = false,
            licenses = {
                ['id'] = {
                    item = 'id_card',
                    label = 'ID Card',
                    cost = 50,
                },
                ['driver'] = {
                    item = 'driver_license',
                    label = 'Driver License',
                    cost = 50,
                },
            },
        },
        {
            -- 2: Centre-Ville (Legion Square Job Center)
            coords = vec3(-209.5, -916.5, 30.68),
            showBlip = true,
            blip = {
                label = 'Job Center',
                shortRange = false,
                sprite = 407,
                display = 4,
                scale = 0.75,
                colour = 3,
            },
            enableEmployment = true,
            licenses = {},
        },
    },

    employment = {
        enabled = true,
        jobs = {
            unemployed = 'Unemployed',
            taxi = 'Taxi Driver',
            trucker = 'Trucker',
            garbage = 'Garbage Collector',
            bus = 'Bus Driver',
            tow = 'Tow Truck',
            reporter = 'News Reporter',
        },
        jobLocations = {
            taxi = { coords = vec3(896.37, -177.27, 73.7), label = 'Taxi Depot' },
            trucker = { coords = vec3(806.30, -3183.80, 4.89), label = 'Trucker Depot' },
            garbage = { coords = vec3(-337.08, -1533.47, 27.72), label = 'Garbage Center' },
            bus = { coords = vec3(462.22, -641.15, 28.45), label = 'Bus Depot' },
            tow = { coords = vec3(471.39, -1311.03, 29.21), label = 'Tow Yard' },
            reporter = { coords = vec3(-598.4, -929.85, 24.0), label = 'Weazel News' },
        },
    },
}
