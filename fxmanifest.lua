fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'
author 'MaDHouSe79'
description 'MH Cardealer - A realistic cardealer system for players, they can create there own location to sell there vehicles.'
version '1.0.0'

files {'core/images/*.*'}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/cardealers/*.lua',
    'core/vehicles.lua',
    'core/functions.lua',
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'core/framework/client.lua',
    'client/main.lua',
    'client/menus.lua',
    'client/create.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'core/framework/server.lua',
    'server/main.lua',
    'server/update.lua',
}

dependencies {
    'oxmysql',
}