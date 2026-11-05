

fx_version 'cerulean'
game 'gta5'
version '1.0.3'
author 'aiakoscodem'

client_scripts {
	'client/*.lua',
}

ui_page "html/index.html"

files {
	'html/**/*'
}

escrow_ignore {
	'client/example.lua',
}

lua54 'yes'

export 'OpenTextUI'
export 'CloseTextUI'

dependency '/assetpacks'


