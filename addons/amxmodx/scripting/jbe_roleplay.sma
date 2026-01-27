#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <engine>
#include <hamsandwich>
#include <jbe_core>
#include <dhudmessage>

#define PLUGIN "[JBE] RolePlay"
#define VERSION "3.0"
#define AUTHOR "arttty7 & kotya"

#define SetBit(%0,%1) ((%0) |= (1 << (%1)))
#define ClearBit(%0,%1) ((%0) &= ~(1 << (%1)))
#define IsSetBit(%0,%1) ((%0) & (1 << (%1)))
#define IsNotSetBit(%0,%1) (~(%0) & (1 << (%1)))
#define jbe_is_user_valid(%0) (%0 && %0 <= 32)
#pragma tabsize 0

#define MsgId_ScreenFade 98
#define TASK_SPID 95983
#define TASK_GOLOVA 95983
#define TASK_ADDICTION 95983

enum _:CVAR { POTENCIYA, VIAGRA, BLOCK_1DAY, BLOCK_2DAY, BLOCK_3DAY, MONEY, 
AVTO_POTENCIYA, AVTO_VIRUS, AVTO_BLOCK_10DAY, AVTO_POYAS, GIPS, PARALICH, EAR, SPID, FOOT, HEAD }
enum _:CVARS { PLAYER_MIN_ENERGY, PLAYER_MAX_ENERGY, CREAT_ENERGY, VAMPIR_ENERGY, SUPER_ADMIN_ENERGY, ADMIN_ENERGY, VIP_ENERGY,
ST_SMOTRITEL_ENERGY, HOOK_ENERGY, BOSS_ENERGY, POTENCIYA_ED, AVTO_POTENCIYA_ED, ADDICTION }
new g_iShopCvars[CVAR], g_iAllCvars[CVARS];

native jbe_set_user_money(index, money, flash = 1); 
native jbe_get_user_money(index); 

new g_iBitUserCreat, g_iBitUserVampir, g_iBitUserSuperAdmin, g_iBitUserAdmin, g_iBitUserVip, g_iBitUserStSmotr, g_iBitUserHook, g_iBitUserBoss, g_iBitUserIznosilovan;
new g_iBitSlomalRyki, g_iBitSlomalNogi, g_iBitSpid, g_iBitZrenie, g_iBitParalich, g_iBitGolova;
new g_iBitViagra, g_iBitStoyak, g_iBitVirus, g_iBitVernosti, g_iBitBigStoyak, bool:g_iParalize[33] = false;
new g_iBlock[33] = 0, g_iEnergy[33], g_iSpid[33], g_iGolova[33], g_iScreenFades[33], g_iAntiVor[33] = 0, g_iAddiction[33];

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_menucmd(register_menuid("Show_RolePlayMenu"), 1023, "Handle_RolePlayMenu");
	register_menucmd(register_menuid("Show_RolePlayShop"), 1023, "Handle_RolePlayShop");
	register_menucmd(register_menuid("Show_RolePlayVipShop"), 1023, "Handle_RolePlayVipShop");
	register_menucmd(register_menuid("Show_RolePlayAptecka"), 1023, "Handle_RolePlayAptecka");
	register_event("ResetHUD","startround","be")
	RegisterHam(Ham_Killed, "player", "Ham_PlayerKilled_Post", true)
	register_dictionary("jbe_roleplay.txt")	
	
	register_cvar("jbe_player_energy_min", "1"); register_cvar("jbe_player_energy_max", "4"); register_cvar("jbe_creat_energy", "100"); register_cvar("jbe_st_smotritel_energy", "50");
	register_cvar("jbe_vip_energy", "3"); register_cvar("jbe_admin_energy", "4"); register_cvar("jbe_super_admin_energy", "5"); register_cvar("jbe_vampir_energy", "3");
	register_cvar("jbe_hook_energy", "3"); register_cvar("jbe_boss_energy", "6"); register_cvar("jbe_potenciya_koll", "3"); register_cvar("jbe_avto_potenciya_koll", "5");	
	register_cvar("jbe_price_potenciya", "58"); register_cvar("jbe_price_viagra", "25"); register_cvar("jbe_price_block_1day", "28"); register_cvar("jbe_price_block_2day", "37");
	register_cvar("jbe_price_block_3day", "64"); register_cvar("jbe_price_money", "35"); register_cvar("jbe_price_avto_potenciya", "70"); register_cvar("jbe_price_virus", "42");
	register_cvar("jbe_price_block_10day", "72"); register_cvar("jbe_price_poyas", "30"); register_cvar("jbe_price_gips", "17"); register_cvar("jbe_price_paralich", "30");
	register_cvar("jbe_price_ear", "23"); register_cvar("jbe_price_spid", "51"); register_cvar("jbe_price_foot", "18"); register_cvar("jbe_price_head", "42");
	register_cvar("jbe_day_addiction", "5");
}

public plugin_precache()
{
	new i, szBuffer[64];
	new const szBarney[][] = {"ba_die1", "ba_die2", "ba_die3", "ba_pain1", "ba_pain2", "ba_pain3"};
	for(i = 0; i < sizeof(szBarney); i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "barney/%s.wav", szBarney[i]);
		engfunc(EngFunc_PrecacheSound, szBuffer);
	}
}

public plugin_cfg()
{
    new szCfgDir[64];
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir));
	server_cmd("exec %s/jb_engine/cfg/roleplay_cvars.cfg", szCfgDir);
	set_task(0.1, "jbe_cvars");
}

public jbe_cvars()
{
    g_iAllCvars[PLAYER_MAX_ENERGY] = get_cvar_num("jbe_player_energy_min");
	g_iAllCvars[PLAYER_MIN_ENERGY] = get_cvar_num("jbe_player_energy_max");
	g_iAllCvars[CREAT_ENERGY] = get_cvar_num("jbe_creat_energy");
	g_iAllCvars[VAMPIR_ENERGY] = get_cvar_num("jbe_vampir_energy");
	g_iAllCvars[ADMIN_ENERGY] = get_cvar_num("jbe_admin_energy");
	g_iAllCvars[ST_SMOTRITEL_ENERGY] = get_cvar_num("jbe_st_smotritel_energy");
	g_iAllCvars[SUPER_ADMIN_ENERGY] = get_cvar_num("jbe_super_admin_energy");
	g_iAllCvars[VIP_ENERGY] = get_cvar_num("jbe_vip_energy ");
	g_iAllCvars[HOOK_ENERGY] = get_cvar_num("jbe_hook_energy");
	g_iAllCvars[BOSS_ENERGY] = get_cvar_num("jbe_boss_energy");
	g_iAllCvars[POTENCIYA_ED] = get_cvar_num("jbe_potenciya_koll");
	g_iAllCvars[AVTO_POTENCIYA_ED] = get_cvar_num("jbe_avto_potenciya_koll");
	g_iAllCvars[ADDICTION] = get_cvar_num("jbe_day_addiction");
	
	g_iShopCvars[POTENCIYA] = get_cvar_num("jbe_price_potenciya");
	g_iShopCvars[VIAGRA] = get_cvar_num("jbe_price_viagra");
	g_iShopCvars[BLOCK_1DAY] = get_cvar_num("jbe_price_block_1day");
	g_iShopCvars[BLOCK_2DAY] = get_cvar_num("jbe_price_block_2day");
	g_iShopCvars[BLOCK_3DAY] = get_cvar_num("jbe_price_block_3day");
	g_iShopCvars[MONEY] = get_cvar_num("jbe_price_money");
	g_iShopCvars[AVTO_POTENCIYA] = get_cvar_num("jbe_price_avto_potenciya");
	g_iShopCvars[AVTO_VIRUS] = get_cvar_num("jbe_price_virus");
	g_iShopCvars[AVTO_BLOCK_10DAY] = get_cvar_num("jbe_price_block_10day");
	g_iShopCvars[AVTO_POYAS] = get_cvar_num("jbe_price_poyas");
	g_iShopCvars[GIPS] = get_cvar_num("jbe_price_gips");
	g_iShopCvars[PARALICH] = get_cvar_num("jbe_price_paralich");
	g_iShopCvars[EAR] = get_cvar_num("jbe_price_ear");
	g_iShopCvars[SPID] = get_cvar_num("jbe_price_spid");
	g_iShopCvars[FOOT] = get_cvar_num("jbe_price_foot");
	g_iShopCvars[HEAD] = get_cvar_num("jbe_price_head");
}

Show_RolePlayMenu(id)
{
	new iAlive = is_user_alive(id);
	new szMenu[512], iKeys = (1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n", id, "JBE_MENU_ROLEPLAY_MAIN_TITLE", g_iEnergy[id]);
    if(iAlive && g_iEnergy[id] > 0)
	{
	    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w1\r] \w%L^n", id, "JBE_MENU_ROLEPLAY_IZNAS");
		iKeys |= (1<<0);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L^n", id, "JBE_MENU_ROLEPLAY_IZNAS");
	if(iAlive)
	{
	    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w2\r] \w%L^n", id, "JBE_MENU_ROLEPLAY_SEX_SHOP");
		iKeys |= (1<<1);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L^n", id, "JBE_MENU_ROLEPLAY_SEX_SHOP");
	if(iAlive && IsSetBit(g_iBitUserVampir, id) || IsSetBit(g_iBitUserVip, id) || IsSetBit(g_iBitUserHook, id))
	{
	    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w3\r] \w%L^n", id, "JBE_MENU_ROLEPLAY_AVTO_SEX_SHOP");
		iKeys |= (1<<2);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L^n", id, "JBE_MENU_ROLEPLAY_AVTO_SEX_SHOP");
	if(iAlive)
	{
	    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w4\r] \w%L^n^n", id, "JBE_MENU_ROLEPLAY_APTEKA");
		iKeys |= (1<<3);
	}
    else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L^n^n", id, "JBE_MENU_ROLEPLAY_APTEKA");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w9\r] \wНазад^n");
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w0\r] \wВыход^n");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n%L", id, "JBE_MENU_ROLEPLAY_INFO");
	return show_menu(id, iKeys, szMenu, -1, "Show_RolePlayMenu");
}

public Handle_RolePlayMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
		    new i_Player, iBody;
			get_user_aiming(id, i_Player, iBody, 60);
			if(jbe_is_user_valid(i_Player) && is_user_alive(i_Player) && is_user_alive(id))
			{
			    if(get_user_team(i_Player) != 1) ChatColor(id,"%L", id, "JBE_ROLEPLAY_PRISONER")
				else
				{
				    new szRapist[33], szVictim[33];
		     	    get_user_name(id,szRapist,32);
			       	get_user_name(i_Player,szVictim,32);
				    if(IsSetBit(g_iBitUserCreat, i_Player))
		    	    {
					    user_silentkill(id);
						ChatColor(0,"%L", id, "JBE_ROLEPLAY_IZNAS_CREAT", szRapist, szVictim);
				    }
					else if(IsSetBit(g_iBitUserStSmotr, i_Player) && IsNotSetBit(g_iBitUserCreat, id))
		    	    {
					    ChatColor(id, "%L", id, "JBE_ROLEPLAY_IZNAS_ST_SMOTR");
						ChatColor(i_Player, "%L", id, "JBE_ROLEPLAY_IZNAS_ST_SMOTR_ID", szVictim);
				    }
				    else if(IsSetBit(g_iBitVirus, i_Player) && IsNotSetBit(g_iBitUserCreat, id)) 
		   	        {
					    user_silentkill(id);
					    ClearBit(g_iBitVirus, i_Player);
						roleplay_victim_iznas(i_Player);
						roleplay_rapist_iznas(id);
						ChatColor(0, "%L", id, "JBE_ROLEPLAY_IZNAS_VIRUS",szRapist,szVictim);
					    ChatColor(i_Player, "%L", id, "JBE_ROLEPLAY_IZNAS_VIRUS_ID");
						g_iAddiction[id] = 0;
		   	        }
					else if(IsSetBit(g_iBitVernosti, i_Player)) ChatColor(id, "%L", id, "JBE_ROLEPLAY_IZNAS_POYAS_VERNOSTI");
			        else if(IsSetBit(g_iBitUserIznosilovan, i_Player)) ChatColor(id, "%L", id, "JBE_ROLEPLAY_IZNAS_IZNAS");
					else if(IsSetBit(g_iBitViagra, id) && g_iBlock[i_Player] > 0)
					{
			            RolePlay_situation(id, i_Player);
						roleplay_victim_iznas(i_Player);
						roleplay_rapist_iznas(id);						
			        }
					else if(g_iBlock[i_Player] > 0) ChatColor(id, "%L", id, "JBE_ROLEPLAY_BLOCK_MSG");
           	        else
	        	    {
			            RolePlay_situation(id, i_Player);
						roleplay_victim_iznas(i_Player);
						roleplay_rapist_iznas(id);		
			        }
				}
			}
			else ChatColor(id, "%L", id, "JBE_ROLEPLAY_NEAR");
		}
		case 1: if(is_user_alive(id)) return Show_RolePlayShop(id);
		case 2: if(is_user_alive(id) && (IsSetBit(g_iBitUserVampir, id) || IsSetBit(g_iBitUserVip, id) || IsSetBit(g_iBitUserHook, id))) return Show_RolePlayVipShop(id);
		case 3: if(is_user_alive(id)) return Show_RolePlayAptecka(id);
		case 8: client_cmd(id, "say /menu");
		case 9: return PLUGIN_HANDLED;
	}
	return Show_RolePlayMenu(id);
}	

public RolePlay_situation(id, i_Player)
{
	new szRapist[33], szVictim[33];
	get_user_name(id,szRapist,32);
	get_user_name(i_Player,szVictim,32);
	switch(random_num(1, 21))
	 {
		case 1,2:
		{
			set_user_health(i_Player, 1)
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_1",szRapist,szVictim);
			ChatColor(i_Player,"%L", id, "JBE_ROLEPLAY_SITUATION_1_ID",szRapist,szVictim);
		}
		case 3:
		{
			set_user_maxspeed(i_Player, 100.0);
			SetBit(g_iBitSlomalNogi, i_Player);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_2",szRapist,szVictim);
		}
		case 4:
		{
			if(g_iAntiVor[i_Player] > 0 && jbe_get_user_money(i_Player) < 50000) 
			{
				new victimmoney = jbe_get_user_money(i_Player)
				new attackermoney = jbe_get_user_money(id)
				new minmoney = 1;
				new maxmoney = victimmoney -1;
				new resultmoney = random_num(minmoney,maxmoney);
				jbe_set_user_money(id,attackermoney + resultmoney);
				jbe_set_user_money(i_Player,victimmoney - resultmoney);
				g_iEnergy[id]--;
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_3",szRapist,szVictim,resultmoney);
			}
			else
			{
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_4",szRapist,szVictim)
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_SITUATION_4_ID")
			}
		}
		case 5:
		{
			if(!task_exists(id + TASK_SPID)) set_task(2.0, "un_spid", id+TASK_SPID, _, _, "a", 200)
			g_iScreenFades[id] = 1;
			SetBit(g_iBitSpid, id);
			set_task(1.0, "Random_screenfade", id);
			message_begin(MSG_ONE, get_user_msgid("SetFOV"), { 0, 0, 0 }, id);
			write_byte(180);
			message_end();
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_5",szRapist, szVictim);
			ChatColor(id,"%L", id, "JBE_ROLEPLAY_SITUATION_5_ID");
		}
		case 6:
		{
			if(!task_exists(i_Player + TASK_SPID)) set_task(2.0, "un_spid", i_Player+TASK_SPID, _, _, "a", 200);
			g_iScreenFades[i_Player] = 1;
			SetBit(g_iBitSpid, i_Player)
			set_task(1.0, "Random_screenfade", i_Player);
			message_begin(MSG_ONE, get_user_msgid("SetFOV"), { 0, 0, 0 }, i_Player);
			write_byte(180);
			message_end();
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_6",szRapist, szVictim);
			ChatColor(i_Player,"%L", id, "JBE_ROLEPLAY_SITUATION_6_ID");
		}
		case 7:
		{
			g_iParalize[id] = true;
			SetBit(g_iBitParalich, id);
			set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_7",szRapist,szVictim);
		}
		case 8:
		{
			g_iParalize[i_Player] = true;
			SetBit(g_iBitParalich, i_Player);
			set_pev(i_Player, pev_flags, pev(i_Player, pev_flags) | FL_FROZEN);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_8",szRapist,szVictim);
		}
		case 9,10:
		{
			set_user_health(id, 200);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_9",szRapist,szVictim);
			ChatColor(id,"%L", id, "JBE_ROLEPLAY_SITUATION_9_ID");
		}
		case 11,12:
		{
			set_user_maxspeed(id, 280.0);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_10",szRapist,szVictim);
			ChatColor(id,"%L", id, "JBE_ROLEPLAY_SITUATION_10_ID");
		}
		case 13:
		{
			strip_user_weapons(i_Player);
			SetBit(g_iBitSlomalRyki, i_Player);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_11",szRapist,szVictim);
		}
		case 14:
		{
			jbe_add_user_wanted(id);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_12",szRapist,szVictim);
		}
		case 15:
		{
			jbe_add_user_wanted(id);
			jbe_add_user_wanted(i_Player);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_13",szRapist,szVictim);
		}
		case 16:
		{
			if(jbe_is_user_free(i_Player))
			{
				jbe_sub_user_free(i_Player);
				jbe_add_user_free(id);
				g_iEnergy[id]--;
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_14",szRapist,szVictim);
			}
			else
			{
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_4",szRapist,szVictim);
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_SITUATION_4_ID");
			}
		}	
		case 17:
		{
			if(jbe_is_user_free(id))
			{
				jbe_add_user_free(i_Player);
				jbe_sub_user_free(id);
				g_iEnergy[id]--;
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_15",szRapist,szVictim);
			}
			else
			{
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_4",szRapist,szVictim);
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_SITUATION_4_ID");
			}
		}
		case 18:
		{
			UTIL_ScreenFade(i_Player, 0, 0, 4, 0, 0, 0, 255);
			SetBit(g_iBitZrenie, i_Player);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_16", szRapist, szVictim);
		}
		case 19:
		{
			UTIL_ScreenFade(id, 0, 0, 4, 0, 0, 0, 255);
			SetBit(g_iBitZrenie, id);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_17", szRapist, szVictim);
		}
		case 20:
		{
			if(!task_exists(i_Player + TASK_GOLOVA)) set_task(5.0, "un_golova", i_Player+TASK_GOLOVA, _, _, "a", 200);
			SetBit(g_iBitGolova, i_Player);
			g_iEnergy[id]--;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_18",szRapist,szVictim);
		}
		case 21:
		{
			g_iEnergy[id] = 0;
			ChatColor(0,"%L", id, "JBE_ROLEPLAY_SITUATION_19",szRapist,szVictim);
			ChatColor(id,"%L", id, "JBE_ROLEPLAY_SITUATION_19_ID");
		}							
	}
}

public roleplay_victim_iznas(iVictim)
{
	new victim_sound = random_num(1, 3);
	set_dhudmessage(255, 0, 0, -1.0, 0.20, 0, 0.1, 3.0, 0.3, 2.0, false);
    show_dhudmessage(iVictim, "%L", iVictim, "JBE_ROLEPLAY_IZNAS_VICTIM_DHUD");
	SetBit(g_iBitUserIznosilovan, iVictim);
	switch(victim_sound)
	{
		case 1: client_cmd(iVictim, "spk barney/ba_die1");
		case 2: client_cmd(iVictim, "spk barney/ba_die2");
		case 3: client_cmd(iVictim, "spk barney/ba_die3");
	}
}

public roleplay_rapist_iznas(iRapist)
{
	new rapist_sound = random_num(1, 3);
	g_iAddiction[iRapist] = 0;
	remove_task(iRapist+TASK_ADDICTION);
	if(IsNotSetBit(g_iBitZrenie, iRapist)) UTIL_ScreenFade(iRapist, 512, 512, 0, 0, 0, 0, 255, 1);
	switch(rapist_sound)
	{
		case 1: client_cmd(iRapist, "spk barney/ba_pain1");
		case 2: client_cmd(iRapist, "spk barney/ba_pain2");
		case 3: client_cmd(iRapist, "spk barney/ba_pain3");
	}
}

public un_spid(id)
{
	if(id>TASK_SPID) id -= TASK_SPID;
	jbe_set_user_rendering(id, kRenderFxGlowShell, random_num(50, 255), random_num(50, 255), random_num(50, 255), kRenderNormal, 10);
	UTIL_ScreenFade(id, 1, 1, 0, random_num(50, 255), random_num(50, 255), random_num(50, 255), 0, 0);
	ExecuteHamB(Ham_TakeDamage, id, g_iSpid[id] , g_iSpid[id], 5.0 , DMG_BULLET | DMG_NEVERGIB);
}

public un_golova(id)
{
	if(id>TASK_GOLOVA) id -= TASK_GOLOVA;
	set_pev(id, pev_punchangle, { 400.0, 999.0, 400.0 });
	ExecuteHamB(Ham_TakeDamage, id, g_iGolova[id] , g_iGolova[id], 3.0 , DMG_BULLET | DMG_NEVERGIB);
}

public addiction(id)
{
	if(id>TASK_ADDICTION) id -= TASK_ADDICTION;
	set_pev(id, pev_punchangle, { 10.0, 20.0, 40.0 });
	red_ScreenFade(id);
	ExecuteHamB(Ham_TakeDamage, id, g_iGolova[id] , g_iGolova[id], 20.0 , DMG_BULLET | DMG_NEVERGIB);
}

public Random_screenfade(id)
{
	if(is_user_alive(id) && g_iScreenFades[id])
	{
		UTIL_ScreenFade(id, 0, 0, 4, random_num(0, 255), random_num(0, 255), random_num(0, 255), 100, 1);
		set_task(0.35, "Random_screenfade", id);
	}
	return PLUGIN_HANDLED;
}

Show_RolePlayShop(id)
{
    new g_Money = jbe_get_user_money(id)
	new szMenu[512], iKeys = (1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_ROLEPLAY_SEX_SHOP");
	if(IsNotSetBit(g_iBitStoyak, id))
	{
	    if(g_Money > g_iShopCvars[POTENCIYA])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w1\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_SEX_SHOP_POTENCIYA", g_iAllCvars[POTENCIYA_ED], g_iShopCvars[POTENCIYA]);
		    iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_SEX_SHOP_POTENCIYA", g_iAllCvars[POTENCIYA_ED], g_iShopCvars[POTENCIYA]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \d[%d$]^n", id, "JBE_ROLEPLAY_SEX_SHOP_POTENCIYA", g_iAllCvars[POTENCIYA_ED], g_iShopCvars[POTENCIYA]);
	if(IsNotSetBit(g_iBitViagra, id))
	{
	    if(g_Money > g_iShopCvars[VIAGRA])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w2\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_SEX_SHOP_VIAGRA", g_iShopCvars[VIAGRA]);
		    iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_SEX_SHOP_VIAGRA", g_iShopCvars[VIAGRA]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_SEX_SHOP_VIAGRA", g_iShopCvars[VIAGRA]);
	if(g_iBlock[id] <= 0)
	{
	    if(g_Money > g_iShopCvars[BLOCK_1DAY])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w3\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_1DAY", g_iShopCvars[BLOCK_1DAY]);
		    iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_1DAY", g_iShopCvars[BLOCK_1DAY]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_1DAY", g_iShopCvars[BLOCK_1DAY]);
	if(g_iBlock[id] <= 0)
	{
	    if(g_Money > g_iShopCvars[BLOCK_2DAY])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w4\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_2DAY", g_iShopCvars[BLOCK_2DAY]);
		    iKeys |= (1<<3);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_2DAY", g_iShopCvars[BLOCK_2DAY]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_2DAY", g_iShopCvars[BLOCK_2DAY]);
	if(g_iBlock[id] <= 0)
	{
	    if(g_Money > g_iShopCvars[BLOCK_3DAY])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w5\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_3DAY", g_iShopCvars[BLOCK_3DAY]);
		    iKeys |= (1<<4);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_3DAY", g_iShopCvars[BLOCK_3DAY]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_3DAY", g_iShopCvars[BLOCK_3DAY]);
	if(g_iAntiVor[id] <= 0) 
	{
	    if(g_Money > g_iShopCvars[MONEY])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w6\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_SEX_SHOP_MONEY", g_iShopCvars[MONEY]);
		    iKeys |= (1<<5);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_SEX_SHOP_MONEY", g_iShopCvars[MONEY]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_SEX_SHOP_MONEY", g_iShopCvars[MONEY]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\w9\r] \wНазад");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\w0\r] \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Show_RolePlayShop");
}

public Handle_RolePlayShop(id, iKey)
{
    new g_Money = jbe_get_user_money(id)
	switch(iKey)
	{
		case 0:
        {
			if(g_Money > g_iShopCvars[POTENCIYA])
			{
			    jbe_set_user_money(id, g_Money - g_iShopCvars[POTENCIYA], 1);
				SetBit(g_iBitStoyak, id);
				g_iEnergy[id] += g_iAllCvars[POTENCIYA_ED];
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_SEX_SHOP_POTENCIYA_MSG");
			}	
		}
		case 1:
        {
			if(IsNotSetBit(g_iBitViagra, id) && g_Money > g_iShopCvars[VIAGRA])
			{
				jbe_set_user_money(id, g_Money - g_iShopCvars[VIAGRA], 1);
				SetBit(g_iBitViagra, id);
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_SEX_SHOP_VIAGRA_MSG");
			}
		}
		case 2:
        {
			if(g_iBlock[id] <= 0 && g_Money > g_iShopCvars[BLOCK_1DAY])
			{
				jbe_set_user_money(id, g_Money - g_iShopCvars[BLOCK_1DAY], 1);
				g_iBlock[id] = 1;
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_1DAY_MSG");
			}
		}
       case 3:
        {
			if(g_iBlock[id] <= 0 && g_Money > g_iShopCvars[BLOCK_2DAY])
			{
				jbe_set_user_money(id, g_Money - g_iShopCvars[BLOCK_2DAY], 1);
				g_iBlock[id] = 2;
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_2DAY_MSG");
			}	
		}
		case 4:
        {
			if(g_iBlock[id] <= 0 && g_Money > g_iShopCvars[BLOCK_3DAY])
			{
				jbe_set_user_money(id, g_Money - g_iShopCvars[BLOCK_3DAY], 1);
				g_iBlock[id] = 3;
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_SEX_SHOP_BLOCK_3DAY_MSG");
			}	
		}
		case 5:
        {
			if(g_iAntiVor[id] <= 0 && g_Money > g_iShopCvars[MONEY])
			{
				jbe_set_user_money(id, g_Money - g_iShopCvars[MONEY], 1);
				g_iAntiVor[id] = 3;
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_SEX_SHOP_MONEY_MSG");
			}	
		}
		case 8: return Show_RolePlayMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_RolePlayShop(id);
}

Show_RolePlayVipShop(id)
{
    new g_Money = jbe_get_user_money(id)
	new szMenu[512], iKeys = (1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_ROLEPLAY_AVTO_SEX_SHOP");
	if(IsNotSetBit(g_iBitBigStoyak, id))
	{
	    if(g_Money > g_iShopCvars[AVTO_POTENCIYA])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w1\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_POTENCIYA", g_iAllCvars[AVTO_POTENCIYA_ED], g_iShopCvars[AVTO_POTENCIYA]);
		    iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_POTENCIYA", g_iAllCvars[AVTO_POTENCIYA_ED], g_iShopCvars[AVTO_POTENCIYA]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_POTENCIYA", g_iAllCvars[AVTO_POTENCIYA_ED], g_iShopCvars[AVTO_POTENCIYA]);
	if(IsNotSetBit(g_iBitVirus, id))
	{
	    if(g_Money > g_iShopCvars[AVTO_VIRUS])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w2\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_VIRUS", g_iShopCvars[AVTO_VIRUS]);
		    iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_VIRUS", g_iShopCvars[AVTO_VIRUS]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_VIRUS", g_iShopCvars[AVTO_VIRUS]);
	if(g_iBlock[id] <= 0)
	{
	    if(g_Money > g_iShopCvars[AVTO_BLOCK_10DAY])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w3\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_BLOCK_10DAY", g_iShopCvars[AVTO_BLOCK_10DAY]);
		    iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_BLOCK_10DAY", g_iShopCvars[AVTO_BLOCK_10DAY]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_BLOCK_10DAY", g_iShopCvars[AVTO_BLOCK_10DAY]);
	if(IsNotSetBit(g_iBitVernosti, id))
	{
	    if(g_Money > g_iShopCvars[AVTO_POYAS])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w4\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_VERNOSTI", g_iShopCvars[AVTO_POYAS]);
		    iKeys |= (1<<3);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_VERNOSTI", g_iShopCvars[AVTO_POYAS]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_VERNOSTI", g_iShopCvars[AVTO_POYAS]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\w9\r] \wНазад^n");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w0\r] \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Show_RolePlayVipShop");
}

public Handle_RolePlayVipShop(id, iKey)
{
    new g_Money = jbe_get_user_money(id)
	switch(iKey)
	{
		case 0:
        {
            if(g_Money > g_iShopCvars[AVTO_POTENCIYA])
			{
			    jbe_set_user_money(id, g_Money - g_iShopCvars[AVTO_POTENCIYA], 1);
				SetBit(g_iBitBigStoyak, id);	
				g_iEnergy[id] += g_iAllCvars[AVTO_POTENCIYA_ED];
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_POTENCIYA_MSG");
			}
		}
		case 1:
        {
			if(IsNotSetBit(g_iBitVirus, id) && g_Money > g_iShopCvars[AVTO_VIRUS])
			{
				jbe_set_user_money(id, g_Money - g_iShopCvars[AVTO_VIRUS], 1);
				SetBit(g_iBitVirus, id);
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_VIRUS_MSG");
			}	
		}
		case 2:
        {
			if(g_iBlock[id] <= 0 && g_Money > g_iShopCvars[AVTO_BLOCK_10DAY])
			{
				jbe_set_user_money(id, g_Money - g_iShopCvars[AVTO_BLOCK_10DAY], 1);
				g_iBlock[id] = 10;
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_BLOCK_10DAY_MSG");
			}	
		}
		case 3:
        {
			if(IsNotSetBit(g_iBitVernosti, id) && g_Money > g_iShopCvars[AVTO_POYAS])
			{
				jbe_set_user_money(id, g_Money - g_iShopCvars[AVTO_POYAS], 1);
				SetBit(g_iBitVernosti, id);
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_AVTO_SEX_SHOP_VERNOSTI_MSG");
			}
		}
		case 8: return Show_RolePlayMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_RolePlayVipShop(id);
}

Show_RolePlayAptecka(id)
{
    new g_Money = jbe_get_user_money(id);
	new szMenu[512], iKeys = (1<<8|1<<9), iLen = formatex(szMenu, charsmax(szMenu), "\y%L^n^n", id, "JBE_MENU_ROLEPLAY_APTEKA");
	if(IsSetBit(g_iBitSlomalRyki, id))
	{
	    if(g_Money > g_iShopCvars[GIPS])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w1\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_APTEKA_GIPS", g_iShopCvars[GIPS]);
		    iKeys |= (1<<0);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_APTEKA_GIPS", g_iShopCvars[GIPS]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_APTEKA_GIPS", g_iShopCvars[GIPS]);
	if(IsSetBit(g_iBitParalich, id))
	{
	    if(g_Money > g_iShopCvars[PARALICH])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w2\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_APTEKA_PARALICH", g_iShopCvars[PARALICH]);
		    iKeys |= (1<<1);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_APTEKA_PARALICH", g_iShopCvars[PARALICH]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_APTEKA_PARALICH", g_iShopCvars[PARALICH]);
	if(IsSetBit(g_iBitZrenie, id))
	{
	    if(g_Money > g_iShopCvars[EAR])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w3\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_APTEKA_EAR", g_iShopCvars[EAR]);
		    iKeys |= (1<<2);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_APTEKA_EAR", g_iShopCvars[EAR]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_APTEKA_EAR", g_iShopCvars[EAR]);
	if(IsSetBit(g_iBitSpid, id))
	{
	    if(g_Money > g_iShopCvars[SPID])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w4\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_APTEKA_SPID", g_iShopCvars[SPID]);
		    iKeys |= (1<<3);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_APTEKA_SPID", g_iShopCvars[SPID]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_APTEKA_SPID", g_iShopCvars[SPID]);
	if(IsSetBit(g_iBitSlomalNogi, id))
	{
	    if(g_Money > g_iShopCvars[FOOT])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w5\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_APTEKA_FOOT", g_iShopCvars[FOOT]);
		    iKeys |= (1<<4);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_APTEKA_FOOT", g_iShopCvars[FOOT]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_APTEKA_FOOT", g_iShopCvars[FOOT]);
	if(IsSetBit(g_iBitGolova, id))
	{
	    if(g_Money > g_iShopCvars[HEAD])
	    {
		    iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w6\r] \w%L \y[%d\d$\y]^n", id, "JBE_ROLEPLAY_APTEKA_HEAD", g_iShopCvars[HEAD]);
		    iKeys |= (1<<5);
		}
		else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L \r[%d\d$\r]^n", id, "JBE_ROLEPLAY_APTEKA_HEAD", g_iShopCvars[HEAD]);
	}
	else iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \d%L [%d$]^n", id, "JBE_ROLEPLAY_APTEKA_HEAD", g_iShopCvars[HEAD]);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n\r[\w9\r] \wНазад^n");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[\w0\r] \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Show_RolePlayAptecka");
}

public Handle_RolePlayAptecka(id, iKey)
{
    new g_Money = jbe_get_user_money(id);
	new name1[33];
	get_user_name(id, name1, 32);
	switch(iKey)
	{
		case 0:
         {
			if(IsSetBit(g_iBitSlomalRyki, id) && g_Money > g_iShopCvars[GIPS])
			{
			    jbe_set_user_money(id, g_Money - g_iShopCvars[GIPS], 1);
			    fm_give_item(id,"weapon_knife");
				ClearBit(g_iBitSlomalRyki, id);
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_APTEKA_GIPS_MSG", name1);
			}
		}
		case 1:
        {
		    if(IsSetBit(g_iBitParalich, id) && g_Money > g_iShopCvars[PARALICH])
			{
			    jbe_set_user_money(id, g_Money - g_iShopCvars[PARALICH], 1);
			    g_iParalize[id] = false;
				set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
				ClearBit(g_iBitParalich, id);
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_APTEKA_PARALICH_MSG", name1);
			}	
		}
		case 2:
        {
        	if(IsSetBit(g_iBitZrenie, id) && g_Money > g_iShopCvars[EAR])
			{
				jbe_set_user_money(id, g_Money - g_iShopCvars[EAR], 1);
				UTIL_ScreenFade(id, 512, 512, 0, 0, 0, 0, 255, 1);
				ClearBit(g_iBitZrenie, id);
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_APTEKA_EAR_MSG", name1);
			}	
		}
		case 3:
        {
			if(IsSetBit(g_iBitSpid, id) && g_Money > g_iShopCvars[SPID])
			{
			    jbe_set_user_money(id, g_Money - g_iShopCvars[SPID], 1);
			    remove_task(id+TASK_SPID);
				set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
				UTIL_ScreenFade(id, 512, 512, 0, 0, 0, 0, 255, 1);
				ClearBit(g_iBitSpid, id);
				g_iScreenFades[id] = 0;
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_APTEKA_SPID_MSG", name1);
				ChatColor(id,"%L", id, "JBE_ROLEPLAY_APTEKA_SPID_ID_MSG");
			}
		}
		case 4:
        {
		    if(IsSetBit(g_iBitSlomalNogi, id) && g_Money > g_iShopCvars[FOOT])
			{
			    jbe_set_user_money(id, g_Money - g_iShopCvars[FOOT], 1);
			    set_user_maxspeed(id, 240.0);
				ClearBit(g_iBitSlomalNogi, id);
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_APTEKA_FOOT_MSG", name1);
			}	
		}
		case 5:
        {
			if(IsSetBit(g_iBitGolova, id) && g_Money > g_iShopCvars[HEAD])
			{
			    jbe_set_user_money(id, g_Money - g_iShopCvars[HEAD], 1);
			    remove_task(id+TASK_GOLOVA);
			    ClearBit(g_iBitGolova, id);
				ChatColor(0,"%L", id, "JBE_ROLEPLAY_APTEKA_HEAD_MSG", name1);
			}	
		}
		case 8: return Show_RolePlayMenu(id);
		case 9: return PLUGIN_HANDLED;
	}
	return Show_RolePlayAptecka(id);
}


public client_putinserver(id)
{
	new iFlags = get_user_flags(id);
	if(iFlags & ADMIN_LEVEL_G) SetBit(g_iBitUserHook, id);
	if(iFlags & ADMIN_RCON) SetBit(g_iBitUserCreat, id);
	if(iFlags & ADMIN_CVAR) SetBit(g_iBitUserVampir, id);
	if(iFlags & ADMIN_RESERVATION) SetBit(g_iBitUserStSmotr, id);
	if(iFlags & ADMIN_LEVEL_E) SetBit(g_iBitUserBoss, id);
    if(iFlags & ADMIN_LEVEL_H) SetBit(g_iBitUserVip, id);
	if(iFlags & ADMIN_BAN)
	{
		SetBit(g_iBitUserAdmin, id);
		if(iFlags & ADMIN_VOTE) SetBit(g_iBitUserSuperAdmin, id);
	}
}

public startround(id)
{
    remove_task(id+TASK_SPID);
	remove_task(id+TASK_GOLOVA);
	remove_task(id+TASK_ADDICTION);
    if(jbe_get_day_mode() == 1 && jbe_get_user_team(id) == 1)
    {
		ClearBit(g_iBitStoyak, id); ClearBit(g_iBitBigStoyak, id); ClearBit(g_iBitViagra, id); ClearBit(g_iBitVirus, id); ClearBit(g_iBitVernosti, id); ClearBit(g_iBitUserIznosilovan, id);
		ClearBit(g_iBitSlomalRyki, id); ClearBit(g_iBitSlomalNogi, id); ClearBit(g_iBitSpid, id); ClearBit(g_iBitParalich, id); ClearBit(g_iBitGolova, id); ClearBit(g_iBitZrenie, id);
		g_iBlock[id]--; g_iAntiVor[id]--; g_iParalize[id] = false; g_iEnergy[id] = random_num(g_iAllCvars[PLAYER_MIN_ENERGY], g_iAllCvars[PLAYER_MAX_ENERGY]); g_iScreenFades[id] = 0;
	    UTIL_ScreenFade(id, 512, 512, 0, 0, 0, 0, 255, 1);
		if(IsSetBit(g_iBitUserCreat, id)) g_iEnergy[id] = g_iAllCvars[CREAT_ENERGY];
		else if(IsSetBit(g_iBitUserStSmotr, id)) g_iEnergy[id] = g_iAllCvars[ST_SMOTRITEL_ENERGY];
		else if(IsSetBit(g_iBitUserBoss, id)) g_iEnergy[id] = g_iAllCvars[BOSS_ENERGY];
		else if(IsSetBit(g_iBitUserSuperAdmin, id)) g_iEnergy[id] = g_iAllCvars[SUPER_ADMIN_ENERGY];
		else if(IsSetBit(g_iBitUserAdmin, id)) g_iEnergy[id] = g_iAllCvars[ADMIN_ENERGY];
		else if(IsSetBit(g_iBitUserVampir, id)) g_iEnergy[id] = g_iAllCvars[VAMPIR_ENERGY];
		else if(IsSetBit(g_iBitUserHook, id)) g_iEnergy[id] = g_iAllCvars[HOOK_ENERGY];
		else if(IsSetBit(g_iBitUserVip, id)) g_iEnergy[id] = g_iAllCvars[VIP_ENERGY];
		g_iAddiction[id]++;
		if(g_iAddiction[id] == g_iAllCvars[ADDICTION] && AlivePlayerTeam(1) >= 2)
		{
			set_hudmessage(232, 19, 19, 0.3, 0.85, 0, 6.0, 10.0);
			show_hudmessage(id, "%L", id, "JBE_ROLEPLAY_ADDICTION");
			if(!task_exists(id + TASK_ADDICTION)) set_task(5.0, "addiction", id+TASK_ADDICTION, _, _, "a", 200);
			set_user_maxspeed(id, 500.0);
			g_iAddiction[id] = 0;
		}
		else if(g_iAddiction[id] >= g_iAllCvars[ADDICTION] - 1 && AlivePlayerTeam(1) >= 2)
		{
			set_hudmessage(232, 19, 19, 0.3, 0.85, 0, 6.0, 10.0);
			show_hudmessage(id, "%L", id, "JBE_ROLEPLAY_WARNING_1DAY", g_iAllCvars[ADDICTION] - 1);
		}
    }
}

public Ham_PlayerKilled_Post(id)
{
	g_iParalize[id] = false;
	remove_task(id+TASK_SPID);
	remove_task(id+TASK_GOLOVA);
	remove_task(id+TASK_ADDICTION);
	g_iScreenFades[id] = 0;
	jbe_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	UTIL_ScreenFade(id, 512, 512, 0, 0, 0, 0, 255, 1);
	ClearBit(g_iBitStoyak, id); ClearBit(g_iBitViagra, id); ClearBit(g_iBitVirus, id); ClearBit(g_iBitVernosti, id); ClearBit(g_iBitBigStoyak, id);
	ClearBit(g_iBitSlomalRyki, id); ClearBit(g_iBitSlomalNogi, id); ClearBit(g_iBitSpid, id); ClearBit(g_iBitParalich, id); ClearBit(g_iBitGolova, id); ClearBit(g_iBitZrenie, id);
}

public client_disconnect(id)
{
	ClearBit(g_iBitStoyak, id); ClearBit(g_iBitViagra, id); ClearBit(g_iBitVirus, id); ClearBit(g_iBitVernosti, id); ClearBit(g_iBitBigStoyak, id);
	ClearBit(g_iBitSlomalRyki, id); ClearBit(g_iBitSlomalNogi, id); ClearBit(g_iBitSpid, id); ClearBit(g_iBitParalich, id); ClearBit(g_iBitGolova, id); ClearBit(g_iBitZrenie, id);
	g_iBlock[id] = 0; g_iParalize[id] = false; g_iEnergy[id] = 0; g_iAntiVor[id] = 0; g_iScreenFades[id] = 0;
	ClearBit(g_iBitUserAdmin, id); ClearBit(g_iBitUserBoss, id); ClearBit(g_iBitUserCreat, id); ClearBit(g_iBitUserVampir, id); ClearBit(g_iBitUserVip, id); 
	ClearBit(g_iBitUserSuperAdmin, id); ClearBit(g_iBitUserHook, id); ClearBit(g_iBitUserStSmotr, id);
	ClearBit(g_iBitUserIznosilovan, id);
	UTIL_ScreenFade(id, 512, 512, 0, 0, 0, 0, 255, 1);
}	
public plugin_natives ()	register_native("jbe_roleplay", "jbe_roleplay", 1)
public jbe_roleplay(id) Show_RolePlayMenu(id)

stock AlivePlayerTeam(const iTeam = 1)
{
    new iCount = 0;  
    for(new i = 1; i <= 32; i++) if(is_user_alive(i) && jbe_get_user_team(i) == iTeam) iCount++;                 
    return iCount;
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32], msg[191]; vformat(msg, 190, input, 3)
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!t", "^3")
	if(id)players[0] = id; else get_players(players, count, "ch")
{
	for(new i = 0; i < count; i++)
	{
		if(is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
			write_byte(players[i])
			write_string(msg)
			message_end()
		}
	}
}
}

stock fm_give_item(id, const szItem[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szItem));
	if(!pev_valid(iEntity)) return 0;
	new Float:vecOrigin[3];
	pev(id, pev_origin, vecOrigin);
	set_pev(iEntity, pev_origin, vecOrigin);
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, iEntity);
	new iSolid = pev(iEntity, pev_solid);
	dllfunc(DLLFunc_Touch, iEntity, id);
	if(pev(iEntity, pev_solid) == iSolid)
	{
		engfunc(EngFunc_RemoveEntity, iEntity);
		return -1;
	}
	return iEntity;
}

stock red_ScreenFade(client)
{               
	if(is_user_alive(client))
	{
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0, 0, 0}, client);
		write_short(10 << 12);
		write_short(10 << 16);
		write_short(1 << 1);
		write_byte(255);
		write_byte(0);
		write_byte(0);
		write_byte(255);
		message_end();
	}
	return PLUGIN_HANDLED;	
}


stock UTIL_ScreenFade(id, iDuration, iHoldTime, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	message_begin(iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MsgId_ScreenFade, _, id);
	write_short(iDuration);
	write_short(iHoldTime);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}