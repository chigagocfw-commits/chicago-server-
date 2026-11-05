fx_version 'cerulean'
game 'gta5'
version '1.5'
author 'aiakoscodem'

shared_scripts {
	'config/config.lua',
	'config/GetCore.lua',
	'locales/*.lua',
}

client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/CircleZone.lua',
	'client/*.lua',
	'locales/*.lua',
	'editable/*.lua',

}

server_scripts {
	-- '@mysql-async/lib/MySQL.lua', --:warning:PLEASE READ:warning:; Uncomment this line if you use 'mysql-async'.:warning:
	'@oxmysql/lib/MySQL.lua', --:warning:PLEASE READ:warning:; Uncomment this line if you use 'oxmysql'.:warning:
	'config/server_config.lua',
	'server/*.lua',
	'config/*.lua',
	'locales/*.lua',
}

ui_page "html/index.html"

files {
	'html/**/*'
}

escrow_ignore {
	'server/utility.lua',
	'locales/*.lua',
	'editable/*.lua',
	'config/*.lua',
	'client/utility.lua',
}

dependencies {
	'/server:4752',
	'/onesync',
}

lua54 'yes'

dependency '/assetpacks'