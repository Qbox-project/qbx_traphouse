fx_version 'cerulean'
game 'gta5'

description 'QBX-Traphouse'
repository 'https://github.com/Qbox-project/qbx_traphouse'
version '2.0.0'

ui_page 'html/index.html'

shared_scripts {
	'config.lua',
	'@ox_lib/init.lua',
    '@qbx_core/shared/locale.lua',
	'@qbx_core/import.lua',
	'locales/en.lua'
}
client_script {
    'client/*.lua',
}

server_script 'server/*.lua'

files {
    'html/*'
}

modules {
	'qbx_core:playerdata',
	'qbx_core:utils'
}


lua54 'yes'
use_experimental_fxv2_oal 'yes'