/**
 * Вызывается после выбора режима
 *
 * @param 	id				- инициатор
 * @param	mode			- id режима
 * @return		- указать PLUGIN_HANDLED, если нужно заблокировать выбор режима
 */
forward n21_dr_set_mode(id, mode)

/**
 * Вызывается для проверки возможности купить предмет 
 *
 * @param 	id				- инициатор
 * @param	item			- id предмета
 * @return 
		** CASE_HAVE    - предмет уже есть
		** CASE_MODE    - предмет заблокирован в данном режиме
		** CASE_DUEL    - предмет заблокирован во время дуэли
		** CASE_LOTERY  - предмет заблокирован во время лотереи
		** CASE_ONLYONE - предмет можно купить только одному игроку за раунд
		** CASE_NOT_T	- предмет нельзя использовать на террориста, которого нет
		** 0		    - предмет не забокирован
 */
forward n21_dr_can_buy(id, item)

/**
 * Вызывается после покупки предмета
 *
 * @param 	id				- инициатор
 * @param	item			- id предмета
 */
forward n21_dr_buy(id, item)

/**
 * Вызывается при выборе нового террориста из-за дизконнекта
 *
 * @param 	id				- новый террорист
 * @param 	mode			- id режима
 */
forward n21_dr_new_terr(id, mode)

/**
 * Регестрация режима
 *
 * @param 	mode_name[]				- Название режима
 * @param	mode_instruction[]		- Указания, которые будут выводяиться после выбора режима
 * @param 	mode_times_const		- Кол-во раундов, требующие переждать после выбора режима
 * @param	r						- RGB настройка ХУД сообщения после выбора режима
 * @param	g						- up
 * @param	b						- up
 * @param	static_id				- статичный id режима
 * @return		- id режима
 */
native n21_dr_mode_registration(const mode_name[], const mode_instruction[], const mode_times_const, const r, const g, const b, const static_id)

/**
 * Регестрация предмета в магазине
 *
 * @param 	item_name[]				- Название предмета
 * @param	item_instruction[]		- Указания, которые будут выводяиться после покупки предмета
 * @param 	item_coast				- Цена предмета
 * @param	item_alive				- 1 - предмет может купить только живой, 2 - только мертвый, 0 - все
 * @param	item_team				- для какой команды предназначен предмет (0 - всем)
 * @return		- id предмета
 */
native n21_dr_item_registration(const item_name[], const item_instruction[], const item_coast, const item_alive, const item_team)

/**
 * Получает id режима в данный момент
 *
 * @return		- id режима
 */
native n21_dr_get_mode_id()

/**
 * Получает статичный id режима в данный момент
 *
 * @return		- id режима
 */
native n21_dr_get_mode_st_id()

/**
 * Получает основной тег для чат сообщений
 *
 * @return		- строка с тегом
 */
native n21_dr_get_maintag()

/**
 * Получает денежный лимит
 *
 * @return		- денежный лимит
 */
native n21_dr_get_maxmoney()

/**
 * Получает установленную цену жизни для lifemenu
 *
 * @return		- цена жизни
 */
native n21_dr_get_lifecost()

/**
 * Получает установленную цену для продажи жизни для lifemenu
 *
 * @return		- цена жизни
 */
native n21_dr_get_lifesell()

/**
 * Получает установленную лимит жизней для lifemenu
 *
 * @return		- цена жизни
 */
native n21_dr_get_lifelimit()

/**
 * Разрешены ли ставки в дуэлях
 *
 * @return		- 1/0
 */
native n21_dr_duel_bets()

/**
 * Устанавливает максимальную скорость игроку
 *
 * @param 	id				- id игрока
 * @param 	speed			- скорость (0 - сбрасывает скорость до стандартной с ножом)
 * @return		- 1, если все ок
 */
native n21_dr_set_maxspeed(const id, const Float: speed)