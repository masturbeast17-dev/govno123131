#if defined _portal_gun_inc
#endinput
#endif
#define _portal_gun_inc

/**
 * Выдаёт игроку портальную пушку.
 *
 * @param	id	- id игрока, кому выдать портальную пушку
 * @return		- 0, если пушка уже есть, 1 - всё ок, выдали
 */
native pg_give(const id)

/**
 * Забирает у игрока портальную пушку.
 *
 * @param	id	- id игрока, у кого забрать портальную пушку
 * @return		- 0, если пушки и так нету, 1 - всё ок, забрали
 */
native pg_remove(const id)

/**
 * Проверяет - может ли игрок переключиться на портальную пушку.
 *
 * @param	id	- id игрока для проверки
 * @return		- 1 - есть, 0 - нету
 */
native pg_is_have(const id)

/**
 * Если в данный момент у игрока вместо ножа портальна пушка - вернёт 1
 * Причём вернёт 1 даже если в руках какое-то другое оружие (например пистолет)
 *
 * @param	id	- id игрока для проверки
 * @return		- 1 - есть, 0 - нету
 */
native pg_is_in_hand(const id)

/**
 * Удаляет портал игрока.
 *
 * @param	id		- id игрока для проверки
 * @param	portal	- тип портала 's' - синий (правая кнопка мыши), 'e' - оранжевый (левая кнопка мыши), 'a' - оба
 * @return			- 1 - удалено, 0 - не удалено, т.к. у игрока нет портальной пушки, либо параметр portal неправильный
 */
native pg_delete_portal(const id, const portal)

/**
 * Возвращает id энтитии портала.
 *
 * @param	id		- id игрока для проверки
 * @param	portal	- тип портала 's' - синий (правая кнопка мыши), 'e' - оранжевый (левая кнопка мыши)
 * @return			- id энтитии портала, 0 - если у игрока нет портальной пушки или параметр portal неправильный
 */
native pg_get_portal_id(const id, const portal)
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
