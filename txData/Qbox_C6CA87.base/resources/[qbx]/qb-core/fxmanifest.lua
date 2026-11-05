fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qb-core'
description 'Qbox backwards compatibility shim for qb-core'
version '1.0.0'

dependencies {
    'qbx_core'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

