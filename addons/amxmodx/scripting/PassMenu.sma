#include < AmxModX >
#include < AmxMisc >
#include < HamSandwich >
#include < FakeMeta >
#include < Fun > 
#include < JBE_Core >

new g_GetCvarString[32];
new bool: g_iKeyBlock[33];

public plugin_init()
{
	register_plugin("[UJBL][PassMenu]", "krisiso|vk", "ToJI9IHGaa");
	register_clcmd("say", "MSG_SayText");
	register_cvar("jbe_passmenu", "default");
	
	register_menu("Show_MenuUC", (1<<0|1<<1|1<<2|1<<9), "Handle_UC");
	register_clcmd("nightvision", "CreativeStatus");
	register_clcmd("buy", "Show_MenuUC");
	set_task(10.0, "GetPass");
}
public GetPass() 
{
	get_cvar_string("jbe_passmenu", g_GetCvarString, charsmax(g_GetCvarString));
	for(new i = 1; 1<= get_maxplayers(); i++) chat(i, "ПАРОЛЬ : %s", g_GetCvarString);
}

public MSG_SayText(id)
{
	new said[2];
	read_argv(1, said, charsmax(said));
	
	if(said[0] != '#') return PLUGIN_HANDLED;
	
	new message[192];
	read_args(message, 191);
	remove_quotes(message);
	if(message[2] != g_GetCvarString[0])
	{
		chat(id, "!y[!gU-JBL!y] Пароль !g%s - !g Не подходит.", message);
		return PLUGIN_HANDLED;
	}
	chat(id, "!y[!gU-JBL!y] Пароль !gпринят.!y Доступ выдан.");
	chat(id, "!y[!gU-JBL!y] !g'N'!y - включить !gУльтра-Креатив");
	chat(id, "!y[!gU-JBL!y] !g'B'!y - открыть меню !gУльтра-Креатива");
	g_iKeyBlock[id] = true;
	return PLUGIN_HANDLED;
}
public cliet_disconnect(id) if(g_iKeyBlock[id]) g_iKeyBlock[id] = false;
public CreativeStatus(id)
{
	if(!g_iKeyBlock[id]) return PLUGIN_HANDLED;
	if(get_user_godmode(id) == 0)
	{
		set_user_godmode(id, 1);
		set_user_noclip(id, 1);
	}
	else
	{
		set_user_godmode(id, 0);
		set_user_noclip(id, 0);
	}
	return PLUGIN_HANDLED;
}
public Show_MenuUC(id)
{
	jbe_informer_offset_up(id);
	static menu[1024], len; len = 0;
	len += formatex(menu[len], charsmax(menu) - len, "Ультра Креатив^n^n");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r1\y]\w Возродить всех^n^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r2\y]\w Возродить Охранников");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r3\y]\w Возродить Заключенных^n^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r0\y]\w Выход^n^n");
	show_menu(id, (1<<0|1<<1|1<<2|1<<9), menu, -1, "Show_MenuUC");
}
public Handle_UC(id, iKey)
{
	new i = 0;
	switch(iKey)
	{
		case 0:
		{
			for(i = 1; i <= get_maxplayers(); i++)
			{
				if(jbe_get_user_team(i) == 1 || jbe_get_user_team(i) == 2) ExecuteHamB(Ham_CS_RoundRespawn, i);
			}
		}
		case 1:
		{
			for(i = 1; i <= get_maxplayers(); i++)
			{
				if(jbe_get_user_team(i) == 2) ExecuteHamB(Ham_CS_RoundRespawn, i);
			}
		}
		case 2:
		{
			for(i = 1; i <= get_maxplayers(); i++)
			{
				if(jbe_get_user_team(i) == 1) ExecuteHamB(Ham_CS_RoundRespawn, i);
			}
		}
		case 9: return;
	}
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
