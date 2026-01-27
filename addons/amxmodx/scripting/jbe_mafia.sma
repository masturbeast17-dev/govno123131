#include amxmodx
#include jbe_core
#include hamsandwich
#include amxmisc
#include fakemeta

#define CREATE				"[ReJBE] MAFIA"
#define FOR					"krisiso"
#define YULIA_NYASHA		"ToJI9IHGaa"

//#define NATIVE_OPEN_MENU		// Открываем нативом или /mafia ? (Нативом - не комментируй, командой - комментируй)

/******************************************************/
#define MAX_PLAYERS 32
#define PLAYERS_PER_PAGE 8
#define FOURNUM (1<<0|1<<1|1<<2|1<<3|1<<9)
#define NINENUM (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
#define TASK_SHOW_MAFIA_INF 1234124
/******************************************************/



native jbe_mafia_start();		// В моде шаманим выключение информеров и Статус Валуе
native jbe_mafia_end();			// В моде шаманим включание информеров и Статус Валуе


/*################################################################################################################################################*/
// ----------------------- ПЕРЕМЕННЫЕ, МАССИВЫ И Т.Д, >>>
new g_DonID, g_CommissarID, g_DoctorID, g_ManiacID, g_CourtesanID, // Дон, Комиссар, Доктор, Маньяк
	sz_DonName[32], sz_CommissarName[32], sz_DocName[32], sz_ManiacName[32], sz_CourtesanName[32], sz_YouStatus[32][33],
	bool:g_Mafia[ MAX_PLAYERS + 1 ], bool:g_Villager[ MAX_PLAYERS + 1 ], 	// Мафиози, Житель
	g_MaxMafiozi = 10, g_Mafiozi, g_VilligerMax, g_StatusValue_plID;	// Максимум Мафиози и Максимум Куртизанок
	
new bool:g_DayMode, 						// День|Ночь
	bool:g_MafiaStatus, 					// Игра Мафия: Включена|Выключена
	bool:g_Freezie[MAX_PLAYERS + 1],		// Переключатель: Заморожен|Разморожен
	g_iInformerMafia, g_iSynStatusValue, 	// Размеры для информеров
	g_StatusPlMenu[MAX_PLAYERS + 1],		// Для генерации меню (Чтобы не создавать по 100 менюх)
	g_iMaxPlayers,							// Перемённая которая хранит в себе Максимальное кол-во слотов
	g_BugFixer_Freezie[ MAX_PLAYERS + 1 ];	// Огран. на 5 сек к меню заморозки чтобы не ложили сервер массовым циклом.

new g_ReMark[5][33], g_ReMark_GiveStatus[33], g_RemarkStatus[33];
	
/* -> Массивы для меню из игроков -> */
new g_iMenuPlayers[ MAX_PLAYERS + 1 ][ MAX_PLAYERS ], g_iMenuPosition[ MAX_PLAYERS + 1 ];

/*################################################################################################################################################*/



public plugin_init()
{
	register_plugin(	CREATE, FOR, YULIA_NYASHA	);
	
	/* --- Суем в переменные --- */
	g_iInformerMafia = CreateHudSyncObj();
	g_iSynStatusValue = CreateHudSyncObj();
	g_iMaxPlayers = get_maxplayers();
	
	#if !defined NATIVE_OPEN_MENU
	register_clcmd(	"say /mafia", "Show_MafiaMenu"	);
	#endif
	
	register_clcmd( "remark_mafia", "Bool_ReMarkMafia"	);
	
	/* --- Ham / Event / Menu --- */
	ham_init();
	event_init();
	menu_init();
}

ham_init()
{
	RegisterHam(Ham_Spawn, "player", "Ham_PlayerSpawn_Post", true);
	RegisterHam(Ham_Killed, "player", "fw_HamKilled", true)
}

event_init()
{
	register_event("StatusValue", "player_status", "be", "1=2", "2!0");
	register_logevent("LogEvent_RoundEnd", 2, "1=Round_End");
}

menu_init()
{
	register_menu(		"Show_MafiaMenu", (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_MafiaMenu"		);
	register_menu(		"Show_FreezieMenu", FOURNUM, "Handle_FreezieMenu"		);
	
	register_menu(		"Show_RolePlayMenu", (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<9), "Handle_RolePlayMenu"		);
	
	register_menu(		"Show_RoleList", NINENUM, "Handle_PlayersList"		);
	register_menu(		"Show_FrList", NINENUM, "Handle_FrPlayersList"		);
	
	register_menu(		"Show_ReMarkMenu", (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9), "Handle_ReMarkMenu"		);
}



/*#################################################################################################################################*/
//; ------------------------- НАТИВЫ >>>
public plugin_natives() 
{
	#if defined NATIVE_OPEN_MENU	
	register_native(	"jbe_open_mafia_menu", "jbe_open_mafia_menu", 1		);							// Натив на открытие менюхи
	#endif
	
	register_native(	"jbe_mafia_get_don_id", "jbe_mafia_get_don_id", 1		);						// Возвращает индекс Лидера Мафии
	register_native(	"jbe_mafia_get_doctor_id", "jbe_mafia_get_doctor_id", 1		);					// Возвращает индекс Доктор
	register_native(	"jbe_mafia_get_maniac_id", "jbe_mafia_get_maniac_id", 1		);					// Возвращает индекс Маньяка
	register_native(	"jbe_mafia_get_commissar_id", "jbe_mafia_get_commissar_id", 1		);			// Возвращает индекс Комиссара
	
	register_native(	"jbe_mafia_is_user_villiger", "jbe_mafia_is_user_villiger", 1		);			// Возвращает true если игрок Житель
	register_native(	"jbe_mafia_get_courtesan_id", "jbe_mafia_get_courtesan_id", 1		);			// Возвращает true если игрок Куртизанка
	register_native(	"jbe_mafia_is_user_mafia", "jbe_mafia_is_user_mafia", 1		);					// Возвращает true если игрок Мафиози
	
	register_native(	"jbe_mafia_get_day", "jbe_mafia_get_day", 1		);								// Возвращает true если включена игра
	register_native(	"jbe_mafia_get_freezie_status", "jbe_mafia_get_freezie_status", 1		);		// Возвращает true если игрок заморожен
	register_native(	"jbe_mafia_set_freezie", "jbe_mafia_set_freezie", 1		);						// Устанавливает заморозку
}

#if defined NATIVE_OPEN_MENU
public jbe_open_mafia_menu(id) Show_MafiaMenu(id);
#endif

public jbe_mafia_get_don_id() return g_DonID;
public jbe_mafia_get_doctor_id() return g_DoctorID;
public jbe_mafia_get_maniac_id() return g_ManiacID;
public jbe_mafia_get_commissar_id() return g_CommissarID;
public jbe_mafia_get_courtesan_id() return g_CommissarID;

public bool:jbe_mafia_is_user_villiger(id)
{
	if(g_Villager[id]) return true;
	return false;
}
public bool:jbe_mafia_is_user_mafia(id)
{
	if(g_Mafia[id]) return true;
	return false;
}
public bool:jbe_mafia_get_day(id)
{
	if(g_DayMode) return true;
	return false;
}
public bool:jbe_mafia_get_freezie_status(id)
{
	if(g_Freezie[id]) return true;
	return false;
}
public jbe_mafia_set_freezie(id, iType)
{
	switch(iType)
	{
		case 0:
		{
			g_Freezie[id] = false;
			unfreezie_end(id);
		}
		case 1:
		{
			g_Freezie[id] = true;
			freezie_start(id);
		}
		default: server_cmd("[MAFIA] Error native (jbe_mafia): jbe_mafia_set_freezie(id, iType) - Указан неверно.");
	}
}
/*#################################################################################################################################*/

public Bool_ReMarkMafia(id)
{
	switch(g_RemarkStatus[id])
	{
		case true: 
		{
			g_RemarkStatus[id] = false;
			UTIL_SayText(id, "!y[!gMAFIA!y] Вы !tвыключили !gметки!y для !tзеков");
		}
		case false: 
		{
			g_RemarkStatus[id] = true;
			UTIL_SayText(id, "!y[!gMAFIA!y] Вы !tвключили !gметки!y для !tзеков");
		}
	}
}

public LogEvent_RoundEnd()
{
	if(g_MafiaStatus)
	{
		jbe_mafia_end();
				
		g_CommissarID = 0;
		g_DoctorID = 0;
		g_DonID = 0;
		g_ManiacID = 0;
		g_CourtesanID = 0;
		
		sz_CommissarName = "Не выбран";
		sz_CourtesanName = "Не выбрана";
		sz_DocName = "Не выбран";
		sz_DonName = "Не выбран";
		sz_ManiacName = "Не выбран";
		
		
		for(new id; id <= get_maxplayers(); id++)
		{
			g_Mafia[id] = false;
			g_Villager[id] = false;
		}
		g_MaxMafiozi = 0;
		g_MafiaStatus = false;
		for(new id; id <= g_iMaxPlayers; id++) remove_task(id + TASK_SHOW_MAFIA_INF);
		message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
		write_byte(0);  // Red
		write_byte(0);  // Green
		write_byte(0);  // Blue
		write_byte(0); 	// SD
		write_byte(0);  // ED
		write_byte(0);  // D1
		write_byte(0);  // D2
		message_end();
		g_DayMode = false;
	}
}

public player_status(id)
{
	if(!g_MafiaStatus) return PLUGIN_HANDLED;
	new pplayer = read_data(2);
	
	new name[32]; 
	get_user_name(pplayer, name, charsmax(name));

	if(id == jbe_get_chief_id() && g_RemarkStatus[id])
	{
		set_hudmessage(102, 69, 0, -1.0, 0.8, 0, 0.0, 4.0, 0.0, 0.0, -1);
		switch(jbe_get_user_team(pplayer))
		{
			case 1, 3, 4: 
			{
				ShowSyncHudMsg(id, g_iSynStatusValue, "Ник:[%s]^nХП: %d | Броня: %d^nКласс: %s", name, get_user_health(pplayer), get_user_armor(pplayer), sz_YouStatus[pplayer]);
				g_StatusValue_plID = pplayer;
				Show_ReMarkMenu(id);
			}
			case 2: ShowSyncHudMsg(id, g_iSynStatusValue, "Ник:[%s]^nХП: %d | Броня: %d", name, get_user_health(pplayer), get_user_armor(pplayer));
	
		}
		
	}else
	{
		switch(jbe_get_user_team(id))
		{
			case 1, 3, 4: 
			{
				set_hudmessage(102, 69, 0, -1.0, 0.8, 0, 0.0, 4.0, 0.0, 0.0, -1);
				ShowSyncHudMsg(id, g_iSynStatusValue, "Ник:[%s]^nХП: %d | Броня: %d", name, get_user_health(pplayer), get_user_armor(pplayer));
			}
			case 2:	// Кейс в Кейсе - Гуру скриптинг :D
			{
				set_hudmessage(102, 69, 0, -1.0, 0.8, 0, 0.0, 4.0, 0.0, 0.0, -1);
				switch(jbe_get_user_team(pplayer))
				{
					case 1: ShowSyncHudMsg(id, g_iSynStatusValue, "Ник:[%s]^nХП: %d | Броня: %d^nКласс: %s", name, get_user_health(pplayer), get_user_armor(pplayer), sz_YouStatus[pplayer]);
					case 2: ShowSyncHudMsg(id, g_iSynStatusValue, "Ник:[%s]^nХП: %d | Броня: %d^n", name, get_user_health(pplayer), get_user_armor(pplayer));
				}
			}
		}
	}
	return PLUGIN_HANDLED;
}
public Show_ReMarkMenu(id)
{
	static menu[1024], len; len = 0;
	new iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9);
	new Names[32];
	get_user_name(g_StatusValue_plID, Names, charsmax(Names));
	
	len = formatex(menu[len], charsmax(menu) - len, "\yМеню выдачи метки^n\wИгрок: %s^n^n", Names);
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r1\y]\w Метка \rДона: \y%d^n", g_ReMark[0][g_StatusValue_plID]);
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r2\y]\w Метка \rКомиссара: \y%d^n", g_ReMark[1][g_StatusValue_plID]);
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r3\y]\w Метка \rДоктора: \y%d^n", g_ReMark[2][g_StatusValue_plID]);
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r4\y]\w Метка \rМаньяка: \y%d^n", g_ReMark[3][g_StatusValue_plID]);
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r5\y]\w Метка \rКуртизанки: \y%d^n^n", g_ReMark[4][g_StatusValue_plID]);
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r6\y]\w Функция: %s^n^n", g_ReMark_GiveStatus[id] ? "Выдать метку": "Забрать метку");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r7\y]\w Сброс всех \yметок\w на \r'0'^n^n");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r0\y]\w Выход^n^n");
	
	show_menu(id, iKeys, menu, -1, "Show_ReMarkMenu");
}
public Handle_ReMarkMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			switch(g_ReMark_GiveStatus[id])
			{
				case true: g_ReMark[0][g_StatusValue_plID]++;
				case false:
				{
					if(g_ReMark[0][g_StatusValue_plID] < 0)
					{
						Show_ReMarkMenu(id);
						return PLUGIN_HANDLED;
					}else g_ReMark[0][g_StatusValue_plID]--;
				}
			}
		}
		case 1:
		{
			switch(g_ReMark_GiveStatus[id])
			{
				case true: g_ReMark[1][g_StatusValue_plID]++;
				case false:
				{
					if(g_ReMark[1][g_StatusValue_plID] < 0)
					{
						Show_ReMarkMenu(id);
						return PLUGIN_HANDLED;
					}else g_ReMark[1][g_StatusValue_plID]--;
				}
			}
		}
		case 2:
		{
			switch(g_ReMark_GiveStatus[id])
			{
				case true: g_ReMark[2][g_StatusValue_plID]++;
				case false:
				{
					if(g_ReMark[2][g_StatusValue_plID] < 0)
					{
						Show_ReMarkMenu(id);
						return PLUGIN_HANDLED;
					}else g_ReMark[2][g_StatusValue_plID]--;
				}
			}
		}
		case 3:
		{
			switch(g_ReMark_GiveStatus[id])
			{
				case true: g_ReMark[3][g_StatusValue_plID]++;
				case false:
				{
					if(g_ReMark[3][g_StatusValue_plID] < 0)
					{
						Show_ReMarkMenu(id);
						return PLUGIN_HANDLED;
					}else g_ReMark[3][g_StatusValue_plID]--;
				}
			}
		}
		case 4:
		{
			switch(g_ReMark_GiveStatus[id])
			{
				case true: g_ReMark[4][g_StatusValue_plID]++;
				case false:
				{
					if(g_ReMark[4][g_StatusValue_plID] < 0)
					{
						Show_ReMarkMenu(id);
						return PLUGIN_HANDLED;
					}else g_ReMark[4][g_StatusValue_plID]--;
				}
			}
		}
		case 5:
		{
			switch(g_ReMark_GiveStatus[id])
			{
				case true: g_ReMark_GiveStatus[id] = false;
				case false: g_ReMark_GiveStatus[id] = true;
			}
		}
		case 6:
		{
			for(new i = 0; i <= 4; i++)
			{
				g_ReMark[i][g_StatusValue_plID] = 0;
			}
		}
		case 9: return PLUGIN_HANDLED;
	}
	Show_ReMarkMenu(id);
	return PLUGIN_HANDLED;
}

public fw_HamKilled(victim, attacker)
{
	if(victim == jbe_get_chief_id())
	{
		jbe_mafia_end();
			
		g_CommissarID = 0;
		g_DoctorID = 0;
		g_DonID = 0;
		g_ManiacID = 0;
		g_CourtesanID = 0;
		
		for(new id; id <= get_maxplayers(); id++)
		{
			g_Mafia[id] = false;
			g_Villager[id] = false;
		}
		g_MaxMafiozi = 0;
		g_MafiaStatus = false;
		for(new id; id <= g_iMaxPlayers; id++) remove_task(id + TASK_SHOW_MAFIA_INF);
		message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
		write_byte(0);  // Red
		write_byte(0);  // Green
		write_byte(0);  // Blue
		write_byte(0); 	// SD
		write_byte(0);  // ED
		write_byte(0);  // D1
		write_byte(0);  // D2
		message_end();
		g_DayMode = false;
	}
	if(g_Villager[victim]) g_VilligerMax--;
	
	if(g_Mafia[victim])
	{
		g_Mafia[victim] = false;
		g_Villager[victim] = true;
	}
	if(victim == g_DoctorID) g_DoctorID = 0; 
	if(victim == g_DonID) g_DonID = 0;
	if(victim == g_ManiacID) g_ManiacID = 0;
	if(victim == g_CommissarID) g_CommissarID = 0;
	if(victim == g_CourtesanID) g_CourtesanID = 0;
}


public Ham_PlayerSpawn_Post(id)
{
	if(g_MafiaStatus) set_task(2.0, "Show_Informer", id + TASK_SHOW_MAFIA_INF, _, _, "b");
	else if(task_exists(id+TASK_SHOW_MAFIA_INF)) remove_task(id+TASK_SHOW_MAFIA_INF);
	if(g_MafiaStatus)
	{
		g_Villager[id] = true;
		sz_YouStatus[id] = "Житель";
		g_VilligerMax++
	}
	
}
public client_putinserver(id)
{
	if(g_MafiaStatus) set_task(2.0, "Show_Informer", id + TASK_SHOW_MAFIA_INF, _, _, "b");
	else if(task_exists(id+TASK_SHOW_MAFIA_INF)) remove_task(id+TASK_SHOW_MAFIA_INF);
}
public client_disconnect(id)
{
	remove_task(id + TASK_SHOW_MAFIA_INF);
	if(id == jbe_get_chief_id())
	{
		jbe_mafia_end();
			
		g_CommissarID = 0;
		g_DoctorID = 0;
		g_DonID = 0;
		g_ManiacID = 0;
		g_CourtesanID = 0;
		
		for(new id; id <= get_maxplayers(); id++)
		{
			g_Mafia[id] = false;
			g_Villager[id] = false;
		}
		g_MaxMafiozi = 0;
		g_MafiaStatus = false;
		for(new id; id <= g_iMaxPlayers; id++) remove_task(id + TASK_SHOW_MAFIA_INF);
		message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
		write_byte(0);  // Red
		write_byte(0);  // Green
		write_byte(0);  // Blue
		write_byte(0); 	// SD
		write_byte(0);  // ED
		write_byte(0);  // D1
		write_byte(0);  // D2
		message_end();
		g_DayMode = false;
	}
	if(g_Mafia[id]) 
	{
		g_Mafia[id] = false;
		g_Villager[id] = true;
	}
	if(g_Villager[id]) 
	{
		g_Villager[id] = false;
		g_VilligerMax--;
	}
	if(id == g_DoctorID) g_DoctorID = 0; 
	if(id == g_DonID) g_DonID = 0;
	if(id == g_ManiacID) g_ManiacID = 0;
	if(id == g_CommissarID) g_CommissarID = 0;
	if(id == g_CourtesanID) g_CourtesanID = 0;
}

public Show_FreezieMenu(id)
{
	if(g_BugFixer_Freezie[id])
	{
		UTIL_SayText(id, "!y[!gMAFIA!g] Во избежание падений сервера, подождите !g~5 секунд");
		return;
	}
	static menu[1024], len; len = 0;
	new iKeys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9);
	len = formatex(menu[len], charsmax(menu) - len, "\yМеню \rЗаморозки + Темнота^n^n");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r1\y]\w Заморозить выборочно^n^n");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r2\y]\w Заморозить всех^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r3\y]\w Разморозить всех^n^n");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r4\y]\w Заморозить Добрых^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r5\y]\w Разморозить Добрых^n^n");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r6\y]\w Заморозить Злых^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r7\y]\w Разморозить Злых^n^n");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r0\y]\w Выход^n^n");
	
	show_menu(id, iKeys, menu, -1, "Show_FreezieMenu");
}

public Handle_FreezieMenu(id, iKey)
{
	switch(iKey)
	{
		case 0: Formatex_FrizieList(id);
		case 1: for(new idx; idx <= get_maxplayers(); idx++) if(jbe_get_user_team(idx) == 1) freezie_start(idx);
		case 2: for(new idx; idx <= get_maxplayers(); idx++) if(jbe_get_user_team(idx) == 1) unfreezie_end(idx);
		case 3:
		{
			for(new idx; idx <= get_maxplayers(); idx++) if(g_Villager[idx]) freezie_start(idx);
			freezie_start(g_CommissarID);
			freezie_start(g_DoctorID);
		}
		case 4:
		{
			for(new idx; idx <= get_maxplayers(); idx++) if(g_Villager[idx]) unfreezie_end(idx);
			unfreezie_end(g_CommissarID);
			unfreezie_end(g_DoctorID);
		}
		case 5:
		{
			for(new idx; idx <= get_maxplayers(); idx++)
			{
				if(g_Mafia[idx]) freezie_start(idx);
			}
			freezie_start(g_CourtesanID);
			freezie_start(g_ManiacID);
			freezie_start(g_DonID);
		}
		case 6:
		{
			for(new idx; idx <= get_maxplayers(); idx++)
			{
				if(g_Mafia[idx]) unfreezie_end(idx);
			}
			unfreezie_end(g_CourtesanID);
			unfreezie_end(g_ManiacID);
			unfreezie_end(g_DonID);
		}
	}
	g_BugFixer_Freezie[id] = true;
	set_task(5.0, "FixerFreezie", id + 1000101);
}

public FixerFreezie(id)
{
	id -= 1000101;
	g_BugFixer_Freezie[id] = false;
	UTIL_SayText(id, "!y[!gMAFIA!y] Вам вновь доступно меню !gзаморозки");
}

Formatex_FrizieList(id) return Show_FrList(id, g_iMenuPosition[id] = 0);
Show_FrList(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iPlayersNum;
	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		if(jbe_get_user_team(i) == 1) g_iMenuPlayers[id][iPlayersNum++] = i;
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
			UTIL_SayText(id, "!y[!gMAFIA!y]!y Подходящих игроков нету.");
			Show_FreezieMenu(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\yМеню Заморозки \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\y%d\r] \w%s \d[%s]^n", ++b, szName, g_Freezie[i] ? "Заморожен":"Разморожен");
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \wДальше^n\r[\y0\r] \w%s", iPos ? "Назад" : "Выход");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Назад" : "Выход");
	return show_menu(id, iKeys, szMenu, -1, "Show_FrList");
}

public Handle_FrPlayersList(id, iKey)
{
	switch(iKey)
	{
		case 8: return Show_FrList(id, ++g_iMenuPosition[id]);
		case 9: return Show_FrList(id, --g_iMenuPosition[id]);
		default:
		{
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			if(is_user_connected(iTarget))
			{
				switch(g_Freezie[iTarget])
				{
					case true: unfreezie_end(iTarget)
					case false: freezie_start(iTarget)
				}
			}
			Show_FreezieMenu(id);
		}
	}
	return PLUGIN_HANDLED;
}

public Show_MafiaMenu(id)
{
	if(!is_user_admin(id))
	{
		UTIL_SayText(id, "!y[!gMAFIA!y] Вы не игрок с !gпривилегиями!");
		return;
	}
	if(id != jbe_get_chief_id()) return;
	static menu[1024], len; len = 0;
	new iKeys = (1<<0|1<<9);
	len = formatex(menu[len], charsmax(menu) - len, "\yМеню \rМафии^n\wЗабиндите кнопку на \r'remark_mafia'^n^n");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r1\y]\w %s мафию^n^n", g_MafiaStatus ? "Закончить":"Начать");
	
	if(g_MafiaStatus)
	{
		len += formatex(menu[len], charsmax(menu) - len, "\y[\r2\y]\w Выдать \rРоли \d[menu]^n");
		len += formatex(menu[len], charsmax(menu) - len, "\y[\r3\y]\w Сделать \r%s^n", g_DayMode ? "День":"Ночь");
		len += formatex(menu[len], charsmax(menu) - len, "\y[\r4\y]\w Дать\d|\wЗабрать\y Затемнение экрана + Заморозка\d[menu]^n^n");
		len += formatex(menu[len], charsmax(menu) - len, "\y[\r5\y]\w Сбросить \квсем \цвсе \кметки^n^n");
		
		iKeys |= (1<<1|1<<2|1<<3|1<<4);
	}
	
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r0\y]\w Выход^n^n");
	show_menu(id, iKeys, menu, -1, "Show_MafiaMenu");
}

public Handle_MafiaMenu(id, ikey)
{
	switch(ikey)
	{
		case 0: jbe_mafia_setting();
		case 1: Show_RolePlayMenu(id);
		case 2: DayMode_Setting();
		case 3: Show_FreezieMenu(id);
		case 4:
		{
			for(new ii = 1; ii <= g_iMaxPlayers; ii++)
			{
				for(new i = 0; i <= 4; i++)
				{
					g_ReMark[i][ii] = 0;
				}
			}
			UTIL_SayText(id, "!y[!gMAFIA!y] Все !gметки!y у всех игроков !gсброшены.");
		}
		case 9: return;
	}
}

public Show_RolePlayMenu(id)
{
	static menu[1024], len; len = 0;
	new iKeys = (1<<9);
	len = formatex(menu[len], charsmax(menu) - len, "\yМеню \rВыдачи Роли^n^n");
	
	if(g_DoctorID == 0) iKeys |= (1<<5);
	if(g_ManiacID == 0) iKeys |= (1<<4);
	if(g_CourtesanID == 0) iKeys |= (1<<3);
	if(g_CommissarID == 0) iKeys |= (1<<2);
	if(g_MaxMafiozi > 0) iKeys |= (1<<1);
	if(g_DonID == 0) iKeys |= (1<<0)
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r1\y]\w Выдать \rДона Мафии %s^n", (g_DonID == 0) ? "":"\d[ВЫБРАН]");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r2\y]\w Сделать \rМафиози \y[%d]^n", g_MaxMafiozi);
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r3\y]\w Выдать \rКомиссара %s^n", (g_CommissarID == 0) ? "":"\d[ВЫБРАН]");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r4\y]\w Выдать \rКуртизанку %s^n", (g_CourtesanID == 0) ? "":"\d[ВЫБРАНА]");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r5\y]\w Выдать \rМаньяка %s^n", (g_ManiacID == 0) ? "":"\d[ВЫБРАН]");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r6\y]\w Выдать \rДоктора %s^n^n", (g_DoctorID == 0) ? "":"\d[ВЫБРАН]");
	
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r0\y]\w Выход^n^n");
	
	show_menu(id, iKeys, menu, -1, "Show_RolePlayMenu");
}

public Handle_RolePlayMenu(id, iKey)
{
	switch(iKey)
	{
		case 0: g_StatusPlMenu[id] = 1;
		case 1: g_StatusPlMenu[id] = 2;
		case 2: g_StatusPlMenu[id] = 3;
		case 3: g_StatusPlMenu[id] = 4;
		case 4: g_StatusPlMenu[id] = 5;
		case 5: g_StatusPlMenu[id] = 6;
		case 9: return;
	}
	Format_RoleList(id);
}

Format_RoleList(id) return Show_RoleList(id, g_iMenuPosition[id] = 0);
Show_RoleList(id, iPos)
{
	if(iPos < 0) return PLUGIN_HANDLED;
	new iPlayersNum;
	for(new i = 1; i <= g_iMaxPlayers; i++)
	{
		switch(g_StatusPlMenu[id])
		{
			case 1, 2, 3, 4, 5, 6:
			{
				if(jbe_get_user_team(i) == 1 && i != g_CourtesanID && i != g_CommissarID && i != g_DonID && i != g_DoctorID && i != g_ManiacID && i != g_CourtesanID && !g_Mafia[i])
					g_iMenuPlayers[id][iPlayersNum++] = i;
			}
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
			UTIL_SayText(id, "!y[!gMAFIA!y]!y Подходящих игроков нету.");
			Show_RolePlayMenu(id);
		}
		default: iLen = formatex(szMenu, charsmax(szMenu), "\yКому выдаем? \w[%d|%d]^n^n", iPos + 1, iPagesNum);
	}
	new szName[32], i, iKeys = (1<<9), b;
	for(new a = iStart; a < iEnd; a++)
	{
		i = g_iMenuPlayers[id][a];
		get_user_name(i, szName, charsmax(szName));
		iKeys |= (1<<b);
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\y%d\r] \w%s^n", ++b, szName);
	}
	for(new i = b; i < PLAYERS_PER_PAGE; i++) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n");
	if(iEnd < iPlayersNum)
	{
		iKeys |= (1<<8);
		formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\y9\r] \wДальше^n\r[\y0\r] \w%s", iPos ? "Назад" : "Выход");
	}
	else formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\r[\y0\r] \w%s", iPos ? "Назад" : "Выход");
	return show_menu(id, iKeys, szMenu, -1, "Show_RoleList");
}

public Handle_PlayersList(id, iKey)
{
	switch(iKey)
	{
		case 8: return Show_RoleList(id, ++g_iMenuPosition[id]);
		case 9: return Show_RoleList(id, --g_iMenuPosition[id]);
		default:
		{
			new iTarget = g_iMenuPlayers[id][g_iMenuPosition[id] * PLAYERS_PER_PAGE + iKey];
			new sName[32], tName[32];
			get_user_name(jbe_get_chief_id(), sName, charsmax(sName));
			get_user_name(iTarget, tName, charsmax(tName));
			if(is_user_connected(iTarget))
			{
				switch(g_StatusPlMenu[id])
				{
					case 1:
					{
						g_DonID = iTarget;
						sz_DonName = tName;
						sz_YouStatus[iTarget] = "Лидер Мафии";
						for(new idx; idx <= get_maxplayers(); idx++)
						{
							switch(jbe_get_user_team(idx))
							{
								case 1, 3, 4: UTIL_SayText(idx, "!y[!gMAFIA!y] Начальник !g%s!y выбрал !gДОНА мафии", sName);
								case 2: UTIL_SayText(idx, "!y[!gMAFIA!y][!gCT!y] Начальник !g%s!y выбрал !gДОНА мафии - !t%s", sName, tName);
							}
						}
					}
					case 2:
					{
						g_Mafia[iTarget] = true;
						g_MaxMafiozi--;
						g_Mafiozi++;
						sz_YouStatus[iTarget] = "Мафиози";
						for(new idx; idx <= get_maxplayers(); idx++)
						{
							switch(jbe_get_user_team(idx))
							{
								case 1, 3, 4: UTIL_SayText(idx, "!y[!gMAFIA!y] Начальник !g%s!y выбрал !gМафиози", sName);
								case 2: UTIL_SayText(idx, "!y[!gMAFIA!y][!gCT!y] Начальник !g%s!y выбрал !gМафиози - !t%s", sName, tName);
							}
						}
					}
					case 3:
					{
						g_CommissarID = iTarget;
						sz_CommissarName = tName;
						sz_YouStatus[iTarget] = "Комиссар";
						for(new idx; idx <= get_maxplayers(); idx++)
						{
							switch(jbe_get_user_team(idx))
							{
								case 1, 3, 4: UTIL_SayText(idx, "!y[!gMAFIA!y] Начальник !g%s!y выбрал !gКомиссара", sName);
								case 2: UTIL_SayText(idx, "!y[!gMAFIA!y][!gCT!y] Начальник !g%s!y выбрал !gКомиссара - !t%s", sName, tName);
							}
						}
					}
					case 4:
					{
						g_CourtesanID = iTarget;
						sz_CourtesanName = tName;
						sz_YouStatus[iTarget] = "Куптизанка";
						for(new idx; idx <= get_maxplayers(); idx++)
						{
							switch(jbe_get_user_team(idx))
							{
								case 1, 3, 4: UTIL_SayText(idx, "!y[!gMAFIA!y] Начальник !g%s!y выбрал !gКуртизанку", sName);
								case 2: UTIL_SayText(idx, "!y[!gMAFIA!y][!gCT!y] Начальник !g%s!y выбрал !gКуртизанку - !t%s", sName, tName);
							}
						}
					}
					case 5:
					{
						g_ManiacID = iTarget;
						sz_ManiacName = tName;
						sz_YouStatus[iTarget] = "Маньяк";
						for(new idx; idx <= get_maxplayers(); idx++)
						{
							switch(jbe_get_user_team(idx))
							{
								case 1, 3, 4: UTIL_SayText(idx, "!y[!gMAFIA!y] Начальник !g%s!y выбрал !gМаньяка", sName);
								case 2: UTIL_SayText(idx, "!y[!gMAFIA!y][!gCT!y] Начальник !g%s!y выбрал !gМаньяка - !t%s", sName, tName);
							}
						}
					}
					case 6:
					{
						g_DoctorID = iTarget;
						sz_DocName = tName;
						sz_YouStatus[iTarget] = "Доктор";
						for(new idx; idx <= get_maxplayers(); idx++)
						{
							switch(jbe_get_user_team(idx))
							{
								case 1, 3, 4: UTIL_SayText(idx, "!y[!gMAFIA!y] Начальник !g%s!y выбрал !gДоктора", sName);
								case 2: UTIL_SayText(idx, "!y[!gMAFIA!y][!gCT!y] Начальник !g%s!y выбрал !gДоктора - !t%s", sName, tName);
							}
						}
					}
				}
				g_Villager[iTarget] = false;
				g_VilligerMax--;
				Show_RolePlayMenu(id);
			}
		}
	}
	return PLUGIN_HANDLED;
}

public DayMode_Setting()
{
	switch(g_DayMode)
	{
		case false: 
		{
			UTIL_SayText(0, "!t~~~~~~!y Приходит !gночь!y - просыпается !gМафия !t~~~~~~");
			message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
			write_byte(20); 	 	// Red
			write_byte(20); 		// Green
			write_byte(20); 		// Blue
			write_byte(10); 						// SD
			write_byte(41);  						// ED
			write_byte(95);  						// D1
			write_byte(59);  						// D2
			message_end();	
			g_DayMode = true;
		}
		case true:
		{
			UTIL_SayText(0, "!t~~~~~~!y Приходит !gДень!y - !gМафия!y засыпает !t~~~~~~");
			message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
			write_byte(0);  // Red
			write_byte(0);  // Green
			write_byte(0);  // Blue
			write_byte(0); 	// SD
			write_byte(0);  // ED
			write_byte(0);  // D1
			write_byte(0);  // D2
			message_end();
			g_DayMode = false;
		}
	}
	Show_MafiaMenu(jbe_get_chief_id());
}

public jbe_mafia_setting()
{
	switch(g_MafiaStatus)
	{
		case false:
		{
			jbe_mafia_start();
			g_VilligerMax = 0;
			g_MaxMafiozi = 10;
			g_MafiaStatus = true;
			for(new id; id <= g_iMaxPlayers; id++) set_task(2.0, "Show_Informer", id + TASK_SHOW_MAFIA_INF, _, _, "b");
			for(new id; id <= get_maxplayers(); id++) if(is_user_connected(id) && jbe_get_user_team(id) == 1 && is_user_alive(id))
			{				
				g_Villager[id] = true;
				sz_YouStatus[id] = "Житель";
				g_VilligerMax++
			}
		}
		case true:
		{
			jbe_mafia_end();
			
			g_CommissarID = 0;
			g_DoctorID = 0;
			g_DonID = 0;
			g_ManiacID = 0;
			g_CourtesanID = 0;
			for(new id; id <= get_maxplayers(); id++)
			{
				g_Mafia[id] = false;
				g_Villager[id] = false;
			}
			g_MaxMafiozi = 0;
			g_MafiaStatus = false;
			for(new id; id <= g_iMaxPlayers; id++) remove_task(id + TASK_SHOW_MAFIA_INF);
			message_begin(MSG_ALL, get_user_msgid("Fog"), {0,0,0}, 0);
			write_byte(0);  // Red
			write_byte(0);  // Green
			write_byte(0);  // Blue
			write_byte(0); 	// SD
			write_byte(0);  // ED
			write_byte(0);  // D1
			write_byte(0);  // D2
			message_end();
			g_DayMode = false;
		}
	}
	Show_MafiaMenu(jbe_get_chief_id());
}

public Show_Informer(id)
{
	id -= TASK_SHOW_MAFIA_INF;
	new ChiefName[32];
	get_user_name(jbe_get_chief_id(), ChiefName, charsmax(ChiefName));

	set_hudmessage(133, 10, 220, 0.15, 0.18, 0, 0.0, 1.0, 0.2, 1.0, -1);
	switch(jbe_get_user_team(id))
	{
		case 1, 3, 4: 
		if(g_Mafia[id])
			ShowSyncHudMsg(id, g_iInformerMafia, "Вы: %s^nСаймон: %s^n^nДон: %s(%s)^nКомиссар: (%s)^nДоктор: (%s)^nМаньяк: (%s)^nКуртизанока: (%s)^n^nМафиози: %d^nЖителей: %d", 
			sz_YouStatus[id],
			ChiefName,
			(g_DonID  == 0) ? "Не выбран":sz_DonName, is_user_alive(g_DonID) ? "Жив":"Мёртв",
			is_user_alive(g_CommissarID) ? "Жив":"Мёртв",
			is_user_alive(g_DoctorID) ? "Жив":"Мёртв",
			is_user_alive(g_ManiacID) ? "Жив":"Мёртв",
			is_user_alive(g_CourtesanID) ? "Жива":"Мёртва",
			g_Mafiozi, g_VilligerMax
			);
		else
			ShowSyncHudMsg(id, g_iInformerMafia, "Вы: %s^nСаймон: %s^n^nДон: (%s)^nКомиссар: (%s)^nДоктор: (%s)^nМаньяк: (%s)^nКуртизанка: (%s)^n^nМафиози: %d^nЖителей: %d", 
			sz_YouStatus[id],
			ChiefName,
			is_user_alive(g_DonID) ? "Жив":"Мёртв",
			is_user_alive(g_CommissarID) ? "Жив":"Мёртв",
			is_user_alive(g_DoctorID) ? "Жив":"Мёртв",
			is_user_alive(g_ManiacID) ? "Жив":"Мёртв",
			is_user_alive(g_CourtesanID) ? "Жива":"Мёртва",
			g_Mafiozi, g_VilligerMax
		);
		case 2: ShowSyncHudMsg(id, g_iInformerMafia, "Саймон: %s^n^nДон: %s (%s)^nКомиссар: %s (%s)^nДоктор: %s (%s)^nМаньяк: %s (%s)^nКуртизанка: %s(%s)^n^nМафиози: %d^nЖителей: %d", 
			ChiefName,
			(g_DonID  == 0) ? "Не выбран":sz_DonName, is_user_alive(g_DonID) ? "Жив":"Мёртв",
			(g_CommissarID  == 0) ? "Не выбран":sz_CommissarName, is_user_alive(g_CommissarID) ? "Жив":"Мёртв",
			(g_DoctorID  == 0) ? "Не выбран":sz_DocName, is_user_alive(g_DoctorID) ? "Жив":"Мёртв",
			(g_ManiacID  == 0) ? "Не выбран":sz_ManiacName, is_user_alive(g_ManiacID) ? "Жив":"Мёртв",
			(g_CourtesanID  == 0) ? "Не выбрана":sz_CourtesanName, is_user_alive(g_CourtesanID) ? "Жива":"Мёртва",
			g_Mafiozi, g_VilligerMax
		);

	}
	
}

public freezie_start(i)
{
	set_pev(i, pev_flags, pev(i, pev_flags) | FL_FROZEN);
	UTIL_ScreenFade(i, 0, 0, 4, 0, 0, 0, 255, 1);
	g_Freezie[i] = true;
}
public unfreezie_end(i)
{
	UTIL_ScreenFade(i, 0, 0, 0, 0, 0, 0, 0, 1);
	set_pev(i, pev_flags, pev(i, pev_flags) & ~FL_FROZEN);
	g_Freezie[i] = false;
}

stock UTIL_ScreenFade(id, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	message_begin(iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, 98, _, id);
	write_short(iDuration);
	write_short(iHoldTime);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
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