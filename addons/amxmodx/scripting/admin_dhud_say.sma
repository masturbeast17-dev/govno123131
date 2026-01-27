#include amxmodx
#include amxmisc
#include dhudmessage

#define MAX_PLAYER 32

new g_iType[MAX_PLAYER + 1];
new g_iSyncHud;
new g_Values[10][] = {{255, 255, 255}, {255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {227, 96, 8}, {45, 89, 116}, {103, 44, 38}};
new Float:g_Pos[5][] = {{-1.0, -1.0}, {-1.0, 0.3}, {-1.0, 0.75}, {0.15,-1.0}, {0.55, -1.0}};
public plugin_init()
{
	register_plugin("[REMAKE] Admin DHUD & HUD message", "krisiso", "ToJI9IHGaa");
	g_iSyncHud = CreateHudSyncObj();
	register_clcmd("say", "MSG_SayAdmin");
	register_clcmd("say /achat", "MSG_SayAChat");
	register_clcmd("ADMIN_CHAT_ARG", "Achat_Cmd");
}
public MSG_SayAChat(id) client_cmd(id, "messagemode ADMIN_CHAT_ARG");
public Achat_Cmd(id)
{
	new message[192];
	read_args(message, 191);
	remove_quotes(message);
	new sName[32];
	get_user_name(id, sName, charsmax(sName));
	for(new i = 1; i <= get_maxplayers(); i++)
		if(is_user_admin(i))
			chat(i, "!y[!gАдмин-Чат!y] | [!g%s!y]: !t%s", sName, message);
}
public MSG_SayAdmin(id)
{
	if(is_user_admin(id))
	{
		new said[3];
		read_argv(1, said, 5);
		
		new message[192], a = 0, c = 0;
		read_args(message, 191);
		remove_quotes(message);
		
		switch(said[0])
		{
			case 'd': g_iType[id] = 1;
			case 'h': g_iType[id] = 2;
		}
		if(g_iType[id] > 0)
		{
			switch(said[1])
			{
				case 'r': a = 1
				case 'g': a = 2
				case 'b': a = 3
				case 'y': a = 4
				case 'm': a = 5
				case 'c': a = 6
				case 'o': a = 7
			}
			switch(said[2])
			{
				case 'u': c = 1
				case 'd': c = 2
				case 'l': c = 3
				case 'r': c = 4
			}
			new sName[32];
			get_user_name(id, sName, charsmax(sName));
			switch(g_iType[id])
			{
				case 1:
				{
					clear_dhud(id);
					set_dhudmessage(g_Values[a][0], g_Values[a][1], g_Values[a][2],  g_Pos[c][0], g_Pos[c][1],    0, 0.0, 10.0, 0.2, 2.0, false);
					show_dhudmessage(0, "[%s] %s", sName, message[3]);			
				}
				case 2:
				{
					clear_dhud(id);
					set_hudmessage(g_Values[a][0], g_Values[a][1], g_Values[a][2],  g_Pos[c][0], g_Pos[c][1],  0, 0.0, 10.0, 0.2, 2.0, -1);
					ShowSyncHudMsg(0, g_iSyncHud, "[%s] %s", sName, message[3]);
				}
			}
			g_iType[id] = 0;
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

stock clear_dhud(id) for (new iDHUD = 0; iDHUD < 8; iDHUD++) show_dhudmessage(id, "");
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

