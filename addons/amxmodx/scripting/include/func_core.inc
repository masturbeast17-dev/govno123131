#if defined _fc_included
  #endinput
#endif
#define _fc_included

enum FcTeams {
	CS_TEAM_UNNAMED,
	CS_TEAM_T,
	CS_TEAM_CT,
	CS_TEAM_SPECTATOR
};

native fc_user_connected( client );
native fc_user_alive( client );
native FcTeams:fc_get_user_team( client );
native fc_set_user_team( client, jointeam, joinclass = 1 );
native fc_get_user_money( client );
native fc_set_user_money( client, money, flash = 1 );
native fc_get_user_flags( client );
native fc_set_user_health( client, health );
native fc_get_user_health( client );