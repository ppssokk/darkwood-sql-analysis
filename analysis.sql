/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Али Фирас
 * Дата: 08.08.2026
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь

SELECT 
	COUNT(id) AS number_of_players,
	SUM(payer) AS number_of_payers, 
	SUM(payer)::NUMERIC / COUNT(id) AS share_of_paying_players
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь

SELECT
	r.race AS race,
	SUM(u.payer) AS number_of_payers_of_race,
	COUNT(u.id) AS number_of_players_of_race,
	SUM(u.payer)::NUMERIC / COUNT(u.id) AS share_of_paying_players_of_race
FROM fantasy.users u 
JOIN fantasy.race r
	ON u.race_id = r.race_id 
GROUP BY r.race
ORDER BY r.race;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь

SELECT 
	COUNT(e.transaction_id) AS number_of_transactions,
	SUM(e.amount) AS SUM_of_transactions,
	min(e.amount) AS min_transaction,
	max(e.amount) AS max_transaction,
	AVG(e.amount) AS AVG_transaction,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY e.amount) median_transaction,
	STDDEV(e.amount) standard_deviation_transaction
FROM fantasy.events e;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь

SELECT
	COUNT(e.transaction_id) FILTER (WHERE e.amount = 0) AS number_of_zero_cost_transaction,
	COUNT(e.transaction_id) FILTER (WHERE e.amount = 0)::NUMERIC / COUNT(e.transaction_id) AS share_of_zero_cost_transaction
FROM fantasy.events e; 

-- 2.3: Популярные эпические предметы:
-- Напишите ваш запрос здесь

SELECT
	i.game_items AS name_of_item,
	COUNT(e.transaction_id) AS number_of_transaction,
	COUNT(e.transaction_id)::NUMERIC / SUM(COUNT(e.transaction_id)) OVER () AS share_of_transaction,
	COUNT(DISTINCT e.id)::NUMERIC / (
	SELECT 
		COUNT(DISTINCT id)
	FROM fantasy.events
	WHERE amount != 0
	) AS share_of_players
FROM fantasy.events e 
JOIN fantasy.items i
	ON e.item_code = i.item_code 
WHERE e.amount != 0
GROUP BY i.item_code, i.game_items
ORDER BY COUNT(DISTINCT e.id) DESC;

-- Часть 2. Решение ad hoc-задачbи
-- Задача: Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь

SELECT
	r.race AS race,
	COUNT(DISTINCT u.id) AS number_of_players,
	COUNT(DISTINCT e.id) AS number_of_buying_players,
	COUNT(DISTINCT e.id)::NUMERIC / COUNT(DISTINCT u.id) AS share_of_buying_players,
	COUNT(DISTINCT u.id) FILTER (WHERE e.id IS NOT NULL AND u.payer = 1)::NUMERIC
	/ COUNT(DISTINCT u.id) FILTER (WHERE e.id IS NOT NULL) AS share_of_paying_players,
	COUNT(e.transaction_id)::NUMERIC / COUNT(DISTINCT e.id) AS avg_number_of_transactions_per_player,
	AVG(e.amount) AS avg_transaction_amount,
	SUM(e.amount) / COUNT(DISTINCT e.id) AS avg_total_amount_per_player
FROM fantasy.users u 
LEFT JOIN fantasy.events e
	ON e.id = u.id 
	AND e.amount != 0
JOIN fantasy.race r 
	ON r.race_id = u.race_id 
GROUP BY r.race;
