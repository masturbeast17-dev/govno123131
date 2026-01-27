/* Fun functions
*
* by Revka
*
* This file is provided as is (no warranties).
*/ 

#if defined _csxinc_included
  #endinput
#endif
#define _csxinc_included

#include <amxmodx>
native set_user_frozen(id)

stock Print_Ban_Info(id, const name[], const authid[], const reason[], const length, const unban_time[])
{
	static Time[9], Data[64];
	static hostname[64], ban_length[64];
	
	get_cvar_string("hostname",hostname,63);
	get_time("%H:%M:%S", Time, 8);
	get_time("%d.%m.%Y", Data, 63);
	
	if(id == 0)
	{
	server_print("^n************************************^n------------------------------------")
	server_print("[CSX:|Bans ] Print Ban Informations")
	server_print("|Banned Made on : %s ",hostname)
	server_print("|Banned Name :'%s'",name)
	if( length > 0 )
	{
		GetBanTime(length, ban_length, sizeof(ban_length) - 1);
		server_print("|Ban Lenght :'%s'",ban_length)
	}
	server_print("|Banned STEAM ID : '%s'",authid)
	server_print("|Banned Reason :	'%s'",reason)
	server_print("|Unban time is:'%s'",unban_time)
	server_print("|You had made a screenshot!")
	server_print("|Visit our website for unban....")
	server_print("|Current  Data '%s', Current Time '%s'",Data,Time)
	
	}
	else
	
	client_cmd(id,"echo ^"^n************************************^n------------------------------------^"")
	client_cmd(id,"echo [CSX:|Bans ] Print Ban Informations")
	client_cmd(id,"echo |Banned Made on : %s ",hostname)
	client_cmd(id,"echo |Banned Name :'%s'",name)
	if( length > 0 )
	{
		GetBanTime(length, ban_length, sizeof(ban_length) - 1);
		client_cmd(id,"echo |Ban Lenght :'%s'",ban_length)
	}
	client_cmd(id,"echo |Banned STEAM ID : '%s'",authid)
	client_cmd(id,"echo |Banned Reason :	'%s'",reason)
	client_cmd(id,"echo |Unban time is:'%s'",unban_time)
	client_cmd(id,"echo |You had made a screenshot!")
	client_cmd(id,"echo |Visit our website for unban....")
	client_cmd(id,"echo |Current  Data '%s', Current Time '%s'",Data,Time)
	client_cmd(id,"echo ^"^n************************************^n------------------------------------^"")

}

stock GenerateUnbanTime(const bantime, unban_time[], len)
{
	static _hours[5], _minutes[5], _seconds[5], _month[5], _day[5], _year[7];
	format_time(_hours, sizeof(_hours) - 1, "%H");
	format_time(_minutes, sizeof(_minutes) - 1, "%M");
	format_time(_seconds, sizeof(_seconds) - 1, "%S");
	format_time(_month, sizeof(_month) - 1, "%m");
	format_time(_day, sizeof(_day) - 1, "%d");
	format_time(_year, sizeof(_year) - 1, "%Y");
	
	new hours = str_to_num(_hours);
	new minutes = str_to_num(_minutes);
	new seconds = str_to_num(_seconds);
	new month = str_to_num(_month);
	new day = str_to_num(_day);
	new year = str_to_num(_year);
	
	minutes += bantime;
	
	while( minutes >= 60 )
	{
		minutes -= 60;
		hours++;
	}
	
	while( hours >= 24 )
	{
		hours -= 24;
		day++;
	}
	
	new max_days = GetDaysInMonth(month, year);
	while( day > max_days )
	{
		day -= max_days;
		month++;
	}
	
	while( month > 12 )
	{
		month -= 12;
		year++;
	}
	
	formatex(unban_time, len, "%i.%i.%i %i:%02i:%02i ", day, month, year, hours, minutes, seconds);
}
GetDaysInMonth(month, year=0)
{
	switch( month )
	{
		case 1:		return 31; // january
		case 2:		return ((year % 4) == 0) ? 29 : 28; // february
		case 3:		return 31; // march
		case 4:		return 30; // april
		case 5:		return 31; // may
		case 6:		return 30; // june
		case 7:		return 31; // july
		case 8:		return 31; // august
		case 9:		return 30; // september
		case 10:	return 31; // october
		case 11:	return 30; // november
		case 12:	return 31; // december
	}
	
	return 30;
}
stock GetBanTime(const bantime, length[], len)
{
	new minutes = bantime;
	new hours = 0;
	new days = 0;
	
	while( minutes >= 60 )
	{
		minutes -= 60;
		hours++;
	}
	
	while( hours >= 24 )
	{
		hours -= 24;
		days++;
	}
	
	new bool:add_before;
	if( minutes )
	{
		formatex(length, len, "%i minute%s", minutes, minutes == 1 ? "" : "s");
		
		add_before = true;
	}
	if( hours )
	{
		if( add_before )
		{
			format(length, len, "%i hour%s, %s", hours, hours == 1 ? "" : "s", length);
		}
		else
		{
			formatex(length, len, "%i hour%s", hours, hours == 1 ? "" : "s");
			
			add_before = true;
		}
	}
	if( days )
	{
		if( add_before )
		{
			format(length, len, "%i day%s, %s", days, days == 1 ? "" : "s", length);
		}
		else
		{
			formatex(length, len, "%i day%s", days, days == 1 ? "" : "s");
			
			add_before = true;
		}
	}
	if( !add_before )
	{
		// minutes, hours, and days = 0
		// assume permanent ban
		copy(length, len, "PERMAMENT");
	}
}

Print_Color(const id, const szMessageFormat[ ], any:...)
{
 static szMessage[ 192 ], iLen;
 iLen = formatex( szMessage, 191, "^1[^3CSX:|Bans^1] " );
 vformat( szMessage[ iLen ], 191 - iLen, szMessageFormat, 3 );
 
 if( id )
	{
		UTIL_SayText( id, id, szMessage );
		Team_Info(id, MSG_ONE, "TERRORIST");
	}
	else
	{
		new i;
		for( i = 1; i <= get_maxplayers(); i++ )
		{
			if( is_user_connected( i ) )
			{
				UTIL_SayText( i, i, szMessage );
				Team_Info(i, MSG_ONE, "CT");
			}
		}
	}
	
}
UTIL_SayText( const iReceiver, const iSender, const szMessage[ ] )
{
	message_begin( iReceiver ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid( "SayText" ), _, iReceiver );
	write_byte( iSender );
	write_string( szMessage );
	message_end( );
}
Team_Info(id, type, team[])
{
	static bool:teaminfo_used;
	static get_user_msgid_teaminfo;
	if(!teaminfo_used)
	{
		get_user_msgid_teaminfo = get_user_msgid("TeamInfo");
		teaminfo_used = true;
	}
	message_begin(type, get_user_msgid_teaminfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
