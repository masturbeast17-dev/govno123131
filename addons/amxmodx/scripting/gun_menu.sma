#include amxmodx

#define PLUGIN "menu"
#define VERSION "1.0"
#define AUTHOR "AMC"

public plugin_init()
{
register_plugin(PLUGIN, VERSION, AUTHOR)
register_clcmd("adminmenu", "server_menu" )
}

public server_menu(id)
{
new i_Menu = menu_create("\wМенюшка оружий \r[\yby zloi\r]*", "MMENU" )
menu_additem(i_Menu, "\wЗонтик", "1", 0)
menu_additem(i_Menu, "\y2 пистолета", "2", 0)
menu_additem(i_Menu, "\wАвтомат СФ", "3", 0)
menu_additem(i_Menu, "\rАк-47 +НОЖ ", "4", 0)
menu_additem(i_Menu, "\yСнайперка", "5", 0)
menu_additem(i_Menu, "\rОбрез", "6", 0)

menu_setprop(i_Menu, MPROP_EXIT, MEXIT_ALL)
menu_display(id, i_Menu, 0)
return PLUGIN_HANDLED
}
public MMENU(id, menu, item)
{
if (item == MENU_EXIT)
{
menu_destroy(menu)

return PLUGIN_HANDLED
}
new s_Data[6], s_Name[64], i_Access, i_Callback
menu_item_getinfo(menu, item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback)
new i_Key = str_to_num(s_Data)
switch(i_Key)
{
case 1:
if(get_user_flags(id) & ADMIN_LEVEL_H)
{
client_cmd(id, "zontik" )
}
else
{
server_menu(id)
}
case 2:
if(get_user_flags(id) & ADMIN_LEVEL_H)
{
client_cmd(id, "infinity" )
}
else
{
server_menu(id)
}
case 3:
if(get_user_flags(id) & ADMIN_LEVEL_H)
{
client_cmd(id, "sf1" )
}
else
{
server_menu(id)
}
case 4:
if(get_user_flags(id) & ADMIN_LEVEL_H)
{
client_cmd(id, "ak47knife" )
}
else
{
server_menu(id)
}
case 5:
if(get_user_flags(id) & ADMIN_LEVEL_H)
{
client_cmd(id, "vsk94" )
}
else
{
server_menu(id)
}
case 6:
{
client_cmd(id, "dbarell" )
}
case 7:
{
client_cmd(id, "" )
}
case 8:
{
client_cmd(id, "" )
}
case 9:
{
client_cmd(id, "" )
}
}

menu_destroy(menu)
return PLUGIN_HANDLED

}
