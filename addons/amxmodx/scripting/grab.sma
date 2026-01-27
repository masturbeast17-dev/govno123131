#include < amxmodx >
#include < amxmisc >
#include < fakemeta >
#include < jbe_core >
#include < chat >
#include < cstrike >
#include < fun >
#include < hamsandwich >

#define PLUGIN 		"[UJBL] Grab"
#define VERSION		"2.1"
#define AUTHOR		"ToJI9IHGaa"

// Макросы

#define TSK_CHKE 50

new client_data[33][4]

#define GRABBED  0
#define GRABBER  1
#define GRAB_LEN 2
#define FLAGS    3

stock close_menu_player(id) show_menu(id, 0, "^n", 1);

//Cvar Pointers
new p_enabled, p_players_only
new p_throw_force, p_min_dist, p_speed, p_grab_force
new p_choke_time, p_choke_dmg, p_auto_choke
new speed_off[33]
//Pseudo Constants
new g_iMaxPlayers, sp_Ball;

public plugin_init( )
{
	reIS-GAMINGter_plugin(PLUGIN, VERSION, AUTHOR)
	
	p_enabled = reIS-GAMINGter_cvar( "gp_enabled", "1" )
	p_players_only = reIS-GAMINGter_cvar( "gp_players_only", "0" )
	
	p_min_dist = reIS-GAMINGter_cvar ( "gp_min_dist", "90" )
	p_throw_force = reIS-GAMINGter_cvar( "gp_throw_force", "1500" )
	p_grab_force = reIS-GAMINGter_cvar( "gp_grab_force", "8" )
	p_speed = reIS-GAMINGter_cvar( "gp_speed", "5" )
	
	p_choke_time = reIS-GAMINGter_cvar( "gp_choke_time", "1.5" )
	p_choke_dmg = reIS-GAMINGter_cvar( "gp_choke_dmg", "5" )
	p_auto_choke = reIS-GAMINGter_cvar( "gp_auto_choke", "1" )
	
	reIS-GAMINGter_clcmd( "amx_grab", "force_grab" )
	reIS-GAMINGter_clcmd( "+grab", "grab" )
	reIS-GAMINGter_clcmd( "-grab", "unset_grabbed" )
	
	reIS-GAMINGter_clcmd( "+push", "push" )
	reIS-GAMINGter_clcmd( "-push", "push" )
	reIS-GAMINGter_clcmd( "+pull", "pull" )
	reIS-GAMINGter_clcmd( "-pull", "pull" )
	reIS-GAMINGter_clcmd( "push", "push2" )
	reIS-GAMINGter_clcmd( "pull", "pull2" )
	
	
	reIS-GAMINGter_menu("grab_menu", (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "Handle_GrabMenu")
	
	reIS-GAMINGter_clcmd( "drop" ,"throw" )
	
	reIS-GAMINGter_event( "DeathMsg", "DeathMsg", "a" )
	
	reIS-GAMINGter_forward( FM_PlayerPreThink, "fm_player_prethink" )
	
	g_iMaxPlayers = get_maxplayers()
	
}

public plugin_precache()
{
	precache_sound( "player/PL_PAIN2.WAV" )
	sp_Ball = precache_model("sprites/ball_mini.spr");
	
	precache_sound("ujbl_grab_target.wav");
	precache_sound("ujbl_grab_id.wav");
}

public fm_player_prethink( id )
{
	new target
	//Search for a target
	if ( client_data[id][GRABBED] == -1 )
	{
		new Float:orig[3], Float:ret[3]
		get_view_pos( id, orig )
		ret = vel_by_aim( id, 9999 )
		
		ret[0] += orig[0]
		ret[1] += orig[1]
		ret[2] += orig[2]
		
		target = traceline( orig, ret, id, ret )
		
		if( 0 < target <= g_iMaxPlayers )
		{
			if( is_grabbed( target, id ) ) return FMRES_IGNORED
			set_grabbed( id, target )
		}
		else if( !get_pcvar_num( p_players_only ) )
		{
			new movetype
			if( target && pev_valid( target ) )
			{
				movetype = pev( target, pev_movetype )
				if( !( movetype == MOVETYPE_WALK || movetype == MOVETYPE_STEP || movetype == MOVETYPE_TOSS ) )
					return FMRES_IGNORED
			}
			else
			{
				target = 0
				new ent = engfunc( EngFunc_FindEntityInSphere, -1, ret, 12.0 )
				while( !target && ent > 0 )
				{
					movetype = pev( ent, pev_movetype )
					if( ( movetype == MOVETYPE_WALK || movetype == MOVETYPE_STEP || movetype == MOVETYPE_TOSS )
							&& ent != id  )
						target = ent
					ent = engfunc( EngFunc_FindEntityInSphere, ent, ret, 12.0 )
				}
			}
			if( target )
			{
				if( is_grabbed( target, id ) ) return FMRES_IGNORED
				set_grabbed( id, target )
			}
		}
	}
	
	target = client_data[id][GRABBED]
	//If they've grabbed something
	if( target > 0 )
	{
		if( !pev_valid( target ) || ( pev( target, pev_health ) < 1 && pev( target, pev_max_health ) ) )
		{
			unset_grabbed( id )
			return FMRES_IGNORED
		}
		 
		//Use key choke
		if( pev( id, pev_button ) & IN_USE )
			do_choke( id )
		
		//Push and pull
		new cdf = client_data[id][FLAGS]
		if ( cdf & (1<<1) )
			do_pull( id )
		else if ( cdf & (1<<0) )
			do_push( id )
		
		if( target > g_iMaxPlayers ) grab_think( id )
	}
	
	//If they're grabbed
	target = client_data[id][GRABBER]
	if( target > 0 ) grab_think( target )
	
	return FMRES_IGNORED
}

public grab_think( id ) //id of the grabber
{
	new target = client_data[id][GRABBED]
	
	//Keep grabbed clients from sticking to ladders
	if( pev( target, pev_movetype ) == MOVETYPE_FLY && !(pev( target, pev_button ) & IN_JUMP ) ) client_cmd( target, "+jump;wait;-jump" )
	
	//Move targeted client
	new Float:tmpvec[3], Float:tmpvec2[3], Float:torig[3], Float:tvel[3]
	
	get_view_pos( id, tmpvec )
	
	tmpvec2 = vel_by_aim( id, client_data[id][GRAB_LEN] )
	
	torig = get_target_origin_f( target )
	
	new force = get_pcvar_num( p_grab_force )
	
	tvel[0] = ( ( tmpvec[0] + tmpvec2[0] ) - torig[0] ) * force
	tvel[1] = ( ( tmpvec[1] + tmpvec2[1] ) - torig[1] ) * force
	tvel[2] = ( ( tmpvec[2] + tmpvec2[2] ) - torig[2] ) * force
	
	set_pev( target, pev_velocity, tvel )
}

stock Float:get_target_origin_f( id )
{
	new Float:orig[3]
	pev( id, pev_origin, orig )
	
	//If grabbed is not a player, move origin to center
	if( id > g_iMaxPlayers )
	{
		new Float:mins[3], Float:maxs[3]
		pev( id, pev_mins, mins )
		pev( id, pev_maxs, maxs )
		
		if( !mins[2] ) orig[2] += maxs[2] / 2
	}
	
	return orig
}

public grab( id )
{
	if( !(get_user_flags(id) & ADMIN_BAN)|| !get_pcvar_num( p_enabled ) || jbe_get_day_mode() == 3) return PLUGIN_HANDLED
	
	if ( !client_data[id][GRABBED] ) client_data[id][GRABBED] = -1
	
	return PLUGIN_HANDLED
}

new bool:g_Freez[33], iPlayerType[33][2];
public grab_menu(id, iType) 
{
	jbe_informer_offset_up(id);
	new tg = client_data[id][GRABBED]
	iPlayerType[id][0] = iType;
	
	new szMenu[1024], iLen;
	new iKeys;
	if(iType == 1)
	{
		iKeys = (1<<0|1<<1|1<<2|1<<5|1<<6|1<<7|1<<8|1<<9) 
		new name[32];
		get_user_name(tg, name, charsmax(name));
		iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "Вы взяли: \r%s^n\wЖизни: \r%d \d|\w Броня: \r%d^n\wДеньги: \r%d \d|\w Команда: \r%s^n^n", 
		name, get_user_health(tg), get_user_armor(tg), jbe_get_user_money(tg), jbe_get_user_team(tg) == 2 ? "Охранник":"Зэк");
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1]\w Перевести за \r%s^n", jbe_get_user_team(tg) == 2 ? "Зеков":"Охрану");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2]\w Убить^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[3] \r%s^n^n", !g_Freez[tg] ? "Заморозить":"Разморозить");
		
		if(get_user_flags(id) & ADMIN_LEVEL_F)
		{
			switch(jbe_get_user_team(tg))
			{
				case 1:
				{
					iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4]\r %s\w розыск^n", jbe_is_user_wanted(tg) ? "Забрать" : "Дать");
					iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5]\r %s\w отдых^n^n", jbe_is_user_free(tg) ? "Забрать" : "Дать");
				}
				default:
				{
					iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4]\r %s\w Бесмертие^n", get_user_godmode(tg) ? "Забрать" : "Дать");
					iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5]\r %s\w Режим Призрака^n^n", get_user_noclip(tg) ? "Забрать" : "Дать");
				}
			}
			iKeys |= (1<<3|1<<4)
		}else
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[4]\d Мало Полномочий [ГодМод]^n");
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[5]\d Мало Полномочий [ГодМод]^n^n");
		}
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[6]\w Закрутить Экран^n^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[7]\r Кикнуть^n^n");
		
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[8]\r Притянуть^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[9]\r Отблизить^n^n");
	}
	else
	{
		iKeys = (1<<0|1<<1|1<<9);
		iLen = formatex(szMenu[iLen], charsmax(szMenu) - iLen, "Вы взяли: \rОружие^n^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[1]\r Притянуть^n");
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[2]\r Отблизить^n^n");
	}	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n\y[0]\w Выход^n^n");
	show_menu(id, iKeys, szMenu, -1, "grab_menu");	
}
	 
public Handle_GrabMenu(id, iKey) 
{
	new tg = client_data[id][GRABBED]
	new pName[32], tName[32]
	get_user_name(id, pName, charsmax(tName));
	get_user_name(tg, tName, charsmax(tName));
	if(iPlayerType[id][0] == 1) if(!is_user_alive(tg) || !is_user_connected(tg)) return PLUGIN_HANDLED;
	
	switch(iKey)
	{
		case 0:
		{
			switch(iPlayerType[id][0])
			{
				case 1:
				{
					switch(jbe_get_user_team(tg))
					{
						case 1:
						{
							jbe_set_user_team(tg, 2);
							chat(0, "!y[!IS-GAMING!y] Администратор !g%s!y перевёл !g%s!y за !gОхранников", pName, tName);
						}
						default: 
						{
							jbe_set_user_team(tg, 1);
							chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y перевёл !g%s!y за !gЗаключенных", pName, tName);
						}
					}
				}
				case 0: 
				{
					client_cmd(id, "+pull");
					iPlayerType[id][1] = 1;
					set_task(0.4, "UnPullPushTask", id + 9876);
					grab_menu(id, 0); 
				}
			}
		}
		case 1:
		{
			switch(iPlayerType[id][0])
			{
				case 1: user_kill(tg);
				case 0: 
				{
					client_cmd(id, "+push");
					iPlayerType[id][1] = 2;
					set_task(0.4, "UnPullPushTask", id + 9876);
					grab_menu(id, 0); 
				}
				
			}
		}
		case 2: 
		{
			switch(g_Freez[tg])
			{
				case false:
				{
					set_pev(tg, pev_flags, pev(tg, pev_flags) | FL_FROZEN);
					chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y заморозил !g%s!y", pName, tName);
					g_Freez[tg] = true;
				}
				case true:
				{
					set_pev(tg, pev_flags, pev(tg, pev_flags) & ~FL_FROZEN);
					chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y разморозил !g%s!y", pName, tName);
					g_Freez[tg] = false;
				}
			}
		}
		case 3:
		{
			switch(jbe_get_user_team(tg))
			{
				case 1:
				{
					if(jbe_is_user_wanted(tg))
					{
						jbe_sub_user_wanted(tg)
						chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y забрал розыск у !g%s!y", pName, tName);
					}else
					{
						jbe_add_user_wanted(tg);
						chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y дал розыск у !g%s!y", pName, tName);
					}
				}
				default:
				{
					if(get_user_godmode(tg))
					{
						set_user_godmode(tg, 0);
						chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y забрал GodMode у !g%s!y", pName, tName);
					}else
					{
						set_user_godmode(tg, 1);
						chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y дал GodMode у !g%s!y", pName, tName);
					}
				}
			}
		}
		case 4:
		{
			switch(jbe_get_user_team(tg))
			{
				case 1:
				{
					if(jbe_is_user_free(tg))
					{
						jbe_sub_user_free(tg)
						chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y забрал выходной у !g%s!y", pName, tName);
					}else
					{
						jbe_add_user_free(tg);
						chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y дал выходной у !g%s!y", pName, tName);
					}
				}
				default:
				{
					if(get_user_noclip(tg))
					{
						set_user_noclip(tg, 0);
						chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y забрал NoClip у !g%s!y", pName, tName);
					}else
					{
						set_user_noclip(tg, 1);
						chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y дал NoClip у !g%s!y", pName, tName);
					}
				}
			}
		}
		case 5:
		{
			set_pev(tg, pev_punchangle, { 400.0, 999.0, 400.0 })
			chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y закрутил экран !g%s!y", pName, tName);
		}
		case 6: 
		{
			server_cmd("kick #%d ^"Кикнут Грабом^" %s", get_user_userid(tg), pName)
			chat(0, "!y[!gIS-GAMING!y] Администратор !g%s!y кикнул !g%s!y", pName, tName);
		}
		case 7:
		{
			client_cmd(id, "+pull");
			iPlayerType[id][1] = 1;
			set_task(0.4, "UnPullPushTask", id + 9876);
			grab_menu(id, 1); 
		}
		case 8:
		{
			client_cmd(id, "+push");
			iPlayerType[id][1] = 2;
			set_task(0.4, "UnPullPushTask", id + 9876);
			grab_menu(id, 1); 
		}
		case 9: return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED
}
public UnPullPushTask(id)
{
	id -= 9876;
	switch(iPlayerType[id][1])
	{
		case 1: client_cmd(id, "-pull");
		case 2: client_cmd(id, "-push");
	}
}
public throw( id )
{
	new target = client_data[id][GRABBED]
	if( target > 0 )
	{
		set_pev( target, pev_velocity, vel_by_aim( id, get_pcvar_num(p_throw_force) ) )
		unset_grabbed( id )
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public unset_grabbed( id )
{
	new target = client_data[id][GRABBED]
	if( target > 0 && pev_valid( target ) )
	{
		if(task_exists(target + 9141)) remove_task(target + 9141); 
		if(!jbe_is_user_wanted(target) && !jbe_is_user_free(target))
		{
			set_pev( target, pev_renderfx, kRenderFxNone )
			set_pev( target, pev_rendercolor, {0.0, 0.0, 0.0} )
			set_pev( target, pev_rendermode, kRenderNormal )
			set_pev( target, pev_renderamt, 16.0 )
		}
		
		if( 0 < target <= g_iMaxPlayers )
			client_data[target][GRABBER] = 0
	}
	close_menu_player(id);
	client_data[id][GRABBED] = 0;
}

//Grabs onto someone
public set_grabbed( id, target )
{
	if(!jbe_is_user_wanted(target) && !jbe_is_user_free(target) && pev_valid(target))
	{
		jbe_set_user_rendering(target, kRenderFxGlowShell, random_num(0,255), random_num(0,255), random_num(0,255), kRenderNormal, 4);
		set_task(0.4, "Task_RandomGlow", target + 9141, _, _, "b");
	}
	if( 0 < target <= g_iMaxPlayers ) client_data[target][GRABBER] = id
	client_data[id][FLAGS] = 0;
	client_data[id][GRABBED] = target;
	new name[33], name2[33]
	get_user_name(id, name, 32) 
	get_user_name(target, name2, 32)
	if(get_user_team(target)==1 || get_user_team(target)==2)
	{
		chat(target, "!y[!gIS-GAMING!y] Администратор !g%s !yвзял Вас !gграбом", name)  
		chat(id, "!y[!gIS-GAMING!y] Вы взяли грабом !g%s", name2)
		grab_menu(id, 1);
		client_cmd(id, "spk sound/ujbl_grab_id");
		client_cmd(target, "spk sound/ujbl_grab_target");
	}
	else
	{
		client_cmd(id, "spk sound/ujbl_grab_id");
		chat(id, "!y[!gIS-GAMING!y] Вы взяли грабом !gОружие")  
		grab_menu(id, 0);
	}
	new Float:torig[3], Float:orig[3]
	pev( target, pev_origin, torig )
	pev( id, pev_origin, orig )
	CREATE_SPRITETRAIL(torig, sp_Ball, 10, 10, 1, 20, 10);
	client_data[id][GRAB_LEN] = floatround( get_distance_f( torig, orig ) )
	if( client_data[id][GRAB_LEN] < get_pcvar_num( p_min_dist ) ) client_data[id][GRAB_LEN] = get_pcvar_num( p_min_dist )
}
public Task_RandomGlow(id)
{
	id -= 9141;
	if(!jbe_is_user_wanted(id) && !jbe_is_user_free(id) && id > 0 && pev_valid(id))
	{
		jbe_set_user_rendering(id, kRenderFxGlowShell, random_num(0,255), random_num(0,255), random_num(0,255), kRenderNormal, 4);
	}else remove_task(id + 9141);
}
public push( id )
{
	client_data[id][FLAGS] ^= (1<<0)
	return PLUGIN_HANDLED
}

public pull( id )
{
	client_data[id][FLAGS] ^= (1<<1)
	return PLUGIN_HANDLED
}

public push2( id )
{
	if( client_data[id][GRABBED] > 0 )
	{
		do_push( id )
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public pull2( id )
{
	if( client_data[id][GRABBED] > 0 )
	{
		do_pull( id )
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public do_push( id )
	if( client_data[id][GRAB_LEN] < 9999 )
		client_data[id][GRAB_LEN] += get_pcvar_num( p_speed )

public do_pull( id )
{
	new mindist = get_pcvar_num( p_min_dist )
	new len = client_data[id][GRAB_LEN]
	
	if( len > mindist )
	{
		len -= get_pcvar_num( p_speed )
		if( len < mindist ) len = mindist
		client_data[id][GRAB_LEN] = len
	}
	else if( get_pcvar_num( p_auto_choke ) )
		do_choke( id )
}

public do_choke( id )
{
	new target = client_data[id][GRABBED]
	if( client_data[id][FLAGS] & (1<<2) || id == target || target > g_iMaxPlayers) return
	
	new dmg = get_pcvar_num( p_choke_dmg )
	new vec[3]
	FVecIVec( get_target_origin_f( target ), vec )
	
	message_begin( MSG_ONE, get_user_msgid("ScreenShake"), _, target )
	write_short( 999999 ) //amount
	write_short( 9999 ) //duration
	write_short( 999 ) //frequency
	message_end( )
	
	message_begin( MSG_ONE, get_user_msgid("ScreenFade"), _, target )
	write_short( 9999 ) //duration
	write_short( 100 ) //hold
	write_short( SF_FADE_MODULATE ) //flags
	write_byte( 200 ) //r
	write_byte( 0 ) //g
	write_byte( 0 ) //b
	write_byte( 200 ) //a
	message_end( )
	
	message_begin( MSG_ONE, get_user_msgid("Damage"), _, target )
	write_byte( 0 ) //damage armor
	write_byte( dmg ) //damage health
	write_long( DMG_CRUSH ) //damage type
	write_coord( vec[0] ) //origin[x]
	write_coord( vec[1] ) //origin[y]
	write_coord( vec[2] ) //origin[z]
	message_end( )
		
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BLOODSTREAM )
	write_coord( vec[0] ) //pos.x
	write_coord( vec[1] ) //pos.y
	write_coord( vec[2] + 15 ) //pos.z
	write_coord( random_num( 0, 255 ) ) //vec.x
	write_coord( random_num( 0, 255 ) ) //vec.y
	write_coord( random_num( 0, 255 ) ) //vec.z
	write_byte( 70 ) //col index
	write_byte( random_num( 50, 250 ) ) //speed
	message_end( )
	
	new health = pev( target, pev_health ) - dmg
	set_pev( target, pev_health, float( health ) )
	if( health < 1 ) dllfunc( DLLFunc_ClientKill, target )
	
	emit_sound( target, CHAN_BODY, "player/PL_PAIN2.WAV", VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
	
	client_data[id][FLAGS] ^= (1<<2)
	set_task( get_pcvar_float( p_choke_time ), "clear_no_choke", TSK_CHKE + id )
}

public clear_no_choke( tskid )
{
	new id = tskid - TSK_CHKE
	client_data[id][FLAGS] ^= (1<<2)
}

//Grabs the client and teleports them to the admin
public force_grab(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN) || !get_pcvar_num( p_enabled )) return PLUGIN_HANDLED;

	new arg[33];
	read_argv( 1, arg, 32 );

	new targetid = cmd_target(id, arg, 1);
	
	if(is_grabbed(targetid, id)) return PLUGIN_HANDLED;
	if(!is_user_alive(targetid)) return PLUGIN_HANDLED;

	new Float:tmpvec[3], Float:orig[3], Float:torig[3], Float:trace_ret[3];
	new bool:safe = false, i
	
	get_view_pos( id, orig )
	tmpvec = vel_by_aim( id, get_pcvar_num( p_min_dist ) )
	
	for( new j = 1; j < 11 && !safe; j++ )
	{
		torig[0] = orig[0] + tmpvec[i] * j;
		torig[1] = orig[1] + tmpvec[i] * j;
		torig[2] = orig[2] + tmpvec[i] * j;
		
		traceline(tmpvec, torig, id, trace_ret)
		
		if(get_distance_f(trace_ret, torig)) break;		
		engfunc(EngFunc_TraceHull, torig, torig, 0, HULL_HUMAN, 0, 0);
		if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)) safe = true
	}
	

	pev(id, pev_origin, orig);
	new try[3];
	orig[2] += 2;
	while( try[2] < 3 && !safe )
	{
		for( i = 0; i < 3; i++ )
			switch( try[i] )
			{
				case 0 : torig[i] = orig[i] + ( i == 2 ? 80 : 40 );
				case 1 : torig[i] = orig[i];
				case 2 : torig[i] = orig[i] - ( i == 2 ? 80 : 40 );
			}
		
		traceline( tmpvec, torig, id, trace_ret )
		
		engfunc( EngFunc_TraceHull, torig, torig, 0, HULL_HUMAN, 0, 0 )
		if ( !get_tr2( 0, TR_StartSolid ) && !get_tr2( 0, TR_AllSolid ) && get_tr2( 0, TR_InOpen )
				&& !get_distance_f( trace_ret, torig ) ) safe = true
		
		try[0]++
		if( try[0] == 3 )
		{
			try[0] = 0
			try[1]++
			if(try[1] == 3)
			{
				try[1] = 0;
				try[2]++;
			}
		}
	}
	
	if( safe )
	{
		set_pev( targetid, pev_origin, torig )
		set_grabbed( id, targetid )
	}

	return PLUGIN_HANDLED
}

public is_grabbed( target, grabber )
{
	for( new id = 1; id <= g_iMaxPlayers; id++ )
	if(client_data[id][GRABBED] == target)
	{
		unset_grabbed(grabber);
		return true;
	}
	return false;
}

public DeathMsg( )
	kill_grab( read_data( 2 ) )

public client_disconnect( id )
{
	kill_grab( id )
	speed_off[id] = false
	return PLUGIN_CONTINUE
}

public kill_grab( id )
{
	//If given client has grabbed, or has a grabber, unset it
	if( client_data[id][GRABBED] )
		unset_grabbed( id )
	else if( client_data[id][GRABBER] )
		unset_grabbed( client_data[id][GRABBER] )
}

stock traceline( const Float:vStart[3], const Float:vEnd[3], const pIgnore, Float:vHitPos[3] )
{
	engfunc( EngFunc_TraceLine, vStart, vEnd, 0, pIgnore, 0 )
	get_tr2( 0, TR_vecEndPos, vHitPos )
	return get_tr2( 0, TR_pHit )
}

stock get_view_pos( const id, Float:vViewPos[3] )
{
	new Float:vOfs[3]
	pev( id, pev_origin, vViewPos )
	pev( id, pev_view_ofs, vOfs )		
	
	vViewPos[0] += vOfs[0]
	vViewPos[1] += vOfs[1]
	vViewPos[2] += vOfs[2]
}

stock Float:vel_by_aim( id, speed = 1 )
{
	new Float:v1[3], Float:vBlah[3]
	pev( id, pev_v_angle, v1 )
	engfunc( EngFunc_AngleVectors, v1, v1, vBlah, vBlah )
	
	v1[0] *= speed
	v1[1] *= speed
	v1[2] *= speed
	
	return v1
}
stock fm_give_item(index, const item[])
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent))
		return 0

	new Float:origin[3];
	pev(index, pev_origin, origin)
	set_pev(ent, pev_origin, origin)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)

	new save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, index)
	if (pev(ent, pev_solid) != save)
		return ent

	engfunc(EngFunc_RemoveEntity, ent)

	return -1
}

stock fm_strip_user_weapons(id)
{
        static ent
        ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
        if (!pev_valid(ent)) return;
       
        dllfunc(DLLFunc_Spawn, ent)
        dllfunc(DLLFunc_Use, ent, id)
        engfunc(EngFunc_RemoveEntity, ent)
}

stock CREATE_SPRITETRAIL(Float:vecOrigin[3], pSprite, iCount, iLife, iScale, iVelocityAlongVector, iRandomVelocity)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITETRAIL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]); // start
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]); // end
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(pSprite);
	write_byte(iCount);
	write_byte(iLife); // 0.1's
	write_byte(iScale);
	write_byte(iVelocityAlongVector);
	write_byte(iRandomVelocity);
	message_end(); 
}