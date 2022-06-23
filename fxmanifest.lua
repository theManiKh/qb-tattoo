fx_version 'cerulean'
game 'gta5'

author 'theMani_kh'

client_scripts {
	'client/main.lua',
	'config.lua'
}

server_script {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua',
}

file 'tattoos.json'