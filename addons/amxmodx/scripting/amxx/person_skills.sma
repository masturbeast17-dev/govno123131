
/*-------------------*/ /*-------------------*/
#include amxmodx	 // Главное Ядро
#include amxmisc	 // Создание менюшек
#include jbe_core	 // Главное Ядро Мода
#include hamsandwich // Отлов событий
#include cstrike	 // Выдача/Установка значений
#include sqlx		 // База Данных / сохранение
#include chat		 // Отправка сообщений в чат

/*-------------------*/ /*-------------------*/

/*-------------------/ Макросы /-------------------*/

															#define		CREATE			"[U-JBL] Стата Персонажа"
															#define		BY				"vk.com/krisiso"
															#define		ToJI9IHGaa		"ToJI9IHGaa"
															
															#define SQLX_HOST			"ds4.shootline.ru"	/* < - Адресс Хостинга БД */
															#define SQLX_USER			"s2025_newserver"  /* < - Ник Админа БД */
															#define SQLX_PASS			"VKb8dWjcGCMqICR"	/* < - Пароль Админа БД */
															#define SQLX_DTBS			"s2025_newserver"	/* < - Название БД */
															
#define team(%0) jbe_get_user_team(%0)


/*----------------------*/ /*----------------------*/

/*-------------------------/ Данные для подключения к БД /----------------------------------*/
new g_sz_Host[32], g_sz_User[32], g_sz_Pass[32], g_sz_DataBase[32], g_sz_Table[32];
new Handle: g_SqlDB;
new g_iBonusExp[33], g_iNoDBExp[33];
enum _:
{
	SQL_CHECK,
	SQL_LOAD,
	SQL_IGNORE
};

/* Sets users max. speed. */
native set_user_maxspeed(index, Float:speed = -1.0);

/* Returns users max. speed. */
native Float:get_user_maxspeed(index);

/* Sets player armor. */
native set_user_armor(index, armor);

/* Sets player health. */
native set_user_health(index, health);


new g_SkillsPerson[33][5];
new const g_Force[9] =
{
	float:1.0, 
	float:1.1, 
	float:1.2, 
	float:1.3, 
	float:1.4, 
	float:1.5, 
	float:1.6, 
	float:1.8, 
	float:2.0
}; 
new const g_Protection[9] = 
{
	0, 5, 10, 15, 20, 25, 30, 55, 80
}; 
new const g_Agility[9] = 
{
	float:0.0, 
	float:3.0, 
	float:10.0, 
	float:13.0, 
	float:15.0, 
	float:20.0, 
	float:22.0, 
	float:25.0, 
	float:30.0, 
}; 
new const g_Lot[9] = 
{
	0, 5, 10, 15, 20, 30, 40, 50, 100
};

public plugin_init()
{
	register_plugin(	CREATE, BY, ToJI9IHGaa		);
	
	register_menu( "Show_SkillsMenu", (1<<0|1<<1|1<<2|1<<3|1<<9), "Handle_SkillsMenu");
	
	register_event( "CurWeapon", "HookCurWeapon", "be", "1=1" );
	
	register_clcmd( "say /ibexp", "Check_iExpBonus" );
	
	RegisterHam(Ham_Spawn, "player", "HamSpawn_Post");
	RegisterHam(Ham_Killed, "player", "UserTakeDamage");
	
	/*------/ Перенаправление /------*/
	//{
	sqlx_load_db();
	//}
	/*-------------------------------*/
}
public plugin_natives()
{
	/*---------------------*/			/*------------------------*/
	register_native( "ujbl_set_user_bonus", "ujbl_set_user_bonus", 1);
	register_native( "ujbl_get_user_bonus", "ujbl_get_user_bonus", 1);
	/*---------------------*/			/*------------------------*/
	
	/*---------------------*/			/*------------------------*/
	register_native( "ujbl_get_forse_skills", "ujbl_get_forse_skills", 1);
	register_native( "ujbl_get_protection_skills", "ujbl_get_protection_skills", 1);
	register_native( "ujbl_get_agility_skills", "ujbl_get_agility_skills", 1);
	register_native( "ujbl_get_lot_skills", "ujbl_get_lot_skills", 1);
	/*---------------------*/			/*------------------------*/
	
	register_native( "ujbl_set_skills", "ujbl_set_skills", 1);
	register_native( "jbe_open_skills_menu", "Show_SkillsMenu", 1);
}
public ujbl_get_forse_skills(id) return g_SkillsPerson[id][0];
public ujbl_get_protection_skills(id) return g_SkillsPerson[id][1];
public ujbl_get_agility_skills(id) return g_SkillsPerson[id][2];
public ujbl_get_lot_skills(id) return g_SkillsPerson[id][3];
public ujbl_set_skills(id, iType, iNum, iSv)
{
	if(g_SkillsPerson[id][iType] > 3 || g_SkillsPerson[id][iType] < 0) return;
	g_SkillsPerson[id][iType] += iNum;
	if(iSv == 1) ujbl_set_user_ibonus(id, g_SkillsPerson[id][iType] + iNum);
	return;
}
public Show_SkillsMenu(id)
{
	jbe_informer_offset_up(id);
	new iKeys = (1<<9);
	static szMenu[1023], iLen; iLen = 0;
	iLen = formatex(szMenu, charsmax(szMenu), "\yМеню Прокачки Персонажа^n\wВаши Бонусы: \r[%d]^n^n", g_iNoDBExp[id]);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1]%s Прокачать \rСилу \d[%f]\R%d lvl^n", g_iNoDBExp[id] <= 0 || g_SkillsPerson[id][0] >= 8 ? "\d":"\w", g_Force[g_SkillsPerson[id][0]], g_SkillsPerson[id][0]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2]%s Прокачать \rЗащиту \d[%d]\R%d lvl^n", (g_iNoDBExp[id] <= 0 || g_SkillsPerson[id][1] >= 8) ? "\d":"\w", g_Protection[g_SkillsPerson[id][1]], g_SkillsPerson[id][1]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3]%s Прокачать \rЛовкость \d[%f]\R%d lvl^n", (g_iNoDBExp[id] <= 0 || g_SkillsPerson[id][2] >= 8) ? "\d":"\w", g_Agility[g_SkillsPerson[id][2]], g_SkillsPerson[id][2]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4]%s Прокачать \rМассу \d[%d]\R%d lvl^n^n", (g_iNoDBExp[id] <= 0 || g_SkillsPerson[id][3] >= 8) ? "\d":"\w", g_Lot[g_SkillsPerson[id][3]], g_SkillsPerson[id][3]);
	
	for(new i; i <= 3; i++)
	{
		if(g_iNoDBExp[id] > 0 && g_SkillsPerson[id][i] < 8)
			iKeys |= (1<<i);
	}
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[0] Выход^n");
	return show_menu(id, iKeys, szMenu, -1, "Show_SkillsMenu");
}
public Handle_SkillsMenu(id, iNum)
{
	switch(iNum)
	{
		case 0:
		{
			g_iNoDBExp[id]--;
			g_SkillsPerson[id][0]++;
		}
		case 1:
		{
			g_iNoDBExp[id]--;
			g_SkillsPerson[id][1]++;
		}
		case 2:
		{
			g_iNoDBExp[id]--;
			g_SkillsPerson[id][2]++;
		}
		case 3:
		{
			g_iNoDBExp[id]--;
			g_SkillsPerson[id][3]++;
		}
		case 9: return PLUGIN_HANDLED;
	}
	Check_Limit(id);
	return PLUGIN_HANDLED;
}

public Check_Limit(id)
{
	for(new i; i <= 3; i++)
	{
		if(g_SkillsPerson[id][i] > 8) g_SkillsPerson[id][i] = 8;
	}
	return PLUGIN_HANDLED;
}
public Check_iExpBonus(id)
{
	chat(id, "!y[!gU-JBL!y] Ваш опыт прокачки персонажа в Базе Данных: %d", g_iBonusExp[id]);
	chat(id, "!y[!gU-JBL!y] Ваш опыт прокачки персонажа в игре (с учетом использованых): %d", g_iNoDBExp[id]);
}

public HookCurWeapon(id)
{
	if(jbe_get_day_mode() == 3) return;
	if(team(id))
	{
		set_user_maxspeed(id, get_user_maxspeed(id) + g_Agility[g_SkillsPerson[id][2]]);
	}
}
public HamSpawn_Post(id)
{
	set_task(3.0, "FixSapwn", id + 1141);
}
public FixSapwn(id)
{
	id -= 1141;
	if(jbe_get_day_mode() == 3) return;
	set_user_maxspeed(id, 240.0);
	if(team(id) == 1)
	{
		new hp = g_Lot[g_SkillsPerson[id][3]], 
			ar = g_Protection[g_SkillsPerson[id][1]];
		set_user_health(id, get_user_health(id) + hp);
		set_user_armor(id, get_user_armor(id) + ar);
		set_user_maxspeed(id, get_user_maxspeed(id) + g_Agility[g_SkillsPerson[id][2]]);
	}
}
public UserTakeDamage( victim, weapon, attacker, Float:damage)
{
	if(jbe_get_day_mode() == 3) return;

	if(victim == attacker || !victim) return;
	if(team(attacker) == 1) SetHamParamFloat(4, damage * g_Force[g_SkillsPerson[attacker][0]]);
}
sqlx_load_db()
{
	register_cvar( "sqlx_skills_host", 		SQLX_HOST	);	// Хост БД
	register_cvar( "sqlx_skills_user", 		SQLX_USER	);	// Ник Юзера
	register_cvar( "sqlx_skills_password", 	SQLX_PASS	);	// Пароль
	register_cvar( "sqlx_skills_database", 	SQLX_DTBS	);	// Название БД
	register_cvar( "sqlx_skills_table", 	"admins"	);	// ...
}
public plugin_cfg() set_task(1.0, "sql_connected");
public sql_connected()
{
	get_cvar_string("sqlx_skills_host", 		g_sz_Host, charsmax(g_sz_Host));
	get_cvar_string("sqlx_skills_user", 		g_sz_User, charsmax(g_sz_User));
	get_cvar_string("sqlx_skills_password", 	g_sz_Pass, charsmax(g_sz_Pass));
	get_cvar_string("sqlx_skills_database", 	g_sz_DataBase, charsmax(g_sz_DataBase));
	get_cvar_string("sqlx_skills_table", 		g_sz_Table, charsmax(g_sz_Table));
	
	// Кешируем Данные	
	g_SqlDB = SQL_MakeDbTuple(g_sz_Host, g_sz_User, g_sz_Pass, g_sz_DataBase);
	new szQuery[512], szDataNew[1];
	formatex(szQuery, charsmax(szQuery), "CREATE TABLE IF NOT EXISTS `%s` (`id` int(11) NOT NULL AUTO_INCREMENT, `authId` varchar(32) NOT NULL, `exp` int(11) DEFAULT '0', PRIMARY KEY (`id`)) ", g_sz_Table);
	szDataNew[0] = SQL_IGNORE;
	SQL_ThreadQuery(g_SqlDB, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
}

public SQL_Handler(iFailState, Handle:sqlQuery, const szError[], iError, const szData[], iDataSize)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED:
		{
			log_amx("[Skills] MySQL connection failed");
			log_amx("[ %d ] %s", iError, szError);
			if(iDataSize) log_amx("Query state: %d", szData[0]);
			return PLUGIN_HANDLED;
		}
		case TQUERY_QUERY_FAILED:
		{
			log_amx("[Skills] MySQL query failed");
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
					formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`(`authId`, `exp`) VALUES ('%s', '0')", g_sz_Table, szAuth);
					szDataNew[0] = SQL_IGNORE;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_SqlDB, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
				default:
				{
					new szAuth[32], szQuery[128], szDataNew[2];
					get_user_authid(id, szAuth, charsmax(szAuth));
					formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`(`authId`, `exp`) VALUES ('%s', '0')", g_sz_Table, szAuth);
					szDataNew[0] = SQL_LOAD;
					szDataNew[1] = id;
					SQL_ThreadQuery(g_SqlDB, "SQL_Handler", szQuery, szDataNew, sizeof szDataNew);
				}
			}
		}
		case SQL_LOAD:
		{
			new id = szData[1];
			if(!is_user_connected(id)) return PLUGIN_HANDLED;
			new ibonus = SQL_ReadResult(sqlQuery, 0);
			ujbl_set_user_ibonus(id, ibonus, .bMessage = false, .bSql = false);
		}
	}
	return PLUGIN_HANDLED;
}

ujbl_set_user_ibonus(id, iBonus, bool:bMessage = true, bool:bSql = true)
{
	if(bMessage) chat(id, "!y[!gJBE!y] Ваши !gБонус очки обновились на!y: !g%d", iBonus);
	g_iBonusExp[id] = iBonus;
	g_iNoDBExp[id] += g_iBonusExp[id];
	
	if(bSql)
	{
		new szAuth[32], szQuery[128], szData[2];
		get_user_authid(id, szAuth, charsmax(szAuth));
		formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`(`authId`, `exp`) VALUES ('%s', '0')", g_sz_Table, szAuth);
		szData[0] = SQL_IGNORE;
		szData[1] = id;
		SQL_ThreadQuery(g_SqlDB, "SQL_Handler", szQuery, szData, sizeof szData);
	}
}

public client_putinserver(id)
{ 
	new szAuth[32];
	get_user_authid(id, szAuth, charsmax(szAuth));
	if(equal(szAuth, "ID_PENDING") ||  equal(szAuth, "STEAM_ID_LAN") ||  equal(szAuth, "VALVE_ID_LAN"))
	{
		new szAuth[32], szQuery[128];
		get_user_authid(id, szAuth, charsmax(szAuth));
		formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`(`authId`, `exp`) VALUES ('%s', '0')", g_sz_Table, szAuth);
	}
	else set_task(1.0, "load_bonus", id + 1245);
	return PLUGIN_HANDLED;
}
public client_disconnect(id)
{
	g_iNoDBExp[id] = 0;
	for(new i; i <= 4; i++)
	{
		g_SkillsPerson[id][i] = 0;
	}
}
public load_bonus(pPlayer)
{
	pPlayer -= 1245;
	new szAuth[32], szQuery[128], szData[2];
	get_user_authid(pPlayer, szAuth, charsmax(szAuth));
	formatex(szQuery, charsmax(szQuery), "INSERT INTO `%s`(`authId`, `exp`) VALUES ('%s', '0')", g_sz_Table, szAuth);
	szData[0] = SQL_CHECK;
	szData[1] = pPlayer;
	SQL_ThreadQuery(g_SqlDB, "SQL_Handler", szQuery, szData, sizeof szData);
}
public ujbl_set_user_bonus(id, iNum) ujbl_set_user_ibonus(id, iNum);
public ujbl_get_user_bonus(id) return g_iBonusExp[id];