return {
    useTarget = true,
    debugPoly = false,

    peds = {
        { -- 1: Spawn Ped (Inside Hotel)
            model = 'a_m_m_hasjew_01',
            coords = vec4(-262.79, -964.18, 30.22, 181.71),
            scenario = 'WORLD_HUMAN_STAND_MOBILE',
            cityhall = true,
            zoneOptions = {
                length = 3.0,
                width = 3.0,
                debugPoly = false,
            },
        },
        { -- 2: Centre-Ville Ped (Legion Square Job Center - on sidewalk)
            model = 'a_m_m_business_01',
            coords = vec4(-209.5, -916.5, 30.68, 250.0),
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            cityhall = true,
            zoneOptions = {
                length = 3.0,
                width = 3.0,
                debugPoly = false,
            },
        },
    },
}
