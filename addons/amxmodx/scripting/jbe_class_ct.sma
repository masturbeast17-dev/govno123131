#include amxmodx
#include amxmisc
#include fun
#include fakemeta
#include cstrike
#include hamsandwich
#include chat
#include jbe_core

native jbe_get_privileges(id);

/* > -------- > ------- Макросы > ------- > ------- */

#define		CREATE										"[U-JBL] Классы Охраны"
#define		BY											"vk.com/krisiso"
#define		ToJI9IHGaa									"ToJI9IHGaa"

#define MAX_PLAYERS 32

native ujbl_get_protection_skills(id);
native ujbl_get_agility_skills(id);
native ujbl_get_lot_skills(id);

/* > -------- > ------- Перемённые и Массивы > ------- > ------- */

new g_iClass[MAX_PLAYERS + 1];
new const szClass[5][] =
{
	"Ловкач",
	"Пуленепробивной",
	"Охотник",
	"Живучий",
	"Снайпер"
};

public plugin_init()
{
	register_plugin(	CREATE, BY, ToJI9IHGaa		);
	
	register_menu( "Show_ClassGrMenu", (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "Handle_ClassMenu" );
	
	RegisterHam(Ham_Spawn, "player", "HamSpawn_Post");
	register_event("CurWeapon", "Event_WeaponChange", "be", "1=1");
	
	RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Player", false);
}

public plugin_natives()
{
	register_native("ujbl_get_ct_class", "ujbl_get_ct_class", 1);
	register_native("ujbl_open_class_ct_menu", "Show_ClassGrMenu", 1);
}
public ujbl_get_ct_class(id) return g_iClass[id];
public Show_ClassGrMenu(id)
{
	new menu[1024], iLen, iKeys; iKeys = (1<<9);
	
	iLen = formatex(menu[iLen], charsmax(menu) - iLen,  "\yМеню выбора \d[\rКласса\d]^n^n");
	
	if(g_iClass[id] != 1)
	{
		iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[1]\w Ловкач \d[\wСкорость\d]^n");
		iKeys |= (1<<0);
	}else iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[1]\d Ловкач \R\y[Выбран]^n");
		
	if(g_iClass[id] != 2)
	{
		iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[2]\w Вышибала \d[\wБольше жизней + Меньше урона\d]^n");
		iKeys |= (1<<1);
	}else iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[2]\d Вышибала \R\y[Выбран]^n");
	
	if(g_iClass[id] != 3)
	{
		iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[3]\w Охотник \d[\wАВП\d(Доп. оружие)\w + Тихий Шаг\d]^n");
		iKeys |= (1<<2);
	}else iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[3]\d Охотник \R\y[Выбран]^n");
	
	if(g_iClass[id] != 4)
	{
		iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[4]\w Живучий \d[\wРегенерация\d]^n");
		iKeys |= (1<<3);
	}else iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[4]\d Живучий \R\y[Выбран]^n");
	
	if(jbe_get_privileges(id) < 7 && jbe_get_privileges(id) != 0)
	{
		if(g_iClass[id] != 5)
		{
			iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[5]\w Снайпер \d[\wМаскировка\d][\rЭлитка\d]^n");
			iKeys |= (1<<4);
		}else iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[5]\d Снайпер \R\y[Выбран]^n");
	}else iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "\y[5]\d Снайпер \R\d[Нету Прав]^n");
	
	iLen += formatex(menu[iLen], charsmax(menu) - iLen,  "^n\y[0]\w Выход");
	
	show_menu(id, iKeys, menu, -1, "Show_ClassGrMenu");
}

public Handle_ClassMenu(id, iKey)
{
	if(iKey == 9) return PLUGIN_HANDLED;
	g_iClass[id] = iKey + 1;
	chat(id, "!y[!gU-JBL!y] Вы выбрали класс !g%s!y. Он вступит в силу после !gвозрождения!y.", szClass[iKey]);
	return PLUGIN_HANDLED;
}

public HamSpawn_Post(id) if(jbe_get_day_mode() != 3)set_task(3.0, "Fix_SpawnPost", id + 888822);
public Fix_SpawnPost(id)
{
	id -= 888822;
	if(task_exists(id + 9898981)) remove_task(id + 9898981);
	if(jbe_get_user_team(id) != 2) return HAM_IGNORED;
	
	new g_iNum[3];
	
	for(new i; i <= ujbl_get_agility_skills(id); i++) g_iNum[0] += 1;
	for(new i; i <= ujbl_get_lot_skills(id); i++) g_iNum[1] += 10;
	for(new i; i <= ujbl_get_protection_skills(id); i++) g_iNum[2] += 5;
	
	new Float:sSp = float(g_iNum[0]) + 30.0;
	g_iNum[1] += 50;
	g_iNum[2] += 100;
	
	switch(g_iClass[id])
	{
		case 1:
		{
			set_user_health(id, get_user_health(id) + 50);
			set_user_maxspeed(id, get_user_maxspeed(id) + sSp);
		}
		case 2:
		{
			set_user_armor(id, get_user_armor(id) + g_iNum[2]);
			cs_set_weapon_ammo(give_item(id, "weapon_m249"), 1000);
			cs_set_user_bpammo(id, CSW_M249, 900);
		}
		case 3:
		{
			set_user_footsteps(id, 1);
			cs_set_weapon_ammo(give_item(id, "weapon_awp"), 50);
			cs_set_user_bpammo(id, CSW_AWP, 900);
		}
		case 4:
		{
			set_task(20.0, "Give_Health_Healer", id + 9898981, _, _, "b");
			set_user_health(id, get_user_health(id) + g_iNum[1]);
		}
		case 5:
		{
			jbe_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 50);
			set_user_footsteps(id, 1);
			cs_set_weapon_ammo(give_item(id, "weapon_awp"), 50);
			cs_set_user_bpammo(id, CSW_AWP, 900);
		}
	}
	return HAM_IGNORED;
}

public Event_WeaponChange(id)
{
	if(g_iClass[id] != 1) return;
	new Float:sSp = 30.0
	for(new i; i <= ujbl_get_agility_skills(id); i++) sSp + 1.0;
	set_user_maxspeed(id, get_user_maxspeed(id) + sSp);
}
public Give_Health_Healer(id)
{
	id -= 9898981;
	if(get_user_health(id) >= 150 || !is_user_alive(id) || jbe_get_day_mode() == 3) return;
	set_user_health(id, get_user_health(id) + 1);
}

public Ham_TakeDamage_Player(iVictim, iInflictor, iAttacker, Float:fDamage)
{
	if(!is_user_connected(iVictim)) return HAM_IGNORED;
	if(g_iClass[iVictim] !=2) return HAM_IGNORED;
	
	fDamage = (fDamage / 0.1);
	return HAM_IGNORED;
}
public client_putinserver(id) g_iClass[id] = 1;