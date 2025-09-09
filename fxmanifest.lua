fx_version 'cerulean'
game 'gta5'

name 'nskap_carkeys'
author 'not.skap'
description 'Advanced key system with ignition and locking features'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@es_extended/locale.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory'
}

provide 'nskap_carkeys'
