#include amxmodx
#include nvault

#define NVAULT_NAME		"DrugsSave"

#define CHAR 32
#define MAX_PLAYER 32

native ujbl_get_drugs(id, iDrugs)				// 1 - "??????", 2 - "?????", 3 - "???", 4 - "??????"
native ujbl_set_drugs(id, iDrugs, iNum)

native ujbl_get_material(id, iMaterial)			// 1 - "??????", 2 - "?????", 3 - "??? ?????", 4 - "??????"
native ujbl_set_material(id, iMaterial, iNum)

new g_nVault, g_DeleteDay, g_s_AuthID[MAX_PLAYER + 1][CHAR + 3];
public plugin_init()
{
	register_plugin("[U-JBL] Drugs Save", "vk.com/krisiso", "ToJI9IHGaa");
	
	g_DeleteDay = register_cvar("delete_nvault_drugs", "2");
}
public plugin_cfg()
{
    g_nVault = nvault_open(NVAULT_NAME);
    if(g_nVault == INVALID_HANDLE) set_fail_state("Error opening nVault!");
    nvault_prune(g_nVault, 0, get_systime() - (86400 * get_pcvar_num( g_DeleteDay)));
}
public plugin_end() nvault_close(g_nVault);
public client_authorized(id) get_user_authid(id, g_s_AuthID[id], charsmax(g_s_AuthID[]));
public client_putinserver(id) GetDrugs(id);
public cliet_disconnect(id) SaveDrugs(id);
public SaveDrugs(id)
{
    new s_Data[CHAR + CHAR], s_Key[40];

    formatex(s_Key, charsmax(s_Key), "%sVALUE", g_s_AuthID[id])
    formatex(s_Data, charsmax(s_Data), "%d %d %d %d %d %d %d %d", ujbl_get_drugs(id, 1), 
	ujbl_get_drugs(id, 2), ujbl_get_drugs(id, 3), ujbl_get_drugs(id, 4),
	ujbl_get_material(id, 1), ujbl_get_material(id, 2), ujbl_get_material(id, 3), ujbl_get_material(id, 4))

    nvault_set(g_nVault, s_Key, s_Data);
}
public GetDrugs(id)
{
    new s_Data[CHAR + CHAR];
    new s_Key[40];
    formatex(s_Key, charsmax(s_Key), "%sVALUE", g_s_AuthID[id])
    if(nvault_get(g_nVault, s_Key, s_Data, charsmax(s_Data)))
    {
		new i_SpacePos = contain(s_Data, " ");
		if(i_SpacePos > -1)
		{    
			new s_iDrugs[4][8];
			new s_iMt[4][8];
			formatex(s_iDrugs[0], i_SpacePos, "%s", s_Data);
			for(new i = 1; i <= 3; i++) formatex(s_iDrugs[i], 7, "%s", s_Data[i_SpacePos + i]);				
			for(new i = 0; i <= 3; i++) formatex(s_iMt[i], 7, "%s", s_Data[i_SpacePos + (i+4)]);
			for(new i = 0; i <= 3; i++)
			{
				ujbl_set_drugs(id, i+1, str_to_num(s_iDrugs[i]));
				ujbl_set_material(id, i+1, str_to_num(s_iMt[i]));
			}
		}
    }
}