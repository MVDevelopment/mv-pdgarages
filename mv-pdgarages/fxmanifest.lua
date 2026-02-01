fx_version 'cerulean'
game 'gta5'
author 'TDC Leaks - https://discord.com/invite/DSXjU4ukhz'

shared_script 'config.lua'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server.lua'
}

client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/ComboZone.lua',
	'client.lua'
}

lua54 'yes'