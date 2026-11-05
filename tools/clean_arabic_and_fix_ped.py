# Clean Arabic text from qbx_cityhall config/shared.lua
shared_path = 'txData/Qbox_C6CA87.base/resources/[qbx]/qbx_cityhall/config/shared.lua'
with open(shared_path, 'r', encoding='utf-8') as f:
    text = f.read()

clean_shared = """return {
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
"""

with open(shared_path, 'w', encoding='utf-8') as f:
    f.write(clean_shared)
print("Updated config/shared.lua (No Arabic)")

# Clean Arabic text and fix ped positioning in qbx_cityhall/config/client.lua
client_cfg_path = 'txData/Qbox_C6CA87.base/resources/[qbx]/qbx_cityhall/config/client.lua'
clean_client_cfg = """return {
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
"""

with open(client_cfg_path, 'w', encoding='utf-8') as f:
    f.write(clean_client_cfg)
print("Updated config/client.lua (Sidewalk coords)")

# Update server.cfg locale
server_cfg_path = 'txData/Qbox_C6CA87.base/server.cfg'
with open(server_cfg_path, 'r', encoding='utf-8') as f:
    s_cfg = f.read()

s_cfg = s_cfg.replace('sets locale "ar-MA"', 'sets locale "en-US"')
with open(server_cfg_path, 'w', encoding='utf-8') as f:
    f.write(s_cfg)
print("Updated server.cfg locale to en-US")

