#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <engine>
#include <hamsandwich>
#include jbe_core

#define		CREATE										"[U-JBL] Создатель меню"
#define		BY											"Lol"
#define		IS-GAMING									"IS-GAMING"

#define MAX_PLAYERS 32

public plugin_init()
{
	register_plugin(	CREATE, BY, IS-GAMING		);
	
    register_menucmd(register_menuid("Show_CreatorMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_CreatorMenu");
    register_menucmd(register_menuid("Show_GiveMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_GiveMenu");
    register_menucmd(register_menuid("Show_OjjMenu"), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_OjjMenu");
}

public Show_CreatorMenu(id)	{
	if(~get_user_flags(id) & ADMIN_RCON)
	return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iKeys = (1<<0|1<<1|1<<2|1<<3|1<<8|1<<9);
	static menu[2014], len; len = 0;
	len = formatex(menu[len], charsmax(menu) - len, "\yПанель создателя^n^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r1\y] Меню \rРаздачи^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r2\y] Меню \rОбъектов^n");

	len += formatex(menu[len], charsmax(menu) - len, "\y[\r0\y]\w Выход");
	show_menu(id, iKeys, menu, -1, "Show_CreatorMenu"); return PLUGIN_HANDLED;
}

public Handle_CreatorMenu(id, iKey)
{
	switch(iKey)
	{
		case 0: return Show_GiveMenu(id);
		case 1: return Show_OjjMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_CreatorMenu(id);
}

public Show_GiveMenu(id)	{
	if(~get_user_flags(id) & ADMIN_RCON)
	return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iKeys = (1<<0|1<<1|1<<2|1<<3|1<<8|1<<9);
	static menu[2014], len; len = 0;
	len = formatex(menu[len], charsmax(menu) - len, "\yПанель раздачи^n^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r1\y] Разраб... \rПунктов^n");

	len += formatex(menu[len], charsmax(menu) - len, "\y[\r0\y]\w Выход");
	show_menu(id, iKeys, menu, -1, "Show_GiveMenu"); return PLUGIN_HANDLED;
}

public Handle_GiveMenu(id, iKey)
{
	switch(iKey)
	{
		case 0: { client_cmd(id, "test"); return PLUGIN_HANDLED; }
		case 9: return PLUGIN_HANDLED;
	}
	return Show_GiveMenu(id);
}

public Show_OjjMenu(id)	{
	if(~get_user_flags(id) & ADMIN_RCON)
	return PLUGIN_HANDLED;
	jbe_informer_offset_up(id);
	new iKeys = (1<<0|1<<1|1<<2|1<<3|1<<8|1<<9);
	static menu[2014], len; len = 0;
	len = formatex(menu[len], charsmax(menu) - len, "\yПанель выдачи \rОбъектов^n^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r1\y] Поставить \rБарыгу^n");
	len += formatex(menu[len], charsmax(menu) - len, "\y[\r2\y] Удалить \rБарыгу^n");

	len += formatex(menu[len], charsmax(menu) - len, "\y[\r0\y]\w Выход");
	show_menu(id, iKeys, menu, -1, "Show_OjjMenu"); return PLUGIN_HANDLED;
}

public Handle_OjjMenu(id, iKey)
{
	switch(iKey)
	{
		case 0: { client_cmd(id, "trade_spawn"); return PLUGIN_HANDLED; }
		case 1: { client_cmd(id, "trade_remove"); return PLUGIN_HANDLED; }
		case 9: return PLUGIN_HANDLED;
	}
	return Show_OjjMenu(id);
}