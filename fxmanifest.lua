fx_version 'cerulean'
game 'gta5'

name 'qb-trunk'
description 'Trunk System for QBox Framework'
author 'Milan'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    '@sleepless_interact/init.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

lua54 'yes'