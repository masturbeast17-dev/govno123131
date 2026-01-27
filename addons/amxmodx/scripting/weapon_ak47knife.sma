#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>

#define ENG_NULLENT		-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define ak47knife_WEAPONKEY	796
#define MAX_PLAYERS  			  32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 4
const OFFSET_LINUX_WEAPONS = 4

#define WEAP_LINUX_XTRA_OFF			4
#define m_fKnown				44
#define m_flNextPrimaryAttack 			46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF			5
#define m_flNextAttack				83

#define ak47knife_RELOAD_TIME 2.5

new const Fire_Sounds[][] = { "weapons/akm-1.wav" }
new const knifeattackhit_sound[] = "weapons/ak47knife_hitplayer.wav"
new const knifeattackmill_sound[] = "weapons/ak47knife_hitmiss.wav"
new const knifeattackwall_sound[] = "weapons/ak47knife_hitwall.wav"

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }
new ak47knife_V_MODEL[64] = "models/v_ak47knife.mdl"
new ak47knife_P_MODEL[64] = "models/p_ak47knife.mdl"
new ak47knife_W_MODEL[64] = "models/w_ak47knife.mdl"

new cvar_dmg_ak47knife, cvar_recoil_ak47knife, cvar_clip_ak47knife, cvar_ak47knife_ammo , cvar_ak47knife_delay , cvar_ak47knife_knife , cvar_rad
new g_MaxPlayers, g_orig_event_ak47knife, g_clip_ammo[33] , cvar_ak47knife_fire
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_ak47knife_TmpClip[33] , oldweap[33] ,  g_has_ak47knife[33] , g_delay[33]

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("Weapon: AK-47 Knife", "1.0", "Crock / =)")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_ak47knife_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_ak47knife_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_ak47knife_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47", "ak47knife_ItemPostFrame");
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "ak47knife_Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "ak47knife_Reload_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")

	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)

	cvar_dmg_ak47knife = register_cvar("ak47knife_dmg", "2.0")
	cvar_recoil_ak47knife = register_cvar("ak47knife_recoil", "0.9")
	cvar_clip_ak47knife = register_cvar("ak47knife_clip", "45")
	cvar_ak47knife_ammo = register_cvar("ak47knife_ammo", "120")
	cvar_ak47knife_delay =  register_cvar("ak47knife_delay", "0")
	cvar_ak47knife_knife = register_cvar("ak47knife_kndmg", "500.0")
	cvar_rad =  register_cvar("ak47knife_rad", "50.0")
	cvar_ak47knife_fire = register_cvar("ak47knife_speedfire", "0.1")
	register_clcmd("ak47knife", "give_ak47knife");
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(ak47knife_V_MODEL)
	precache_model(ak47knife_P_MODEL)
	precache_model(ak47knife_W_MODEL)
	precache_sound("weapons/akm_clipin.wav")
	precache_sound("weapons/akm_clipout.wav")
	precache_sound("weapons/akm_draw.wav")
	precache_sound("weapons/akm-1.wav")
	precache_sound(knifeattackhit_sound)
	precache_sound(knifeattackmill_sound)
	precache_sound(knifeattackwall_sound)
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	precache_model("sprites/640hud5.spr")
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/ak47.sc", name))
	{
		g_orig_event_ak47knife = get_orig_retval()
		return FMRES_HANDLED
	}
	
	return FMRES_IGNORED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return;

	new g_currentweapon = get_user_weapon(iAttacker)
	if(g_currentweapon != CSW_AK47) return
	
	if((g_currentweapon == CSW_AK47 && !g_has_ak47knife[iAttacker])) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt)
	{
		// Put decal on an entity
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
		write_short(iEnt)
		message_end()
	}
	else
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
		message_end()
	}
	
	// Show sparcles
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num ( 0, sizeof GUNSHOT_DECALS -1 ) ] )
	message_end()
}


public client_connect(id)
{
	g_has_ak47knife[id] = false
	g_delay[id] = 0
}

public client_disconnect(id)
{
	g_has_ak47knife[id] = false
	g_delay[id] = 0
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(id > 32)
		return PLUGIN_HANDLED

	if(!g_has_ak47knife[id])
		return PLUGIN_HANDLED	

	if(!is_user_alive(id) || cs_get_user_team(id) == CS_TEAM_T) 
		return PLUGIN_HANDLED

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon(id, szClip, szAmmo)
		if(szWeapID == CSW_AK47 && flNextAttack <= 0.0)
		{
			weapon_ability(id)
		}

	}

	return PLUGIN_HANDLED
}

public weapon_ability(id)
{
	if(!is_user_alive(id) || g_delay[id] ||  cs_get_user_team(id) == CS_TEAM_T)
		return;

	set_pdata_float(id, m_flNextAttack, 1.3, PLAYER_LINUX_XTRA_OFF)
	UTIL_PlayWeaponAnimation(id, 6)

	new Float:origin[3],Float:pOrigin[3], target, body ,aimOrigin[3],Float:aimOrigin2[3]
	get_user_aiming(id, target, body)
	get_user_origin(id, aimOrigin, 3)

	aimOrigin2[0] = float(aimOrigin[0])
	aimOrigin2[1] = float(aimOrigin[1])
	aimOrigin2[2] = float(aimOrigin[2])

	pev(id, pev_origin, pOrigin);
	pev(target, pev_origin, origin);

	new Float:dist = get_distance_f(origin, pOrigin);
	new Float:dist2 = get_distance_f(aimOrigin2, pOrigin);

	if(is_user_alive(target) &&  cs_set_user_team(id,CS_TEAM_T, target) && dist <= get_pcvar_float(cvar_rad) )
	{
		ExecuteHamB(Ham_TakeDamage, target , id , id, get_pcvar_float(cvar_ak47knife_knife) , DMG_BULLET | DMG_NEVERGIB);
		make_blood(aimOrigin2, get_pcvar_float(cvar_ak47knife_knife), target);
		emit_sound(id, CHAN_WEAPON,knifeattackhit_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}else if(!is_user_alive(target) && dist2 <= get_pcvar_float(cvar_rad))
	{
		emit_sound(id, CHAN_WEAPON,knifeattackwall_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}else emit_sound(id, CHAN_WEAPON,knifeattackmill_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	g_delay[id] = 1
	set_task(float(get_pcvar_num(cvar_ak47knife_delay)),"can_use",id)
}

stock make_blood(const Float:vTraceEnd[3], Float:Damage, hitEnt) {
	new bloodColor = ExecuteHam(Ham_BloodColor, hitEnt);
	if (bloodColor == -1)
		return;

	new amount = floatround(Damage);

	amount *= 2; //according to HLSDK

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BLOODSPRITE);
	write_coord(floatround(vTraceEnd[0]));
	write_coord(floatround(vTraceEnd[1]));
	write_coord(floatround(vTraceEnd[2]));
	write_short(m_iBlood[1]);
	write_short(m_iBlood[0]);
	write_byte(bloodColor);
	write_byte(min(max(3, amount/10), 16));
	message_end();
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_ak47.mdl"))
	{
		static iStoredSVDID
		
		iStoredSVDID = find_ent_by_owner(ENG_NULLENT, "weapon_ak47", entity)
	
		if(!is_valid_ent(iStoredSVDID))
			return FMRES_IGNORED;
	
		if(g_has_ak47knife[iOwner])
		{
			entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, ak47knife_WEAPONKEY)
			g_has_ak47knife[iOwner] = false
			g_delay[iOwner] = 0
			
			entity_set_model(entity, ak47knife_W_MODEL)
			
			return FMRES_SUPERCEDE;
		}
	}
	
	
	return FMRES_IGNORED;
}
public give_ak47knife(id)
{
	if(!(get_user_flags(id) & ADMIN_LEVEL_H) ) 
		return
	drop_weapons(id, 1);
	oldweap[id] = CSW_KNIFE
	new iWep2 = give_item(id,"weapon_ak47")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_ak47knife))
		cs_set_user_bpammo (id, CSW_AK47, get_pcvar_num(cvar_ak47knife_ammo))
	}
	UTIL_PlayWeaponAnimation(id, 2)
	set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
	g_has_ak47knife[id] = true;

}
public fw_ak47knife_AddToPlayer(ak47knife, id)
{
	if(!is_valid_ent(ak47knife) || !is_user_connected(id))
		return HAM_IGNORED;
	
	if(entity_get_int(ak47knife, EV_INT_WEAPONKEY) == ak47knife_WEAPONKEY)
	{
		g_has_ak47knife[id] = true
		
		entity_set_int(ak47knife, EV_INT_WEAPONKEY, 0)
		
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if (use_type == USE_STOPPED && is_user_connected(caller))
		replace_weapon_models(caller, get_user_weapon(caller))
}

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	replace_weapon_models(owner, weaponid)
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_AK47:
		{
			if ( cs_get_user_team(id) == CS_TEAM_T)
				return;
			
			if(g_has_ak47knife[id])
			{
				set_pev(id, pev_viewmodel2, ak47knife_V_MODEL)
				set_pev(id, pev_weaponmodel2, ak47knife_P_MODEL)
				if(oldweap[id] != CSW_AK47) 
				{
					UTIL_PlayWeaponAnimation(id, 2)
					set_pdata_float(id, m_flNextAttack, 1.0, PLAYER_LINUX_XTRA_OFF)
				}
				
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
        if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_AK47) || !g_has_ak47knife[Player])
        return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_ak47knife_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if (!g_has_ak47knife[Player])
		return;
	
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_ak47knife))
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
		return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_ak47knife_PrimaryAttack_Post(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	new szClip, szAmmo
	get_user_weapon(Player, szClip, szAmmo)
	if(Player > 0 && Player < 33)
	{
	if(!g_has_ak47knife[Player])
	{
		//if(szClip > 0) emit_sound(Player, CHAN_WEAPON, "weapons/ak47-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	if(g_has_ak47knife[Player])
	{
		new Float:push[3]
		pev(Player,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[Player],push)
		
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_ak47knife),push)
		xs_vec_add(push,cl_pushangle[Player],push)
		set_pev(Player,pev_punchangle,push)
		
		if (!g_clip_ammo[Player])
			return
		
		emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		UTIL_PlayWeaponAnimation(Player, 3)
		set_pdata_float(Player, m_flNextAttack, get_pcvar_float(cvar_ak47knife_fire), PLAYER_LINUX_XTRA_OFF)
	}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_AK47)
		{
			if(g_has_ak47knife[attacker])
				SetHamParamFloat(4, damage * get_pcvar_float(cvar_dmg_ak47knife))
		}
	}
}

public message_DeathMsg(msg_id, msg_dest, id)
{
	static szTruncatedWeapon[33], iAttacker, iVictim
	
	get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
	
	iAttacker = get_msg_arg_int(1)
	iVictim = get_msg_arg_int(2)
	
	if(!is_user_connected(iAttacker) || iAttacker == iVictim)
		return PLUGIN_CONTINUE
	
	if(equal(szTruncatedWeapon, "famas") && get_user_weapon(iAttacker) == CSW_AK47)
	{
		if(g_has_ak47knife[iAttacker])
			set_msg_arg_string(4, "famas")
	}
		
	return PLUGIN_CONTINUE
}

stock fm_cs_get_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}

public ak47knife_ItemPostFrame(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_ak47knife[id])
		return HAM_IGNORED;

	new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

	new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

	if( fInReload && flNextAttack <= 0.0 )
	{
		new j = min(get_pcvar_num(cvar_clip_ak47knife) - iClip, iBpAmmo)
	
		set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
		cs_set_user_bpammo(id, CSW_AK47, iBpAmmo-j);
		
		set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
		fInReload = 0
	}

	return HAM_IGNORED;
}

public ak47knife_Reload(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_ak47knife[id])
		return HAM_IGNORED;

	g_ak47knife_TmpClip[id] = -1;

	new iBpAmmo = cs_get_user_bpammo(id, CSW_AK47);
	new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

	if (iBpAmmo <= 0)
		return HAM_SUPERCEDE;

	if (iClip >= get_pcvar_num(cvar_clip_ak47knife))
		return HAM_SUPERCEDE;


	g_ak47knife_TmpClip[id] = iClip;

	return HAM_IGNORED;
}

public ak47knife_Reload_Post(weapon_entity) {
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (!g_has_ak47knife[id])
		return HAM_IGNORED;

	if (g_ak47knife_TmpClip[id] == -1)
		return HAM_IGNORED;

	set_pdata_int(weapon_entity, m_iClip, g_ak47knife_TmpClip[id], WEAP_LINUX_XTRA_OFF)

	set_pdata_float(weapon_entity, m_flTimeWeaponIdle, ak47knife_RELOAD_TIME, WEAP_LINUX_XTRA_OFF)

	set_pdata_float(id, m_flNextAttack, ak47knife_RELOAD_TIME, PLAYER_LINUX_XTRA_OFF)

	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)

	// relaod animation
	UTIL_PlayWeaponAnimation(id, 1)

	return HAM_IGNORED;
}


public CurrentWeapon(id) replace_weapon_models(id, read_data(2))
public can_use(id) g_delay[id] = 0
public plugin_natives ()	register_native("give_weapon_ak47knife", "native_give_weapon_add", 1)
public native_give_weapon_add(id) give_ak47knife(id)

stock drop_weapons(id, dropwhat)
{
     static weapons[32], num, i, weaponid
     num = 0
     get_user_weapons(id, weapons, num)
     
     for (i = 0; i < num; i++)
     {
          weaponid = weapons[i]
          
          if (dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
          {
               static wname[32]
               get_weaponname(weaponid, wname, sizeof wname - 1)
               engclient_cmd(id, "drop", wname)
          }
     }
}