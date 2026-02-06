#if defined _VtcApi_Included
	#endinput
#endif
#define _VtcApi_Included

#pragma reqlib VtcApi
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib VtcApi
#endif

native VTC_MuteClient(playerSlot);
native VTC_UnmuteClient(playerSlot);
native bool:VTC_IsClientMuted(playerSlot);

native VTC_BlockClient(playerSlot);
native VTC_UnblockClient(playerSlot);
native bool:VTC_IsClientBlocked(playerSlot);

native bool:VTC_IsClientSpeaking(playerSlot);
forward VTC_OnClientStartSpeak(playerSlot);
forward VTC_OnClientStopSpeak(playerSlot);

native VTC_PlaySound(receiver, const soundFilePath[]);