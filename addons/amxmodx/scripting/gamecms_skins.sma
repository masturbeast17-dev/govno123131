/*
	* Плагин "GameCMS Skins";
	* Автор: "OverGame";
	* Версия: "1.0".
	
	* Специально для магазина https://worksma.ru
*/
#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <sqlx>

stock const VERSION[] = "1.0";

	/* Параметры по типу микроконстант */
#define TASK_FIX_MYSQL 120230221019
#define TASK_FIX_MODEL 120230223302

#if AMXX_VERSION_NUM > 183
	#define client_disconnect client_disconnected
#endif

	/* Создаем переменные для SQL. */
new Handle:sth;

	/* Различные настройки */
new server_id;
new user_model[33][33];

	/* База купленных товаров (по индексу сервера) */
enum _:DATA_PURCHASES { NICK_NAME[33], MODEL_NAME[64], PASS_WORD[64], SKIN_ID };
new Array:i_ArrayPurchases, i_Purchases[DATA_PURCHASES];

public plugin_precache() {
	new buffer[512], precache[256];
	new file = fopen("/addons/amxmodx/configs/gamecms_skins.ini", "r");
	
	while(!feof(file)) {
		fgets(file, buffer, charsmax(buffer));
		trim(buffer);
		
		if(buffer[0] == '"') {
			if(parse(buffer, precache, charsmax(precache))) {
				formatex(precache, charsmax(precache), "models/player/%s/%s.mdl", precache, precache);
				
				if(file_exists(precache)) {
					precache_model(precache);
				}
			}
		}
		else {
			continue;
		}
	}
	
	fclose(file);
}

public plugin_init() {
	register_plugin("GameCMS Skins", VERSION, "OverGame");
	RegisterHam(Ham_Spawn, "player", "fwd_HamSpawn");
	
	register_cvar("gamecms_hostname", "");
	register_cvar("gamecms_username", "");
	register_cvar("gamecms_password", "");
	register_cvar("gamecms_database", "");
}

public plugin_cfg() {
	new configs_dir[64];
	get_localinfo("amxx_configsdir", configs_dir, charsmax(configs_dir));
	server_cmd("exec %s/gamecms_skins.cfg", configs_dir);
	
	set_task(1.0, "please_connect_mysql", TASK_FIX_MYSQL);
}

public please_connect_mysql(task) {
	new err, error[256];
	sth = SQL_MakeDbTuple(cvar_string("gamecms_hostname"), cvar_string("gamecms_username"), cvar_string("gamecms_password"), cvar_string("gamecms_database"));
	sth = SQL_Connect(sth, err, error, charsmax(error));
	
	if(sth == Empty_Handle) {
		set_fail_state(error);
	}
	
	SQL_QueryAndIgnore(sth, "set names utf8");
	
	new Handle:query;
	
		/* Получаем ID сервера. */
	new address[23];
	get_user_ip(0, address, charsmax(address), 0);
	
	query = f_query(sth, "SELECT * FROM `servers` WHERE `address`='%s'", address);
	server_id = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));
	
		/* Получаем покупки пользователей */
	i_ArrayPurchases = ArrayCreate(DATA_PURCHASES);
	query = f_query(sth, "SELECT * FROM `skins__purchases` WHERE `enable`='1' and `server_id`='%d'", server_id);
	
	while(SQL_MoreResults(query)) {
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "nickname"), i_Purchases[NICK_NAME], charsmax(i_Purchases[NICK_NAME]));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "password"), i_Purchases[PASS_WORD], charsmax(i_Purchases[PASS_WORD]));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "model_name"), i_Purchases[MODEL_NAME], charsmax(i_Purchases[MODEL_NAME]));
		i_Purchases[SKIN_ID] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "skin_id"));
		ArrayPushArray(i_ArrayPurchases, i_Purchases);
		
		SQL_NextRow(query);
	}
	
	SQL_FreeHandle(sth);
	remove_task(task);
}

public client_putinserver(id) {
	formatex(user_model[id], charsmax(user_model[]), "");
	
	new nickname[33], password[33];
	get_user_name(id, nickname, charsmax(nickname));
	get_user_info(id, cvar_string("amx_password_field"), password, charsmax(password));
	
	for(new i; i < ArraySize(i_ArrayPurchases); i++) {
		ArrayGetArray(i_ArrayPurchases, i, i_Purchases);
		
		if(equal(nickname, i_Purchases[NICK_NAME]) && equal(password, i_Purchases[PASS_WORD])) {
			copy(user_model[id], charsmax(user_model[]), i_Purchases[MODEL_NAME]);
			break;
		}
	}
}

public client_disconnect(id) {
	remove_task(TASK_FIX_MODEL + id);
}

public fwd_HamSpawn(id) {
	if(is_user_connected(id) && !equal(user_model[id], "")) {
		set_task(0.2, "set_player_model", TASK_FIX_MODEL + id);
	}
}

public set_player_model(user_id) {
	user_id = user_id - TASK_FIX_MODEL;
	
	if(is_user_alive(user_id)) {
		cs_set_user_model(user_id, user_model[user_id]);
	}
}

stock Handle:f_query(Handle:connect, const text[], any:...) {
	new request[256];
	vformat(request, charsmax(request), text, 3);
	
	new Handle:query = SQL_PrepareQuery(connect, request);
	
	if(!SQL_Execute(query)) {
		new error[256];
		SQL_QueryError(query, error, charsmax(error));
		
		set_fail_state(error);
	}
	
	return query;
}

stock cvar_string(const cvar_name[]) {
	new text[128];
	get_cvar_string(cvar_name, text, charsmax(text));
	
	return text;
}