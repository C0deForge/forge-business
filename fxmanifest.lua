fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'forge-business'
description 'Script to open/close businesses with a custom UI'
author 'Forge'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/fonts/Poppins-Regular.ttf'
}
