#include <amxmodx>
#include <reapi>

public plugin_init()
{
	register_plugin("Change Game Name", "1.2", "ReHLDS Team");
	register_cvar("amx_gamename", "ReHLDS");
#if AMXX_VERSION_NUM < 183
	set_task(1.0, "OnAutoConfigsBuffered")
#endif
}

public OnAutoConfigsBuffered()
{
	new GameName[32];
	get_cvar_string("amx_gamename", GameName, charsmax(GameName));
	set_member_game(m_GameDesc, GameName);
}