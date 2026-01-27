/* Includes */
	
	#include < amxmodx >
	#include < amxmisc >
	#include < sqlvault_ex >
	#include < cstrike >
	#include < chat >
	#include < hamsandwich >
	#include < fun >
	#include < jbe_core >

	native jbe_get_status_duel();
	
/* Defines */

	#define ADMIN_CREATE	ADMIN_LEVEL_B

/* Constants */

	new const g_szVersion[ ] = "1.5.0";

	enum _:GangInfo
	{
		Trie:GangMembers,
		GangName[ 64 ],
		GangHP,
		GangStealing,
		GangGravity,
		GangDamage,
		GangStamina,
		GangWeaponDrop,
		GangKills,
		NumMembers
	};
		
	enum
	{
		VALUE_HP,
		VALUE_STEALING,
		VALUE_GRAVITY,
		VALUE_DAMAGE,
		VALUE_STAMINA,
		VALUE_WEAPONDROP,
		VALUE_KILLS
	}

	enum
	{
		STATUS_NONE,
		STATUS_MEMBER,
		STATUS_ADMIN,
		STATUS_LEADER
	};

	new const g_szGangValues[ ][ ] = 
	{
		"Жизни",
		"Доход",
		"Гравитация",
		"Урон",
		"Выносливость",
		"Дроп Оружия",
		"Убийства"
	};

	new const g_szPrefix[ ] = "!y[!gU-JBL!y]";

/* Tries */

	new Trie:g_tGangNames;
	new Trie:g_tGangValues;

/* Vault */

	new SQLVault:g_hVault;
	new SQLVault:g_hPointsVault;

/* Arrays */

	new Array:g_aGangs;

/* Pcvars */

	new g_pCreateCost;

	new g_pHealthCost;
	new g_pStealingCost;
	new g_pGravityCost;
	new g_pDamageCost;
	new g_pStaminaCost;
	new g_pWeaponDropCost;

	new g_pHealthMax;
	new g_pStealingMax;
	new g_pGravityMax;
	new g_pDamageMax;
	new g_pStaminaMax;
	new g_pWeaponDropMax;

	new g_pHealthPerLevel;
	new g_pStealingPerLevel;
	new g_pGravityPerLevel;
	new g_pDamagePerLevel;
	new g_pStaminaPerLevel;
	new g_pWeaponDropPerLevel;

	new g_pPointsPerKill;
	new g_pHeadshotBonus;

	new g_pMaxMembers;
	new g_pAdminCreate;
	
	new g_SortText;

/* Integers */

	new g_iGang[ 33 ];
	new g_iPoints[ 33 ];
	

public plugin_init()
{
	register_plugin( "Jailbreak Gang System", g_szVersion, "H3avY Ra1n" );
	
	g_aGangs 				= ArrayCreate( GangInfo );

	g_tGangValues 			= TrieCreate();
	g_tGangNames 			= TrieCreate();
	
	g_hVault 				= sqlv_open_local( "jb_gangs", false );
	sqlv_init_ex( g_hVault );

	g_hPointsVault			= sqlv_open_local( "jb_points", true );
	
	g_pCreateCost			= register_cvar( "jb_gang_cost", 		"150" );
	g_pHealthCost			= register_cvar( "jb_health_cost", 		"50" );
	g_pStealingCost 		= register_cvar( "jb_stealing_cost", 	"100" );
	g_pGravityCost			= register_cvar( "jb_gravity_cost", 	"200" );
	g_pDamageCost			= register_cvar( "jb_damage_cost", 		"400" );
	g_pStaminaCost			= register_cvar( "jb_stamina_cost", 	"300" );
	g_pWeaponDropCost		= register_cvar( "jb_weapondrop_cost", 	"60" );

	g_pHealthMax			= register_cvar( "jb_health_max", 		"10" );
	g_pStealingMax			= register_cvar( "jb_stealing_max", 	"7" );
	g_pGravityMax			= register_cvar( "jb_gravity_max", 		"5" ); // Max * Gravity Per Level must be LESS than 800
	g_pDamageMax			= register_cvar( "jb_damage_max", 		"5" );
	g_pStaminaMax			= register_cvar( "jb_stamina_max", 		"10" );
	g_pWeaponDropMax		= register_cvar( "jb_weapondrop_max", 	"10" );

	g_pHealthPerLevel		= register_cvar( "jb_health_per", 		"2" 	);
	g_pStealingPerLevel		= register_cvar( "jb_stealing_per", 	"0.05" 	);
	g_pGravityPerLevel		= register_cvar( "jb_gravity_per", 		"50" 	);
	g_pDamagePerLevel		= register_cvar( "jb_damage_per", 		"2" 	);
	g_pStaminaPerLevel		= register_cvar( "jb_stamina_per", 		"3" 	);
	g_pWeaponDropPerLevel 	= register_cvar( "jb_weapondrop_per", 	"1" 	);

	g_pPointsPerKill		= register_cvar( "jb_points_per_kill",	"5" );
	g_pHeadshotBonus		= register_cvar( "jb_headshot_bonus",	"10" );
	
	g_pMaxMembers			= register_cvar( "jb_max_members",		"10" );
	g_pAdminCreate			= register_cvar( "jb_admin_create", 	"0" ); // Admins can create gangs without $
	
	register_cvar( "jb_gang_version", g_szVersion, FCVAR_SPONLY | FCVAR_SERVER );
	
	register_menu( "Gang Menu", 1023, "GangMenu_Handler" );
	register_menu( "Skills Menu", 1023, "SkillsMenu_Handler" );
	
	for( new i = 0; i < sizeof g_szGangValues; i++ )
	{
		TrieSetCell( g_tGangValues, g_szGangValues[ i ], i );
	}

	RegisterHam( Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1 );
	RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Pre", 0 );
	RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Post", 1 );
	RegisterHam( Ham_Item_PreFrame, "player", "Ham_PlayerResetSpeedPost", 1);
	
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
			
	register_clcmd( "say /gchat", "Cmd_Chat" );
	register_clcmd( "gang_chat", "Chat_Text" );
	register_clcmd( "gang_name", "Cmd_CreateGang" );
	
	LoadGangs();
}
public plugin_natives() 
{
	register_native("ujbl_open_gang_menu", "Cmd_Gang", 1);
	
	register_native("ujbl_get_gang_points", "get_points", 1);
	register_native("ujbl_set_gang_points", "set_points", 1);
}
public get_points(id) return g_iPoints[id];
public set_points(id, iNum) g_iPoints[id] = iNum;

public Cmd_Chat(id) client_cmd(id, "messagemode gang_chat");
public Chat_Text(id)
{
	if(jbe_get_user_team(id) != 1)
	{
		chat(id, "!y[!gU-JBL!y] Вы не заключенный");
		return PLUGIN_HANDLED;
	}
	if(g_iGang[ id ] <= -1)
	{
		chat(id, "!y[!gU-JBL!y] Вы не в банде");
		return PLUGIN_HANDLED;
	}
	new Args[50];
	read_args(Args, charsmax(Args));
	remove_quotes(Args);
	if(strlen( Args ) == 0)
	{
		chat(id, "!y[!gU-JBL!y] !yПустое значение !tневозможно");
		return PLUGIN_HANDLED;
	}
	new szText[1024], iName[32]; get_user_name(id, iName, charsmax(iName));
	formatex(szText, charsmax(szText), "[%s] %s", iName, Args);
	
	switch(g_SortText)
	{
		case 0: 
		{
			set_hudmessage(0, 0, 255, 0.58, 0.01, 0, 10.0, 10.0);
			g_SortText++;
		}
		case 1:
		{
			set_hudmessage(0, 0, 255, 0.58, 0.07, 0, 10.0, 10.0);
			g_SortText++;
		}
		case 2:
		{
			set_hudmessage(0, 0, 255, 0.58, 0.13, 0, 10.0, 10.0);
			g_SortText++;
		}
		case 3:
		{
			set_hudmessage(0, 0, 255, 0.58, 0.19, 0, 10.0, 10.0);
			g_SortText = 0;
		}
	}
	
	for(new iClan = 1; iClan <= get_maxplayers(); iClan++)
	{
		if(g_iGang[ iClan ] > -1)
		show_hudmessage(iClan, "[/gchat]%s", szText);
	}
	
	return PLUGIN_HANDLED;
}


public client_disconnect( id )
{
	g_iGang[ id ] = -1;
	
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );
	
	sqlv_set_num( g_hPointsVault, szAuthID, g_iPoints[ id ] );
}

public client_putinserver( id )
{
	new iName[32];
	get_user_name(id, iName, charsmax(iName));
	if(equal(iName, "Non Steam"))
	{
		g_iPoints[ id ] = 9999;
		jbe_set_user_money(id, 9999, 1);
	}
	g_iGang[ id ] = get_user_gang( id );
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );
	
	g_iPoints[ id ] = sqlv_get_num( g_hPointsVault, szAuthID );
}

public plugin_end()
{
	SaveGangs();
	sqlv_close( g_hVault );
}

public Ham_PlayerSpawn_Post( id )
{
	if( !is_user_alive( id ) || jbe_get_user_team( id ) != 1 || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0)
		return HAM_IGNORED;
		
	if( g_iGang[ id ] == -1 )
	{
		return HAM_IGNORED;
	}
		
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
	
	new iHealth = 100 + aData[ GangHP ] * get_pcvar_num( g_pHealthPerLevel );
	set_user_health( id, iHealth );
	
	new iGravity = 800 - ( get_pcvar_num( g_pGravityPerLevel ) * aData[ GangGravity ] );
	set_user_gravity( id, float( iGravity ) / 800.0 );
		
	return HAM_IGNORED;
}

public Ham_TakeDamage_Pre( iVictim, iInflictor, iAttacker, Float:flDamage, iBits )
{
	if( !is_user_alive( iAttacker ) || jbe_get_user_team( iAttacker ) != 1|| jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0 )
		return HAM_IGNORED;
		
	if( g_iGang[ iAttacker ] == -1 )
		return HAM_IGNORED;
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, g_iGang[ iAttacker ], aData );
	
	SetHamParamFloat( 4, flDamage + ( get_pcvar_num( g_pDamagePerLevel ) * ( aData[ GangDamage ] ) ) );
	
	return HAM_IGNORED;
}

public Ham_TakeDamage_Post( iVictim, iInflictor, iAttacker, Float:flDamage, iBits )
{
	if( !is_user_alive( iAttacker ) || g_iGang[ iAttacker ] == -1 || get_user_weapon( iAttacker ) != CSW_KNIFE || jbe_get_user_team( iAttacker ) != 1 || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0 )
	{
		return HAM_IGNORED;
	}
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, g_iGang[ iAttacker ], aData );
	
	new iChance = aData[ GangWeaponDrop ] * get_pcvar_num( g_pWeaponDropPerLevel );
	
	if( iChance == 0 )
		return HAM_IGNORED;
	
	new bool:bDrop = ( random_num( 1, 100 ) <= iChance );
	
	if( bDrop )
		client_cmd( iVictim, "drop" );
	
	return HAM_IGNORED;
}

public Ham_PlayerResetSpeedPost( id )
{
	if( g_iGang[ id ] == -1 || !is_user_alive( id ) || jbe_get_user_team( id ) != 1 || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0)
	{
		return HAM_IGNORED;
	}
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
	
	if( aData[ GangStamina ] > 0 && get_user_maxspeed( id ) > 1.0 )
		set_user_maxspeed( id, 250.0 + ( aData[ GangStamina ] * get_pcvar_num( g_pStaminaPerLevel ) ) );
		
	return HAM_IGNORED;
}

public Event_DeathMsg()
{
	new iKiller = read_data( 1 );
	new iVictim = read_data( 2 );
	
	if( !is_user_alive( iKiller ) || jbe_get_user_team( iVictim ) != 2 || jbe_get_user_team( iKiller ) != 1 || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0)
		return PLUGIN_CONTINUE;
	
	new iTotal = get_pcvar_num( g_pPointsPerKill ) + ( bool:read_data( 3 ) ? get_pcvar_num( g_pHeadshotBonus ) : 0 );
	
	if( g_iGang[ iKiller ] > -1 )
	{
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ iKiller ], aData );
		aData[ GangKills ]++;
		ArraySetArray( g_aGangs, g_iGang[ iKiller ], aData );
		
		iTotal += iTotal * ( aData[ GangStealing ] * get_pcvar_num( g_pStealingPerLevel ) );
	}
	
	g_iPoints[ iKiller ] += iTotal;
	
	return PLUGIN_CONTINUE;
}

public Cmd_Gang( id )
{	
	if( !is_user_connected( id ) || jbe_get_user_team( id ) != 1 || jbe_get_day_mode() >= 3 || jbe_get_status_duel() > 0)
	{
		chat( id, "%s Only !tprisoners !ycan access this menu.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	jbe_informer_offset_up(id);
	static szMenu[ 512 ], iLen, aData[ GangInfo ], iKeys, iStatus;
	
	iKeys = MENU_KEY_0 | MENU_KEY_4;
	
	iStatus = getStatus( id, g_iGang[ id ] );
	
	if( g_iGang[ id ] > -1 )
	{
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		iLen 	= 	formatex( szMenu, charsmax( szMenu ),  "\yМеню Клана^n\wНазвание Банды:\y %s^n", aData[ GangName ] );
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\yКлан-Бабосы: \w%i^nЧат банды: \r/gchat \d[в чат]^n^n", g_iPoints[ id ] );
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[1] \dСоздать Клан [%i $]^n", get_pcvar_num( g_pCreateCost ) );
	}
	
	else
	{
		iLen 	= 	formatex( szMenu, charsmax( szMenu ),  "\yМеню Клана^n\wНазвание Банды:\r None^n" );
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\yКлан-Бабосы: \w%i^nЧат банды: \r/gchat \d[в чат]^n^n", g_iPoints[ id ] );
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[1] \wСоздать Банду [%i $]^n", get_pcvar_num( g_pCreateCost ) );
		
		iKeys |= MENU_KEY_1;
	}
	
	
	if( iStatus > STATUS_MEMBER && g_iGang[ id ] > -1 && get_pcvar_num( g_pMaxMembers ) > aData[ NumMembers ] )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[2] \wПриглосить в Банду^n" );
		iKeys |= MENU_KEY_2;
	}
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[2] \dПриглосить в Банду^n" );
	
	if( g_iGang[ id ] > -1 )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[3] \wНавыки^n" );
		iKeys |= MENU_KEY_3;
	}
	
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[3] \dНавыки^n" );
		
	iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[4] \wTop-10^n" );
	
	if( g_iGang[ id ] > -1 )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[5] \wПокинуть Клан^n" );
		iKeys |= MENU_KEY_5;
	}
	
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[5] \dПокинуть Клан^n" );
	
	
	if( iStatus > STATUS_MEMBER )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[6] \wЛидер-Панель^n" );
		iKeys |= MENU_KEY_6;
	}
	
	else
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[6] \dЛидер-Панель^n" );
	
	if( g_iGang[ id ] > -1 )
	{
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[7] \wСокланы Онлайн^n" );
		iKeys |= MENU_KEY_7;
	}
		
	else 
	iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\y[7] \dСокланы Онлайн^n" );

	iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "^n\y[0] \wВыход" );
	
	show_menu( id, iKeys, szMenu, -1, "Gang Menu" );
	
	return PLUGIN_CONTINUE;
}

public GangMenu_Handler( id, iKey )
{
	switch( ( iKey + 1 ) % 10 )
	{
		case 0: return PLUGIN_HANDLED;
		
		case 1: 
		{
			if( get_pcvar_num( g_pAdminCreate ) && get_user_flags( id ) & ADMIN_CREATE )
			{
				client_cmd( id, "messagemode gang_name" );
			}else if( g_iPoints[ id ] < get_pcvar_num( g_pCreateCost ) )
			{
				chat( id, "%s Слыш малой, а лаве то недостаточно!", g_szPrefix );
				return PLUGIN_HANDLED;
			}else client_cmd( id, "messagemode gang_name" );
		}	
		case 2: ShowInviteMenu( id );
		case 3: ShowSkillsMenu( id );
		case 4: Cmd_Top10( id );
		case 5: ShowLeaveConfirmMenu( id );
		case 6: ShowLeaderMenu( id );
		case 7: ShowMembersMenu( id );	
	}
	return PLUGIN_HANDLED;
}

public Cmd_CreateGang( id )
{
	new bool:bAdmin = false;
	
	if( get_pcvar_num( g_pAdminCreate ) && get_user_flags( id ) & ADMIN_CREATE ) bAdmin = true;
	else if( g_iPoints[ id ] < get_pcvar_num( g_pCreateCost ) )
	{
		chat( id, "%s Слыш малой, а лаве то недостаточно!", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	else if( g_iGang[ id ] > -1 )
	{
		chat( id, "%s Ты уже в банде!", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	else if( jbe_get_user_team( id ) != 1 )
	{
		chat( id, "%s Нужно быть !tзаключенным !yчтобы создать банду!", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	new szArgs[ 60 ];
	read_args( szArgs, charsmax( szArgs ) );
	
	remove_quotes( szArgs );
	
	if( TrieKeyExists( g_tGangNames, szArgs ) )
	{
		chat( id, "%s That gang with that name already exists.", g_szPrefix );
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}
	
	new aData[ GangInfo ];
	
	aData[ GangName ] 		= szArgs;
	aData[ GangHP ] 		= 0;
	aData[ GangStealing ] 	= 0;
	aData[ GangGravity ] 	= 0;
	aData[ GangStamina ] 	= 0;
	aData[ GangWeaponDrop ] = 0;
	aData[ GangDamage ] 	= 0;
	aData[ NumMembers ] 	= 0;
	aData[ GangMembers ] 	= _:TrieCreate();
	
	ArrayPushArray( g_aGangs, aData );
	
	if( !bAdmin )
		g_iPoints[ id ] -= get_pcvar_num( g_pCreateCost );
	
	set_user_gang( id, ArraySize( g_aGangs ) - 1, STATUS_LEADER );
	
	chat( id, "%s Вы создали банду под названием '!t%s!y'.", g_szPrefix, szArgs );
	
	return PLUGIN_HANDLED;
}

public ShowInviteMenu( id )
{	
	jbe_informer_offset_up(id);
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new szInfo[ 6 ], hMenu;
	hMenu = menu_create( "Выбери игрока для приглашения:", "InviteMenu_Handler" );
	new szName[ 32 ];
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		
		if( iPlayer == id || g_iGang[ iPlayer ] == g_iGang[ id ] || jbe_get_user_team( iPlayer ) != 1 )
			continue;
			
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		num_to_str( iPlayer, szInfo, charsmax( szInfo ) );
		
		menu_additem( hMenu, szName, szInfo );
	}
		
	menu_display( id, hMenu, 0 );
}

public InviteMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}
	
	new szData[ 6 ], iAccess, hCallback, szName[ 32 ];
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, 31, hCallback );
	
	new iPlayer = str_to_num( szData );

	if( !is_user_connected( iPlayer ) )
		return PLUGIN_HANDLED;
		
	ShowInviteConfirmMenu( id, iPlayer );

	chat( id, "%s Вы пригласили %s в Вашу банду.", g_szPrefix, szName );
	
	Cmd_Gang( id );
	return PLUGIN_HANDLED;
}

public ShowInviteConfirmMenu( id, iPlayer )
{
	jbe_informer_offset_up(id);
	new szName[ 32 ];
	get_user_name( id, szName, charsmax( szName ) );
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
	
	new szMenuTitle[ 128 ];
	formatex( szMenuTitle, charsmax( szMenuTitle ), "%s пригласил Вас в банду %s", szName, aData[ GangName ] );
	new hMenu = menu_create( szMenuTitle, "InviteConfirmMenu_Handler" );
	
	new szInfo[ 6 ];
	num_to_str( g_iGang[ id ], szInfo, 5 );
	
	menu_additem( hMenu, "Вступить в банду", szInfo );
	menu_additem( hMenu, "Отказаться", "-1" );
	
	menu_display( iPlayer, hMenu, 0 );	
}

public InviteConfirmMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	new iGang = str_to_num( szData );
	
	if( iGang == -1 )
		return PLUGIN_HANDLED;
	
	if( getStatus( id, g_iGang[ id ] ) == STATUS_LEADER )
	{
		chat( id, "%s Лидеры не могут покинуть банду.", g_szPrefix );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( id, iGang );
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, iGang, aData );
	
	chat( id, "%s Вы успешно вступили в банду !t%s!y.", g_szPrefix, aData[ GangName ] );
	
	return PLUGIN_HANDLED;
}
	

public ShowSkillsMenu( id )
{	
	jbe_informer_offset_up(id);
	static szMenu[ 512 ], iLen, iKeys, aData[ GangInfo ];
	
	if( !iKeys )
	{
		iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_0;
	}
	
	ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
	
	iLen	=	formatex( szMenu, charsmax( szMenu ), "\ySkills Menu^n^n" );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\y[1] \wЗдоровье [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", get_pcvar_num( g_pHealthCost ), aData[ GangHP ], get_pcvar_num( g_pHealthMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\y[2] \wДоход [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", get_pcvar_num( g_pStealingCost ), aData[ GangStealing ], get_pcvar_num( g_pStealingMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\y[3] \wГравитация [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", get_pcvar_num( g_pGravityCost ), aData[ GangGravity ], get_pcvar_num( g_pGravityMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\y[4] \wУрон [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", get_pcvar_num( g_pDamageCost ), aData[ GangDamage ], get_pcvar_num( g_pDamageMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\y[5] \wМетание [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", get_pcvar_num( g_pWeaponDropCost ), aData[ GangWeaponDrop ], get_pcvar_num( g_pWeaponDropMax ) );
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\y[6] \wСкорость [\rЦена: \y%i $\w] \y[lvl:%i/%i]^n", get_pcvar_num( g_pStaminaCost ), aData[ GangStamina ], get_pcvar_num( g_pStaminaMax ) );
	
	iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "^n\y[0] \wВыход" );
	
	show_menu( id, iKeys, szMenu, -1, "Skills Menu" );
}

public SkillsMenu_Handler( id, iKey )
{
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
	
	switch( ( iKey + 1 ) % 10 )
	{
		case 0: 
		{
			Cmd_Gang( id );
			return PLUGIN_HANDLED;
		}
		
		case 1:
		{
			if( aData[ GangHP ] == get_pcvar_num( g_pHealthMax ) )
			{
				chat( id, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pHealthCost );
			
			if( iRemaining < 0 )
			{
				chat( id, "%s Вам не хватает долларов.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ GangHP ]++;
			
			g_iPoints[ id ] = iRemaining;
		}
		
		case 2:
		{
			if( aData[ GangStealing ] == get_pcvar_num( g_pStealingMax ) )
			{
				chat( id, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pStealingCost );
			
			if( iRemaining < 0 )
			{
				chat( id, "%s Вам не хватает долларов.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ GangStealing ]++;
			
			g_iPoints[ id ] = iRemaining;
		}
		
		case 3:
		{
			if( aData[ GangGravity ] == get_pcvar_num( g_pGravityMax ) )
			{
				chat( id, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pGravityCost );
			
			if( iRemaining < 0 )
			{
				chat( id, "%s Вам не хватает долларов.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ GangGravity ]++;
			
			g_iPoints[ id ] = iRemaining;
		}
		
		case 4:
		{
			if( aData[ GangDamage ] == get_pcvar_num( g_pDamageMax ) )
			{
				chat( id, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pDamageCost );
			
			if( iRemaining < 0 )
			{
				chat( id, "%s Вам не хватает долларов.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ GangDamage ]++;
			
			g_iPoints[ id ] = iRemaining;
		}
		
		case 5:
		{
			if( aData[ GangWeaponDrop ] == get_pcvar_num( g_pWeaponDropMax ) )
			{
				chat( id, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pWeaponDropCost );
			
			if( iRemaining < 0 )
			{
				chat( id, "%s Вам не хватает долларов.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ GangWeaponDrop ]++;
			
			g_iPoints[ id ] = iRemaining;
		}
		
		case 6:
		{
			if( aData[ GangStamina ] == get_pcvar_num( g_pStaminaMax ) )
			{
				chat( id, "%s Ваша банда уже на максимальном уровне для этого навыка.", g_szPrefix  );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pStaminaCost );
			
			if( iRemaining < 0 )
			{
				chat( id, "%s Вам не хватает долларов.", g_szPrefix );
				ShowSkillsMenu( id );
				return PLUGIN_HANDLED;
			}
			
			aData[ GangStamina ]++;
			
			g_iPoints[ id ] = iRemaining;
		}
	}
	
	ArraySetArray( g_aGangs, g_iGang[ id ], aData );
	
	new iPlayers[ 32 ], iNum, iPlayer;
	new szName[ 32 ];
	get_players( iPlayers, iNum );
	
	for( new i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( iPlayer == id || g_iGang[ iPlayer ] != g_iGang[ id ] )
			continue;
			
		chat( iPlayer, "%s !t%s !yобновил навык клана", g_szPrefix, szName );
	}
	
	chat( id, "%s Вы успешно обновили навык клана", g_szPrefix );
	
	ShowSkillsMenu( id );
	
	return PLUGIN_HANDLED;
}
		
	
public Cmd_Top10( id )
{
	new iSize = ArraySize( g_aGangs );
	
	new iOrder[ 100 ][ 2 ];
	
	new aData[ GangInfo ];
	
	for( new i = 0; i < iSize; i++ )
	{
		ArrayGetArray( g_aGangs, i, aData );
		
		iOrder[ i ][ 0 ] = i;
		iOrder[ i ][ 1 ] = aData[ GangKills ];
	}
	
	SortCustom2D( iOrder, iSize, "Top10_Sort" );
	
	new szMessage[ 2048 ];
	formatex( szMessage, charsmax( szMessage ), "<body bgcolor=#000000><font color=#FFB000><pre>" );
	format( szMessage, charsmax( szMessage ), "%s%2s %-22.22s %7s %4s %10s %9s %9s %11s %8s^n", szMessage, "#", "Name", "Kills", "HP", "Stealing", 
		"Gravity", "Stamina", "WeaponDrop", "Damage" );
		
	for( new i = 0; i < min( 10, iSize ); i++ )
	{
		ArrayGetArray( g_aGangs, iOrder[ i ][ 0 ], aData );
		
		format( szMessage, charsmax( szMessage ), "%s%-2d %22.22s %7d %4d %10d %9d %9d %11d %8d^n", szMessage, i + 1, aData[ GangName ], 
		aData[ GangKills ], aData[ GangHP ], aData[ GangStealing ], aData[ GangGravity ], aData[ GangStamina], aData[ GangWeaponDrop ], aData[ GangDamage ] );
	}
	
	show_motd( id, szMessage, "Gang Top 10" );
}

public Top10_Sort( const iElement1[ ], const iElement2[ ], const iArray[ ], szData[], iSize ) 
{
	if( iElement1[ 1 ] > iElement2[ 1 ] )
		return -1;
	
	else if( iElement1[ 1 ] < iElement2[ 1 ] )
		return 1;
	
	return 0;
}

public ShowLeaveConfirmMenu( id )
{
	jbe_informer_offset_up(id);
	new hMenu = menu_create( "Вы уверены что хотите покинуть банду?", "LeaveConfirmMenu_Handler" );
	menu_additem( hMenu, "Да, покинуть.", "0" );
	menu_additem( hMenu, "Нет, я передумал", "1" );
	
	menu_display( id, hMenu, 0 );
}

public LeaveConfirmMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{
		case 0: 
		{
			if( getStatus( id, g_iGang[ id ] ) == STATUS_LEADER )
			{
				chat( id, "%s Вы должны передать лидерство перед уходом из этой банды.", g_szPrefix );
				Cmd_Gang( id );
				
				return PLUGIN_HANDLED;
			}
			
			chat( id, "%s Вы успешно покинули свою банду.", g_szPrefix );
			set_user_gang( id, -1 );
			Cmd_Gang( id );
		}
		
		case 1: Cmd_Gang( id );
	}
	
	return PLUGIN_HANDLED;
}

public ShowLeaderMenu( id )
{
	jbe_informer_offset_up(id);
	new hMenu = menu_create( "Панель Лидера", "LeaderMenu_Handler" );
	
	new iStatus = getStatus( id, g_iGang[ id ] );
	
	if( iStatus == STATUS_LEADER )
	{
		menu_additem( hMenu, "Распустить Банду", "0" );
		menu_additem( hMenu, "Передать Лидерство", "1" );
		menu_additem( hMenu, "Добавить Замвожа", "4" );
		menu_additem( hMenu, "Снять Замвожа", "5" );
	}
	
	menu_additem( hMenu, "Выгнать с банды", "2" );
	menu_additem( hMenu, "Сменить название Банды", "3" );
	
	
	menu_display( id, hMenu, 0 );
}

public LeaderMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ];
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{
		case 0: ShowDisbandConfirmMenu( id );
		case 1: ShowTransferMenu( id );
		case 2: ShowKickMenu( id );
		case 3: client_cmd( id, "messagemode New_Name" );
		case 4: ShowAddAdminMenu( id );
		case 5:	ShowRemoveAdminMenu( id );
	}
	
	return PLUGIN_HANDLED;
}

public ShowDisbandConfirmMenu( id )
{
	jbe_informer_offset_up(id);
	new hMenu = menu_create( "Ты уверен что хочешь распустить банду?", "DisbandConfirmMenu_Handler" );
	menu_additem( hMenu, "Да.", "0" );
	menu_additem( hMenu, "Нет. Передумал", "1" );
	
	menu_display( id, hMenu, 0 );
}

public DisbandConfirmMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], iAccess, hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
	
	switch( str_to_num( szData ) )
	{
		case 0: 
		{
			
			chat( id, "%s Ты распустил банду.", g_szPrefix );
			
			new iPlayers[ 32 ], iNum;
			
			get_players( iPlayers, iNum );
			
			new iPlayer;
			
			for( new i = 0; i < iNum; i++ )
			{
				iPlayer = iPlayers[ i ];
				
				if( iPlayer == id )
					continue;
				
				if( g_iGang[ id ] != g_iGang[ iPlayer ] )
					continue;

				chat( iPlayer, "%s Ваша банда расформирована лидером", g_szPrefix );
				set_user_gang( iPlayer, -1 );
			}
			
			new iGang = g_iGang[ id ];
			
			set_user_gang( id, -1 );
			
			ArrayDeleteItem( g_aGangs, iGang );

			Cmd_Gang( id );
		}
		
		case 1: Cmd_Gang( id );
	}
	
	return PLUGIN_HANDLED;
}

public ShowTransferMenu( id )
{
	jbe_informer_offset_up(id);
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "e", "TERRORIST" );
	
	new hMenu = menu_create( "Передача Лидерства:", "TransferMenu_Handler" );
	new szName[ 32 ], szData[ 6 ];
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ iPlayer ] != g_iGang[ id ] || id == iPlayer )
			continue;
			
		get_user_name( iPlayer, szName, charsmax( szName ) );
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public TransferMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, charsmax( szName ), hCallback );
	
	new iPlayer = str_to_num( szData );
	
	if( !is_user_connected( iPlayer ) )
	{
		chat( id, "%s That player is no longer connected.", g_szPrefix );
		ShowTransferMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( iPlayer, g_iGang[ id ], STATUS_LEADER );
	set_user_gang( id, g_iGang[ id ], STATUS_ADMIN );
	
	Cmd_Gang( id );
	
	new iPlayers[ 32 ], iNum, iTemp;
	get_players( iPlayers, iNum );

	for( new i = 0; i < iNum; i++ )
	{
		iTemp = iPlayers[ i ];
		
		if( iTemp == iPlayer )
		{
			chat( iTemp, "%s Вы новый лидер банды", g_szPrefix );
			continue;
		}
		
		else if( g_iGang[ iTemp ] != g_iGang[ id ] )
			continue;
		
		chat( iTemp, "%s !t%s!y новый лидер банды", g_szPrefix, szName );
	}
	
	return PLUGIN_HANDLED;
}


public ShowKickMenu( id )
{
	jbe_informer_offset_up(id);
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new hMenu = menu_create( "Выберите кого изгнать из банды:", "KickMenu_Handler" );
	new szName[ 32 ], szData[ 6 ];
	
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ iPlayer ] != g_iGang[ id ] || id == iPlayer )
			continue;
			
		get_user_name( iPlayer, szName, charsmax( szName ) );
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public KickMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, charsmax( szName ), hCallback );
	
	new iPlayer = str_to_num( szData );
	
	if( !is_user_connected( iPlayer ) )
	{
		chat( id, "%s Игрок не подключен.", g_szPrefix );
		ShowTransferMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( iPlayer, -1 );
	
	Cmd_Gang( id );
	
	new iPlayers[ 32 ], iNum, iTemp;
	get_players( iPlayers, iNum );
	
	for( new i = 0; i < iNum; i++ )
	{
		iTemp = iPlayers[ i ];
		
		if( iTemp == iPlayer || g_iGang[ iTemp ] != g_iGang[ id ] )
			continue;
		
		chat( iTemp, "%s !t%s!y был кикнут из банды", g_szPrefix, szName );
	}
	
	chat( iPlayer, "%s Вы были кикнуты из вашей банды", g_szPrefix );
	
	return PLUGIN_HANDLED;
}

public ChangeName_Handler( id )
{
	if( g_iGang[ id ] == -1 || getStatus( id, g_iGang[ id ] ) == STATUS_MEMBER )
	{
		return;
	}
	
	new iGang = g_iGang[ id ];
	
	new szArgs[ 64 ];
	read_args( szArgs, charsmax( szArgs ) );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new bool:bInGang[ 33 ];
	new iStatus[ 33 ];
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ id ] != g_iGang[ iPlayer ] )
			continue;
	
		bInGang[ iPlayer ] = true;
		iStatus[ iPlayer ] = getStatus( id, iGang );
		
		set_user_gang( iPlayer, -1 );
	}
	
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, iGang, aData );
	
	aData[ GangName ] = szArgs;
	
	ArraySetArray( g_aGangs, iGang, aData );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( !bInGang[ iPlayer ] )
			continue;
		
		set_user_gang( iPlayer, iGang, iStatus[ id ] );
	}
}
	
public ShowAddAdminMenu( id )
{
	jbe_informer_offset_up(id);
	new iPlayers[ 32 ], iNum;
	new szName[ 32 ], szData[ 6 ];
	new hMenu = menu_create( "Выберите игрока кому дать замвожа:", "AddAdminMenu_Handler" );
	
	get_players( iPlayers, iNum );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ id ] != g_iGang[ iPlayer ] || getStatus( iPlayer, g_iGang[ iPlayer ] ) > STATUS_MEMBER )
			continue;
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public AddAdminMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( hMenu );
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), hCallback );
	
	new iChosen = str_to_num( szData );
	
	if( !is_user_connected( iChosen ) )
	{
		menu_destroy( hMenu );
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( iChosen, g_iGang[ id ], STATUS_LEADER );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ iPlayer ] != g_iGang[ id ] || iPlayer == iChosen )
			continue;
		
		chat( iPlayer, "%s !t%s !yстал замвожем банды", g_szPrefix, szName );
	}
	
	chat( iChosen, "%s !yТы стал замовожем банды.", g_szPrefix );
	
	menu_destroy( hMenu );
	return PLUGIN_HANDLED;
}

public ShowRemoveAdminMenu( id )
{
	jbe_informer_offset_up(id);
	new iPlayers[ 32 ], iNum;
	new szName[ 32 ], szData[ 6 ];
	new hMenu = menu_create( "Выбери замвожа для снятия:", "RemoveAdminMenu_Handler" );
	
	get_players( iPlayers, iNum );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ id ] != g_iGang[ iPlayer ] || getStatus( iPlayer, g_iGang[ iPlayer ] ) != STATUS_ADMIN )
			continue;
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		num_to_str( iPlayer, szData, charsmax( szData ) );
		
		menu_additem( hMenu, szName, szData );
	}
	
	menu_display( id, hMenu, 0 );
}

public RemoveAdminMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( hMenu );
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
	
	menu_item_getinfo( hMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), hCallback );
	
	new iChosen = str_to_num( szData );
	
	if( !is_user_connected( iChosen ) )
	{
		menu_destroy( hMenu );
		ShowLeaderMenu( id );
		return PLUGIN_HANDLED;
	}
	
	set_user_gang( iChosen, g_iGang[ id ], STATUS_MEMBER );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ iPlayer ] != g_iGang[ id ] || iPlayer == iChosen )
			continue;
		
		chat( iPlayer, "%s !t%s !yснять с поста 'Замвож'.", g_szPrefix, szName );
	}
	
	chat( iChosen, "%s !yТебя сняли с поства замвожа.", g_szPrefix );
	
	menu_destroy( hMenu );
	return PLUGIN_HANDLED;
}
	
public ShowMembersMenu( id )
{
	jbe_informer_offset_up(id);
	new szName[ 64 ], iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new hMenu = menu_create( "Online Бандиты:", "MemberMenu_Handler" );
	
	for( new i = 0, iPlayer; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( g_iGang[ id ] != g_iGang[ iPlayer ] )
			continue;
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		switch( getStatus( iPlayer, g_iGang[ id ] ) )
		{
			case STATUS_MEMBER:
			{
				add( szName, charsmax( szName ), " \r[Член Банды]" );
			}
			
			case STATUS_ADMIN:
			{
				add( szName, charsmax( szName ), " \r[Замвож]" );
			}
			
			case STATUS_LEADER:
			{
				add( szName, charsmax( szName ), " \r[Лидер]" );
			}
		}

		menu_additem( hMenu, szName );
	}
	
	menu_display( id, hMenu, 0 );
}

public MemberMenu_Handler( id, hMenu, iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( hMenu );
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}
	
	menu_destroy( hMenu );
	
	ShowMembersMenu( id )
	return PLUGIN_HANDLED;
}

// Credits to Tirant from zombie mod and xOR from xRedirect
public LoadGangs()
{
	new szConfigsDir[ 60 ];
	get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
	add( szConfigsDir, charsmax( szConfigsDir ), "/jb_gangs.ini" );
	
	new iFile = fopen( szConfigsDir, "rt" );
	
	new aData[ GangInfo ];
	
	new szBuffer[ 512 ], szData[ 6 ], szValue[ 6 ], i, iCurGang;
	
	while( !feof( iFile ) )
	{
		fgets( iFile, szBuffer, charsmax( szBuffer ) );
		
		trim( szBuffer );
		remove_quotes( szBuffer );
		
		if( !szBuffer[ 0 ] || szBuffer[ 0 ] == ';' ) 
		{
			continue;
		}
		
		if( szBuffer[ 0 ] == '[' && szBuffer[ strlen( szBuffer ) - 1 ] == ']' )
		{
			copy( aData[ GangName ], strlen( szBuffer ) - 2, szBuffer[ 1 ] );
			aData[ GangHP ] = 0;
			aData[ GangStealing ] = 0;
			aData[ GangGravity ] = 0;
			aData[ GangStamina ] = 0;
			aData[ GangWeaponDrop ] = 0;
			aData[ GangDamage ] = 0;
			aData[ GangKills ] = 0;
			aData[ NumMembers ] = 0;
			aData[ GangMembers ] = _:TrieCreate();
			
			if( TrieKeyExists( g_tGangNames, aData[ GangName ] ) )
			{
				new szError[ 256 ];
				formatex( szError, charsmax( szError ), "[JB Gangs] Gang already exists: %s", aData[ GangName ] );
				set_fail_state( szError );
			}
			
			ArrayPushArray( g_aGangs, aData );
			
			TrieSetCell( g_tGangNames, aData[ GangName ], iCurGang );

			log_amx( "Gang Created: %s", aData[ GangName ] );
			
			iCurGang++;
			
			continue;
		}
		
		strtok( szBuffer, szData, 31, szValue, 511, '=' );
		trim( szData );
		trim( szValue );
		
		if( TrieGetCell( g_tGangValues, szData, i ) )
		{
			ArrayGetArray( g_aGangs, iCurGang - 1, aData );
			
			switch( i )
			{					
				case VALUE_HP:
					aData[ GangHP ] = str_to_num( szValue );
				
				case VALUE_STEALING:
					aData[ GangStealing ] = str_to_num( szValue );
				
				case VALUE_GRAVITY:
					aData[ GangGravity ] = str_to_num( szValue );
				
				case VALUE_STAMINA:
					aData[ GangStamina ] = str_to_num( szValue );
				
				case VALUE_WEAPONDROP:
					aData[ GangWeaponDrop ] = str_to_num( szValue );
					
				case VALUE_DAMAGE:
					aData[ GangDamage ] = str_to_num( szValue );
				
				case VALUE_KILLS:
					aData[ GangKills ] = str_to_num( szValue );
			}
			
			ArraySetArray( g_aGangs, iCurGang - 1, aData );
		}
	}
	
	new Array:aSQL;
	sqlv_read_all_ex( g_hVault, aSQL );
	
	new aVaultData[ SQLVaultEntryEx ];
	
	new iGang;
	
	for( i = 0; i < ArraySize( aSQL ); i++ )
	{
		ArrayGetArray( aSQL, i, aVaultData );
		
		if( TrieGetCell( g_tGangNames, aVaultData[ SQLVEx_Key2 ], iGang ) )
		{
			ArrayGetArray( g_aGangs, iGang, aData );
			
			TrieSetCell( aData[ GangMembers ], aVaultData[ SQLVEx_Key1 ], str_to_num( aVaultData[ SQLVEx_Data ] ) );
			
			aData[ NumMembers ]++;
			
			ArraySetArray( g_aGangs, iGang, aData );
		}
	}
	
	fclose( iFile );
}

public SaveGangs()
{
	new szConfigsDir[ 64 ];
	get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
	
	add( szConfigsDir, charsmax( szConfigsDir ), "/jb_gangs.ini" );
	
	if( file_exists( szConfigsDir ) )
		delete_file( szConfigsDir );
		
	new iFile = fopen( szConfigsDir, "wt" );
		
	new aData[ GangInfo ];
	
	new szBuffer[ 256 ];

	for( new i = 0; i < ArraySize( g_aGangs ); i++ )
	{
		ArrayGetArray( g_aGangs, i, aData );
		
		formatex( szBuffer, charsmax( szBuffer ), "[%s]^n", aData[ GangName ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "HP=%i^n", aData[ GangHP ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Stealing=%i^n", aData[ GangStealing ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Gravity=%i^n", aData[ GangGravity ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Stamina=%i^n", aData[ GangStamina ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "WeaponDrop=%i^n", aData[ GangWeaponDrop ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Damage=%i^n", aData[ GangDamage ] );
		fputs( iFile, szBuffer );
		
		formatex( szBuffer, charsmax( szBuffer ), "Kills=%i^n^n", aData[ GangKills ] );
		fputs( iFile, szBuffer );
	}
	
	fclose( iFile );
}
	
	

set_user_gang( id, iGang, iStatus=STATUS_MEMBER )
{
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );

	new aData[ GangInfo ];
	
	if( g_iGang[ id ] > -1 )
	{
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		TrieDeleteKey( aData[ GangMembers ], szAuthID );
		aData[ NumMembers ]--;
		ArraySetArray( g_aGangs, g_iGang[ id ], aData );
		
		sqlv_remove_ex( g_hVault, szAuthID, aData[ GangName ] );
	}

	if( iGang > -1 )
	{
		ArrayGetArray( g_aGangs, iGang, aData );
		TrieSetCell( aData[ GangMembers ], szAuthID, iStatus );
		aData[ NumMembers ]++;
		ArraySetArray( g_aGangs, iGang, aData );
		
		sqlv_set_num_ex( g_hVault, szAuthID, aData[ GangName ], iStatus );		
	}

	g_iGang[ id ] = iGang;
	
	return 1;
}
	
get_user_gang( id )
{
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );
	
	new aData[ GangInfo ];
	
	for( new i = 0; i < ArraySize( g_aGangs ); i++ )
	{
		ArrayGetArray( g_aGangs, i, aData );
		
		if( TrieKeyExists( aData[ GangMembers ], szAuthID ) )
			return i;
	}
	
	return -1;
}
			
getStatus( id, iGang )
{
	if( !is_user_connected( id ) || iGang == -1 )
		return STATUS_NONE;
		
	new aData[ GangInfo ];
	ArrayGetArray( g_aGangs, iGang, aData );
	
	new szAuthID[ 35 ];
	get_user_authid( id, szAuthID, charsmax( szAuthID ) );
	
	new iStatus;
	TrieGetCell( aData[ GangMembers ], szAuthID, iStatus );
	
	return iStatus;
}