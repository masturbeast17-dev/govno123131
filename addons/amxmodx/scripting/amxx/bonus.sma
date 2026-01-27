#include amxmodx

native ujbl_get_gang_points(id);
native ujbl_set_gang_points(id, iNum);

native ujbl_set_user_bonus(id, iNum);
native ujbl_get_user_bonus(id);

public plugin_init()
{
	register_plugin( "Бонусы", "...", "ToJI9IHGaa");
	register_clcmd("say /crack", "get_bonus");
}
public get_bonus(id)
{
	ujbl_set_gang_points(id, ujbl_get_gang_points(id) + 100);
	ujbl_set_user_bonus(id, ujbl_get_user_bonus(id) + 1);
}