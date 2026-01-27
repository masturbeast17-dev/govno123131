#if defined _as_core_included
  #endinput
#endif
#define _as_core_included

/*
	* Нативы
*/
/* Получить или установить уровень игроку */
native as_get_user_level ( id );
native as_set_user_level ( id, level );

/* Получить или установить опыт игроку */
native as_get_user_exp ( id );
native as_get_user_max_exp ( id );
native as_set_user_exp ( id, exp );

/*
	* События
*/
/* Событие сохранения данных игрока */
forward AS_Save_Base ( id );

/* Событие получения данных игрока */
forward AS_Check_Base ( id );

/* Событие нового уровня игрока */
forward AS_New_Level ( id, level );