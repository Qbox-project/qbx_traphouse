fx_version 'cerulean'
game 'gta5'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    '@ox_lib/init.lua'
}

client_scripts {
    'client/*.lua'
}

server_script 'server/*.lua'

files {
    'html/*'
}

lua54 'yes'