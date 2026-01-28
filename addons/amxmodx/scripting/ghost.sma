#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>

#define PLUGIN		"Ghost"
#define VERSION		"1.0"
#define AUTHOR		"OsuDesu"

#define MODEL_GHOST	"models/ruzmcs/ghost.mdl"

new bool:g_save_cpl

static Array:g_cp_id, Array:g_cp_origin_x, Array:g_cp_origin_y,	Array:g_cp_origin_z

public plugin_precache() precache_model(MODEL_GHOST)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	g_cp_id = ArrayCreate()
	g_cp_origin_x = ArrayCreate()
	g_cp_origin_y = ArrayCreate()
	g_cp_origin_z = ArrayCreate()
	
	register_clcmd("ghost_menu", "ghosts_menu", ADMIN_RCON)
	
	get_maps_cfg()
}

public get_maps_cfg()
{
	new map[32]
	get_mapname(map, charsmax(map))
	formatex(map, charsmax(map),"%s.ini",map)
	
	new cfgDir[64], i_Dir, i_File[128]
	get_configsdir(cfgDir, charsmax(cfgDir))
	formatex(cfgDir, charsmax(cfgDir), "%s/ghost", cfgDir)
	
	i_Dir = open_dir(cfgDir, i_File, charsmax(i_File))
	
	if(i_Dir)
	{
		while(next_file(i_Dir, i_File, charsmax(i_File)))
		{
			if (i_File[0] == '.')
				continue
				
			if(equal(map, i_File))
			{
				format(i_File,128,"%s/%s",cfgDir, i_File)
				get_checkpoints(i_File)
				break
			}
		}
	}
}

public set_maps_cfg()
{
	new map[32]
	get_mapname(map, charsmax(map))
	formatex(map, charsmax(map),"%s.ini",map)
	
	new cfgDir[64], i_File[128]
	get_configsdir(cfgDir, charsmax(cfgDir))
	formatex(cfgDir, charsmax(cfgDir), "%s/ghost", cfgDir)
	formatex(i_File, charsmax(i_File),"%s/%s",cfgDir, map)
	
	if(!dir_exists(cfgDir))
		if(!mkdir(cfgDir))
			return
	
	delete_file(i_File)
	
	static cp_count; cp_count = ArraySize(g_cp_id)
	if(!cp_count)
		return
	
	for(new i=0; i<cp_count; i++)
	{
		new text[128], Float:fOrigin[3], ent = ArrayGetCell(g_cp_id, i)
		pev(ent, pev_origin, fOrigin)
		format(text, charsmax(text),"^"%f^" ^"%f^" ^"%f^"",fOrigin[0], fOrigin[1], fOrigin[2])
		write_file(i_File, text, i) 
	}
}

public get_checkpoints(i_File[128])
{	
	new file = fopen(i_File,"rt")
	
	while(file && !feof(file))
	{
		new sfLineData[512]
		fgets(file, sfLineData, charsmax(sfLineData))
			
		if(sfLineData[0] == ';')
			continue
			
		if(equal(sfLineData,""))
			continue	
			
		new i_origins[3][32], Float: fOrigins[3]		
		parse(sfLineData, i_origins[0], 31, i_origins[1], 31, i_origins[2], 31)
		
		fOrigins[0] = str_to_float(i_origins[0])
		fOrigins[1] = str_to_float(i_origins[1])
		fOrigins[2] = str_to_float(i_origins[2])
		
		create_checkpoint(fOrigins)
	}
	
	fclose(file)
}

public ghosts_menu(id)
{
	static cp_count; cp_count = ArraySize(g_cp_id)
	
	new menu_name[90]
	format(menu_name, 90, "\rМеню душ")

	new i_menu = menu_create(menu_name, "menu_handler")
	
	menu_additem(i_menu, "\wДобавить", "1", 0)
	
	if(!cp_count)
	{
		menu_additem(i_menu, "\dУдалить предыдущий", "2", 0)
		menu_additem(i_menu, "\dУдалить все", "3", 0)
	}
	else 
	{
		menu_additem(i_menu, "\wУдалить предыдущий", "2", 0)
		menu_additem(i_menu, "\wУдалить все", "3", 0)
	}
	
	if(!g_save_cpl)
		menu_additem(i_menu, "\dСохранить изменения", "4", 0)
	else menu_additem(i_menu, "\wСохранить изменения", "4", 0)

	menu_setprop(i_menu, MPROP_EXIT, MEXIT_ALL)
	menu_setprop(i_menu, MPROP_EXITNAME, "\yВыход")
	menu_display(id, i_menu, 0)
		
	return PLUGIN_HANDLED
}

public menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static cp_count; cp_count = ArraySize(g_cp_id)
	switch(item)
	{
		case 0:
		{	
			g_save_cpl = true
			
			static Float:fOrigins[3]
			fm_get_aim_origin(id, fOrigins)
			fOrigins[2]+=60
			
			create_checkpoint(fOrigins)
			ghosts_menu(id)
		}
		case 1:
		{
			if(!cp_count)
			{
				client_print(id, print_chat, "На карте нет душ") 
				ghosts_menu(id)
				return PLUGIN_HANDLED
			}
			
			g_save_cpl = true
			client_print(id, print_chat, "Душа удалена")
			
			remove_entity(ArrayGetCell(g_cp_id, cp_count-1))
			ArrayDeleteItem(g_cp_id, cp_count-1)
			ArrayDeleteItem(g_cp_origin_x, cp_count-1)
			ArrayDeleteItem(g_cp_origin_y, cp_count-1)
			ArrayDeleteItem(g_cp_origin_z, cp_count-1)
			
			if(cp_count-1)
			{
				set_pev(ArrayGetCell(g_cp_id, cp_count-2), pev_body, 2)
				set_pev(ArrayGetCell(g_cp_id, cp_count-2), pev_skin, 0)
			}
			
			ghosts_menu(id)
		}
		case 2:
		{
			if(!cp_count)
			{
				client_print(id, print_chat, "На карте нет душ") 
				ghosts_menu(id)
				return PLUGIN_HANDLED
			}
			
			g_save_cpl = true
			client_print(id, print_chat, "Было удалено %d Душ", cp_count)
			
			for(new i=0; i<cp_count; i++)
				remove_entity(ArrayGetCell(g_cp_id, i))
			
			ArrayClear(g_cp_id) 
			ArrayClear(g_cp_origin_x) 
			ArrayClear(g_cp_origin_y) 
			ArrayClear(g_cp_origin_z) 
			ghosts_menu(id)
		}
		case 3:
		{
			if(!g_save_cpl)
			{
				ghosts_menu(id)
				return PLUGIN_HANDLED
			}
			
			g_save_cpl = false
			set_maps_cfg()
			
			client_print(id, print_chat, "Сохранено")
			ghosts_menu(id)
		}
	}
	return PLUGIN_HANDLED
}

public create_checkpoint(Float: fOrigins[3])
{
	static ent; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(ent)) return
	
	ArrayPushCell(g_cp_id, ent)
		
	ArrayPushCell(g_cp_origin_x, fOrigins[0])
	ArrayPushCell(g_cp_origin_y, fOrigins[1])
	ArrayPushCell(g_cp_origin_z, fOrigins[2])
	
	engfunc(EngFunc_SetModel, ent, MODEL_GHOST)
		
	set_pev(ent, pev_origin, fOrigins)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_sequence, 1) 
	set_pev(ent, pev_gaitsequence, 1) 
	set_pev(ent, pev_framerate, 1.0)
	set_pev(ent, pev_classname, "ghost")
	
	entity_set_size(ent,Float:{-45.0, -45.0, -45.0}, Float:{45.0, 45.0, 45.0})
}