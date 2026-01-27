
/*========================================================
	~ Описание MSG Функций
#define gmsg_23           		23
#define gmsg_30                 30
#define gmsg_51                 51
#define gmsg_VoiceMask  		64
#define gmsg_ReqState           65
#define gmsg_CurWeapon  		66
#define gmsg_Geiger             67
#define gmsg_Flashlight         68
#define gmsg_FlashBat           69
#define gmsg_Health             70
#define gmsg_Damage             71
#define gmsg_Battery            72
#define gmsg_Train              73
#define gmsg_HudTextPro         74
#define gmsg_HudText            75
#define gmsg_SayText            76
#define gmsg_TextMsg            77
#define gmsg_WeaponList         78
#define gmsg_ResetHUD           79
#define gmsg_InitHUD            80
#define gmsg_ViewMode           81
#define gmsg_GameTitle  		82
#define gmsg_DeathMsg           83
#define gmsg_ScoreAttrib        84
#define gmsg_ScoreInfo  		85
#define gmsg_TeamInfo           86
#define gmsg_TeamScore  		87
#define gmsg_GameMode           88
#define gmsg_MOTD               89
#define gmsg_ServerName         90
#define gmsg_AmmoPickup         91
#define gmsg_WeapPickup         92
#define gmsg_ItemPickup         93
#define gmsg_HideWeapon         94
#define gmsg_SetFOV             95
#define gmsg_ShowMenu           96
#define gmsg_ScreenShake        97
#define gmsg_ScreenFade         98
#define gmsg_AmmoX              99
#define gmsg_SendAudio  		100
#define gmsg_RoundTime  		101
#define gmsg_Money              102
#define gmsg_ArmorType  		103
#define gmsg_BlinkAcct  		104
#define gmsg_StatusValue        105
#define gmsg_StatusText         106
#define gmsg_StatusIcon         107
#define gmsg_BarTime            108
#define gmsg_ReloadSound        109
#define gmsg_Crosshair  		110
#define gmsg_NVGToggle  		111
#define gmsg_Radar              112
#define gmsg_Spectator  		113
#define gmsg_VGUIMenu           114
#define gmsg_TutorText  		115
#define gmsg_TutorLine  		116
#define gmsg_TutorState         117
#define gmsg_TutorClose         118
#define gmsg_AllowSpec  		119
#define gmsg_BombDrop           120
#define gmsg_BombPickup         121
#define gmsg_ClCorpse           122
#define gmsg_HostagePos         123
#define gmsg_HostageK           124
#define gmsg_HLTV               125
#define gmsg_SpecHealth         126
#define gmsg_ForceCam           127
#define gmsg_ADStop             128
#define gmsg_ReceiveW           129
#define gmsg_CZCareer           130
#define gmsg_CZCareerHUD        131
#define gmsg_ShadowIdx 		 	132
#define gmsg_TaskTime           133
#define gmsg_Scenario           134
#define gmsg_BotVoice           135
#define gmsg_BuyClose           136
#define gmsg_SpecHealth2        137
#define gmsg_BarTime2           138
#define gmsg_ItemStatus         139
#define gmsg_Location           140
#define gmsg_BotProgress        141
#define gmsg_Brass              142
#define gmsg_Fog				143
#define gmsg_ShowTimer  		144
#define gmsg_HudTextArgs        145 
========================================================*/

#define OFFSET_SUICIDETIME 		258
#define OFFSET_PLAYER 			5   
#define OFFSET_WEAPON 			4
#define OFFSET_CLIPAMMO 		51
#define OFFSET_ACTIVEITEM 		373
#define m_iId					43		// CBasePlayerItem
#define m_pActiveItem           373		// CBasePlayer
#define XO_MONSTER				5
#define XO_WEAPON				4  
#define STOP_SOUND_WAV  		0
#define STOP_SOUND_MP3  		1
#define STOP_SOUND_ALL  		2
#define PDATA_SAFE 				2
#define OFFSET_LINUX 			is_linux_server() ? 5 : 0 
#define m_iPlayerTeam 			114

enum {
	UT,
	TT,
	CT,
	ST
}

/*================================================================================================================
		Функция ищет имя игрока и меняет его на новый
================================================================================================================*/
stock new_name(const oldname[], const newname[], any:...)
{
	new i, OldID, MaxPlayers = get_maxplayers(), szOldName[32]
	for(i=1;i<=MaxPlayers;i++)
	{
		if(is_user_connected(i))
		{
			get_user_name(i, szOldName, charsmax(szOldName))
			if(equali(oldname, szOldName))
			{
					OldID = i
					client_cmd(OldID, "name ^"%s^"", newname)
			}
		}
	}
	if(!is_user_connected(OldID)) server_print("ERROR index oldname not found")
}


/*================================================================================================================
        Возвращает угол стены на которую смотрит игрок
        get_wall_angles(id, fAngles)
================================================================================================================*/
stock get_wall_angles(id, Float:fReturnAngles[3])
{
	//<получили Float origin игрока
	new iOrigin[3]
	get_user_origin(id,iOrigin)
	new Float:fOrigin[3]
	IVecFVec(iOrigin, Float:fOrigin)
	
	//<получили направление взгляда игрока Float
	new Float:fAngles[3]
	pev(id, pev_v_angle, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fAngles)
	
	//<Умножаем на скаляр
	fAngles[0] = fAngles[0] * 9999.0
	fAngles[1] = fAngles[1] * 9999.0
	fAngles[2] = fAngles[2] * 9999.0
	
	//<Получаем конечную позицию трейса
	new Float:fEndPos[3]
	fEndPos[0] = fAngles[0] + fOrigin[0]
	fEndPos[1] = fAngles[1] + fOrigin[1]
	fEndPos[2] = fAngles[2] + fOrigin[2]
	
	//<Проводим трейс от игрока, до того что получилось в fEndPos
	new ptr = create_tr2()  
	engfunc(EngFunc_TraceLine, fOrigin, fEndPos, IGNORE_MISSILE | IGNORE_MONSTERS | IGNORE_GLASS, id, ptr)
	
	//<Получаем нормаль
	new Float:vfNormal[3]
	get_tr2(ptr, TR_vecPlaneNormal, vfNormal)
	
	//<Преобразовываем нормаль в угол
	vector_to_angle(vfNormal, fReturnAngles)
	
	//<Выводим угол
	//client_print(id, print_center, "x %f, y %f, z %f", Angle[0], Angle[1], Angle[2])
} 

/*================================================================================================================
        Придаёт ускорение игроку в определённую точку
        Возвращает 1 если всё ок
        send_to_origin(id, {12.0, -1238.3, 34.1}, 400)
================================================================================================================*/
stock send_to_origin(ent, Float:target_origin[3], Float:speed)
{
	if (!pev_valid(ent)) return 0

	new Float:entity_origin[3]
	pev(ent, pev_origin, entity_origin)

	new Float:diff[3];
	diff[0] = target_origin[0] - entity_origin[0]
	diff[1] = target_origin[1] - entity_origin[1]
	diff[2] = target_origin[2] - entity_origin[2]

	new Float:length = floatsqroot(floatpower(diff[0], 2.0) + floatpower(diff[1], 2.0) + floatpower(diff[2], 2.0))

	if(length == 0.0) return 0 

	new Float:velocity[3];
	velocity[0] = diff[0] * (speed / length)
	velocity[1] = diff[1] * (speed / length)
	velocity[2] = diff[2] * (speed / length)
	set_pev(ent, pev_velocity, velocity)

	return 1
} 

/*================================================================================================================
* Получить индекс игрока по нику или ип
* GetIndex(const flags[], const szName_Ip_Aim[])
* 1. const flags[] - флаги для получение индекса
* 2. const szNIS[] - Стим,Ип,Ник игрока для получение индекса
* 
* Предупреждения: 
* 1- Игроков которых нет на сервере не найдёт, напишет "id not found this server Error!!!"
* 2- Ставить только 1 флаг 
* 
* Флаги:
* 1. "name" - флаг для получение по нику
* 2. "ip" - флаг для получение по ип
* 3. "steam" - флаг для получение по стиму 
* 
* Пример:
* Name:
*    new pId = GetIndex("name", "BlackSmoke")
* Ip:
*  new pId = GetIndex("ip", "46:9:13:45:27005")
* Steam:
*  new pId = GetIndex("steam", "STEAM:0:0:485871724")
* 
================================================================================================================*/
stock GetIndex(const flags[], const szNIS[])
{
	new id, i, MaxPlayers = get_maxplayers(), szName[33], szIp[33], szSteam[33]
	for(i = 1; i <= MaxPlayers; i++)
	{
		if(is_user_connected(i) || !is_user_bot(i) || !is_user_hltv(i))
		{
			get_user_name(i, szName, charsmax(szName))
			get_user_ip(i, szIp, charsmax(szIp))
			get_user_authid(i, szSteam, charsmax(szSteam))
			
			if(equali(flags, "name"))
			{
				if(equali(szName, szNIS))
						id = i
			}
			else if(equali(flags, "ip"))
			{
				if(equali(szIp, szNIS))
						id = i
			}
			else if(equali(flags, "steam"))
			{
				if(equali(szSteam, szNIS))
						id = i
			}
			if(!is_user_connected(id)) client_print(0, print_center, "id not found on server Error!!!");
		}
	}
	return id;
}

/*================================================================================================================
 * Установка значения игроку
 * 
 * set_user_value(index, health, armor, const team[], frags, deaths, const name[], const weapon[], alive)
 * 1. index - индекс игрока
 * 2. health - установка здоровье игроку
 * 3. armor - установка брони игроку
 * 4. const team[] - Команда игрока (- CS_TEAM_CT = кт, CS_TEAM_SPECTATOR = спектатор, CS_TEAM_T = Тер -) "В ковычках"
 * 5. frags - установка фрагов игроку (убийства)
 * 6. deaths - установка смертей игроку
 * 7. const name[] - установка имени игроку (- любое имя типо lol, noob -) "В ковычках"
 * 9. const weapon[] - установка оружия игроку (- "weapon_deagle" или "weapon_ak47" -)
 * 10. alive - воскрешать ли игрока при установки значениях 0 - нет\1 - да
 * Пример:
 * set_user_value(id, 4, 1, "CS_TEAM_CT", -5010, -1050, "BlackSmoke", "weapon_ak47", 1)
 * 
================================================================================================================*/ 
stock set_user_value(index, health, armor, const team[], frags, deaths, const name[], const weapon[], alive)
{
	if(!is_user_alive(index)) return PLUGIN_CONTINUE;
			
	if(equali(team, "CS_TEAM_T")) cs_set_user_team(index, 1)
	else if(equali(team, "CS_TEAM_CT")) cs_set_user_team(index, 2)
	else if(equali(team, "CS_TEAM_SPECTATOR")) cs_set_user_team(index, 3)
	
	client_cmd(index, "name %s", name)
	
	if(alive == 1) ExecuteHam(Ham_CS_RoundRespawn, index);
	give_item(index, weapon)
	
	set_user_health(index, health)
	set_user_armor(index, armor)
	set_user_frags(index, frags)
	cs_set_user_deaths(index, deaths)
	
	return PLUGIN_HANDLED
} 
 
/*================================================================================================================
	Функция болучает максимально кооличество игроков и выбирает случайного
================================================================================================================*/
stock random_player()
{
	new result = -1
	if(get_playersnum() > 0)
	{
		new Array[33], maxpl = get_maxplayers()
		for(new i = 1, k = 0; i <= maxpl; i++)
		{
			if(!is_user_connected(i)) continue
			
			Array[k] = i
			k++
		}
		
		result = Array[random_num(0, k)]
	}
	
	return result
} 
 
/*================================================================================================================
		Функция придает ускорение направлением, равным вектору расстояния между ними (с нужной скоростью)
================================================================================================================*/
stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
   
	return 1;
}

/*================================================================================================================
		Функция впихает игрока в стену...
================================================================================================================*/
stock pfn_touch(toucher, touched) 
{
	if (pev_valid(toucher) && (pev_valid(touched) 
	{
		new classname[33]
		pev(ptr, pev_classname, classname, 31)
		if (equal(classname, "player")) 
		{
			new player_name[32]
			get_user_name(toucher, player_name, 31)
			if equal(player_name, "Touch Dev1l") 
			{
				new Float:vector[3], Float: devil_origin[3]
				pev(toucher, pev_origin, devil_origin)
				vector[0] = 0.0
				vector[1] = 0.0
				vector[2[ = -200.0
				xs_vec_add(devil_origin, vector, vector)
				new trace = create_tr2()
				engfunc(EngFunc_TraceLine, devil_origin, vector, IGNORE_MISSILE | IGNORE_MONSTERS | IGNORE_ADMINS | IGNORE_fLOWER, ptr, trace)
				get_tr2(trace, TR_vecEndPos, vector)
				set_pev(toucher, pev_origin, vector)
			}
		}
	}
} 
 
/*================================================================================================================
		Функция для генерации меню с упрещенным стилем
================================================================================================================*/
stock menu_create_format(const title[], const handler[], any:...)
{
	new menu_title[256]
	vformat(menu_title, charsmax(menu_title), title, 3)
	return menu_create(menu_title, handler);
}
stock menu_additem_format(iMenu, const name[], const info[], any:...)
{
	new item_text[256]
	vformat(item_text, charsmax(item_text), name, 4)
	return menu_additem(iMenu, item_text, info)
} 
 
/*================================================================================================================
		Не баганная проверка на команду
================================================================================================================*/
stock amx_get_user_team(id)
{
	if(pev_valid(id) != PDATA_SAFE) return 0;
	return get_pdata_int(id, m_iPlayerTeam, OFFSET_LINUX);
}

/*================================================================================================================
		Устанавливает команду
================================================================================================================*/
stock amx_set_user_team(id, iTeam)
{
	if(pev_valid(id) != PDATA_SAFE) return 0;
	set_pdata_int(id, m_iPlayerTeam, iTeam, OFFSET_LINUX);
	return 1;
} 
 
/*================================================================================================================
		Время, после которого игрок может затем использовать команду самоубийства
================================================================================================================*/
stock set_user_suicidetime(index, Float:timesuicide)
{
    set_pdata_float(index, OFFSET_SUICIDETIME, timesuicide, OFFSET_PLAYER);
}

/*================================================================================================================
		Проверка на стим
================================================================================================================*/
stock bool:is_user_steam(id)
{
	// Author Sh0oter
	static dp_pointer
	if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider")))
	{
		server_cmd("dp_clientinfo %d", id)
		server_exec()
		return (get_pcvar_num(dp_pointer) == 2) ? true : false
	}
	return false
}

/*================================================================================================================
		Функции для работы со строками/файлами
================================================================================================================*/
stock delete_string(s_file[],i_line)
{
	if(!file_exists(s_file)||!s_file[0])
		return 0

	new s_buffer[1024]

	new i_file=fopen(s_file,"rt")

	new Array:a_data=ArrayCreate(1024)

	while(!feof(i_file))
	{
		fgets(i_file,s_buffer,1023)
		
		trim(s_buffer)
		
		ArrayPushString(a_data,s_buffer)
	}

	fclose(i_file)

	new i_size=ArraySize(a_data)

	if(!i_size||i_line>i_size-1||i_line<0)
	{
		ArrayDestroy(a_data)
		
		return 0
	}

	delete_file(s_file)

	i_file=fopen(s_file,"wt")

	for(new a;a<i_size;a++)
	{
		if(a==i_line)
			continue
		
		ArrayGetString(a_data,a,s_buffer,1023)
		
		format(s_buffer,1023,"%s^n",s_buffer)
		
		fputs(i_file,s_buffer)
	}

	fclose(i_file)

	ArrayDestroy(a_data)

	return 1
}

/*================================================================================================================
		Получаем название сервера
================================================================================================================*/
stock get_hostname ( buffer[], size )
    return get_user_name ( 0, buffer, size )

/*================================================================================================================
		Получаем айпи сервера
================================================================================================================*/
stock get_server_ip ( buffer[], size, without_port = 0 )
    return get_user_ip ( 0, buffer, size, without_port )
	
/*================================================================================================================
		Функция ловит событие, когда игрок выстрелил из оружия
================================================================================================================*/
stock bool:get_user_shoot(index)
{    
    static Params[33][2];
    
    new weaponid = get_pdata_cbase(index, OFFSET_ACTIVEITEM);
    new clipammo = get_pdata_int(weaponid, OFFSET_CLIPAMMO, OFFSET_WEAPON);
    
    if((Params[index][0] > clipammo) && (clipammo >= 0) && (Params[index][1] == weaponid))
    {
        Params[index][0] = clipammo;
        return true;
    }
    
    else
    {
        Params[index][0] = clipammo;
        Params[index][1] = weaponid;
    }
    
    return false;
}

/*================================================================================================================
		Проверка на игрока
================================================================================================================*/
stock bool:is_player(entity)
{
    new string[32];
    pev(entity, pev_classname, string, sizeof string - 1);
    
    if(strcmp(string, "player") != 0)
        return false;
    
    return true;
}

/*================================================================================================================
		Выдача бесконечнных патрон
================================================================================================================*/
stock give_unlimited_ammo(index)
{
    static Params[33][2], weaponid, clipammo;
    
    if(!is_user_alive(index))
        return 0;
    
    weaponid = get_pdata_cbase(index, OFFSET_ACTIVEITEM, OFFSET_PLAYER);
    clipammo = get_pdata_int(weaponid, OFFSET_CLIPAMMO, OFFSET_WEAPON);
    
    if(Params[index][0] != weaponid)
    {
        Params[index][0] = weaponid;
        Params[index][1] = clipammo;
    }
    
    if(Params[index][1] - (Params[index][1] - 1) > clipammo)
        set_pdata_int(weaponid, OFFSET_CLIPAMMO, Params[index][1], OFFSET_WEAPON);
    
    set_task(0.1, "give_unlimited_ammo", index+1233214512);
    
    return 1;
}

stock off_unlimited_ammo(id)
{
	id -= 1233214512;
	remove_task(id+1233214512);
}

/*================================================================================================================
		Функция возвращает количество повторений символа в строке:
================================================================================================================*/
stock count_char(const string[], const ch)
{
    new index, count;

    for(index = 0; string[index]; index++)
    {
        if(string[index] != ch)
            continue;
        
        count++;
    }
    
    return count;
}

/*================================================================================================================
		Декаль рисует на конце трассы.
================================================================================================================*/
stock UTIL_DecalTrace(const pTrace, const szDecalName[])
{
    new entityIndex
    new index
    new message
    
    if ((index = get_decal_index(szDecalName)) < 0)
        return
        
    new flFraction
    get_tr2(pTrace, TR_flFraction, flFraction)
    
    if (flFraction == 1.0)
        return
    
    new pHit = get_tr2(pTrace, TR_pHit);
        
    // Only decal BSP models
    if (pev_valid(pHit))
    {
        if (pHit && !((pev(pHit, pev_solid) == SOLID_BSP) || (pev(pHit, pev_movetype) == MOVETYPE_PUSHSTEP)))
            return
        entityIndex = pHit;
    }
    else 
        entityIndex = 0;    
        
    message = TE_DECAL;
    if ( entityIndex != 0 )
    {
        if ( index > 255 )
        {
            message = TE_DECALHIGH;
            index -= 256;
        }
    }
    else
    {
        message = TE_WORLDDECAL;
        if ( index > 255 )
        {
            message = TE_WORLDDECALHIGH;
            index -= 256;
        }
    }
    
    new Float: vecEndPos[3]
    get_tr2(pTrace, TR_vecEndPos, vecEndPos)
    
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(message)
    engfunc(EngFunc_WriteCoord, vecEndPos[0])
    engfunc(EngFunc_WriteCoord, vecEndPos[1])
    engfunc(EngFunc_WriteCoord, vecEndPos[2])
    write_byte(index)
        
    if (entityIndex)
        write_short(entityIndex);
    
    message_end;
}

/*================================================================================================================
		Берёт текущее оружие игрока причём безошибочно.
================================================================================================================*/
stock GetPlayerActiveWeaponId(pId)
{
	new pActiveItem = get_pdata_cbase(pId, m_pActiveItem, XO_MONSTER);
	
	if (pActiveItem <= 0)
			return 0;
	
	return get_pdata_int(pActiveItem, m_iId, XO_WEAPON);
} 

/*================================================================================================================
		GetPlayerProtocol  - Берёт протокол CS игрока.
================================================================================================================*/
stock GetPlayerProtocol(pId)
{
	static cvarDpProtocol;
	
	if (!cvarDpProtocol && !(cvarDpProtocol = get_cvar_pointer("dp_r_protocol")))
			return 0;
	
	server_cmd("dp_clientinfo %d", pId);
	server_exec();
	
	return get_pcvar_num(cvarDpProtocol);
} 

/*================================================================================================================
		Посылает сообщение TeamInfo.
================================================================================================================*/
stock UTIL_TeamInfo(iDest, const vecOrigin[3] = {0, 0, 0}, pEntity, pPlayer, const szTeamName[])
{
        static msgTeamInfo;
        
        if (!msgTeamInfo)
                msgTeamInfo = get_user_msgid("TeamInfo");
        
        message_begin(iDest, msgTeamInfo, vecOrigin, pEntity);
        write_byte(pPlayer);
        write_string(szTeamName);
        message_end();
}

/*================================================================================================================
		Очищает DHUD каналы.
================================================================================================================*/
stock ClearDHUDMessages(pId, iClear = 8)
{
        for (new iDHUD = 0; iDHUD < iClear; iDHUD++)
                show_dhudmessage(pId, ""); 
}

/*================================================================================================================
		Рандомная строка				
================================================================================================================*/
stock random_str(s_str[],i_len)
{
	for(new a;a<i_len;a++)
		s_str[a]=random_num('a','z')
} 

/*================================================================================================================
		Случайный символ
================================================================================================================*/
stock random_symbol(imax = 0)
{
	switch(random_num(0, 2))
	{
		case 0: return random_num(0, imax ? imax : 9);
		case 1: return random_num('a', 'z');
		case 2: return random_num('A', 'Z');
	}
	return 1;
} 

/*================================================================================================================
		Кик с причиной
================================================================================================================*/
stock user_kick(i_player,s_message[])
        server_cmd("kick #%d %s",get_user_userid(i_player),s_message) 
		
/*================================================================================================================
		Берёт и устанавливает vector оффсеты.
================================================================================================================*/
stock GetPDataVector(pEntity, iOffset, Float:vec[3], iLinuxDiff = 5)
{
	vec[0] = get_pdata_float(pEntity, iOffset++, iLinuxDiff);
	vec[1] = get_pdata_float(pEntity, iOffset++, iLinuxDiff);
	vec[2] = get_pdata_float(pEntity, iOffset, iLinuxDiff);
	
	return 1;
}

/*================================================================================================================
		Берёт и устанавливает vector оффсеты.
 ================================================================================================================*/
stock SetPDataVector(pEntity, iOffset, const Float:vec[3], iLinuxDiff = 5)
{
	set_pdata_float(pEntity, iOffset++, vec[0], iLinuxDiff);
	set_pdata_float(pEntity, iOffset++, vec[1], iLinuxDiff);
	set_pdata_float(pEntity, iOffset, vec[2], iLinuxDiff);
	
	return 1;
} 

/*================================================================================================================
		Кик с причиной и эффектом
================================================================================================================*/
stock UTIL_Disconnect(iDest, const vecOrigin[3] = {0, 0, 0}, pEntity = 0, const szReason[])
{
	message_begin(iDest, SVC_DISCONNECT, vecOrigin, pEntity);
	write_string(szReason);
	message_end();
} 

/*================================================================================================================
		Проигрывает звук на игроке .wav или .mp3
================================================================================================================*/
stock PlaySound(pId, const szSound[], bool:bMp3 = false, bool:bLoop = false)
{
	if (bMp3) client_cmd(pId, "mp3 %s %s", bLoop ? "loop" : "play", szSound);
	else client_cmd(pId, "spk %s", szSound);
	return 1;
}

/*================================================================================================================
		Останавливает все звуки (все .wav и/или .mp3)
================================================================================================================*/
stock StopSound(pId, iType = STOP_SOUND_ALL)
{
	switch (iType)
	{
		case STOP_SOUND_WAV: client_cmd(pId, "stopsound");
		case STOP_SOUND_MP3: client_cmd(pId, "mp3 stop");
		case STOP_SOUND_ALL: client_cmd(pId, "stopsound;mp3 stop");
	}
	
	return 1;
} 

/*================================================================================================================
		Возвращает кол-во наблюдателей
================================================================================================================*/
stock FindPlayerSpectators(pId, apSpectators[32])
{
	static iMaxPlayers;
	
	if (!iMaxPlayers)
			iMaxPlayers = get_maxplayers();
	
	new iSpectators = 0;
	
	for (new pPlayer = 1; pPlayer <= iMaxPlayers; pPlayer++)
	{
		if (!is_user_connected(pPlayer))
				continue;
		if (is_user_alive(pPlayer))
				continue;
		if (entity_get_int(pPlayer, EV_INT_iuser2) != pId)
				continue;
		
		apSpectators[iSpectators++] = pPlayer;
	}
	
	return iSpectators;
} 

/*================================================================================================================
		Получает crc32 для файла:
================================================================================================================*/
stock crc32(const s_Buffer[])
{
	new a_CRC_Table[256] =
	{
		0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F, 0xE963A535,
		0x9E6495A3, 0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988, 0x09B64C2B, 0x7EB17CBD,
		0xE7B82D07, 0x90BF1D91, 0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE, 0x1ADAD47D,
		0x6DDDE4EB, 0xF4D4B551, 0x83D385C7, 0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC,
		0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5, 0x3B6E20C8, 0x4C69105E, 0xD56041E4,
		0xA2677172, 0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B, 0x35B5A8FA, 0x42B2986C,
		0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59, 0x26D930AC,
		0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
		0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924, 0x2F6F7C87, 0x58684C11, 0xC1611DAB,
		0xB6662D3D, 0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F,
		0x9FBFE4A5, 0xE8B8D433, 0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB,
		0x086D3D2D, 0x91646C97, 0xE6635C01, 0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E,
		0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457, 0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA,
		0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65, 0x4DB26158, 0x3AB551CE,
		0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB, 0x4369E96A,
		0x346ED9FC, 0xAD678846, 0xDA60B8D0, 0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
		0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409,
		0xCE61E49F, 0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81,
		0xB7BD5C3B, 0xC0BA6CAD, 0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A, 0xEAD54739,
		0x9DD277AF, 0x04DB2615, 0x73DC1683, 0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8,
		0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1, 0xF00F9344, 0x8708A3D2, 0x1E01F268,
		0x6906C2FE, 0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7, 0xFED41B76, 0x89D32BE0,
		0x10DA7A5A, 0x67DD4ACC, 0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5, 0xD6D6A3E8,
		0xA1D1937E, 0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
		0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55, 0x316E8EEF,
		0x4669BE79, 0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236, 0xCC0C7795, 0xBB0B4703,
		0x220216B9, 0x5505262F, 0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7,
		0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D, 0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A,
		0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713, 0x95BF4A82, 0xE2B87A14, 0x7BB12BAE,
		0x0CB61B38, 0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21, 0x86D3D2D4, 0xF1D4E242,
		0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777, 0x88085AE6,
		0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
		0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2, 0xA7672661, 0xD06016F7, 0x4969474D,
		0x3E6E77DB, 0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5,
		0x47B2CF7F, 0x30B5FFE9, 0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605,
		0xCDD70693, 0x54DE5729, 0x23D967BF, 0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94,
		0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D
	}

	new i_CRC = 0xFFFFFFFF
	
	for (new i; i < strlen(s_Buffer); i++)
		i_CRC = (i_CRC >>> 8) ^ a_CRC_Table[(i_CRC ^ s_Buffer[i]) & 0xFF]
		
	return i_CRC ^ 0xFFFFFFFF
} 

/*================================================================================================================
		Получает Длительность wav файла:
================================================================================================================*/
stock Float:get_wav_duration(const s_WavFile[])
{
	if (!file_exists(s_WavFile))
		return 0.0
			
	new a_Frequence[4], a_Bitrate[2], a_DataLength[4], i_File
	
	i_File = fopen(s_WavFile, "rb")
	fseek(i_File, 24, SEEK_SET)
	fread_blocks(i_File, a_Frequence, 4, BLOCK_INT)
	fseek(i_File, 34, SEEK_SET) 
	fread_blocks(i_File, a_Bitrate, 2, BLOCK_BYTE)

	if (fgetc(i_File) != 'd')
		while (fgetc(i_File) != 'd' && !feof(i_File))
		{}
			
	fseek(i_File, 3, SEEK_CUR)
	fread_blocks(i_File, a_DataLength, 4, BLOCK_INT)
   
   fclose(i_File)
	
	return float(a_DataLength[0]) / (float(a_Frequence[0] * a_Bitrate[0]) / 8.0)
} 

/*================================================================================================================
        Возвращает количество игроков из определённой команды (t, ct, spec, hltv)
        Живых или мертвых
        get_count_team("ct", "alive")
        * 1 параметр: ct, t, spec, hltv
        * 2 параметр: alive, dead, all
================================================================================================================*/
stock get_count_team(const sTeam[5], const sAlive[6] = "all")
{
	new iNum = 0
	new team
	
	if(equal(sTeam, "t") team = CS_TEAM_T
	else if (equal(sTeam, "ct") team = CS_TEAM_CT
	else if (equal(sTeam, "spec") team = CS_TEAM_SPECTATOR
	else if (equal(sTeam, "hltv") team = 1337
	else iNum = -1
	
	for (new i = 1; i <= get_maxplayers(); i++)
	{
		if(!is_user_connected(i) || is_user_bot(i) || iNum < 0) continue
		if(team == 1337){
			if(is_user_hltv(i)) iNum++
			continue
		}else if(team == CS_TEAM_SPECTATOR){
			if(cs_get_user_team(i) == CS_TEAM_SPECTATOR) iNum++
			continue
		}
		if(equal(sAlive, "alive")){
			if(cs_get_user_team(i) == team && is_user_alive(i)) iNum++
		}else if(equal(sAlive, "dead")){
			if(cs_get_user_team(i) == team && !is_user_alive(i)) iNum++
		}else if(equal(sAlive, "all")){
			if(cs_get_user_team(i) == team) iNum++
		}else continue
	}
	return iNum
}

/*================================================================================================================
        Установить количество патронов в обойме (НЕ в запасе)
        set_ammo_hard(player_id, "weapon_scout", 5)
================================================================================================================*/
stock set_ammo_hard(const id, const weapon_name[64], const ammo_num)
{
	const wpn
	strip_user_weapons(id)
	give_item(id, weapon_name)
	wpn = find_ent_by_owner(-1, weapon_name,id)
	cs_set_weapon_ammo(wpn, ammo_num)
}

/*================================================================================================================
        Воспроизвести анимацию оружия, которое держит игрок
        UTIL_PlayWeaponAnimation(player_id, 3) 
        * второй параметр - номер анимации
================================================================================================================*/
stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player,pev_body))
	message_end()
} 

/*================================================================================================================
		Функция возвращает колличество строк в файле:
================================================================================================================*/
stock get_count_lines(szFileName[])
{
	new fHandle = fopen(szFileName, "rt");
	
	if(!fHandle)
		return 0;
	
	new szBuffer[2], iLines;
	
	while(!feof(fHandle))
	{
		fgets(fHandle, szBuffer, 1);
		iLines++;
	}
	
	fclose(fHandle);
	
	return iLines;
} 

/*================================================================================================================
		Получает название иоружия
================================================================================================================*/
stock get_weapon_ent(id,wpnid=0,wpnName[]="")
{
	// who knows what wpnName will be
	static newName[24];

	// need to find the name
	if(wpnid) get_weaponname(wpnid,newName,23);

	// go with what we were told
	else formatex(newName,23,"%s",wpnName);

	// prefix it if we need to
	if(!equal(newName,"weapon_",7))
			format(newName,23,"weapon_%s",newName);

	return fm_find_ent_by_owner(get_maxplayers(),newName,id);
} 

/*================================================================================================================
		Генеерация случайных слов
================================================================================================================*/
stock GetRandomWord(word[],len)
{
	if(len<2)
		return;
	static const cons_start[][]=
	{
		// single consonants. Beware of Q, it"s often awkward in words
		"b", "c", "d", "f", "g", "h", "j", "k", "l", "m",
		"n", "p", "r", "s", "t", "v", "w", "x", "z",
		// possible combinations excluding those which cannot start a word
		"pt", "gl", "gr", "ch", "ph", "ps", "sh", "st", "th", "wh" 
	};
	static const cons_all[][]=
	{
		// single consonants. Beware of Q, it"s often awkward in words
		"b", "c", "d", "f", "g", "h", "j", "k", "l", "m",
		"n", "p", "r", "s", "t", "v", "w", "x", "z",
		// possible combinations excluding those which cannot start a word
		"pt", "gl", "gr", "ch", "ph", "ps", "sh", "st", "th", "wh" ,
		"ck", "cm",
		"dr", "ds",
		"ft",
		"gh", "gn",
		"kr", "ks",
		"ls", "lt", "lr",
		"mp", "mt", "ms",
		"ng", "ns",
		"rd", "rg", "rs", "rt",
		"ss",
		"ts", "tch"
	}
	static const vows[][]=
	{
		// single vowels
		"a", "e", "i", "o", "u", "y", 
		// vowel combinations your language allows
		"ee", "oa", "oo" 
	}
	
	format(word,len,"");
	new cur=random_num(0,1);
	new rnd;
	new rndlen;
	formatex(word,len,"%s",cur?vows[random_num(0,sizeof(vows)-1)]:cons_start[random_num(0,sizeof(cons_start)-1)]);
	word[0]-=('a'-'A');	//для заглавной буквы
	cur=!cur;
	
	while( strlen(word) <len) 
	{
		rnd=cur?random_num(0,sizeof(vows)-1):random_num(0,sizeof(cons_all)-1);
		rndlen=cur?strlen(vows[rnd]):strlen(cons_all[rnd])

		// check if random sign fits in word length
		if( strlen(word)+rndlen <=len) 
		{
			format(word,len,"%s%s",word,cur?vows[rnd]:cons_all[rnd]);
			// alternate sounds
			cur=!cur;
		}
	}
} 

/*================================================================================================================
		Возвращает одно из двух числе
================================================================================================================*/
stock random_or(one, two)
{
	switch(random_num(1, 2))
	{
		case 1: return one;
		case 2: return two;
	}
	
	return false;
} 
 
/*================================================================================================================
		Функция возвращаент команду игрока
================================================================================================================*/
stock get_user_team2(id) 
{
	static szTeam[2]

	get_user_team( id, szTeam, 1 )
	switch ( szTeam[0] ) 
	{
		case 'T' : return TT
		case 'C' : return CT
		case 'S' : return ST
	}

	return UT
} 