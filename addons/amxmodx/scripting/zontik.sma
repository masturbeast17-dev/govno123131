#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cstrike>
 
#define ENG_NULLENT             -1
#define EV_INT_WEAPONKEY        EV_INT_impulse
#define reinbow_WEAPONKEY     91421
#define MAX_PLAYERS                       32
#define IsValidUser(%1) (1 <= %1 <= g_MaxPlayers)
 
const USE_STOPPED = 0
const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 5
 
#define WEAP_LINUX_XTRA_OFF                     4
#define m_fKnown                                44
#define m_flNextPrimaryAttack                   46
#define m_flTimeWeaponIdle                      48
#define m_iClip                                 51
#define m_fInReload                             54
#define PLAYER_LINUX_XTRA_OFF                   5
#define m_flNextAttack                          83

#define PRAVA ADMIN_RESERVATION
 
#define weapon_rainbowgun "weapon_m3"
#define CSW_RAINBOWGUN CSW_M3
 
new Float:g_last_postframe[33]
 
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_P90)|(1<<CSW_P90)|(1<<CSW_P90)|(1<<CSW_SG550)|(1<<CSW_P90)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_P90)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_M3)|(1<<CSW_P90)|(1<<CSW_AK47)|(1<<CSW_P90)
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_p90",
                        "weapon_p90", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_p90", "weapon_sg550",
                        "weapon_p90", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_p90", "weapon_m249",
                        "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_m3", "weapon_flashbang", "weapon_deagle", "weapon_p90",
                        "weapon_ak47", "weapon_knife", "weapon_p90" }

new const Fire_Sounds[][] = { "weapons/rainbowgun-2.wav" }


new reinbow_V_MODEL[64] = "models/v_rainbowgun.mdl"
new reinbow_P_MODEL[64] = "models/p_rainbowgun.mdl"
new reinbow_W_MODEL[64] = "models/w_rainbowgun.mdl"


new g_bloodspray, g_blood
new cvar_dmg_reinbow, cvar_recoil_reinbow, cvar_clip_reinbow, cvar_reinbow_ammo, cvar_spd_reinbow
new g_has_reinbow[33]
new g_MaxPlayers, g_orig_event_reinbow, g_clip_ammo[33]
new Float:cl_pushangle[MAX_PLAYERS + 1][3]
new g_itemid
public plugin_init()
{
        register_plugin("Reinbow Gun", "1.3", "Strax")
        register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
        register_event("CurWeapon","CurrentWeapon","be","1=1")
        RegisterHam(Ham_Item_AddToPlayer, "weapon_m3", "ReinbowAddToPlayer")
        RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
        RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
        RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
        RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
        RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
        RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)	
        for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
                if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
        RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "PrimaryAttack")
        RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "PrimaryAttack_Post", 1)
        RegisterHam(Ham_Item_PostFrame, "weapon_m3", "reload");
	RegisterHam(Ham_TakeDamage, "player", "takedmg")
        register_forward(FM_SetModel, "modelka")
        register_forward(FM_UpdateClientData, "client_data_post", 1)
        register_forward(FM_PlaybackEvent, "PlaybackEvent")
 	register_forward(FM_CmdStart, "CmdStart")
 
 
        cvar_dmg_reinbow = register_cvar("reinbow_dmg", "2.0")
        cvar_recoil_reinbow = register_cvar("reinbow_recoil", "0.1")
        cvar_clip_reinbow = register_cvar("reinbow_clip", "8")
        cvar_reinbow_ammo = register_cvar("reinbow_ammo", "48")
        cvar_spd_reinbow = register_cvar("reinbow_spd", "0.7")
	register_clcmd("zontik", "give_zontik");
 
        g_MaxPlayers = get_maxplayers()
}
 
public plugin_precache()
{
        precache_model(reinbow_V_MODEL)
        precache_model(reinbow_P_MODEL)
        precache_model(reinbow_W_MODEL)

	
        precache_sound("weapons/rainbowgun_insert.wav")
        precache_sound("weapons/rainbowgun_draw.wav")
        precache_sound("weapons/rainbowgun_after_reload.wav")
        precache_sound("weapons/rainbowgun_draw2.wav")
        precache_sound("weapons/rainbowgun_start_reload.wav")
        precache_sound("weapons/rainbowgun_shoot.wav")
        precache_sound("weapons/rainbowgun-3.wav")
        precache_sound(Fire_Sounds[0])
        g_blood = precache_model("sprites/blood.spr")
        g_bloodspray = precache_model("sprites/bloodspray.spr")		
        precache_model("sprites/640hud5.spr")
        register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)
}

public give_zontik(id, itemid)
{
	if(!(get_user_flags(id) & PRAVA) ) 
		return
        if(itemid == g_itemid)
        {       
        	give_reinbow(id)
        }
}

public fwPrecacheEvent_Post(type, const name[])
{
        if (equal("events/m3.sc", name))
        {
                g_orig_event_reinbow = get_orig_retval()
                return FMRES_HANDLED
        }
        
        return FMRES_IGNORED
}
 
public modelka(entity, model[])
{
        if(!is_valid_ent(entity))
                return FMRES_IGNORED;
        
        static szClassName[33]
        entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
                
        if(!equal(szClassName, "weaponbox"))
                return FMRES_IGNORED;
        
        static iOwner
        
        iOwner = entity_get_edict(entity, EV_ENT_owner)
        
        if(equal(model, "models/w_m3.mdl"))
        {
                static iStoredSVDID
                
                iStoredSVDID = find_ent_by_owner(ENG_NULLENT, "weapon_m3", entity)
        
                if(!is_valid_ent(iStoredSVDID))
                        return FMRES_IGNORED;
        
                if(g_has_reinbow[iOwner])
                {
                        entity_set_int(iStoredSVDID, EV_INT_WEAPONKEY, reinbow_WEAPONKEY)
                        g_has_reinbow[iOwner] = false
                        
                        entity_set_model(entity, reinbow_W_MODEL)
                        
                        return FMRES_SUPERCEDE;
                }
        }
        
        
        return FMRES_IGNORED;
}

public give_reinbow(id)
{
        drop_weapons(id, 1);
        new iWep2 = give_item(id,"weapon_m3")
        if( iWep2 > 0 )
        {
        	cs_set_weapon_ammo(iWep2, get_pcvar_num(cvar_clip_reinbow))
        	cs_set_user_bpammo (id, CSW_RAINBOWGUN, get_pcvar_num(cvar_reinbow_ammo))
        }
        g_has_reinbow[id] = true;
}
 
public ReinbowAddToPlayer(reinbow, id)
{
        if(!is_valid_ent(reinbow) || !is_user_connected(id))
                return HAM_IGNORED;
        
        if(entity_get_int(reinbow, EV_INT_WEAPONKEY) == reinbow_WEAPONKEY)
        {
                g_has_reinbow[id] = true
                
                entity_set_int(reinbow, EV_INT_WEAPONKEY, 0)
                
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

public CurrentWeapon(id)
{

	replace_weapon_models(id, read_data(2))
	remove_task(id)
	if(read_data(2) != CSW_RAINBOWGUN || !g_has_reinbow[id])
          return
     
	static Float:iSpeed
	if(g_has_reinbow[id])
          iSpeed = get_pcvar_float(cvar_spd_reinbow)

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
                case CSW_RAINBOWGUN:
                {
                        if(g_has_reinbow[id])
                        {
                                set_pev(id, pev_viewmodel2, reinbow_V_MODEL)
                                set_pev(id, pev_weaponmodel2, reinbow_P_MODEL)
                        }
                }
        }
}
 
public client_data_post(Player, SendWeapons, CD_Handle)
{
        if(!is_user_alive(Player) || (get_user_weapon(Player) != CSW_RAINBOWGUN) || !g_has_reinbow[Player])
        return FMRES_IGNORED
        
        set_cd(CD_Handle, CD_flNextAttack, halflife_time () + 0.00001)
        return FMRES_HANDLED
}
 
public PrimaryAttack(Weapon)
{
        new Player = get_pdata_cbase(Weapon, 41, 4)
        
        if (!g_has_reinbow[Player])
                return;
        
        pev(Player,pev_punchangle,cl_pushangle[Player])
        
        g_clip_ammo[Player] = cs_get_weapon_ammo(Weapon)
        
	
	UTIL_PlayWeaponAnimation(Player, 1)
	
	emit_sound(Player, CHAN_WEAPON, Fire_Sounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}
 
public PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
        if ((eventid != g_orig_event_reinbow))
                return FMRES_IGNORED
        if (!(1 <= invoker <= g_MaxPlayers))
                return FMRES_IGNORED
 
        playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
        return FMRES_SUPERCEDE
}
 
public PrimaryAttack_Post(Weapon, weapon_entity)
{
        new Player = get_pdata_cbase(Weapon, 41, 4)
        
        new szClip, szAmmo
        get_user_weapon(Player, szClip, szAmmo)
        if(Player > 0 && Player < 33)
        {
        if(!g_has_reinbow[Player])
        {
        if(szClip > 0) emit_sound(Player, CHAN_WEAPON, "weapons/m3-1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
        }
        if(g_has_reinbow[Player])
        {
                new Float:push[3]
                pev(Player,pev_punchangle,push)
                xs_vec_sub(push,cl_pushangle[Player],push)
                
                xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil_reinbow),push)
                xs_vec_add(push,cl_pushangle[Player],push)
                set_pev(Player,pev_punchangle,push)
                
                if (!g_clip_ammo[Player])
                        return
	       
        }
        }
}

public CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_RAINBOWGUN || !g_has_reinbow[id])
		return FMRES_IGNORED

	new CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)

	if(CurButton & IN_ATTACK2)
	{
	UTIL_PlayWeaponAnimation(id, 7)
	}
	return FMRES_HANDLED
}

public asd(weapon_entity)
{
	static id; id = pev(weapon_entity, pev_owner)
	static iAnim; iAnim = pev(id, pev_weaponanim)
	if(iAnim == 7 && g_has_reinbow[id])
	{
		UTIL_PlayWeaponAnimation(id, 8)
	}
}
 
public takedmg(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return HAM_IGNORED

	if(get_user_weapon(attacker) == CSW_RAINBOWGUN && g_has_reinbow[attacker])
	{
	static Float:Damage
	Damage = get_pcvar_float(cvar_dmg_reinbow)

	
	SetHamParamFloat(4, damage * Damage)
	}
	
	return HAM_HANDLED
}
 
 public TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker) || !is_user_connected(iAttacker))
		return HAM_IGNORED		
	if(get_user_weapon(iAttacker) != CSW_RAINBOWGUN || !g_has_reinbow[iAttacker])
		return HAM_IGNORED
	
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)

	make_bullet(iAttacker, flEnd)

	return HAM_HANDLED
}
 
public message_DeathMsg(msg_id, msg_dest, id)
{
        static szTruncatedWeapon[33], iAttacker, iVictim
        
        get_msg_arg_string(4, szTruncatedWeapon, charsmax(szTruncatedWeapon))
        
        iAttacker = get_msg_arg_int(1)
        iVictim = get_msg_arg_int(2)
        
        if(!is_user_connected(iAttacker) || iAttacker == iVictim)
                return PLUGIN_CONTINUE
        
        if(equal(szTruncatedWeapon, "p90") && get_user_weapon(iAttacker) == CSW_P90)
        {
                if(g_has_reinbow[iAttacker])
                        set_msg_arg_string(4, "p90")
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
 
 
stock make_bullet(id, Float:Origin[3])
{
	new target, body
	get_user_aiming(id, target, body, 999999)
	
	if(target > 0 && target <= get_maxplayers())
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		velocity_by_aim(id, 64, fVel)
		
		fStart[0] = Origin[0]
		fStart[1] = Origin[1]
		fStart[2] = Origin[2]
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(g_bloodspray)
		write_short(g_blood)
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
		} else {
		new decal = 41
		
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			write_short(target)
			message_end()
			} else {
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(floatround(Origin[0]))
			write_coord(floatround(Origin[1]))
			write_coord(floatround(Origin[2]))
			write_byte(decal)
			message_end()
		}
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(floatround(Origin[0]))
		write_coord(floatround(Origin[1]))
		write_coord(floatround(Origin[2]))
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

 
public reload(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return HAM_IGNORED		
	if(get_user_weapon(id) != CSW_RAINBOWGUN || !g_has_reinbow[id])
		return HAM_IGNORED	

	static reinbow
	reinbow = fm_find_ent_by_owner(-1, weapon_rainbowgun, id)
	
	if(get_pdata_int(reinbow, 55, 4) == 1)
	{
		static Float:CurTime
		CurTime = get_gametime()
		
		if(CurTime - 0.4 > g_last_postframe[id])
		{
			UTIL_PlayWeaponAnimation(id, 3)
			g_last_postframe[id] = CurTime
		}
	}

	return HAM_HANDLED
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
