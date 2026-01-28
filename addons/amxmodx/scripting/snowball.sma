#include "amxmodx.inc"
#include "fakemeta.inc"
#include "hamsandwich.inc"
#include "fakemeta_util.inc"

#pragma ctrlchar '\'

#define MAX_CLIENTS				32
#define MAX_ITEM_TYPES				6

// чем выше сила, тем дальше летит снежок, а также
// чем выше сила, тем сильнее урон

#define MAX_POWER				26	//макс. сила снежка (при зажатии ПКМ сила увеличивается не больше чем MAX_POWER)
#define MIN_POWER				12	//мин. сила снежка

#define MULTIPLY_POWER				3.0	//множитель силы
#define FREQUENCY_POWER				0.041	//частота прибавлении силы (как быстро прибавляется сила при зажатии ПКМ)

#define MAPZONE_BUYZONE				(1<<0)
#define HIDEHUD_CROSSHAIR			(1<<6)

#define WPNSTATE_SHIELD_DRAWN			(1<<5)
#define HIDEHUD_CROSSHAIR			(1<<6)

#define ObjectValid(%0)				(pev_valid(%0) == PDATA_SAFE)

#define CSW_SNOW				0x00002
#define STATUSICON_SHOW				1
#define PDATA_SAFE				2

#define ACT_RANGE_ATTACK1			28
#define WEAPON_NAME_SECONDARY			"weapon_snow"

#define SNOW_P_MODEL				"models/p_snow.mdl"
#define SNOW_V_MODEL				"models/v_snow.mdl"
#define SNOW_W_MODEL				"models/w_snow.mdl"

#define SNOW_KEEP				// можно ли удерживать снежок на ЛКМ (зажимать ЛКМ и удерживать для броска)
#define SNOW_DANGER_REND			// подсвечивать render-ом летящий опасный снежок с большой силы
#define SNOW_BARTIME_STATUS			// отображать бартайм статус силы 

//#define SNOW_KNIFE				// сделать снежки на knife (если закомментировано, будет два режима ножа 1 - Обычный нож | 2 - Снежки)
//#define SNOW_SMOKEGRENADE			// сделать снежки на smokegrenade
#define TEAMMATES_KILL				// разрешать ранить тиммейтов

#if defined SNOW_SMOKEGRENADE && defined SNOW_KNIFE
#undef SNOW_KNIFE
#endif

#if !defined SNOW_KNIFE && defined SNOW_SMOKEGRENADE
#define CSW_WEAPON_EX				CSW_SMOKEGRENADE
#define WEAPON_NAME_PRIMARY			"weapon_smokegrenade"
#else
#define CSW_WEAPON_EX				CSW_KNIFE
#define WEAPON_NAME_PRIMARY			"weapon_knife"
#endif

// CBaseMonster::
#define m_Activity				73
#define m_IdealActivity				74
#define m_LastHitGroup				75
#define m_flNextAttack				83

// CBasePlayerWeapon::
#define m_flNextPrimaryAttack			46
#define m_flNextSecondaryAttack			47
#define m_flTimeWeaponIdle			48
#define m_iPrimaryAmmoType			49
#define m_iSecondaryAmmoType			50

#define m_iNextAction				55 // m_fInSpecialReload
#define m_flLastFire				63
#define m_fWeaponState				74

// CBasePlayer::
#define m_fHasSurvivedLastRound			113
#define m_iTeam					114
#define m_iAccount				115
#define m_flLastAttackTime			220
#define m_iHideHUD				361
#define m_rgpPlayerItems			367
#define m_pActiveItem				373
#define m_pLastItem				375
#define m_vecAutoAim				440
#define m_fOnTarget				443
#define m_szAnimExtention			492
#define m_bHasShield				2043 // 510 get_pdata_int(id,m_bHasShield) & (1<<24)
#define m_bShieldDrawn				2044 // 510 get_pdata_int(id,m_bHasShield) & (1<<16)

// CBasePlayerItem::
#define m_pPlayer				41
#define m_pNext					42
#define m_iId					43

// CBaseAnimating::
#define m_flFrameRate				36
#define m_flGroundSpeed				37
#define m_flLastEventCheck			38
#define m_fSequenceFinished			39
#define m_fSequenceLoops			40

// CBaseEntity::
#define m_flStartThrow				30
#define m_flReleaseThrow 			31

#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
enum (+=275282312)
{
	UID_NONE = 0,
	UID_SNOW,
	UID_SNOW_FLY,
	UID_SNOW_MODE
}
#endif

// Anim sequence
enum PLAYER_ANIM
{
	PLAYER_IDLE,
	PLAYER_WALK,
	PLAYER_JUMP,
	PLAYER_SUPERJUMP,
	PLAYER_DIE,
	PLAYER_ATTACK1
};

enum WEAPON_ANIM
{
	AS_IDLE,
	AS_PULLPIN,
	AS_THROW,
	AS_DRAW
};

enum _:HAMHOOK
{
	HamHook:CAN_DROP = 0
};

// Множитель урона в разные части тела | 1.0 - стандартный урон

stock const Float:flMultiplyDamageHit[] = {
	1.0, //HIT_GENERIC	| none
	1.5, //HIT_HEAD		| голова
	1.2, //HIT_CHEST	| грудь
	1.1, //HIT_STOMACH	| брюхо
	1.1, //HIT_LEFTARM	| лев.рука
	1.1, //HIT_RIGHTARM	| прав.рука
	1.0, //HIT_LEFTLEG	| лев.нога
	1.0  //HIT_RIGHTLEG	| прав.нога
};

new Ham:Ham_ResetMaxSpeed;
new HamHook:g_iHamHook[HAMHOOK];
new g_iPower[MAX_CLIENTS + 1];

new g_iSprBlood;
new g_iSprBloodSpray;

new g_msgidWeapPickup;

#if defined SNOW_BARTIME_STATUS
new g_msgidBarTime;
#endif

new g_msgidWeaponList;

public plugin_precache()
{
	precache_model(SNOW_P_MODEL);
	precache_model(SNOW_V_MODEL);
	precache_model(SNOW_W_MODEL);

	precache_generic("sprites/weapon_snow.txt");
	precache_model("sprites/snowball.spr");

	g_iSprBlood = precache_model("sprites/blood.spr");
	g_iSprBloodSpray = precache_model("sprites/bloodspray.spr");
}
public plugin_init()
{
	register_plugin("Snowball","0.6 alpha","s1lent");

#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
	register_clcmd("lastinv","Cmd_Lastinv");
	register_clcmd(WEAPON_NAME_PRIMARY,"Cmd_WeaponSelect");
#endif
	register_clcmd(WEAPON_NAME_SECONDARY,"Cmd_WeaponSelectEx");

	RegisterHam(Ham_Touch,"info_target","CBaseEntity__Touch",1);
	RegisterHam(Ham_Item_PostFrame,WEAPON_NAME_PRIMARY,"CBasePlayerItem__PostFrame");
	RegisterHam(Ham_Item_Deploy,WEAPON_NAME_PRIMARY,"CBasePlayerItem__Deploy",1);
	RegisterHam(Ham_Item_AddToPlayer,WEAPON_NAME_PRIMARY,"CBasePlayerItem__AddToPlayer",1);

	DisableHamForward((g_iHamHook[CAN_DROP] = RegisterHam(Ham_CS_Item_CanDrop,WEAPON_NAME_PRIMARY,"CBasePlayerItem__CanDrop")));

	#if (CSW_WEAPON_EX == CSW_SMOKEGRENADE)
		RegisterHam(Ham_Spawn,"player","CBasePlayer__Spawn_Post",1);
	#endif

	#if defined SNOW_BARTIME_STATUS
	g_msgidBarTime = get_user_msgid("BarTime");
	#endif

	g_msgidWeaponList = get_user_msgid("WeaponList");
	g_msgidWeapPickup = get_user_msgid("WeapPickup");

	Ham_ResetMaxSpeed = Ham_Valid_Player_ResetMaxSpeed();
}
public plugin_natives()
{
	register_library("snow");
	register_native("snowball_disable","native_snowball_disable");
}
public native_snowball_disable(plid,params)
{
	new Players[32],iNum,iPlayer;
	get_players(Players,iNum,"ach");

	for(new i; i < iNum; i++)
	{
		iPlayer = Players[i];

		new pItem = util__WeaponFetchSlot(iPlayer,CSW_WEAPON_EX);

		if(pItem)
		{
			#if (CSW_WEAPON_EX == CSW_KNIFE) && defined SNOW_KNIFE
			util__SendWeaponList(iPlayer,WEAPON_NAME_PRIMARY,CSW_WEAPON_EX);
			#else

			// smokegrenade force drop :/
			EnableHamForward(g_iHamHook[CAN_DROP]);
			engclient_cmd(iPlayer,"drop",WEAPON_NAME_PRIMARY);

			new pWeaponBox = pev(pItem,pev_owner);

			if(pWeaponBox && pWeaponBox != iPlayer)
			{
				dllfunc(DLLFunc_Think,pWeaponBox);
			}
			#endif
		}
	}

	new pSnow;
	while((pSnow = engfunc(EngFunc_FindEntityByString,pSnow,"classname","snow")))
	{
		set_pev(pSnow,pev_flags,FL_KILLME);
	}

	pause("a");
}
public CBasePlayerItem__CanDrop(ent)
{
	SetHamReturnInteger(1);
	DisableHamForward(g_iHamHook[CAN_DROP]);
	return HAM_SUPERCEDE;
}
public CBasePlayer__Spawn_Post(const id)
{
	if(is_user_alive(id))
	{
		fm_give_item(id,WEAPON_NAME_PRIMARY);
	}
	return HAM_IGNORED;
}
public CBaseEntity__Touch(const ent,const id)
{
#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
	if(pev(ent,pev_impulse) != UID_SNOW_FLY)
	{
		return HAM_IGNORED;
	}
#endif

	if(!ObjectValid(id) || !is_user_alive(id))
	{
		util__EffectSnow(ent);
		return HAM_IGNORED;
	}

	new Float:flDamage;
	pev(ent,pev_dmg,flDamage);

	new iAttacker = pev(ent,pev_owner);

	if(flDamage <= 0.0 || iAttacker < 1)
	{
		return HAM_IGNORED;
	}

	#if !defined TEAMMATES_KILL
	if(get_pdata_int(iAttacker,m_iTeam) != get_pdata_int(id,m_iTeam))
	{
	#endif
		new iHitgroup;
		new pTracehandle;

		new Float:vecStart[3],Float:vecEnd[3],Float:vecVelocity[3],Float:vecForward[3],Float:flFraction;

		pev(ent,pev_origin,vecStart);
		pev(ent,pev_velocity,vecVelocity);
		global_get(glb_v_forward,vecForward);

		vecEnd[0] = vecStart[0] + vecForward[0];
		vecEnd[1] = vecStart[1] + vecForward[1];
		vecEnd[2] = vecStart[2] + vecForward[2];

		engfunc(EngFunc_TraceLine,vecStart,vecEnd,IGNORE_MISSILE|IGNORE_MONSTERS|IGNORE_GLASS,iAttacker,pTracehandle);
		get_tr2(pTracehandle,TR_flFraction,flFraction);

		if(flFraction != 1.0)
		{
			iHitgroup = get_tr2(pTracehandle,TR_iHitgroup);

			set_pdata_int(id,m_LastHitGroup,iHitgroup);
		}
		ExecuteHam(Ham_TakeDamage,id,ent,iAttacker,flDamage * flMultiplyDamageHit[iHitgroup],DMG_DROWN);

	#if !defined TEAMMATES_KILL
	}
	#endif

	util__EffectSnow(ent);

	return HAM_IGNORED;
}
#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
public Cmd_Lastinv(const id)
{
	return (CBasePlayer__SelectLastItem(id));
}
#endif
public CBasePlayerItem__AddToPlayer(const ent,const id)
{
	if(!ObjectValid(id))
	{
		return HAM_IGNORED;
	}

	#if defined SNOW_KNIFE || (CSW_WEAPON_EX != CSW_KNIFE)
	util__SendWeaponList(id,WEAPON_NAME_SECONDARY,CSW_WEAPON_EX);
	#else
	set_pev(id,pev_weapons,pev(id,pev_weapons)|(1<<CSW_SNOW));
	util__SendItemPickup(id,CSW_SNOW);
	util__SendWeaponList(id,WEAPON_NAME_PRIMARY,CSW_WEAPON_EX);
	util__SendWeaponList(id,WEAPON_NAME_SECONDARY,CSW_SNOW);
	#endif

	return HAM_IGNORED;
}
#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
public Cmd_WeaponSelect(const id)
{
	if(!ObjectValid(id))
	{
		return PLUGIN_CONTINUE;
	}

	new pItem = util__WeaponFetchSlot(id,CSW_WEAPON_EX);

	if(!pItem
		|| pev(pItem,pev_impulse) != UID_SNOW_MODE)
	{
		return PLUGIN_CONTINUE;
	}

	set_pev(pItem,pev_impulse,UID_NONE);

	set_pdata_cbase(id,m_pLastItem,get_pdata_cbase(id,m_pActiveItem));
	set_pdata_cbase(id,m_pActiveItem,pItem);

	ExecuteHamB(Ham_Item_Deploy,pItem);

	return PLUGIN_CONTINUE;
}
#endif
public Cmd_WeaponSelectEx(const id)
{
	if(!ObjectValid(id))
	{
		return PLUGIN_CONTINUE;
	}
#if (CSW_WEAPON_EX != CSW_KNIFE)
	return engclient_cmd(id,WEAPON_NAME_PRIMARY);
#else
	new pItem = util__WeaponFetchSlot(id,CSW_WEAPON_EX);

	#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
	if(!pItem
		|| (pev(pItem,pev_impulse) == UID_SNOW_MODE && get_pdata_cbase(id,m_pActiveItem) == pItem))
	{
		return PLUGIN_CONTINUE;
	}

	set_pev(pItem,pev_impulse,UID_SNOW_MODE);

	set_pdata_cbase(id,m_pLastItem,get_pdata_cbase(id,m_pActiveItem));
	set_pdata_cbase(id,m_pActiveItem,pItem);
	#else
	if(!pItem)
	{
		return PLUGIN_CONTINUE;
	}
	set_pdata_cbase(id,m_pActiveItem,pItem);
	#endif

	ExecuteHamB(Ham_Item_Deploy,pItem);
	return PLUGIN_CONTINUE;
#endif
}
public CBasePlayerItem__PostFrame(const ent)
{
#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
	if(pev(ent,pev_impulse) != UID_SNOW_MODE)
	{
		return HAM_IGNORED;
	}
#endif
	static Float:flWaitPower[MAX_CLIENTS + 1],Float:flCurrentTime,iButton,id;

	id = get_pdata_cbase(ent,m_pPlayer,4);

	if(!ObjectValid(id))
	{
		return HAM_IGNORED;
	}

	iButton = pev(id,pev_button);

	flCurrentTime = get_gametime();

	if(((iButton & IN_ATTACK && get_pdata_float(ent,m_flNextPrimaryAttack,4) <= flCurrentTime)
		|| (iButton & IN_ATTACK2 && get_pdata_float(ent,m_flNextSecondaryAttack,4) <= flCurrentTime)) && !get_pdata_float(ent,m_flStartThrow,4))
	{
		g_iPower[id] = 0;
		util__SendAnim(id,AS_PULLPIN);
		#if defined SNOW_BARTIME_STATUS
		if(!(iButton & IN_ATTACK))
		{
			util__SendBarTime(id,1);
		}
		#endif
		set_pdata_float(ent,m_flReleaseThrow,0.0,4);
		set_pdata_float(ent,m_flStartThrow,flCurrentTime,4);
		set_pdata_float(ent,m_flTimeWeaponIdle,flCurrentTime + 0.5,4);
	}
#if defined SNOW_KEEP
	else if(!(iButton & (IN_ATTACK|IN_ATTACK2)))
#else
	else if(~iButton & IN_ATTACK2)
#endif
	{
		if(!get_pdata_float(ent,m_flReleaseThrow,4) && get_pdata_float(ent,m_flStartThrow,4))
		{
			set_pdata_float(ent,m_flReleaseThrow,flCurrentTime,4);
		}
		if(get_pdata_float(ent,m_flTimeWeaponIdle,4) > flCurrentTime)
		{
			return HAM_SUPERCEDE;
		}
		if(get_pdata_float(ent,m_flStartThrow,4))
		{
			new Float:flVel;

			new Float:vecStart[3];
			new Float:vecThrow[3];
			new Float:vecVAngle[3];

			new Float:vecUp[3];
			new Float:vecForward[3];

			new Float:vecViewOfs[3];
			new Float:vecAngThrow[3];
			new Float:vecVelocity[3];
			new Float:vecPunchangle[3];

			pev(id,pev_origin,vecStart);
			pev(id,pev_v_angle,vecVAngle);
			pev(id,pev_view_ofs,vecViewOfs);
			pev(id,pev_velocity,vecVelocity);
			pev(id,pev_punchangle,vecPunchangle);

			vecAngThrow[0] = vecVAngle[0] + vecPunchangle[0];
			vecAngThrow[1] = vecVAngle[1] + vecPunchangle[1];
			vecAngThrow[2] = vecVAngle[2] + vecPunchangle[2];

			g_iPower[id] = clamp(g_iPower[id],MIN_POWER,MAX_POWER);

			if(vecAngThrow[0] < 0.0)
			{
				vecAngThrow[0] = -10.0 + vecAngThrow[0] * ((90.0 - 10.0) / 90.0);
			}
			else vecAngThrow[0] = -10.0 + vecAngThrow[0] * ((90.0 + 10.0) / 90.0);

			flVel = (90.0 - vecAngThrow[0]) * (g_iPower[id] / 2);

			if(flVel > 750.0 && g_iPower[id] <= MIN_POWER)
			{
				flVel = 750.0;
			}

			engfunc(EngFunc_MakeVectors,vecAngThrow);

			global_get(glb_v_up,vecUp);
			global_get(glb_v_forward,vecForward);

			vecStart[0] = vecStart[0] + vecViewOfs[0] + vecForward[0] * 16.0 + vecUp[0] * (g_iPower[id] > MIN_POWER ? 5.0 : 1.0);
			vecStart[1] = vecStart[1] + vecViewOfs[1] + vecForward[1] * 16.0 + vecUp[1] * (g_iPower[id] > MIN_POWER ? 5.0 : 1.0);
			vecStart[2] = vecStart[2] + vecViewOfs[2] + vecForward[2] * 16.0 + vecUp[2] * (g_iPower[id] > MIN_POWER ? 5.0 : 1.0);

			vecThrow[0] = vecForward[0] * flVel - vecUp[0] * random_float(45.0,90.0) + vecVelocity[0];
			vecThrow[1] = vecForward[1] * flVel - vecUp[1] * random_float(45.0,90.0) + vecVelocity[1];
			vecThrow[2] = vecForward[2] * flVel - vecUp[2] * random_float(45.0,90.0) + vecVelocity[2];

			#if defined SNOW_BARTIME_STATUS
			util__SendBarTime(id,0);
			#endif

			util__SendAnim(id,AS_THROW);
			util__SendAnimationShoot(id);
			util__ShootContact(id,vecStart,vecThrow);

			set_pdata_float(ent,m_flStartThrow,0.0,4);
			set_pdata_float(ent,m_flNextPrimaryAttack,flCurrentTime + 2.0,4);
			set_pdata_float(ent,m_flNextSecondaryAttack,flCurrentTime + 2.0,4);
			set_pdata_float(ent,m_flTimeWeaponIdle,flCurrentTime + 0.75,4);

			return HAM_SUPERCEDE;
		}
		else if(get_pdata_float(ent,m_flReleaseThrow,4) > 0.0)
		{
			util__SendAnim(id,AS_DRAW);

			set_pdata_float(ent,m_flReleaseThrow,-1.0,4);
			set_pdata_float(ent,m_flTimeWeaponIdle,flCurrentTime + random_float(10.0,15.0),4);

			return HAM_SUPERCEDE;
		}

		util__SendAnim(id,AS_IDLE);

		set_pdata_float(ent,m_flTimeWeaponIdle,flCurrentTime + random_float(10.0,15.0),4);

		return HAM_SUPERCEDE;
	}

	if(flCurrentTime > flWaitPower[id] && (~iButton & IN_ATTACK && iButton & IN_ATTACK2) && get_pdata_float(ent,m_flStartThrow,4))
	{
		g_iPower[id]++;
		flWaitPower[id] = flCurrentTime + FREQUENCY_POWER;
	}
	return HAM_SUPERCEDE;
}
public CBasePlayerItem__Deploy(const ent)
{
	new id = get_pdata_cbase(ent,41,4);

	if(!ObjectValid(id))
	{
		return HAM_IGNORED;
	}

	set_pdata_float(id,m_flNextAttack,0.75,4);
	set_pdata_float(ent,m_flTimeWeaponIdle,1.5,4);
	set_pdata_float(ent,m_flReleaseThrow,-1.0,4);
	set_pdata_float(ent,m_flStartThrow,0.0,4);

#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
	if(pev(ent,pev_impulse) == UID_SNOW_MODE)
	{
#endif

	set_pev(id,pev_viewmodel2,SNOW_V_MODEL);
	set_pev(id,pev_weaponmodel2,SNOW_P_MODEL);

	#if (CSW_WEAPON_EX == CSW_KNIFE)
	set_pdata_string(id,m_szAnimExtention * 4,"grenade",-1,5 * 4);
	#endif

#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
	}
	else
	{
		set_pdata_float(ent,m_flNextPrimaryAttack,-1.0,4);
		set_pdata_float(ent,m_flNextSecondaryAttack,-1.0,4);
	}
#endif

	util__SendAnim(id,AS_DRAW);

	return HAM_IGNORED;
}
stock util__WeaponFetchSlot(const id,const weaponId)
{
	new pItem;
	for(new i; i < MAX_ITEM_TYPES; i++)
	{
		pItem = get_pdata_cbase(id,m_rgpPlayerItems + i);

		while(ObjectValid(pItem))
		{
			if(get_pdata_int(pItem,m_iId,4) == weaponId)
			{
				return pItem;
			}

			pItem = get_pdata_cbase(pItem,m_pNext,4);
		}
	}

	if(!ObjectValid(pItem) || get_pdata_int(pItem,m_iId,4) != CSW_WEAPON_EX)
	{
		return 0;
	}
	return pItem;
}
stock util__SendAnim(const id,const WEAPON_ANIM:anim)
{
	set_pev(id,pev_weaponanim,anim);

	message_begin(MSG_ONE,SVC_WEAPONANIM,_,id);
	write_byte(_:anim);
	write_byte(0);
	message_end();
}
stock util__SendItemPickup(const id,const weaponId)
{
	message_begin(MSG_ONE_UNRELIABLE,g_msgidWeapPickup,_,id);
	write_byte(weaponId);
	message_end();
}
stock util__SendWeaponList(const id,const szWeaponName[32],const weaponID)
{
	message_begin(MSG_ONE_UNRELIABLE,g_msgidWeaponList,_,id);
	write_string(szWeaponName);
	write_byte(-1);
	write_byte(-1);
	write_byte(-1);
	write_byte(-1);

#if (CSW_WEAPON_EX == CSW_KNIFE)
	write_byte(2);
	write_byte((weaponID == CSW_SNOW) ? 20 : 1);
#else
	write_byte(3);
	write_byte(3);
#endif
	write_byte(weaponID);
	write_byte(0);
	message_end()
}
stock util__snowSpawn()
{
	new ent;
	static szAllocString;

	if(szAllocString || (szAllocString = engfunc(EngFunc_AllocString,"info_target")))
	{
		ent = engfunc(EngFunc_CreateNamedEntity,szAllocString);
	}

	if(!ObjectValid(ent))
	{
		return -1;
	}

	set_pev(ent,pev_classname,"snow");
	set_pev(ent,pev_solid,SOLID_BBOX);

#if !defined SNOW_KNIFE && (CSW_WEAPON_EX == CSW_KNIFE)
	set_pev(ent,pev_impulse,UID_SNOW_FLY);
#endif

	set_pev(ent,pev_movetype,MOVETYPE_TOSS);

	engfunc(EngFunc_SetModel,ent,SNOW_W_MODEL);
	engfunc(EngFunc_SetSize,ent,{0.0,0.0,0.0},{0.0,0.0,0.0});

	return ent;
}
stock util__ShootContact(const id,const Float:vecStart[3],const Float:vecVelocity[3])
{
	new Float:flRet[3];
	new ent = util__snowSpawn();

	if(ent == -1)
	{
		return PLUGIN_CONTINUE;
	}

	vector_to_angle(vecVelocity,flRet);

	set_pev(ent,pev_owner,id);
	set_pev(ent,pev_gravity,0.5);
	set_pev(ent,pev_angles,flRet);
	set_pev(ent,pev_dmg,g_iPower[id] * MULTIPLY_POWER);

	set_pev(ent,pev_velocity,vecVelocity);
	set_pev(ent,pev_nextthink,get_gametime() + 0.1);
	set_pev(ent,pev_avelocity,random_float(-100.0,-500.0));
	engfunc(EngFunc_SetOrigin,ent,vecStart);

	if(g_iPower[id] >= MAX_POWER)
	{
		fm_set_rendering(ent,kRenderFxGlowShell,0,200,255,kRenderNormal,150);
	}
	return ent;
}
stock util__SendBarTime(const id,const iDuration)
{
	message_begin(MSG_ONE_UNRELIABLE,g_msgidBarTime,_,id);
	write_short(iDuration);
	message_end();
}
stock util__EffectSnow(const ent)
{
	new Float:vecStart[3];
	pev(ent,pev_origin,vecStart);

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BLOODSPRITE);

	engfunc(EngFunc_WriteCoord,vecStart[0]);
	engfunc(EngFunc_WriteCoord,vecStart[1]);
	engfunc(EngFunc_WriteCoord,vecStart[2]);

	write_short(g_iSprBloodSpray);
	write_short(g_iSprBlood);
	write_byte(9);
	write_byte(15);
	message_end();

	set_pev(ent,pev_flags,FL_KILLME);
}
stock Ham:Ham_Valid_Player_ResetMaxSpeed()
{
	#if defined Ham_CS_Player_ResetMaxSpeed
		return IsHamValid(Ham_CS_Player_ResetMaxSpeed) ? Ham_CS_Player_ResetMaxSpeed : Ham_Item_PreFrame;
	#else
		return Ham_Item_PreFrame;
	#endif
}
// thanks to KORD_12.7 | SetAnimation
// link: http://aghl.ru/forum/viewtopic.php?f=20&t=1493#p17852
stock util__SendAnimationShoot(const id)
{
	new iAnimDesired,Float:flFrameRate,Float:flGroundSpeed,bool:bLoops;

	if((iAnimDesired = lookup_sequence(id,"ref_shoot_grenade",flFrameRate,bLoops,flGroundSpeed)) == -1)
	{
		iAnimDesired = 0;
	}

	new Float:flCurrentTime = get_gametime();

	set_pev(id,pev_frame,0.0);
	set_pev(id,pev_framerate,1.0);
	set_pev(id,pev_animtime,flCurrentTime);
	set_pev(id,pev_sequence,iAnimDesired);

	set_pdata_int(id,m_fSequenceLoops,bLoops,4);
	set_pdata_int(id,m_fSequenceFinished,0,4);

	set_pdata_float(id,m_flFrameRate,flFrameRate,4);
	set_pdata_float(id,m_flGroundSpeed,flGroundSpeed,4);
	set_pdata_float(id,m_flLastEventCheck,flCurrentTime,4);

	set_pdata_int(id,m_Activity,ACT_RANGE_ATTACK1);
	set_pdata_int(id,m_IdealActivity,ACT_RANGE_ATTACK1);   
	set_pdata_float(id,m_flLastAttackTime,flCurrentTime);
}
// reverse CBasePlayer::SelectLastItem(void)
stock CBasePlayer__SelectLastItem(const id)
{
	if(!ObjectValid(id))
	{
		return PLUGIN_CONTINUE;
	}

	new i;
	new pItem;
	new pLastItem;
	new pActiveItem;
	new Float:vecAutoAim[3];

	pActiveItem = get_pdata_cbase(id,m_pActiveItem);

	if(!ObjectValid(pActiveItem) || !ExecuteHam(Ham_Item_CanHolster,pActiveItem))
	{
		return PLUGIN_CONTINUE;
	}

	pLastItem = get_pdata_cbase(id,m_pLastItem);

	if(!ObjectValid(pLastItem) || pLastItem == pActiveItem)
	{
		if(get_pdata_int(pActiveItem,m_iId,4) == CSW_WEAPON_EX)
		{
			set_pev(pActiveItem,pev_impulse,(pev(pActiveItem,pev_impulse) == UID_SNOW_MODE) ? UID_NONE : UID_SNOW_MODE);
			ExecuteHamB(Ham_Item_Deploy,pActiveItem);
			return PLUGIN_HANDLED;
		}
		else
		{
			for(i = 0; i < MAX_ITEM_TYPES; i++)
			{
				pItem = get_pdata_cbase(id,m_rgpPlayerItems + i);

				if(pItem && pItem != pActiveItem)
				{
					pLastItem = pItem;
					set_pdata_cbase(id,m_pLastItem,pItem);

					break;
				}
			}
		}
	}

	if(!ObjectValid(pLastItem) || pLastItem == pActiveItem)
	{
		return PLUGIN_CONTINUE;
	}

	// reverse CBasePlayer::ResetAutoaim(void)
	for(i = 0; i < 3; i++)
	{
		vecAutoAim[i] = get_pdata_float(id,m_vecAutoAim + i);
	}

	if(vecAutoAim[0] != 0.0 || vecAutoAim[1] != 0.0)
	{
		for(i = 0; i < 3; i++)
		{
			set_pdata_float(id,m_vecAutoAim + i,0.0);
		}
		engfunc(EngFunc_CrosshairAngle,id,0.0,0.0);
	}

	set_pdata_int(id,m_fOnTarget,0);

	if(get_pdata_bool(id,m_bHasShield))
	{
		set_pdata_int(pActiveItem,m_fWeaponState,WPNSTATE_SHIELD_DRAWN,4);
		set_pdata_bool(id,m_bShieldDrawn,false);
	}

	set_pdata_cbase(id,m_pActiveItem,pLastItem);
	set_pdata_cbase(id,m_pLastItem,pActiveItem);

	ExecuteHam(Ham_Item_Holster,pActiveItem,0);
	ExecuteHamB(Ham_Item_Deploy,pLastItem);
	ExecuteHam(Ham_Item_UpdateItemInfo,pLastItem);

	set_pdata_int(id,m_iHideHUD,get_pdata_int(id,m_iHideHUD) &~ HIDEHUD_CROSSHAIR);

	ExecuteHam(Ham_ResetMaxSpeed,id);

	return PLUGIN_HANDLED;
}
#if (AMXX_VERSION_NUM < 183)

#define INT_BYTES 4
#define BYTE_BITS 8

stock bool:get_pdata_bool(ent,charbased_offset,intbase_linuxdiff = 5)
{ 
	return !!(get_pdata_int(ent,charbased_offset / INT_BYTES,intbase_linuxdiff) & (0xFF<<((charbased_offset % INT_BYTES) * BYTE_BITS)))
}
stock set_pdata_bool(ent,charbased_offset,bool:value,intbase_linuxdiff = 5)
{
	set_pdata_char(ent,charbased_offset,_:value,intbase_linuxdiff);
}
stock set_pdata_char(ent,charbased_offset,value,intbase_linuxdiff = 5)
{
	value &= 0xFF;
	new int_offset_value = get_pdata_int(ent,charbased_offset / INT_BYTES,intbase_linuxdiff);
	new bit_decal = (charbased_offset % INT_BYTES) * BYTE_BITS;
	int_offset_value &= ~(0xFF<<bit_decal);
	int_offset_value |= value<<bit_decal;
	set_pdata_int(ent,charbased_offset / INT_BYTES,int_offset_value,intbase_linuxdiff);
	return 1;
}
#endif