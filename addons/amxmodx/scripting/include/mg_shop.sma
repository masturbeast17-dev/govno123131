#include <amxmodx>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <colorchat2>
#include <knife\advanced>
#include <grenade_key>
#include <deathrun>

#define PLUGIN "[MG] SHOP"
#define VERSION "1.0"
#define AUTHOR "Nickron"

new name[31]; 
new szThreeJump[33], szThreeJumpNum[33], szDoThreeJump[33]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_PlayerPreThink, "ThreeJump")
	register_forward(FM_PlayerPostThink, "PostThreeJump")
	
	RegisterHam(Ham_CS_RoundRespawn,"player","player_respawn")
	
	register_clcmd("say /shop","Menu_hook")
	register_clcmd("say_team /shop","Menu_hook")
	register_clcmd("shop_menu","Menu_hook")
	register_clcmd("mg_lvl_give","lvl_give")
}

public player_respawn(id)
{
	spawn(id)
}

public lvl_give(id)
{
	set_level(id, 55)
}	

public Menu_hook(id)
{
{
	new money = cs_get_user_money(id)
	new menu = menu_create("\rMG Shop: \yОсновной Магазин ^n\yОбновлённый^n\dSkype: \rkot_994","menu_hook")
	
		if(money >= 4000)
			menu_additem(menu,"\yКомплект Гранат \d(\r4000\w$\d)", "1", 0)
		else
			menu_additem(menu,"\dКомплект Гранат \d(\r4000\w$\d)", "1", 0)
		if(money >= 5000)		
			menu_additem(menu,"\yГравитация \d(\r5000\w$\d)", "2", 0)
		else
			menu_additem(menu,"\dГравитация \d(\r5000\w$\d)", "2", 0)
		if(money >= 4500)		
			menu_additem(menu,"\yЖизни - 99HP \d(\r4500\w$\d)", "3", 0)
		else
			menu_additem(menu,"\dЖизни - 99HP \d(\r4500\w$\d)", "3", 0)
		if(get_level(id) <10)	
			menu_additem(menu,"\dСвечение \d(\r10 LVL\w Free\d)", "4", 0)
		else
			menu_additem(menu,"\yСвечение \d(\r10 LVL\w Free\d)", "4", 0)
		if(money >= 6000)		
			menu_additem(menu,"\yДвойной прыжок - 2 Мин.\d(\r6000\w$\d)", "5", 0)
		else	
			menu_additem(menu,"\dДвойной прыжок - 2 Мин.\d(\r6000\w$\d)", "5", 0)
		if(money >= 9000)		
			menu_additem(menu,"\yНевидимка - FIX 20 Сек.\d(\r9000\w$\d)", "6", 0)
		else
			menu_additem(menu,"\dНевидимка - FIX 20 Сек.\d(\r9000\w$\d)", "6", 0)
		if(money >= 5000)
			menu_additem(menu,"\yЛоторея 100% \d(\r5000\w$\d)", "7", 0)
		else
			menu_additem(menu,"\dЛоторея 100% \d(\r5000\w$\d)", "7", 0)
		if(money >= 7000)
			menu_additem(menu,"\yМодель противника \d(\r7000\w$\d)", "8", 0)
		else
			menu_additem(menu,"\dМодель противника \d(\r7000\w$\d)", "8", 0)	
		if(money >= 4000)
			menu_additem(menu,"\yТелепорт на базу \d(\r4000\w$\d)", "9", 0)
		else
			menu_additem(menu,"\dТелепорт на базу \d(\r4000\w$\d)", "9", 0)
		if(money >= 10000)
			menu_additem(menu,"\yБессмертие (20 Сек.) \d(\r10000\w$\d)", "10", 0)
		else
			menu_additem(menu,"\dБессмертие (20 Сек.) \d(\r10000\w$\d)", "10", 0)
		if(money >= 8000)
			menu_additem(menu,"\yГраната (Галю-ная) \d(\r8000\w$\d)", "11", 0)
		else
			menu_additem(menu,"\dГраната (Галю-ная) \d(\r8000\w$\d)", "11", 0)
		
		menu_setprop(menu , MPROP_NEXTNAME, "Далее")
		menu_setprop(menu , MPROP_BACKNAME, "Назад")
		menu_setprop(menu , MPROP_EXITNAME, "\rВыход")
		menu_setprop(menu , MPROP_EXIT, MEXIT_ALL)
		menu_display(id, menu) 
	}  
	return PLUGIN_HANDLED
}

// =================================================================================================

public menu_hook(id, menu, key)
{
	if(key == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new accss, clbck, data[6], name[64], itm
	menu_item_getinfo(menu, key, accss, data, 5, name, 63, clbck)
	itm = str_to_num(data)
	
	get_user_name(id, name ,31)
	switch(itm)
	{	 
		case 1:
		{
		{
			if(cs_get_user_money(id) < 4000)
			{
				
				ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
				return PLUGIN_HANDLED;
			}
			cs_set_user_money(id, cs_get_user_money(id) - 4000)
			give_item(id, "weapon_hegrenade")
			give_item(id, "weapon_flashbang")
			ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^3%s ^4Купил Набор Гранат", name)
		}
	}  
	case 2:
	{
	{
		if(cs_get_user_money(id) < 5000)
		{
			
			ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
			return PLUGIN_HANDLED;
		}
		cs_set_user_money(id, cs_get_user_money(id) - 5000)
		set_user_gravity(id, 0.6)
		ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^3%s ^4Купил Гравитацию", name)	
	}
}
case 3:
{
{
	if(cs_get_user_money(id) < 4500)
	{
		
		ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
		return PLUGIN_HANDLED;
	}
	cs_set_user_money(id, cs_get_user_money(id) - 4500)
	set_user_health(id, get_user_health(id) + 99)
	ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^3%s ^4Купил 99HP", name)	
}
}
case 4:
{
{
if(get_level(id) <10)
{
	
	ColorChat(id,GREEN, "[MG SHOP] Ваш LVL должен состовлять не меньше ^410", name)
	return PLUGIN_HANDLED;
}
get_level(id) <10
render(id)
ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^3%s ^4Купил Свечение", name)	
}
}
case 5:
{
{
if(cs_get_user_money(id) < 6000)
{

ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
return PLUGIN_HANDLED;
}
cs_set_user_money(id, cs_get_user_money(id) - 6000)
szThreeJump[id] = true
set_task( 120.0, "off_jump", id)
ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^4%s ^3Купил Двойной прыжок на 2 мин.", name)	  
}
}
case 6:
{
{
if(cs_get_user_money(id) < 9000)
{

ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
return PLUGIN_HANDLED;
}
cs_set_user_money(id, cs_get_user_money(id) - 9000)
ka_render_add(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
set_task( 20.0, "EndInvis", id)
ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^3%s ^4Купил Полную Невидимость", name)
}
}
case 7:
{
{
if(cs_get_user_money(id) < 5000)
{

ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
return PLUGIN_HANDLED;
}
cs_set_user_money(id, cs_get_user_money(id) - 5000)
set_task( 10.0, "loter",id)
ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^3%s ^4Купил Беспройгрышную лотерею", name)	
}
}
case 8:
{
{
if(cs_get_user_money(id) < 7000)
{

ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
return PLUGIN_HANDLED;
}
if(get_user_team(id) & 1)
cs_set_user_model(id, "gsg9")
else if(get_user_team(id) & 2)
cs_set_user_model(id, "terror")
cs_set_user_money(id, cs_get_user_money(id) - 7000)	
ColorChat(0,BLUE, "^3[MG SHOP] ^4Один из игроков: ^3стал ^4шпионом, осторожнее", name)
}
}
case 9:
{
{
if(cs_get_user_money(id) < 4000)
{

ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
return PLUGIN_HANDLED;
}
player_respawn(id)
give_item(id, "weapon_hegrenade")
cs_set_user_money(id, cs_get_user_money(id) - 4000)
ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^3%s ^4Купил телепорт", name)
}
}
case 10:
{
{
if(cs_get_user_money(id) < 10000)
{

ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
return PLUGIN_HANDLED;
}
set_user_godmode(id,1)
set_task( 20.0, "bog_off",id)
cs_set_user_money(id, cs_get_user_money(id) - 10000)
ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^3%s ^4Купил Бессмертие", name)
}
}
case 11:
{
{
if(cs_get_user_money(id) < 8000)
{

ColorChat(id,GREEN, "[MG SHOP] У вас не достаточно денег!", name)
return PLUGIN_HANDLED;
}
give_item(id, "weapon_smokegrenade")
cs_set_user_money(id, cs_get_user_money(id) - 8000)
ColorChat(0,BLUE, "^3[MG SHOP] ^4Игрок: ^3%s ^4Купил Гранату (MG Effect Grenade)", name)
}
}
}
}

public bog_off(id)
{
	set_user_godmode(id,0)
}	

public render(id)
{
new iRed = random_num(0, 255)
new iGreen = random_num(0, 255)
new iBlue = random_num(0, 255)
set_user_rendering(id,kRenderFxGlowShell,iRed,iGreen,iBlue,kRenderNormal,0)
}

public ThreeJump(id)
{
if(szThreeJump[id]) 
{
new szButton = pev(id, pev_button)
new szOldButton = pev(id, pev_oldbuttons)

if((szButton & IN_JUMP) && !(pev(id, pev_flags) & FL_ONGROUND) && !(szOldButton & IN_JUMP))
{
if(szThreeJumpNum[id] < 1)
{
szDoThreeJump[id] = true
szThreeJumpNum[id]++
return PLUGIN_CONTINUE
}
}
if((szButton & IN_JUMP) && (pev(id, pev_flags) & FL_ONGROUND))
{
szThreeJumpNum[id] = 0
}
}
return PLUGIN_CONTINUE
}

public PostThreeJump(id)
{
if(szThreeJump[id])  
{
if(!is_user_alive(id)) 
return PLUGIN_CONTINUE

if(szDoThreeJump[id])
{
new Float:szVelocity[3]  
pev(id, pev_velocity, szVelocity)

szVelocity[2] = random_float(295.0,305.0)
set_pev(id, pev_velocity, szVelocity)

szDoThreeJump[id] = false

return PLUGIN_CONTINUE
}
}      
return PLUGIN_CONTINUE
}

public off_jump(id)
{
szThreeJump[id] = false
ColorChat(id, BLUE, "[MG] - Shop У вас закончилась функция двойного прыжка!")	
}

public EndInvis(id)
{
if(is_user_connected(id))
{
ka_render_add(id)
new name[32]
get_user_name(id, name, 31)
ColorChat(id,BLUE, "^3[MG SHOP] ^4Вы Стали^3 Видны", name)
}
return PLUGIN_HANDLED
}

public loter(id)
{
new shans
shans = random_num(0, 2)
new x = random_num(200, 6000)
switch(shans)
{
case 0:
{
cs_set_user_money(id, cs_get_user_money(id) + x)
ColorChat(id, GREEN, "^3[MG - Лотерея]^4Вы выиграли:^3%d$", x)
}
case 1:
{
cs_set_weapon_ammo(give_item(id, "weapon_deagle"), 1)
ColorChat(id, GREEN, "^3[MG - Лотерея]^4Вы выиграли:Дигл с 1 патроном")
}
case 2:
{
set_user_armor(id, get_user_armor(id) +155)
set_user_health(id, get_user_health(id) + 155)
ColorChat(id, GREEN, "^3[MG - Лотерея]^4Вы выиграли:[+155]^3 брони и здоровя")
}
}
return PLUGIN_HANDLED
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
