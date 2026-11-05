fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author '9labs'
describing '9labs - Handik'
version '1.6.0'

client_script 'client_handik.lua'
server_script 'server/main.lua'

files {
    'data/vehicles.meta',
    'data/handling.meta',
    'data/carvariations.meta',
    'data/carcols.meta',
    'data/vehiclelayouts.meta',
    'data/clip_sets.xml',
}

data_file 'CLIP_SETS_FILE'         'data/clip_sets.xml'
data_file 'VEHICLE_LAYOUTS_FILE'   'data/vehiclelayouts.meta'
data_file 'HANDLING_FILE'          'data/handling.meta'
data_file 'VEHICLE_METADATA_FILE'  'data/vehicles.meta'
data_file 'CARCOLS_FILE'           'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'

dependency '/assetpacks'
