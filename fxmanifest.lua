fx_version 'cerulean'
game 'gta5'

description 'https://github.com/Qbox-project/qbx-traphouse'
version '2.0.0'

ui_page 'html/index.html'

shared_scripts {
	'config.lua',
    '@qb-core/shared/locale.lua',
	'@qbx-core/import.lua',
	'locales/en.lua'
}
client_script {
    'client/*.lua',
    '@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/CircleZone.lua',
	'@ox_lib/init.lua'
}

server_script 'server/*.lua'

files {
    'html/*'
}



modules {
    'qbx_core:core',
	'qbx_core:playerdata',
	'qbx_core:utils'
}


lua54 'yes'
