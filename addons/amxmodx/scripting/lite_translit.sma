#include amxmodx
#include jbe_core	
#include chat

/*------------------------------------------------------------------------------------------------------------------------------*/
//	Закомментировано - 'Выключено', Раскомментировано - 'Включено'.

#define LT_PREFIXES					// Свои префиксы. Файл 'addons/amxmodx/configs/lt_prefixes.ini'

#define STEAM_PREFIX				// Тег стим игрока в чате
//#define STANDART_LANG_RUS			// Русский язык при заходе в игру

#define ADMIN_GREEN_CHAT			// Зеленый цвет в чате у Главных админов, админов и випов 
#define MAIN_ADMIN 	ADMIN_RCON		// Флаг доступа для тега "Гл. Админ" в чате	[Нельзя закомментировать!]
#define ADMIN 		ADMIN_BAN		// Флаг доступа для тега "Админ" в чате		[Нельзя закомментировать!]
#define VIP			ADMIN_LEVEL_H	// Флаг доступа для тега "VIP" в чате		[Нельзя закомментировать!]

#define ANTIFLOOD				// Замена стандартного плагина antiflood.amxx [ По умолчанию выключен ]
#define AD_TIME		0.50			// Время между сообщениями, когда сработает антифлуд система [Нельзя закомментировать!]

#define ADMIN_ALLCHAT			// Показывать весь чат админам [ По умолчанию включен ]
/*------------------------------------------------------------------------------------------------------------------------------*/	

new const eng[][] = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "{", "}", ":",'"',"<", ">", "~", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "[", "]", ";", "'", ",", ".", "`", "?", "/", "@", "$", "^^", "&" };
new const rus[][] = { "Ф", "И", "С", "В", "У", "А", "П", "Р", "Ш", "О", "Л", "Д", "Ь", "Т", "Щ", "З", "Й", "К", "Ы", "Е", "Г", "М", "Ц", "Ч", "Н", "Я", "Х", "Ъ", "ж", "Э", "Б", "Ю", "Ё", "ф", "и", "с", "в", "у", "а", "п", "р", "ш", "о", "л", "д", "ь", "т", "щ", "з", "й", "к", "ы", "е", "г", "м", "ц", "ч", "н", "я", "х", "ъ", "ж", "э", "б", "ю", "ё", ",", ".", "'", ";", ":", "?" };	

new const dotc_filter[][] =
{
	"ж27",
	":27",
	"149ю202ю43ю157",
	"149.202.43.157"
};
new bool:g_bUseRus[33];

native jbe_get_user_lvl_rank(id);
new const g_szRankName[16][]=
{
	"JBE_ID_HUD_RANK_NAME_1",
	"JBE_ID_HUD_RANK_NAME_2",
	"JBE_ID_HUD_RANK_NAME_3",
	"JBE_ID_HUD_RANK_NAME_4",
	"JBE_ID_HUD_RANK_NAME_5",
	"JBE_ID_HUD_RANK_NAME_6",
	"JBE_ID_HUD_RANK_NAME_7",
	"JBE_ID_HUD_RANK_NAME_8",
	"JBE_ID_HUD_RANK_NAME_9",
	"JBE_ID_HUD_RANK_NAME_10",
	"JBE_ID_HUD_RANK_NAME_11",
	"JBE_ID_HUD_RANK_NAME_12",
	"JBE_ID_HUD_RANK_NAME_13",
	"JBE_ID_HUD_RANK_NAME_14",
	"JBE_ID_HUD_RANK_NAME_15",
	"JBE_ID_HUD_RANK_NAME_16"
};

#if defined STEAM_PREFIX
new bool:g_iSteamAc[33];
#endif

#if defined LT_PREFIXES
enum _:DATA 
{ 
	TYPE[2], 
	AUTH[32], 
	PREFIX[32] 
};
new Array:g_aData, 
	g_PlayerData[DATA];
new g_szPrefix[33][64];
#endif

#if defined ADMIN_ALLCHAT		// {

#define	GetBit(%1,%2)		(%1 & (1 << (%2 & 31)))
#define	SetBit(%1,%2)		%1 |= (1 << (%2 & 31))
#define	ResetBit(%1,%2)		%1 &= ~(1 << (%2 & 31))

new g_bIsUserAdmin;	

#endif							// }

public plugin_init()
{
	#define VERSION "3.0"
	register_plugin("Lite Translit", VERSION, "neygomon");
	register_cvar("lt_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	
	register_clcmd("say /rus", "LangCtrlRus");
	register_clcmd("say /eng", "LangCtrlEng");
	
	register_clcmd("say", "HandlerSay");
	register_clcmd("say_team", "HandlerSayTeam");
	
	register_dictionary("jbe_core.txt");
}

#if defined LT_PREFIXES
public plugin_cfg()
{
	iLT_prefixes();
}
iLT_prefixes()
{
	g_aData = ArrayCreate(DATA);

	new buff[256], fp = fopen("addons/amxmodx/configs/lt_prefixes.ini", "rt");
	if(!fp) return set_fail_state("File ^"addons/amxmodx/configs/lt_prefixes.ini^" not found");

	while(!feof(fp))
	{
		fgets(fp, buff, charsmax(buff));
		if(buff[0] && buff[0] != ';' && parse(buff, g_PlayerData[TYPE], charsmax(g_PlayerData[TYPE]), g_PlayerData[AUTH], charsmax(g_PlayerData[AUTH]), g_PlayerData[PREFIX], charsmax(g_PlayerData[PREFIX])))
			ArrayPushArray(g_aData, g_PlayerData);
	}
	return fclose(fp);
}
#endif

public client_putinserver(id)
{
	
#if defined LT_PREFIXES
	SearchClient(id);
#endif	

#if defined STANDART_LANG_RUS
	g_bUseRus[id] = true;
#else
	g_bUseRus[id] = false;
#endif

#if defined STEAM_PREFIX
	g_iSteamAc[id] = is_user_steam(id) ? true : false;
#endif

#if defined ADMIN_ALLCHAT
	if(get_user_flags(id) & ADMIN_CHAT) SetBit(g_bIsUserAdmin, id);
	else ResetBit(g_bIsUserAdmin, id);
#endif
}

public HandlerSay(id) return FormatMsg(id, false);
public HandlerSayTeam(id) return FormatMsg(id, true);

public LangCtrlRus(id)
{
	if(g_bUseRus[id])
		chat(id, "!y[!gU-JBL!y] !gРусский язык !tУЖЕ включен!");
	else 
	{
		chat(id, "!y[!gU-JBL!y] !gРусский язык !tактивирован");
		g_bUseRus[id] = true;
		client_cmd(id, "spk buttons/blip1.wav");
	}
}

public LangCtrlEng(id)
{
	if(!g_bUseRus[id])
		chat(id, "!y[!gU-JBL!y] !gАнглийский язык !tУЖЕ включен!");
	else
	{
		chat(id, "!y[!gU-JBL!y] !gАнглийский язык !tактивирован.");
		g_bUseRus[id] = false;
		client_cmd(id, "spk buttons/blip1.wav");
	}
} 

FormatMsg(id, bool:isTeam) /* isTeam - Писать вашу команду или нет? */
{
#define MAX_BYTES 188
	static sMessage[MAX_BYTES]; 
	read_args(sMessage, charsmax(sMessage));
	remove_quotes(sMessage);
	new pos;
#if defined ANTIFLOOD
	static Float:fTimeFlood[33], Float:fGameTime, iFloodWarn[33];
		
	if(fTimeFlood[id] > (fGameTime = get_gametime()))
	{
		if(++iFloodWarn[id] > 2)
		{			
			chat(id, "!y[!gU-JBL!y] Прекратите !gфлудить!");
			fTimeFlood[id] = fGameTime + AD_TIME + 3.0;
			return PLUGIN_HANDLED;
		}
	}
	else if(iFloodWarn[id]) iFloodWarn[id]--;
	fTimeFlood[id] = fGameTime + AD_TIME;
#endif

	static iLen, sTags[MAX_BYTES], idAlive, idTeam; 
	idAlive = is_user_alive(id);

	switch(jbe_get_user_team(id))
	{
		case 1: 
		{
			iLen = formatex(sTags, charsmax(sTags), "%s%s ", idAlive ? "^1" : "^1[^3Мертв^1] ", isTeam ? "^1[^3Зэк^1]" : "");
			iLen += formatex(sTags[iLen], charsmax(sTags) - iLen, "^1[^4%L^1] ", id, g_szRankName[jbe_get_user_lvl_rank(id)]);
		}
		case 2: iLen = formatex(sTags, charsmax(sTags), "%s%s ", idAlive ? "^1" : "^1[^3Мертв^1] ", isTeam ? "^1[^3Охранник^1]" : "");
		default: iLen = formatex(sTags, charsmax(sTags), "^1[^3Спектор^1] ");
	}
	
#if defined ADMIN_GREEN_CHAT || defined LT_PREFIXES
	static IsAccess; IsAccess = CheckFlags(id);
#endif	

#if defined STEAM_PREFIX
	if(g_iSteamAc[id]) iLen += formatex(sTags[iLen], charsmax(sTags) - iLen, "^1[^4Стим^1] ");
#endif

#if defined LT_PREFIXES
	if(g_szPrefix[id][0]) iLen += formatex(sTags[iLen], charsmax(sTags) - iLen, "^1[^4%s^1] ", g_szPrefix[id]);
#endif	


#if defined ADMIN_GREEN_CHAT
	switch(IsAccess)
	{
		case 0: iLen += formatex(sTags[iLen], charsmax(sTags) - iLen, "^3%%s1^1 :  %%s2");
		default:iLen += formatex(sTags[iLen], charsmax(sTags) - iLen, "^3%%s1^1 :  ^4%%s2");
	}
#else
	iLen += formatex(sTags[iLen], charsmax(sTags) - iLen, "^3%%s1^1 :  %%s2");
#endif 

	if(g_bUseRus[id])
	{
		for(new i; i < sizeof eng; i++) replace_all2(sMessage, charsmax(sMessage), eng[i], rus[i]);
	}
	
	static iByteLimit; iByteLimit = MAX_BYTES;
	while(iLen + strlen(sMessage) > MAX_BYTES) sMessage[iByteLimit -= 10] = 0;

	for(new ix; ix <= sizeof dotc_filter - 1; ix++)
	{
		pos = containi(sMessage, dotc_filter[ix]);
		if(pos != -1)
		{
			formatex(sMessage, charsmax(sMessage), "Я ЕБУ СОБАК, ВСЕГДА ГОТОВ.. ТРАХНУТЬ НЕСКОЛЬКО КОТОВ!");
			break;
		}
	}
	if(sMessage[0] > 180) return PLUGIN_HANDLED;
	static players[32], pcount; get_players(players, pcount, "ch");
	switch(isTeam)
	{
		case true:
		{
			for(new i; i < pcount; i++)
			{
#if defined ADMIN_ALLCHAT				
				if(GetBit(g_bIsUserAdmin, players[i]) || (idAlive == is_user_alive(players[i]) && idTeam == get_user_team(players[i])))
					PrintChat(players[i], id, sTags, sMessage);
#else
				if(idAlive == is_user_alive(players[i]) && idTeam == get_user_team(players[i]))
					PrintChat(players[i], id, sTags, sMessage);
#endif
			}								
		}
		case false:
		{
			for(new i; i < pcount; i++)
				PrintChat(players[i], id, sTags, sMessage);
		}
	}
	return PLUGIN_HANDLED;
}

PrintChat(iReceiver, iSender, const sTags[], const sMessage[])
{
	message_begin(MSG_ONE, 76, .player=iReceiver);
	write_byte(iSender);
	write_string(sTags);
	write_string("");
	write_string(sMessage);
	message_end();
}
// serfreeman1337 fixed. thx =)
stock replace_all2(string[], len, const what[], const with[])
{
	new pos;
	if((pos = contain(string, what)) == -1) return 0;
	new total, with_len = strlen(with), diff = strlen(what) - with_len, total_len = strlen(string), temp_pos;
	while(total_len + with_len < len && replace(string[pos], len - pos, what, with) != 0)
	{
		total++;
		pos += with_len;
		total_len -= diff;
		if (pos >= total_len) break;
		temp_pos = contain(string[pos], what);
		if (temp_pos == -1) break;
		pos += temp_pos;
	}
	return total;
}

stock SearchClient(const id)
{
	for(new i; i < ArraySize(g_aData); i++)
	{
		ArrayGetArray(g_aData, i, g_PlayerData);
		switch(g_PlayerData[TYPE])
		{
			case 'f': 
			{
				if(get_user_flags(id) & read_flags(g_PlayerData[AUTH])) 
					return copy(g_szPrefix[id], charsmax(g_szPrefix[]), g_PlayerData[PREFIX]);
			}	
			case 'i': 
			{
				static sIP[16]; get_user_ip(id, sIP, charsmax(sIP), 1);
				if(!strcmp(g_PlayerData[AUTH], sIP)) 
					return copy(g_szPrefix[id], charsmax(g_szPrefix[]), g_PlayerData[PREFIX]);
			}		
			case 's': 
			{
				static sAuthid[25]; get_user_authid(id, sAuthid, charsmax(sAuthid));
				if(!strcmp(g_PlayerData[AUTH], sAuthid)) 
					return copy(g_szPrefix[id], charsmax(g_szPrefix[]), g_PlayerData[PREFIX]);
			}	
			case 'n':
			{
				static sName[32]; get_user_name(id, sName, charsmax(sName));
				if(!strcmp(g_PlayerData[AUTH], sName)) 
					return copy(g_szPrefix[id], charsmax(g_szPrefix[]), g_PlayerData[PREFIX]);
			}
		}
	}
	return g_szPrefix[id][0] = 0;
}

stock CheckFlags(id)
{
	static iFlags; iFlags = get_user_flags(id);
	if(iFlags & MAIN_ADMIN) return 1;
	else if(iFlags & ADMIN) return 2;
	else if(iFlags & VIP) return 3;
	return 0;
}

stock bool:is_user_steam(id)
{
	static dp_pointer;
	if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider")))
	{
		server_cmd("dp_clientinfo %d", id);
		server_exec();
		return (get_pcvar_num(dp_pointer) == 2) ? true : false;
	}
	return false;
}