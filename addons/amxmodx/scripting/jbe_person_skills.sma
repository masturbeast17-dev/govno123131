/*-------------------*/ /*-------------------*/
#include amxmodx	 // Главное Ядро
#include amxmisc	 // Создание менюшек
#include jbe_core	 // Главное Ядро Мода
#include hamsandwich // Отлов событий
#include cstrike	 // Выдача/Установка значений
#include chat		 // Отправка сообщений в чат
/*-------------------*/ /*-------------------*/
native jbe_get_user_lvl_rank(id);
native jbe_get_status_duel();

/* Sets player armor. */
native set_user_armor(index, armor);

/* Sets player health. */
native set_user_health(index, health);

/* Sets users max. speed. */
native set_user_maxspeed(index, Float:speed = -1.0);

/* Returns users max. speed. */
native Float:get_user_maxspeed(index);
/*--------------------------------------/ Макросы /--------------------------------------*/

#define		CREATE			"[U-JBL] RPG MOD"
#define		BY				"vk.com/krisiso"
#define		ToJI9IHGaa		"ToJI9IHGaa"
						
#define MAX_PLAYERS 32
/*-----------------------------------------*/ /*-----------------------------------------*/
new g_nExp[ MAX_PLAYERS + 1 ];

new g_SkillsPerson[33][3];
new const gHealth[11] = { 0, 5, 10, 15, 20, 25, 30, 35, 40, 50, 70 };
new const gArmor[11] = { 0, 5, 10, 15, 20, 25, 30, 40, 45, 50, 100 };
new const gSpeed[11] = { 240, 252, 255, 258, 260, 263, 265, 268, 270, 273, 275 };

public plugin_init()
{
	register_plugin(	CREATE, BY, ToJI9IHGaa		);
	
	register_menu( "Show_SkillsMenu", (1<<0|1<<1|1<<2|1<<9), "Handle_SkillsMenu");

	register_event( "CurWeapon", "HookCurWeapon", "be", "1=1" );
	
	RegisterHam(Ham_Spawn, "player", "HamSpawn_Post");
}

public plugin_natives()
{
	register_native(  "jbe_open_skills_menu", "Show_SkillsMenu", 1);
	
	register_native(  "ujbl_set_user_bonus", "set_user_exp_ps", 1);
	register_native(  "ujbl_get_user_bonus", "ujbl_get_user_bonus", 1);
	
	register_native(  "ujbl_get_agility_skills", "ujbl_get_agility_skills", 1);
	register_native(  "ujbl_get_lot_skills", "ujbl_get_lot_skills", 1);
	register_native(  "ujbl_get_protection_skills", "ujbl_get_protection_skills", 1);
}
public ujbl_get_agility_skills(id) return g_SkillsPerson[id][1];
public ujbl_get_lot_skills(id) return g_SkillsPerson[id][2];
public ujbl_get_protection_skills(id) return g_SkillsPerson[id][0];
public ujbl_get_user_bonus(id) return g_nExp[id];
public set_user_exp_ps(id, inum) g_nExp[id] = inum;

public Show_SkillsMenu(id)
{
	jbe_informer_offset_up(id);
	new iKeys = (1<<9);
	static szMenu[1023], iLen; iLen = 0;
	iLen = formatex(szMenu, charsmax(szMenu), "\yМеню Прокачки Персонажа^n\wВаши Бонусы: \r[%d]^n^n", g_nExp[id]);
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1]%s Прокачать \rЗащиту \d[%d]\R%d lvl^n", (g_nExp[id] <= 0 || g_SkillsPerson[id][0] >= 10) ? "\d":"\w", gArmor[g_SkillsPerson[id][0]], g_SkillsPerson[id][0]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2]%s Прокачать \rЛовкость \d[%d]\R%d lvl^n", (g_nExp[id] <= 0 || g_SkillsPerson[id][1] >= 10) ? "\d":"\w", gSpeed[g_SkillsPerson[id][1]], g_SkillsPerson[id][1]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3]%s Прокачать \rМассу \d[%d]\R%d lvl^n^n", (g_nExp[id] <= 0 || g_SkillsPerson[id][2] >= 10) ? "\d":"\w", gHealth[g_SkillsPerson[id][2]], g_SkillsPerson[id][2]);
	
	for(new i = 0; i <= 2; i++)
	{
		if(g_nExp[id] > 0 && g_SkillsPerson[id][i] < 10) iKeys |= (1<<i);
	}
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[0] Выход^n");
	return show_menu(id, iKeys, szMenu, -1, "Show_SkillsMenu");
}
public Handle_SkillsMenu(id, iNum)
{
	if(iNum == 9) return PLUGIN_HANDLED;
	g_nExp[id]--;
	g_SkillsPerson[id][iNum]++;
	Check_Limit(id);
	return Show_SkillsMenu(id);
}

public Check_Limit(id)
{
	for(new i; i <= 2; i++)
	{
		if(g_SkillsPerson[id][i] > 10) g_SkillsPerson[id][i] = 10;
	}
	return PLUGIN_HANDLED;
}
public HookCurWeapon(id)
{
	if(jbe_get_day_mode() == 3 || jbe_get_status_duel() == 1 || jbe_get_status_duel() == 2 || jbe_get_user_team(id) != 1) return;
	new Float:float_num;
	float_num = float( gSpeed[g_SkillsPerson[id][1]] );
	set_user_maxspeed(id, float_num);
}
public HamSpawn_Post(id) set_task(3.0, "FixSapwn", id + 1141);
public FixSapwn(id)
{
	id -= 1141;
	if(jbe_get_day_mode() == 3 || jbe_get_status_duel() == 1 || jbe_get_status_duel() == 2 || !is_user_connected(id)) return;
	
	new Float:float_num;
	float_num = float(gSpeed[g_SkillsPerson[id][1]]);
	
	set_user_health(id, get_user_health(id) + gHealth[g_SkillsPerson[id][2]]);
	set_user_armor(id, get_user_armor(id) + gArmor[g_SkillsPerson[id][0]]);
	
	set_user_maxspeed(id, float_num);
}

public client_putinserver(id) set_task(10.0, "FixConnect", id + 909);
public FixConnect(id)
{
	id -= 909;
	g_nExp[id] = jbe_get_user_lvl_rank(id);
}
public client_disconnect(id)
{
	g_nExp[id] = 0;
	for(new i; i <= 2; i++)
	{
		g_SkillsPerson[id][i] = 0;
	}
}
