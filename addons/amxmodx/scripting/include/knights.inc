#include amxmodx
#include fun
#include cstrike

stock set_hp(const id, health)
{
	set_user_health(id, get_user_health(id) + health)
}

stock set_ar(const id, armor)
{
	set_user_armor(id, get_user_armor(id) + armor)
}

stock set_gravity(const id, gravity)
{
	set_user_gravity(id, gravity.0)
}

stock set_speed(const id, speed)
{
	set_user_speed(id, speed.0)
}

stock set_money(const id, money)
{
	cs_set_user_money(id, get_user_money(id) + money)
}

stock round_start(name)
{
	register_logevent(name, 2, "1=Round_Start")	
}
stock round_end(name)
{
	register_logevent(name, 2, "1=Round_End")	
}