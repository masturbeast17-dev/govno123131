#if defined _hud_menu_included
  #endinput
#endif
#define _hud_menu_included

native hudmenu_create(titulo[], handler[], r, g, b, Float:x, Float:y, autopage) 

native hudmenu_additem(menu, item[], num) 

native hudmenu_settext(menu, item[])

native hudmenu_show(player, menu, keysmenu, page=0) 

native hudmenu_destroy(menu) 