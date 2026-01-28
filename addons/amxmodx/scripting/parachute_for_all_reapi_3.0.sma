#include <amxmodx>
#include <reapi>
#include <engine>

new pFallSpeed = 100

new bool:g_is_alive[33]

public plugin_init()
{
	register_plugin("Parachute for ALL [ReAPI]", "3.0", "Leo_[BH]")

	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_client_PreThink");
	
	RegisterHookChain(RG_CBasePlayer_Killed, "RG_Player_Killed", 0);
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG_Spawn_Post", 1);
}

public RG_client_PreThink(id)
{
	if(!g_is_alive[id]) return;

	new Float:fallspeed = pFallSpeed * -1.0

	new button = get_entvar(id, EntVars:var_button); // get_user_button(id)
	new oldbutton = get_entvar(id, EntVars:var_oldbuttons); // get_user_oldbutton(id)

	if (get_entvar(id, EntVars:var_gravity) == 0.1) set_entvar(id, EntVars:var_gravity, 1.0)

	if (button & IN_USE) 
	{
		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)

		if (velocity[2] < 0.0) 
		{
			entity_set_int(id, EV_INT_sequence, 3)
			entity_set_int(id, EV_INT_gaitsequence, 1)
			entity_set_float(id, EV_FL_frame, 1.0)
			entity_set_float(id, EV_FL_framerate, 1.0)
			set_entvar(id, EntVars:var_gravity, 0.1)

			velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
			entity_set_vector(id, EV_VEC_velocity, velocity)
		}
	}
	else if ((oldbutton & IN_USE)) 
	{
		set_entvar(id, EntVars:var_gravity, 1.0)
	}
}

// // // // // // // // // // // // // // //

public RG_Spawn_Post(id)
{
	if(is_user_alive(id))
	{
		g_is_alive[id] = true
	}
}

public RG_Player_Killed(victim, attacker)
{
	g_is_alive[victim] = false
}

public client_disconnect(id)
{
	g_is_alive[id] = false
}
