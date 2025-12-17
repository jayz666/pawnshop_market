fx_version 'cerulean'
game 'gta5'

author 'ChatGPT'
description 'Pawn Shop Market (AI pricing + SQL stock + OX/QB bridges)'
version '5.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',          -- safe even if ox_lib missing; lib checks prevent crash
    'config.lua',
    'bridge/shared_detect.lua'
}

client_scripts {
    'bridge/inventory_client.lua',
    'bridge/target_client.lua',
    'bridge/menu_client.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/inventory_server.lua',
    'bridge/money_server.lua',
    'server.lua'
}

dependencies {
    'oxmysql'
}
