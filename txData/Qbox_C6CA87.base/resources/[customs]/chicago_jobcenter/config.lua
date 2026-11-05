Config = {}

-- Interaction coordinates for the Job Center receptionist
-- Location: Downtown Los Santos (San Andreas Ave near Legion Square)
Config.PedLocation = vector4(-210.8, -917.4, 32.3, 250.0)

-- NPC Model
Config.PedModel = `a_m_m_business_01`

-- Max interaction distance allowed by server validation
Config.MaxDistance = 5.0

-- Map Blip Settings
Config.Blip = {
    enable = true,
    coords = vector3(-210.8, -917.4, 32.3),
    sprite = 407,       -- Standard Job Center briefcase sprite
    color = 3,          -- Light Blue
    scale = 0.7,
    label = 'Job Center',
    shortRange = true,
}

-- Public Job Whitelist:
-- ONLY exact lowercase job keys registered in qbx_core/shared/jobs.lua with Grade 0
Config.Jobs = {
    {
        name = 'unemployed',
        label = 'Freelancer (Unemployed)',
        description = 'Quit current job and return to civilian freelancer status',
        icon = 'user-slash',
    },
    {
        name = 'taxi',
        label = 'Taxi Driver',
        description = 'Transport citizens and tourists across Los Santos',
        icon = 'taxi',
    },
    {
        name = 'trucker',
        label = 'Trucker',
        description = 'Heavy haul and freight delivery logistics',
        icon = 'truck',
    },
    {
        name = 'garbage',
        label = 'Garbage Collector',
        description = 'Sanitation and waste collection service routes',
        icon = 'trash',
    },
    {
        name = 'bus',
        label = 'Bus Driver',
        description = 'Public transit routes and passenger transit',
        icon = 'bus',
    },
    {
        name = 'tow',
        label = 'Tow Truck',
        description = 'Vehicle recovery and roadside impound operations',
        icon = 'truck-pickup',
    },
    {
        name = 'reporter',
        label = 'News Reporter',
        description = 'Journalism and live city broadcast coverage',
        icon = 'newspaper',
    },
}
