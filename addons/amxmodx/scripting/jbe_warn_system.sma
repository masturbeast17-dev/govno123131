#include amxmodx
#include amxmisc
#include jbe_core
#include fakemeta
#include sqlx

#define	CREATE				"[JBE] Warn System"
#define	BY					"vk.com/krisiso"
#define ToJI9IHGaa			"ToJI9IHGaa"


/* -> Бит сумм -> */
#define SetBit(%0,%1) 		((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) 	((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) 	((%0) & (1 << (%1)))
#define InvertBit(%0,%1) 	((%0) ^= (1 << (%1)))
#define IsNotSetBit(%0,%1)  (~(%0) & (1 << (%1)))

#define MAX_PLAYERS 32
#define PLAYERS_PER_PAGE 8
#define NINENUM (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)

#define TASK_RANK_UPDATE_EXP 		123451	// Индекс Таска
#define TASK_RANK_UPDATE_UNVALID 	12351	// Индекс Таска

// БД
new Handle:g_sqlTuple, g_szWarnHost[32], g_szWarnUser[32], g_szWarnPassword[32], g_szWarnDataBase[32], g_szWarnTable[32];
enum _:TYPE_WARN
{
	SQL_CHECK,
	SQL_LOAD,
	SQL_IGNORE
};

/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS], g_iMenuPosition[MAX_PLAYERS + 1];

new g_Reason[33];

new g_iAdmin, g_iRconAdmin, g_iPlayer, g_iWarn[ MAX_PLAYERS ], g_Status[ MAX_PLAYERS ], g_iMaxPlayers;

public plugin_init()
{
	register_plugin(	CREATE, BY, ToJI9IHGaa		);
	
	g_iMaxPlayers = get_maxplayers();
	
	clcmd_init();
	menu_init()
	cvars_init()
}

/*========================================================================== Иниты =========================================================================================*/
clcmd_init()
{
	register_clcmd(		"say /warn", "Show_WarnMenu"	);
	register_clcmd(		"amx_warn", "Show_WarnMenu"	);
	register_clcmd(		"warn", "Show_WarnMenu"	);
	
	register_clcmd(		"say /unwarn", "UnWarnCheck"	);
	register_clcmd(		"amx_unwarn", "UnWarnCheck"	);
	register_clcmd(		"unwarn", "UnWarnCheck"	);	
	
	register_clcmd(		"Reason_Warned", "Say_To_Text"	);
	register_clcmd(		"Причина_Варна", "Say_To_Text"	);
}

cvars_init()
{
	register_cvar( "warn_sql_host", 		"ds4.shootline.ru"	);	// Хост БД
	register_cvar( "warn_sql_user", 		"s2025_warns"		);	// Ник Юзера
	register_cvar( "warn_sql_password", 	"67934546mozilka"	);	// Пароль
	register_cvar( "warn_sql_database", 	"s2025_warns"		);	// Название БД
	register_cvar( "warn_sql_table", 		"admins"			);	// ...
}

menu_init()
{	
	register_menu(		"Show_WarnMenu", (1<<0|1<<1|1<<2|1<<3|1<<9), "Handle_WarnMenu"		);	
	register_menu(		"Show_WarnPlayers", NINENUM, "Handle_WarnPlayers"		);
}
/*==========================================================================================================================================================================*/

public UnWarnCheck(id) UTIL_SayText(id, "!y[!gSERVER!y] У Вас !g%d!y варнов", g_iWarn[id]);
public Show_WarnMenu(id)
{
	if(IsNotSetBit(g_iAdmin, id)) return PLUGIN_HANDLED;
	
	static menu[2014], len; len = 0;
	
	new iKeys = (1<<0|1<<1|1<<9);
	
	len = formatex(menu[len], charsmax(menu) - len, "\yПанель выдачи \rВарнов^n^n");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r1\y]%s Выдать \rWarn \d[\rИгроку\d]^n", g_iAdmin ? "\w":"\d");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r2\y]%s Снять \rWarn \d[\rИгроку\d]^n^n", g_iAdmin ? "\w":"\d");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r3\y]%s Выдать \raWarn \d[\rАдмину\d]^n", g_iRconAdmin ? "\w":"\d");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r4\y]%s Снять \raWarn \d[\rАдмину\d]^n^n", g_iRconAdmin ? "\w":"\d");
	
	if(IsSetBit(g_iRconAdmin, id)) iKeys |= (1<<2|1<<3);
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r0\y]\w Выход");
	show_menu(id, iKeys, menu, -1, "Show_WarnMenu"); return PLUGIN_HANDLED;
}

public Handle_WarnMenu(id, pKey)
{
	switch(pKey)
	{
		case 0: 
		{
			g_Status[id] = 1;
			Format_g_Reason(id);
		}
		case 1: 
		{
			g_Status[id] = 2;
			Formatex_PlayerList(id);
		}
		case 2: 
		{
			g_Status[id] = 3;
			Format_g_Reason(id);
		}
		case 3:
		{
			g_Status[id] = 4;
			Formatex_PlayerList(id);
		}
	}
}

public Format_g_Reason(id)
{
	client_cmd(id, "messagemode Reason_Warned");
	return PLUGIN_HANDLED;
}

public Say_To_Text(id)
{
	new Args[69];
	read_args(Args, charsmax(Args));
	remove_quotes(Args);

	if(strlen( Args ) == 0)
	{
		UTIL_SayText(id, "!y[!gU-JBL!y] !yПустое значение !tневозможно");
		return PLUGIN_HANDLED;
	}
	formatex(g_Reason, charsmax(g_Reason), Args);
	return Formatex_PlayerList(id);
}

Formatex_PlayerList(id) return Show_WarnPlayers(id, g_iMenuPosition[id] = 0);
Show_WarnPlayers(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		switch(g_Status[id])
		{
			case 1: if(IsSetBit(g_iPlayer, i)) g_iMenuPlayers[id][iPlayersNum++] = i;	
			case 2: if(IsSetBit(g_iPlayer, i) && g_iWarn[i] > 0) g_iMenuPlayers[id][iPlayersNum++] = i;
			case 3: if(IsSetBit(g_iAdmin, i) && IsNotSetBit(g_iRconAdmin, i)) g_iMenuPlayers[id][iPlayersNum++] = i;
			case 4: if(IsSetBit(g_iAdmin, i) && g_iWarn[i] > 0 && IsNotSetBit(g_iRconAdmin, i)) g_iMenuPlayers[id][iPlayersNum++] = i;
		}
	}
	new iStart = iPos * PLAYERS_PER_PAGE;
	if(iStart > iPlayersNum) iStart = iPlayersNum;
	
	iStart = iStart - (iStart % 8);
	g_iMenuPosition[id] = iStart / PLAYERS_PER_PAGE;
	new iEnd = iStart + PLAYERS_PER_PAGE;
	if(iEnd > iPlayersNum) iEnd = iPlayersNum;
	new szMenu[1024], iLen, iPagesNum = (iPlayersNum / PLAYERS_PER_PAGE + ((iPlayersNum % PLAYERS_PER_PAGE) ? 1 : 0));
	switch(iPagesNum)
	{
		case 0:
		{
			UTIL_SayText(id, "!y[!gU-JBL!y]!y Подходящих игроков нету.");
			return Show_WarnMenu(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\yМеню %s варна \w[%d|%d]^n^n", (g_Status[id] == 2 || g_Status[id] == 4) ? "снятия": "выдачи", iPos + 1, iPagesNum);
	}
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\y%d\r] \w%s \d[%d]^n", ++b, szName, g_iWarn[i]);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \wДальше^n\r[\y0\r] \w%L", iPos ? "Назад" : "Выход");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Назад" : "Выход");
	return show_menu(id, iKeys, szMenu, -1, "Show_WarnPlayers");
}

public Handle_WarnPlayers(id, iKey)
{
	switch(iKey)
	{
		case 8: return Show_WarnPlayers(id, ++g_iMenuPosition[id]);
		case 9: return Show_WarnPlayers(id, --g_iMenuPosition[id]);
		default:
		{
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(is_user_connected(iTarget))
			{
				new Name[32], iAdminName[32];
				get_user_name(iTarget, Name, 33);
				get_user_name(id, iAdminName, 33);
				switch(g_Status[id])
				{
					case 1:
					{
						rejbe_set_user_warn(iTarget, g_iWarn[iTarget] += 1);
						UTIL_SayText(0, "!y[!gU-JBL!y] !gАдминистратор !t%s!y дал !gWARN!y игроку !g%s. !t[%d/3] !y| Причина: !g%s", iAdminName, Name, g_iWarn[iTarget], g_Reason);
						log_to_file("addons/amxmodx/logs/WARN.txt", "[WARN] Админ %s дал варн %s. Причина: %s", iAdminName, Name, g_Reason);
						if(g_iWarn[iTarget] >= 3)
						{
							rejbe_set_user_warn(iTarget, 0);
							UTIL_SayText(0, "!y[!gU-JBL!y] Игрок !g%s!y получил бан на !g4 дня.!y Причина: !gВарны [3/3]", Name);
							server_cmd("amx_ban 4320 ^"%s^" WARN", Name) 
						}else server_cmd("kick #%d ^"Админ %s дал Вам Варн. %s^"", get_user_userid(iTarget), iAdminName, g_Reason) 
					}
					case 2:
					{
						rejbe_set_user_warn(iTarget, g_iWarn[iTarget] -= 1);
						UTIL_SayText(0, "!y[!gU-JBL!y] !gАдминистратор !t%s!y снял !gWARN!y игроку !g%s", iAdminName, Name);
						log_to_file("addons/amxmodx/logs/WARN.txt", "[WARN] Админ %s снял варн %s", iAdminName, Name);
					}
					case 3:
					{
						rejbe_set_user_warn(iTarget, g_iWarn[iTarget] += 1);
						UTIL_SayText(0, "!y[!gU-JBL!y] !gГлавный Администратор !t%s!y дал !g[a]WARN!y Администратору !g%s. !t[%d/3] !y| Причина: !g%s", iAdminName, Name, g_iWarn[iTarget], g_Reason);
						log_to_file("addons/amxmodx/logs/WARN.txt", "[WARN] Глав.Админ %s дал варн админу %s. Причина: %s", iAdminName, Name, g_Reason);
						if(g_iWarn[iTarget] >= 3)
						{
							rejbe_set_user_warn(iTarget, 0);
							UTIL_SayText(0, "!y[!gU-JBL!y] Игрок !g%s!y получил бан на !g4 дня.!y Причина: !gВарны [3/3]", Name);
							server_cmd("amx_ban 4320 ^"%s^" WARN", Name) 
						}else server_cmd("kick #%d ^"Админ %s дал Вам Варн. %s^"", get_user_userid(iTarget), iAdminName, g_Reason)
					}
					case 4:
					{
						rejbe_set_user_warn(iTarget, g_iWarn[iTarget] -= 1);
						UTIL_SayText(0, "!y[!gU-JBL!y] !gГлавный Администратор !t%s!y снял !g[a]WARN!y Администратору !g%s", iAdminName, Name);
						log_to_file("addons/amxmodx/logs/WARN.txt", "[WARN] Глав.Админ %s снял варн админу %s", iAdminName, Name);
					}
				}
			}
		}
	}
	return PLUGIN_HANDLED;
}

stock UTIL_SayText(pPlayer, const szMessage[], any:...)
{
	new szBuffer[190];
	if(numargs() > 2) vformat(szBuffer, charsmax(szBuffer), szMessage, 3);
	else copy(szBuffer, charsmax(szBuffer), szMessage);
	while(replace(szBuffer, charsmax(szBuffer), "!y", "^1")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!t", "^3")) {}
	while(replace(szBuffer, charsmax(szBuffer), "!g", "^4")) {}
	switch(pPlayer)
	{
		case 0:
		{
			for(new iPlayer = 1; iPlayer <= g_iMaxPlayers; iPlayer++)
			{
				if(!is_user_connected(iPlayer)) continue;
				engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, 76, {0.0, 0.0, 0.0}, iPlayer);
				write_byte(iPlayer);
				write_string(szBuffer);
				message_end();
			}
		}
		default:
		{
			engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, 76, {0.0, 0.0, 0.0}, pPlayer);
			write_byte(pPlayer);
			write_string(szBuffer);
			message_end();
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public plugin_natives()
{
	register_native( "jbe_set_users_warn", "jbe_set_users_warn", 1);
	register_native( "jbe_get_user_warn", "jbe_get_user_warn", 1);
}
public plugin_cfg() set_task(0.1, "update_db");
public update_db()
{
	get_cvar_string("warn_sql_host", g_szWarnHost, charsmax(g_szWarnHost));
	get_cvar_string("warn_sql_user", g_szWarnUser, charsmax(g_szWarnUser));
	get_cvar_string("warn_sql_password", g_szWarnPassword, charsmax(g_szWarnPassword));
	get_cvar_string("warn_sql_database", g_szWarnDataBase, charsmax(g_szWarnDataBase));
	get_cvar_string("warn_sql_table", g_szWarnTable, charsmax(g_szWarnTable));
	g_sqlTuple = SQL_MakeDbTuple(g_szWarnHost, g_szWarnUser, g_szWarnPassword, g_szWarnDataBase);
	new szQuery[512], szDataNew[1];
	formatex(szQuery, charsmax(szQuery), "CREATE TABLE IF NOT EXISTS `%s` (`id` int(11) NOT NULL AUTO_INCREMENT, `authId` varchar(32) NOT NULL, `exp` int(11) DEFAULT '0', PRIMARY KEY (`id`)) ", g_szWarnTable);
	szDataNew[0] = SQL_IGNORE;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
}

public SQL_Handler(iFailState, Handle:sqlQuery, const szError[], iError, const szData[], iDataSize)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("[WARN] MySQL connection failed");
			log_amx("[ %d ] %s", iError, szError);
			if(iDataSize) log_amx("Query state: %d", szData[0]);
			return PLUGIN_HANDLED;
		}
		case TQUERY_QUERY_FAILED:
		{
			log_amx("[WARN] MySQL query failed");
			log_amx("[ %d ] %s", iError, szError);
			if(iDataSize) log_amx("Query state: %d", szData[1]);
			return PLUGIN_HANDLED;
		}
	}
	switch(szData[0])
	{
		case SQL_CHECK:
		{
			new id = szData[1];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			switch(SQL_NumResults(sqlQuery))
			{
				case 0:
				{
					new szAuth[32], szQuery[128], szDataNew[2];
					get_user_authid(id, szAuth, charsmax(szAuth));
					formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`(`authId`, `exp`) VALUES ('%s', '0')", g_szWarnTable, szAuth);
					szDataNew[0] = SQL_IGNORE;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
				default:
				{
					new szAuth[32], szQuery[128], szDataNew[2];
					get_user_authid(id, szAuth, charsmax(szAuth));
					formatex(szQuery, charsmax(szQuery),"SELECT `exp` FROM `%s` WHERE `authId` = '%s'", g_szWarnTable, szAuth);
					szDataNew[0] = SQL_LOAD;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
			}
		}
		case SQL_LOAD:
		{
			new id = szData[1];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			new iWarn = SQL_ReadResult(sqlQuery, 0);
			rejbe_set_user_warn(id, iWarn, .bMessage = false, .bSql = false);
		}
	}
	return PLUGIN_HANDLED;
}

rejbe_set_user_warn(id, iWarn, bool:bMessage = true, bool:bSql = true)
{
	if(bMessage) UTIL_SayText(id, "!y[!gJBE!y] Ваши !gВарны!y: !g%d", iWarn);
	g_iWarn[id] = iWarn;
	if(bSql)
	{
		new szAuth[32], szQuery[128], szData[2];
		get_user_authid(id, szAuth, charsmax(szAuth));
		formatex(szQuery, charsmax(szQuery), "UPDATE `%s` SET `exp`='%d' WHERE `authId` = '%s';", g_szWarnTable, g_iWarn[id], szAuth);
		szData[0] = SQL_IGNORE;
		szData[1] = id;
		SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szData, sizeof szData);
	}
}

public jbe_get_user_warn(id) return g_iWarn[id];
public jbe_set_users_warn(id, iNum) rejbe_set_user_warn(id, iNum);	// Быдлокодим пацаны :C

public client_putinserver(id)
{ 
	if(get_user_flags(id) & ADMIN_BAN)
	{
		SetBit(g_iAdmin, id);
		if(get_user_flags(id) & ADMIN_RCON) SetBit(g_iRconAdmin, id);		
	}else SetBit(g_iPlayer, id);
	
	new szAuth[32];
	get_user_authid(id, szAuth, charsmax(szAuth));
	if(equal(szAuth, "ID_PENDING") ||  equal(szAuth, "STEAM_ID_LAN") ||  equal(szAuth, "VALVE_ID_LAN")) set_task(100.0, "jbe_rank_update_unvalid", id + TASK_RANK_UPDATE_UNVALID, _, _, "b");
	else set_task(1.0, "jbe_rank_update_exp", id + TASK_RANK_UPDATE_EXP);
}
public jbe_rank_update_unvalid(pPlayer)
{
	pPlayer -= TASK_RANK_UPDATE_UNVALID;
	UTIL_SayText(pPlayer, "!y[!gJBE!y]!g WARN!y не сохранены");
}
public jbe_rank_update_exp(pPlayer)
{
	pPlayer -= TASK_RANK_UPDATE_EXP;
	new szAuth[32], szQuery[128], szData[2];
	get_user_authid(pPlayer, szAuth, charsmax(szAuth));
	formatex(szQuery, charsmax(szQuery), "SELECT * FROM `%s` WHERE `authId` = '%s'", g_szWarnTable, szAuth);
	szData[0] = SQL_CHECK;
	szData[1] = pPlayer;
	SQL_ThreadQuery(g_sqlTuple, "SQL_Handler", szQuery, szData, sizeof szData);
}
public client_disconnect(id) 
{
	if(task_exists(id+TASK_RANK_UPDATE_UNVALID)) remove_task(id+TASK_RANK_UPDATE_UNVALID);
	if(task_exists(id+129874)) remove_task(id+129874);
	if(IsSetBit(g_iAdmin, id))
	{
		ClearBit(g_iAdmin, id);
		if(IsSetBit(g_iRconAdmin, id)) ClearBit(g_iRconAdmin, id);
	}else ClearBit(g_iPlayer, id);
}
