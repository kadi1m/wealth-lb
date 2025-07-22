fx_version 'cerulean'
game 'gta5'

author 'kadin1443'
description 'A basic FiveM resource template'
version '1.0.0'

-- Scripts to run on client and server
client_script 'client/**.lua'
server_script {
    'server/**.lua'
}
shared_script '@oxmysql/lib/MySQL.lua'
