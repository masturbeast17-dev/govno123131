
#if defined _chat_colored
  #endinput
#endif
#define _chat_colored

stock zp_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	static g_msgSayText_cp, g_MaxPlayers_cp;
	if(!g_msgSayText_cp) {
		g_msgSayText_cp = get_user_msgid("SayText");
	}
	if(!g_MaxPlayers_cp) {
		g_MaxPlayers_cp = get_maxplayers();
	}
	
	// Send to everyone
	if (!target)
	{
		static player
		for (player = 1; player <= g_MaxPlayers_cp; player++)
		{
			// Not connected
			if (!is_user_connected(player))
				continue;
			
			// Remember changed arguments
			static changed[5], changedcount // [5] = max LANG_PLAYER occurencies
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			// Format message for player
			vformat(buffer, charsmax(buffer), message, 3)
			
			replace_all(buffer, charsmax(buffer), "!g", "^4");
			replace_all(buffer, charsmax(buffer), "!y", "^1");
			replace_all(buffer, charsmax(buffer), "!t", "^3");
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText_cp, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		/*
		// Not needed since you should set the ML argument
		// to the player's id for a targeted print message
		
		// Replace LANG_PLAYER with player id
		for (i = 2; i < argscount; i++)
		{
			if (getarg(i) == LANG_PLAYER)
				setarg(i, 0, target)
		}
		*/
		
		// Format message for player
		vformat(buffer, charsmax(buffer), message, 3)
		
		replace_all(buffer, charsmax(buffer), "!g", "^4");
		replace_all(buffer, charsmax(buffer), "!y", "^1");
		replace_all(buffer, charsmax(buffer), "!t", "^3");
		
		// Send it
		message_begin(MSG_ONE, g_msgSayText_cp, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

