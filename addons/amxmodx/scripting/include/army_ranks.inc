#if defined _army_ranks_included
  #endinput
#endif
#define _army_ranks_included

/*
* ¬озвращает опыт игрока.
*/
native get_user_exp(id);

/*
* ¬озвращает уровень игрока.
*/
native get_user_lvl(id);

/*
* ”станавливает опыт игроку.
*	num = кол-во опыта.
*/
native set_user_exp(id,num);

/*
* ”станавливает уровень/звание игроку.
*	num = уровень/звание.
*/
native set_user_lvl(id,num);

/*
* ¬озвращает строку звани€ игрока, например : р€довой,маршал и т.п.
*/
native get_user_rankname(id);