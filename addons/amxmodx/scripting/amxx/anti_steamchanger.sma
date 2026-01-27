#include amxmodx
#include amxmisc

new bool:g_iBlock[33];
new szAuth[33][32], szAuthTwo[33][32];
new g_Cvar[4];

public plugin_init() 
{
	register_plugin("Anti SteamChanger", "vk.com/krisiso", "ToJI9IHGaa");
	
	g_Cvar[0] = register_cvar("anti_changer_log", "1");				// Логировать данные о читере? Если нет то будет кикать
	g_Cvar[1] = register_cvar("anti_changer_inform", "1");			// Информировать о подмене на сервере игрокам?
	g_Cvar[2] = register_cvar("anti_changer_kick_cheater", "1");	// Кикать ли игроков с подменой при логировании? Если нет то будет вести логирование
	g_Cvar[3] = register_cvar("anti_changer_admin_inform", "1");	// Уведомлять о читере всех или только админов? (Если включено уведомление)
}
public client_putinserver(id)
{
	if(!g_iBlock[id])
	{
		new sz_Authr[32];
		get_user_authid(id, sz_Authr, charsmax(sz_Authr));
		szAuth[id] = sz_Authr;
		g_iBlock[id] = true;
	}else set_task(5.0, "FixSteam", id + 1101);
}
public FixSteam(id)
{
	id -= 1101;
	new Name[32], sz_Authr[32], szIp[32];
	get_user_ip(id, szIp, charsmax(szIp), 1);
	get_user_name(id, Name, charsmax(Name));
	get_user_authid(id, sz_Authr, charsmax(sz_Authr));
	szAuthTwo[id] = sz_Authr;
	if(!(equal(szAuthTwo[id], szAuth[id])))
	{
		if(g_Cvar[0])
		{
			log_to_file("addons/amxmodx/logs/SteamChanger.txt", "Ник: %s |Old SteamId: %s |New SteamId: %s |IP: %s", Name, szAuth[id], szAuthTwo[id], szIp);
			if(g_Cvar[2]) server_cmd("amx_kick ^"%s^" SteamChanger", Name);
		}
		else server_cmd("amx_kick ^"%s^" SteamChanger", Name);
		
		if(g_Cvar[1])
		{
			if(g_Cvar[3])
			{
				for(new admin = 1; admin <= get_maxplayers(); admin++)
				{
					if(get_user_flags(admin) & ADMIN_BAN) chat(admin, "!y[!gAS!y] [!g%s!y]|[Старый: !g%s!y][Новый: !g%s!y]|[Айпи:!g%s!y]", Name, szAuth[id], szAuthTwo[id], szIp);
				}
			}else
			{
				for(new admin = 1; admin <= get_maxplayers(); admin++)
				{
					chat(admin, "!y[!gAS!y] Подмена [!g%s!y]|[Старый: !g%s!y][Новый: !g%s!y]|[Айпи:!g%s!y]", Name, szAuth[id], szAuthTwo[id], szIp);
				}
			}
		}
	}
}
public plugin_cfg()
{
	new szCfgDir[64], szFile[192];
	get_configsdir(szCfgDir, charsmax(szCfgDir));
	formatex(szFile,charsmax(szFile),"%s/ac_setting.cfg", szCfgDir);
	
	if(file_exists(szFile))
	server_cmd("exec %s", szFile);
}
stock chat(const id, const input[], any:...)
{
	new count = 1, players[32], msg[191]; vformat(msg, 190, input, 3)
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!t", "^3")
	if(id)players[0] = id; else get_players(players, count, "ch")
	{
		for(new i = 0; i < count; i++)
		{
			if(is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i])
				write_string(msg)
				message_end()
			}
		}
	}
}
