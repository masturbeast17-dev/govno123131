#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>

#define ENG_NULLENT			-1
#define EV_INT_WEAPONKEY	EV_INT_impulse
#define blockar_WEAPONKEY 	284548119
#define MAX_PLAYERS  		32
#define CSW_BRICKPEACE CSW_M4A1
#define weapon_blockar "weapon_m4a1"
#define ROCKET_CLASS "block_missile"

//////////// Change Here For Customize //////////////////////////

/////// MODE A ///////////
#define DEFAULT_CLIP 40
#define DEFAULT_BPAMMO 200
#define DEFAULT_DAMAGE 1.5
#define DEFAULT_SPEED 1.1
#define DEFAULT_RECOIL 0.8
#define RELOAD_TIME 3.0

/////// MODE B ///////////
#define ROCKET_AMMO 10
#define DAMAGE_EXPLODE 600.0
#define EXPLODE_RADIUS 200.0

/////////////////////////////////////////////////////////////////

const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
const m_szAnimExtention = 492

#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif

#define WEAP_LINUX_XTRA_OFF		4
#define m_fKnown					44
#define m_flNextPrimaryAttack 		46
#define m_flTimeWeaponIdle			48
#define m_iClip					51
#define m_fInReload				54
#define PLAYER_LINUX_XTRA_OFF	5
#define m_flNextAttack				83

enum
{
	ANIM_IDLE = 0,
	ANIM_IDLE_EMPTY,
	ANIM_SHOOT_START,
	ANIM_SHOOT_END,
	ANIM_CHANGE1_1,
	ANIM_CHANGE1_2,
	ANIM_CHANGE2_1,
	ANIM_CHANGE2_2,
	ANIM_RELOAD,
	ANIM_DRAW_1,
	ANIM_DRAW_2
}

enum
{
	ANIMX_IDLE = 0,
	ANIMX_SHOOT_1,
	ANIMX_SHOOT_2,
	ANIMX_SHOOT_3,
	ANIMX_CHANGE_1,
	ANIMX_CHANGE_2,
	ANIMX_RELOAD,
	ANIMX_DRAW_1
}


#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1)

new const v_model[] = "models/v_blockar1.mdl"
new const p_model[] = "models/p_blockar1.mdl"
new const v2_model[] = "models/v_blockar2.mdl"
new const p2_model[] = "models/p_blockar2.mdl"
new const v_change_model[] = "models/v_blockchange.mdl"
new const w_model[] = "models/w_blockar1.mdl"
new const ROCKET_MODEL[] = "models/block_missile.mdl"
new const GRENADE_EXPLOSION[] = "sprites/fexplo.spr"
new const weapon_sound[15][] = 
{
	"weapons/blockar2-1.wav",
	"weapons/blockar1_change1.wav",
	"weapons/blockar1_change2.wav",
	"weapons/blockar1_clipin.wav",
	"weapons/blockar1_clipout.wav",
	"weapons/blockar1_draw.wav",
	"weapons/blockar1-1.wav",
	"weapons/blockar2_change1_1.wav",
	"weapons/blockar2_change2_1.wav",
	"weapons/blockar2_change2_2.wav",
	"weapons/blockar2_idle.wav",
	"weapons/blockar2_reload.wav",
	"weapons/blockar2_shoot_end.wav",
	"weapons/blockar2_shoot_start.wav",
	"weapons/blockar2-1.wav"
}

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new g_MaxPlayers, g_orig_event_blockar, g_IsInPrimaryAttack
new Float:cl_pushangle[MAX_PLAYERS + 1][3], m_iBlood[2]
new g_had_blockar[33], g_clip_ammo[33], g_blockar_TmpClip[33], oldweap[33]
new gmsgWeaponList, g_Ham_Bot

new sExplo, g_mode[33], muzzle, blockar_clip[33], blockar_bpammo[33]
new g_rocket_ammo[33]
new sTrail


const PRIMARY_WEAPONS_BIT_SUM = 
(1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_BRICKPEACE)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<
CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_init()
{
	register_plugin("Brick Peace V2", "1.0", "m4m3ts")
	register_cvar("brick_version", "m4m3ts", FCVAR_SERVER|FCVAR_SPONLY)
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	register_touch(ROCKET_CLASS, "*", "fw_touch2")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m4a1", "fw_blockar_AddToPlayer")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
	if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_blockar_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_blockar_PrimaryAttack_Post", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_m4a1", "blockar_ItemPostFrame")
	RegisterHam(Ham_Weapon_Reload, "weapon_m4a1", "blockar_Reload")
	RegisterHam(Ham_Weapon_Reload, "weapon_m4a1", "blockar_Reload_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m4a1", "fw_blockaridleanim", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)
	
	g_MaxPlayers = get_maxplayers()
        gmsgWeaponList = get_user_msgid("WeaponList")
}

public plugin_natives() register_native("jbe_give_brickpeacev", "native_give_weapon", true);
public native_give_weapon(client) give_blockar(client);

public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	precache_model(v2_model)
	precache_model(p2_model)
	precache_model(v_change_model)
	precache_model(w_model)
	precache_model(ROCKET_MODEL)
	sExplo = precache_model(GRENADE_EXPLOSION)
	muzzle = engfunc(EngFunc_PrecacheModel, "sprites/smokepuff.spr")
	sTrail = precache_model("sprites/laserbeam.spr")
	for(new i = 0; i < sizeof(weapon_sound); i++) 
		precache_sound(weapon_sound[i])
		
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
        precache_generic("sprites/weapon_blockar.txt")
   	precache_generic("sprites/640hud115_primary.spr")
    	precache_generic("sprites/640hud8.spr")
	
	register_clcmd("weapon_blockar", "weapon_hook")	
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public client_putinserver(id)
{
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "Do_RegisterHam_Bot", id)
	}
}

public Do_RegisterHam_Bot(id)
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}

public weapon_hook(id)
{
    	engclient_cmd(id, "weapon_m4a1")
    	return PLUGIN_HANDLED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_BRICKPEACE) return
	if(!g_had_blockar[iAttacker]) return
	if(g_mode[iAttacker] == 1) return

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		write_coord_f(flEnd[0])
		write_coord_f(flEnd[1])
		write_coord_f(flEnd[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	write_coord_f(flEnd[0])
	write_coord_f(flEnd[1])
	write_coord_f(flEnd[2])
	write_short(iAttacker)
	write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
	message_end()
}

public fwPrecacheEvent_Post(type, const name[])
{
	if (equal("events/galil.sc", name))
	{
		g_orig_event_blockar = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public fw_PlayerKilled(id) g_had_blockar[id] = false

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
		
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_m4a1.mdl"))
	{
		static iStoredAugID
		
		iStoredAugID = find_ent_by_owner(ENG_NULLENT, "weapon_m4a1", entity)
	
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED
	
		if(g_had_blockar[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_WEAPONKEY, blockar_WEAPONKEY)
			
			g_had_blockar[iOwner] = false
			
			entity_set_model(entity, w_model)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public give_blockar(id)
{
	if(get_user_flags(id) & ADMIN_LEVEL_D) {
	drop_weapons(id, 1)
	g_had_blockar[id] = 1
	new iWep2 = give_item(id,"weapon_m4a1")
	if( iWep2 > 0 )
	{
		cs_set_weapon_ammo(iWep2, DEFAULT_CLIP)
		cs_set_user_bpammo (id, CSW_BRICKPEACE, DEFAULT_BPAMMO)	
	}
	g_mode[id] = 0
	g_rocket_ammo[id] = ROCKET_AMMO
	}
	
	
	message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
	write_string("weapon_blockar")
	write_byte(4)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(17)
	write_byte(CSW_BRICKPEACE)
	write_byte(0)
	message_end()
	
	update_ammo(id)
}

public fw_blockar_AddToPlayer(blockar, id)
{
	if(!is_valid_ent(blockar) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(entity_get_int(blockar, EV_INT_WEAPONKEY) == blockar_WEAPONKEY)
	{
		g_had_blockar[id] = 1
		
		entity_set_int(blockar, EV_INT_WEAPONKEY, 0)

		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_blockar")
		write_byte(4)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(17)
		write_byte(CSW_BRICKPEACE)
		write_byte(0)
		message_end()
		
	}
            else
	{
		message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
		write_string("weapon_m4a1")
		write_byte(4)
		write_byte(90)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(17)
		write_byte(CSW_BRICKPEACE)
		write_byte(0)
		message_end()
	}
	return HAM_IGNORED
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

public CurrentWeapon(id)
{
     replace_weapon_models(id, read_data(2))

     if(read_data(2) != CSW_BRICKPEACE || !g_had_blockar[id])
          return
     
     static Float:iSpeed
     if(g_had_blockar[id])
          iSpeed = DEFAULT_SPEED
     
     static weapon[32],Ent
     get_weaponname(read_data(2),weapon,31)
     Ent = find_ent_by_owner(-1,weapon,id)
     if(Ent)
     {
          static Float:Delay
          Delay = get_pdata_float( Ent, 46, 4) * iSpeed
          if (Delay > 0.0)
          {
               set_pdata_float(Ent, 46, Delay, 4)
          }
     }
}

replace_weapon_models(id, weaponid)
{
	switch (weaponid)
	{
		case CSW_BRICKPEACE:
		{
			if(g_had_blockar[id])
			{
				if(g_mode[id] == 1)
				{
					set_pev(id, pev_viewmodel2, v2_model)
					set_pev(id, pev_weaponmodel2, p2_model)
				}
				else
				{
					set_pev(id, pev_viewmodel2, v_model)
					set_pev(id, pev_weaponmodel2, p_model)
				}
				update_ammo(id)
				
				if(oldweap[id] != CSW_BRICKPEACE) 
				{
					if(g_mode[id] == 1)
					{
						if(g_rocket_ammo[id] >= 1) UTIL_PlayWeaponAnimation(id, ANIM_DRAW_1)
						if(g_rocket_ammo[id] == 0) UTIL_PlayWeaponAnimation(id, ANIM_DRAW_2)
						set_pdata_string(id, m_szAnimExtention * 4, "shotgun", -1 , 20)
					}
					else
					{
						UTIL_PlayWeaponAnimation(id, ANIMX_DRAW_1)
					}
					
					remove_task(id)
					message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
					write_string("weapon_blockar")
					write_byte(4)
					write_byte(90)
					write_byte(-1)
					write_byte(-1)
					write_byte(0)
					write_byte(17)
					write_byte(CSW_BRICKPEACE)
					write_byte(0)
					message_end()

				}
			}
		}
	}
	oldweap[id] = weaponid
}

public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle)
{
	if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_BRICKPEACE || !g_had_blockar[Player]))
		return FMRES_IGNORED
	
	set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.001)
	return FMRES_HANDLED
}

public fw_blockar_PrimaryAttack(Weapon)
{
	new Player = get_pdata_cbase(Weapon, 41, 4)
	
	if(!g_had_blockar[Player])
		return
	
	g_IsInPrimaryAttack = 1
	pev(Player,pev_punchangle,cl_pushangle[Player])
	
	g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
}

public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if ((eventid != g_orig_event_blockar) || !g_IsInPrimaryAttack)
		return FMRES_IGNORED
	if (!(1 <= invoker <= g_MaxPlayers))
    return FMRES_IGNORED

	playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_blockar_PrimaryAttack_Post(Weapon)
{
	g_IsInPrimaryAttack = 0
	new Player = get_pdata_cbase(Weapon, 41, 4)
		
	if(!is_user_alive(Player) || !g_had_blockar[Player] || g_mode[Player] == 1 || !g_clip_ammo[Player])
		return
	
	new Float:push[3]
	pev(Player,pev_punchangle,push)
	xs_vec_sub(push,cl_pushangle[Player],push)
	
	xs_vec_mul_scalar(push,DEFAULT_RECOIL,push)
	xs_vec_add(push,cl_pushangle[Player],push)
	set_pev(Player,pev_punchangle,push)
	
	emit_sound(Player, CHAN_WEAPON, weapon_sound[6], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	UTIL_PlayWeaponAnimation(Player, random_num(ANIMX_SHOOT_1,ANIMX_SHOOT_3))
	set_weapons_timeidle(Player, CSW_BRICKPEACE, 0.1)
	set_player_nextattackx(Player, 0.1)
}

public fw_blockaridleanim(Weapon)
{
	new id = get_pdata_cbase(Weapon, 41, 4)

	if(!is_user_alive(id) || !g_had_blockar[id] || get_user_weapon(id) != CSW_BRICKPEACE)
		return HAM_IGNORED;
	
	if(g_mode[id] != 1) 
		return HAM_SUPERCEDE;
	
	if(g_mode[id] == 1)
	{
		if(g_rocket_ammo[id] == 0 && get_pdata_float(Weapon, 48, 4) <= 0.25) 
		{
			UTIL_PlayWeaponAnimation(id, ANIM_IDLE_EMPTY)
			set_pdata_float(Weapon, 48, 20.0, 4)
			return HAM_SUPERCEDE;
		}
		if(g_rocket_ammo[id] >= 1 && get_pdata_float(Weapon, 48, 4) <= 0.25)
		{
			UTIL_PlayWeaponAnimation(id, ANIM_IDLE)
			set_pdata_float(Weapon, 48, 20.0, 4)
			return HAM_SUPERCEDE;
		}
	}

	return HAM_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	if(get_user_weapon(id) != CSW_BRICKPEACE || !g_had_blockar[id])
		return
	
	static ent; ent = fm_get_user_weapon_entity(id, CSW_BRICKPEACE)
	if(!pev_valid(ent))
		return
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK && get_pdata_float(id, 83, 5) <= 0.0)
	{
		if(get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) > 0.0 || get_pdata_float(ent, 47, OFFSET_LINUX_WEAPONS) > 0.0) 
			return
			
		if(g_rocket_ammo[id] == 0 || g_mode[id] == 0)
			return
		
		if(g_rocket_ammo[id] >= 2)
		{
			UTIL_PlayWeaponAnimation(id, ANIM_SHOOT_START)
			set_task(1.0, "shot", id)
		}
		else
		{
			UTIL_PlayWeaponAnimation(id, ANIM_SHOOT_START)
			set_task(1.0, "shot2", id)
		}
		set_weapons_timeidle(id, CSW_BRICKPEACE, 3.6)
		set_player_nextattackx(id, 3.6)
	}
	else if(CurButton & IN_ATTACK2  && get_pdata_float(id, 83, 5) <= 0.0)
	{
		if(g_mode[id] == 1)
		{
			if(g_rocket_ammo[id] == 0) UTIL_PlayWeaponAnimation(id, ANIM_CHANGE1_2)
			else UTIL_PlayWeaponAnimation(id, ANIM_CHANGE1_1)
			set_task(1.36, "blockchange", id)
		}
		else
		{
			UTIL_PlayWeaponAnimation(id, ANIMX_CHANGE_1)
			set_task(1.36, "blockchange", id)
			
			blockar_clip[id] = cs_get_weapon_ammo(ent)
			blockar_bpammo[id] = cs_get_user_bpammo(id, CSW_BRICKPEACE)
		}
		
		set_weapons_timeidle(id, CSW_BRICKPEACE, 5.08)
		set_player_nextattackx(id, 5.08)
	}
}

public blockchange(id)
{
	if(get_user_weapon(id) != CSW_BRICKPEACE || !g_had_blockar[id])
		return
	
	set_pev(id, pev_viewmodel2, v_change_model)
	UTIL_PlayWeaponAnimation(id, 0)
	set_task(2.36, "backs", id)
}

public backs(id)
{
	if(get_user_weapon(id) != CSW_BRICKPEACE || !g_had_blockar[id])
		return
		
	if(g_mode[id] == 1)
	{
		g_mode[id] = 0
		set_pev(id, pev_viewmodel2, v_model)
		set_pev(id, pev_weaponmodel2, p_model)
		UTIL_PlayWeaponAnimation(id, ANIMX_CHANGE_2)
		set_pdata_string(id, m_szAnimExtention * 4, "ak47", -1 , 20)
		update_ammo_back(id)
	}
	else
	{
		g_mode[id] = 1
		set_pev(id, pev_viewmodel2, v2_model)
		set_pev(id, pev_weaponmodel2, p2_model)
		if(g_rocket_ammo[id] == 0) UTIL_PlayWeaponAnimation(id, ANIM_CHANGE2_2)
		else UTIL_PlayWeaponAnimation(id, ANIM_CHANGE2_1)
		set_pdata_string(id, m_szAnimExtention * 4, "shotgun", -1 , 20)
		update_ammo(id)
	}
}

public shot(id)
{
	if(get_user_weapon(id) != CSW_BRICKPEACE || !g_had_blockar[id])
		return
	
	set_pev(id,pev_punchangle,5.0)
	
	UTIL_PlayWeaponAnimation(id, ANIM_SHOOT_END)
	shoot_rocket(id)
	emit_sound(id, CHAN_WEAPON, weapon_sound[14], 1.0, ATTN_NORM, 0, PITCH_NORM)
	g_rocket_ammo[id]--
	update_ammo(id)
	set_task(1.0, "reloadrocket", id)
}

public shot2(id)
{
	if(get_user_weapon(id) != CSW_BRICKPEACE || !g_had_blockar[id])
		return
	
	set_pev(id,pev_punchangle,5.0)
	
	UTIL_PlayWeaponAnimation(id, ANIM_SHOOT_END)
	shoot_rocket(id)
	emit_sound(id, CHAN_WEAPON, weapon_sound[14], 1.0, ATTN_NORM, 0, PITCH_NORM)
	g_rocket_ammo[id]--
	update_ammo(id)
}

public reloadrocket(id)
{
	if(get_user_weapon(id) != CSW_BRICKPEACE || !g_had_blockar[id])
		return
	
	UTIL_PlayWeaponAnimation(id, ANIM_RELOAD)
}

public shoot_rocket(id)
{
	static Float:StartOrigin[3], Float:TargetOrigin[3], Float:angles[3], Float:angles_fix[3]
	get_position(id, 2.0, 0.0, 0.0, StartOrigin)

	pev(id,pev_v_angle,angles)
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	angles_fix[0] = 360.0 - angles[0]
	angles_fix[1] = angles[1]
	angles_fix[2] = angles[2]
	// Set info for ent
	set_pev(Ent, pev_movetype, MOVETYPE_TOSS)
	set_pev(Ent, pev_owner, id) // Better than pev_owner
	
	entity_set_string(Ent, EV_SZ_classname, ROCKET_CLASS)
	engfunc(EngFunc_SetModel, Ent, ROCKET_MODEL)
	set_pev(Ent, pev_mins,{ -0.1, -0.1, -0.1 })
	set_pev(Ent, pev_maxs,{ 0.1, 0.1, 0.1 })
	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, angles_fix)
	set_pev(Ent, pev_gravity, 0.01)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	set_pev(Ent, pev_frame, 0.0)
	
	static Float:Velocity[3]
	fm_get_aim_origin(id, TargetOrigin)
	get_speed_vector(StartOrigin, TargetOrigin, 1500.0, Velocity)
	set_pev(Ent, pev_velocity, Velocity)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(Ent) // Entity
	write_short(sTrail) // Sprite index
	write_byte(3) // Life
	write_byte(1) // Line width
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(100) // Alpha
	message_end()
	
	mujel(id)
}

public fw_touch2(Ent, Id)
{
	// If ent is valid
	if(!pev_valid(Ent))
		return
		
	static classnameptd[32]
	pev(Id, pev_classname, classnameptd, 31)
	if (equali(classnameptd, "func_breakable")) ExecuteHamB( Ham_TakeDamage, Id, 0, 0, 300.0, DMG_GENERIC )
	
	explode(Ent)
}

public explode(Ent)
{
	new Float:originZ[3], Float:originX[3]
	pev(Ent, pev_origin, originX)
	entity_get_vector(Ent, EV_VEC_origin, originZ)
	// Draw explosion
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION) // Temporary entity ID
	engfunc(EngFunc_WriteCoord, originX[0]) // engfunc because float
	engfunc(EngFunc_WriteCoord, originX[1])
	engfunc(EngFunc_WriteCoord, originX[2]+30.0)
	write_short(sExplo) // Sprite index
	write_byte(20) // Scale
	write_byte(30) // Framerate
	write_byte(0) // Flags
	message_end()
	
	Damage_rocket(Ent)
			
	remove_entity(Ent)
}

public Damage_rocket(Ent)
{
	static Owner; Owner = pev(Ent, pev_owner)
	static Attacker
	if(!is_user_alive(Owner)) 
	{
		Attacker = 0
		return
	} else Attacker = Owner
		
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(i, Ent) > EXPLODE_RADIUS)
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, Attacker, DAMAGE_EXPLODE, DMG_BULLET)
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if (victim != attacker && is_user_connected(attacker))
	{
		if(get_user_weapon(attacker) == CSW_BRICKPEACE)
		{
			if(g_had_blockar[attacker])
			{
				if(g_mode[attacker] == 0)
				{
					SetHamParamFloat(4, damage * DEFAULT_DAMAGE)
				}
			}
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
	
	if(equal(szTruncatedWeapon, "m4a1") && get_user_weapon(iAttacker) == CSW_BRICKPEACE)
	{
		if(g_had_blockar[iAttacker])
			set_msg_arg_string(4, "m4a1")
	}
	return PLUGIN_CONTINUE
}

public blockar_ItemPostFrame(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_had_blockar[id])
          return HAM_IGNORED

     static iClipExtra
     
     iClipExtra = DEFAULT_CLIP
     new Float:flNextAttack = get_pdata_float(id, m_flNextAttack, PLAYER_LINUX_XTRA_OFF)

     new iBpAmmo = cs_get_user_bpammo(id, CSW_BRICKPEACE)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     new fInReload = get_pdata_int(weapon_entity, m_fInReload, WEAP_LINUX_XTRA_OFF) 

     if( fInReload && flNextAttack <= 0.0 )
     {
	     new j = min(iClipExtra - iClip, iBpAmmo)
	
	     set_pdata_int(weapon_entity, m_iClip, iClip + j, WEAP_LINUX_XTRA_OFF)
	     cs_set_user_bpammo(id, CSW_BRICKPEACE, iBpAmmo-j)
		
	     set_pdata_int(weapon_entity, m_fInReload, 0, WEAP_LINUX_XTRA_OFF)
	     fInReload = 0
     }
     return HAM_IGNORED
}

public blockar_Reload(weapon_entity) 
{
     new id = pev(weapon_entity, pev_owner)
     if (!is_user_connected(id))
          return HAM_IGNORED

     if (!g_had_blockar[id])
          return HAM_IGNORED
		  
     if(g_mode[id] == 1)
		return HAM_SUPERCEDE
		
     static iClipExtra

     if(g_had_blockar[id])
          iClipExtra = DEFAULT_CLIP

     g_blockar_TmpClip[id] = -1

     new iBpAmmo = cs_get_user_bpammo(id, CSW_BRICKPEACE)
     new iClip = get_pdata_int(weapon_entity, m_iClip, WEAP_LINUX_XTRA_OFF)

     if (iBpAmmo <= 0)
          return HAM_SUPERCEDE

     if (iClip >= iClipExtra)
          return HAM_SUPERCEDE

     g_blockar_TmpClip[id] = iClip

     return HAM_IGNORED
}

public blockar_Reload_Post(weapon_entity) 
{
	new id = pev(weapon_entity, pev_owner)
	if (!is_user_connected(id))
		return HAM_IGNORED

	if (!g_had_blockar[id])
		return HAM_IGNORED
		
	if(g_mode[id] == 1)
		return HAM_SUPERCEDE

	if (g_blockar_TmpClip[id] == -1)
		return HAM_IGNORED

	set_pdata_int(weapon_entity, m_iClip, g_blockar_TmpClip[id], WEAP_LINUX_XTRA_OFF)
	
	set_weapons_timeidle(id, CSW_BRICKPEACE, RELOAD_TIME)
	set_player_nextattackx(id, RELOAD_TIME)
	
	set_pdata_int(weapon_entity, m_fInReload, 1, WEAP_LINUX_XTRA_OFF)
	
	UTIL_PlayWeaponAnimation(id, ANIMX_RELOAD)

	return HAM_IGNORED
}

public mujel(id)
{
	static Float:Origin[3], TE_FLAG
	get_position(id, 32.0, 6.0, -15.0, Origin)
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, Origin, id)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(muzzle)
	write_byte(9)
	write_byte(35)
	write_byte(TE_FLAG)
	message_end()
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return
	if(g_mode[id] == 1)
	{
		static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_BRICKPEACE)
		if(!pev_valid(weapon_ent)) return
		
		cs_set_weapon_ammo(weapon_ent, g_rocket_ammo[id])	
		cs_set_user_bpammo(id, CSW_BRICKPEACE, g_rocket_ammo[id])
		
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
		write_byte(1)
		write_byte(CSW_BRICKPEACE)
		write_byte(-1)
		message_end()
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
		write_byte(1)
		write_byte(g_rocket_ammo[id])
		message_end()
	}
	else
	{
		static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_BRICKPEACE)
		if(!pev_valid(weapon_ent)) return
		
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
		write_byte(1)
		write_byte(CSW_BRICKPEACE)
		write_byte(cs_get_weapon_ammo(weapon_ent))
		message_end()
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
		write_byte(1)
		write_byte(cs_get_user_bpammo(id, CSW_BRICKPEACE))
		message_end()
	}
}

public update_ammo_back(id)
{
	if(!is_user_alive(id))
		return

	static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_BRICKPEACE)
	if(!pev_valid(weapon_ent)) return
	
	cs_set_weapon_ammo(weapon_ent, blockar_clip[id])
	cs_set_user_bpammo (id, CSW_BRICKPEACE, blockar_bpammo[id])
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_BRICKPEACE)
	write_byte(blockar_clip[id])
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(blockar_bpammo[id])
	message_end()
}

stock set_player_nextattackx(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 47, TimeIdle, WEAP_LINUX_XTRA_OFF)
	set_pdata_float(entwpn, 48, TimeIdle + 1.0, WEAP_LINUX_XTRA_OFF)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}


stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	static Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

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