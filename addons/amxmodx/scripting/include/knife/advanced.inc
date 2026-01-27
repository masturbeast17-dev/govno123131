/**
 * Плагин: he_kill_him
 * Эмулирует убийство игрока, если игрок указанный в параметре victim в течении времени timer умрёт от падения или от чего-то подобного
 *
 * @param 	victim				- Жертва
 * @param	attacker			- Атакующий, тот кому будет засчитан фраг
 * @param	timer				- Время действия
 * @return		- 1
 */
native ka_set_attacker(const victim, const attacker, const Float:timer)

/**
 * Плагин: knife_fire
 * Проверяет, горит ли игрок, который подожжён Fire ножом
 *
 * @param 	id				- Игрок
 * @return		- true - горит, false - не горит
 */
native bool:ka_is_burning(const id)

/**
 * Плагин: knife_fire
 * Останавливает горение игрока, который был подожжён Fire ножом
 *
 * @param 	id				- Игрок
 * @return		- 1
 */
native ka_stop_fire(const id)

/**
 * Плагин: knife_frost
 * Размораживает игрока
 *
 * @param 	id				- Игрок
 * @return		- 1
 */
native ka_unfreez(const id)

/**
 * Плагин: knife_frost
 * Убирает шлейф, синий экран и значок заморозки
 *
 * @param 	id				- Игрок
 * @return		- 1
 */
native ka_unchill(const id)

/**
 * Плагин: knife_frost
 * Проверяет если игрок заморожен
 *
 * @param 	id				- Игрок
 * @return		- true - ослеплён, false - не ослеплён
 */
native bool:ka_in_ffreez(const id)

/**
 * Плагин: knife_frost
 * Проверяет если игрок chilled
 *
 * @param 	id				- Игрок
 * @return		- true - ослеплён, false - не ослеплён
 */
native bool:ka_in_fchill(const id)

/**
 * Плагин: item_frost_gaz
 * Размораживает игрока
 *
 * @param 	id				- Игрок
 * @return		- 1
 */
native ka_gren_unfreez(const id)

/**
 * Плагин: item_frost_gaz
 * Убирает шлейф, синий экран и значок заморозки
 *
 * @param 	id				- Игрок
 * @return		- 1
 */
native ka_gren_unchill(const id)

/**
 * Плагин: item_frost_gaz
 * Проверяет если игрок заморожен
 *
 * @param 	id				- Игрок
 * @return		- true - ослеплён, false - не ослеплён
 */
native bool:ka_in_fgrenfreez(const id)

/**
 * Плагин: item_frost_gaz
 * Проверяет если игрок chilled
 *
 * @param 	id				- Игрок
 * @return		- true - ослеплён, false - не ослеплён
 */
native bool:ka_in_fgrenchill(const id)

/**
 * Плагин: knife_ninja
 * Проверяет, находится ли игрок в невидимости или нет
 *
 * @param 	id				- Игрок
 * @return		- true - в невидимости, false - нет
 */
native bool:ka_in_ninja(const id)

/**
 * Плагин: knife_ninja
 * Убирает невидимость, если игрок в ней находится
 *
 * @param 	id				- Игрок
 * @return		- true - в невидимости, false - нет
 */
native ka_unset_ninja(const id)

/**
 * Плагин: item_candy
 * Проверяет, держит ли игрок сейчас карамельную тросточку
 *
 * @param 	id				- Игрок
 * @return		- true - держит, false - нет
 */
native bool:ka_is_in_candy(const id)

/**
 * Плагин: item_stimpak
 * Даёт игроку регенерацию хп
 *
 * @param 	id				- Игрок
 * @return		- 1
 */
native ka_use_regeneration(const id)

/**
 * Плагин: MindGames
 * Получает ответ на следующий пример
 *
 * @return		- ответ на следующий пример
 */
native ka_next_result_mg()

/**
 * Плагин: item_frost_gaz
 * Проверяет, держит ли игрок сейчас фростовую грену
 *
 * @param 	id				- Игрок
 * @return		- true - держит, false - нет
 */
native bool:ka_frostgren_inhand(const id)

/**
 * Плагин: item_frost_gaz
 * Проверяет, держит ли игрок сейчас газовую грену
 *
 * @param 	id				- Игрок
 * @return		- true - держит, false - нет
 */
native bool:ka_gazgren_inhand(const id)

/**
 * Плагин: item_frost_gaz
 * Получает кол-во фростовых грен у игрока
 *
 * @param 	id				- Игрок
 * @return		- true - держит, false - нет
 */
native ka_frostgren_ammo(const id)

/**
 * Плагин: item_frost_gaz
 * Получает кол-во газовых грен у игрока
 *
 * @param 	id				- Игрок
 * @return		- true - держит, false - нет
 */
native ka_gazgren_ammo(const id)

/**
 * Плагин: item_frost_gaz
 * Выдает игроку фростовую грену
 *
 * @param 	id				- Игрок
 * @return		- 1
 */
native ka_frostgren_give(const id)

/**
 * Плагин: item_frost_gaz
 * Выдает игроку газовую грену
 *
 * @param 	id				- Игрок
 * @return		- 1
 */
native ka_gazgren_give(const id)

/**
 * Устанвливает рендеринг игроку
 *
 * @return		-	-1 если всё ок
 * 					> -1 значит произошло смешение цветов, возвращённое значение id для удаления этого цвета функцией ka_render_sub
 */
native ka_render_add(const index, const fx = kRenderFxNone, const r = 255, const g = 255, const b = 255, const render = kRenderNormal, const amount = 16)

/**
 * Убирает цвет из рендеринга
 *
 * @param 	id				- Игрок
 * @param 	handle			- Id добавленного цвета из функции ka_render_add
 * @return		-	-1 у игрока отсутствуют смешанные цвета или параметр shift неверный
 * 					 0 это был последний цвет, рендеринг сброшен на стандартный
 * 					 1 цвет убран, рендер оставлен
 */
native ka_render_sub(const id, const handle_add)

//-------------------------------------- /advanced_render -------------------------------------
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1049\\ f0\\ fs16 \n\\ par }
*/
