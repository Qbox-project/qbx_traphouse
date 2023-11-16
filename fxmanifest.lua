fx_version 'cerulean'
game 'gta5'

description 'QBX_Traphouse'
repository 'https://github.com/Qbox-project/qbx_traphouse'
version '2.0.0'

shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/modules/utils.lua',
	'@qbx_core/shared/locale.lua',
	'locales/en.lua',
	'locales/*.lua',
	'config.lua',
}

client_script {
	'@qbx_core/modules/playerdata.lua',
    'client/*.lua',
}

server_script 'server/*.lua'

ui_page 'html/index.html'

files {
    'html/*'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'