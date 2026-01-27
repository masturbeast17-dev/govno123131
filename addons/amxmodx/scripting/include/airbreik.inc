forward onCheckAirBrk( playerid );
forward t_SetPlayerPos( playerid, Float:x, Float:y, Float:z );
enum pinfo
{
    Float: pPos_x,
    Float: pPos_y,
    Float: pPos_z,
    bool:pTeleport,
    airbrake,
    pCurrentCar,
    pInt
}new PlayerInfo[ MAX_PLAYERS ][ pinfo ];

public OnFilterScriptInit( )
{
    print( "[FS] Anti-AirBrk by Dima-kun is loaded" );
    return 1;
}
public OnPlayerConnect( playerid )
{
    SetTimerEx( "onCheckAirBrk", 1000, false, "i", playerid );
    return 1;
}
public OnPlayerSpawn( playerid )
{
    PlayerInfo[ playerid ][ pTeleport ] = true;
    PlayerInfo[ playerid ][ airbrake ] = 0;
    return 1;
}
public OnPlayerInteriorChange( playerid, newinteriorid, oldinteriorid )
{
    PlayerInfo[ playerid ][ pTeleport ] = true;
    PlayerInfo[ playerid ][ airbrake ] = 0;
     printf( "%i,%i,%i, %b",playerid, newinteriorid, oldinteriorid, PlayerInfo[ playerid ][ pTeleport ] );
    return 1;
}
public OnPlayerStateChange( playerid, newstate, oldstate )
{
    if( newstate == PLAYER_STATE_DRIVER )PlayerInfo[ playerid ][ pCurrentCar ] = GetPlayerVehicleID( playerid );
    return 1;
}
public t_SetPlayerPos( playerid, Float:x, Float:y, Float:z )
{
    SetPlayerPos( playerid, x, y, z );
    PlayerInfo[ playerid ][ airbrake ] = 0;
    PlayerInfo[ playerid ][ pTeleport ] = true;
    return 1;
}
public onCheckAirBrk( playerid )
{
    if( IsPlayerConnected( playerid ) )
    {
        new string[ 128 ],
            speed = GetPlayerSpeed( playerid, true ),
            Float:currentPos[ 3 ],
            Float:distance,
            currentInt = GetPlayerInterior( playerid );
        GetPlayerPos( playerid, currentPos[ 0 ], currentPos[ 1 ], currentPos[ 2 ] );
        if(speed < 30)
        {
            distance = floatround( GetPlayerDistanceFromPoint( playerid, PlayerInfo[ playerid ][ pPos_x ], PlayerInfo[ playerid ][ pPos_y ], PlayerInfo[ playerid ][ pPos_z] ) );
            if( distance > 100 && PlayerInfo[ playerid ][ pTeleport ] == false )
            {
                if( PlayerInfo[ playerid ][ airbrake ] < 1 )PlayerInfo[ playerid ][ airbrake ]++;
                else
                {
                    PlayerInfo[ playerid ][ airbrake ] ++;
                    if( PlayerInfo[ playerid ][ airbrake ] > 2 )
                    {
			SendClientMessage(playerid, 0xFF6347AA, "¬ы кикнуты по подозрению в читерстве (#0231)");
                    	Kick( playerid );
                    }
                }
            }
          }
        PlayerInfo[ playerid ][ pPos_x ] = currentPos[ 0 ];
        PlayerInfo[ playerid ][ pPos_y ] = currentPos[ 1 ];
        PlayerInfo[ playerid ][ pPos_z ] = currentPos[ 2 ];
        PlayerInfo[ playerid ][ pInt ] = currentInt;
        PlayerInfo[ playerid ][ pTeleport ] = false;
        SetTimerEx( "onCheckAirBrk", 1000, false, "i", playerid );
    }
}
stock getName( const playerid )
{
    new pname[ MAX_PLAYER_NAME ];
    GetPlayerName( playerid, pname, sizeof( pname ) );
    return pname;
}

stock GetPlayerSpeed(const playerid, bool: check3d)
{
    new Float: coord[ 3 ];
    if( IsPlayerInAnyVehicle( playerid ) )
        GetVehicleVelocity( PlayerInfo[ playerid ][ pCurrentCar ], coord[ 0 ], coord[ 1 ], coord[ 2 ] );
    else
        GetPlayerVelocity( playerid, coord[ 0 ], coord[ 1 ], coord[ 2 ] );
    return floatround( floatsqroot( ( check3d ) ? ( coord[ 0 ]*coord[ 0 ] + coord[ 1 ]*coord[ 1 ]+coord[ 2 ]*coord[ 2 ]) : ( coord[ 0 ]*coord[ 0 ] + coord[ 1 ]*coord[ 1 ] ) )*100.0*1.6 );
}