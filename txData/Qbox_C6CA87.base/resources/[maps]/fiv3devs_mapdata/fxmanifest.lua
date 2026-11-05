fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'
author 'Fiv3Devs'
version '1.0.3'

-- [PHASE 1 REMEDIATION] Disabled replace_level_meta to prevent GTA5_b3258.exe+93419F crash on build 3258
-- replace_level_meta 'gta5'

client_scripts {
	'client.lua'
}

files {
	'sp_manifest.ymt',
	'gta5.meta',
    'doortuning.ymt',
	'water.xml'
}

-- [PHASE 1 REMEDIATION] Disabled legacy PSO scenario manifest override
-- data_file 'SCENARIO_POINTS_OVERRIDE_PSO_FILE' 'sp_manifest.ymt'

-- Déclarations automatiques des collisions & archetypes (FiveM Asset Toolkit)
files {
	'stream/country_club.ymt',
	'stream/del_perro_beach.ymt',
	'stream/del_perro_carpark.ymt',
	'stream/del_perro_shops.ymt',
	'stream/downtown.ymt',
	'stream/eclipse.ymt',
	'stream/pillbox_hill.ymt',
}

-- [PHASE 1 REMEDIATION] Disabled legacy PSO scenario point declarations incompatible with build 3258
-- data_file 'SCENARIO_POINTS_PSO_FILE' 'stream/country_club.ymt'
-- data_file 'SCENARIO_POINTS_PSO_FILE' 'stream/del_perro_beach.ymt'
-- data_file 'SCENARIO_POINTS_PSO_FILE' 'stream/del_perro_carpark.ymt'
-- data_file 'SCENARIO_POINTS_PSO_FILE' 'stream/del_perro_shops.ymt'
-- data_file 'SCENARIO_POINTS_PSO_FILE' 'stream/downtown.ymt'
-- data_file 'SCENARIO_POINTS_PSO_FILE' 'stream/eclipse.ymt'
-- data_file 'SCENARIO_POINTS_PSO_FILE' 'stream/pillbox_hill.ymt'
