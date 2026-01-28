#include <amxmodx>
#include <amxmisc>

#define DHUD 					// Раскомментируйте для использования DHUD

#if defined DHUD
	#include <dhudmessage>
#endif	

#define PLUGIN "fb_forwards"
#define VERSION "0.1.4"
#define AUTHOR "Kanagava & Realution & minibam"

new g_Hostname, g_UnbanURL, g_MsgType, g_Number, g_Interval, g_Color;

forward fbans_player_banned_pre(id, userid)								// Объявляем forward - функция которая будет вызвана дургим плагином
 
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
   
	g_Hostname	=	get_cvar_pointer("hostname")						// Не трогать! Автоматически определяет имя сервера.
	g_UnbanURL	=	register_cvar("fb_ss_website", "rp16.ru")	// Ваш сайт
	g_MsgType	=	register_cvar("fb_ss_msgtype", "3")					// 0 - ничего не показывать | 1 - только чат | 2 - только Худ | 3 - чат + худ
	g_Color		=	register_cvar("fb_ss_hudcolor", "255255255")		// Цвет Hud/Dhud сообщения. По умолчанию: 255255255
	g_Interval	=	register_cvar("fb_ss_interval", "1.0")				// Интервал между скринами. По умолчанию: 1.0
	g_Number	=	register_cvar("fb_ss_number", "3")					// Кол-во скринов. По умолчанию: 3
	
	register_dictionary("fb_forwards.txt")								// Языковой файл
}

public fbans_player_banned_pre(id, userid)
{
	if(!id || !is_user_connected(id) || get_user_userid(id)!=userid) 
	return PLUGIN_HANDLED
	
	new time[32], hostname[64], name2[32], ip[32], authid2[32], site[64], R, G, B
	
	get_user_name(id, name2, 31)
	get_user_authid(id, authid2, 31)
	get_user_ip(id, ip, 31, 1)

	get_time("%d/%m/%Y - %H:%M:%S",time,31)
	get_pcvar_string(g_Hostname, hostname, charsmax(hostname))
	get_pcvar_string(g_UnbanURL, site, charsmax(site))
	
	new iColor = get_pcvar_num( g_Color )
	R = iColor / 1000000
	iColor %= 1000000
	G = iColor / 1000
	B = iColor % 1000
	
	switch(get_pcvar_num(g_MsgType))
	{
		case 1:
		{
			ChatColor(id,"^1[^4FB^1]%L", id, "FB_MSG1", time, hostname)
			ChatColor(id,"^1[^4FB^1]%L", id, "FB_MSG2", name2, ip, authid2)
			ChatColor(id,"^1[^4FB^1]%L", id, "FB_MSG3", site)
		}
		case 2:
		{
			#if defined DHUD
				set_dhudmessage(R, G, B, -1.0, 0.01, 0, 7.0, 7.0)
				show_dhudmessage(id, "%L", id, "FB_DHUD", name2, hostname, ip, authid2)
			#else	
				set_hudmessage(R, G, B, -1.0, 0.1, 0, 7.0, 7.0, 0.0, 0.0, -1)
				show_hudmessage(id, "%L", id, "FB_HUD", time, hostname, name2, ip, authid2, site)
			#endif
		}
		case 3:
		{
			ChatColor(id,"^1[^4FB^1]%L", id, "FB_MSG1", time, hostname)
			ChatColor(id,"^1[^4FB^1]%L", id, "FB_MSG2", name2, ip, authid2)
			ChatColor(id,"^1[^4FB^1]%L", id, "FB_MSG3", site)
			
			#if defined DHUD
				set_dhudmessage(R, G, B, -1.0, 0.01, 0, 7.0, 7.0)
				show_dhudmessage(id, "%L", id, "FB_DHUD", name2, hostname, ip, authid2)
			#else	
				set_hudmessage(R, G, B, -1.0, 0.1, 0, 7.0, 7.0, 0.0, 0.0, -1)
				show_hudmessage(id, "%L", id, "FB_HUD", time, hostname, name2, ip, authid2, site)
			#endif
		}
	}
	set_task(get_pcvar_float(g_Interval), "screenshot", id, _, _, "a", get_pcvar_num(g_Number))
	return PLUGIN_HANDLED
}

public screenshot(id)
{
	if(is_user_connected(id))
	client_cmd(id, "snapshot")
}

stock ChatColor(const id, const input[], any:...)
{
        new count = 1, players[32]
        static msg[191]
        vformat(msg, 190, input, 3)
       
        replace_all(msg, 190, "!g", "^4") // Green Color
        replace_all(msg, 190, "!y", "^1") // Default Color
        replace_all(msg, 190, "!team", "^3") // Team Color
        replace_all(msg, 190, "!team2", "^0") // Team2 Color
       
        if (id) players[0] = id; else get_players(players, count, "ch")
        {
                for (new i = 0; i < count; i++)
                {
                        if (is_user_connected(players[i]))
                        {
                                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
                                write_byte(players[i]);
                                write_string(msg);
                                message_end();
                        }
                }
        }
}