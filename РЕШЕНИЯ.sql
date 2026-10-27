-- Выполнять в interview_lab. Сначала попробуй решить самостоятельно.
-- 1. PK связующей таблицы — пара ID: нельзя дважды связать тот же фильм
-- с той же категорией, но по отдельности ID могут повторяться.
-- PK не обязателен для создания таблицы; JOIN не требует FK.
-- Ключ — логическое ограничение; индекс — структура для поиска.
-- PostgreSQL обеспечивает PK/UNIQUE уникальными индексами.
SELECT table_schema, table_name, constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema IN ('cinema','billing')
ORDER BY table_schema, table_name, constraint_type, constraint_name;

-- 2
SELECT film_id, title, rating FROM cinema.films
WHERE release_year >= 2023 AND rating >= 8
ORDER BY rating DESC, film_id;

-- 3. Сравнение с NULL даёт UNKNOWN, а WHERE пропускает только TRUE.
SELECT film_id, title FROM cinema.films WHERE rating IS NULL ORDER BY film_id;
SELECT film_id, title, COALESCE(rating::text, 'Нет оценки') AS rating_label
FROM cinema.films ORDER BY film_id;
-- AVG игнорирует NULL; замена на 0 добавит фиктивную оценку и снизит среднее.

-- 4. Одна строка результата на связь, а не на фильм.
SELECT f.film_id, f.title, c.category_id, c.name AS category_name
FROM cinema.films f
JOIN cinema.film_categories fc ON fc.film_id = f.film_id
JOIN cinema.categories c ON c.category_id = fc.category_id
ORDER BY f.film_id, c.category_id;

-- 5
SELECT f.film_id, f.title, c.category_id, c.name AS category_name
FROM cinema.films f
LEFT JOIN cinema.film_categories fc ON fc.film_id = f.film_id
LEFT JOIN cinema.categories c ON c.category_id = fc.category_id
ORDER BY f.film_id, c.category_id;

-- 6. fc.film_id входит в PK, значит NULL возможен только от внешнего JOIN.
SELECT c.category_id, c.name FROM cinema.categories c
LEFT JOIN cinema.film_categories fc ON fc.category_id = c.category_id
WHERE fc.film_id IS NULL ORDER BY c.category_id;
SELECT c.category_id, c.name FROM cinema.categories c
WHERE NOT EXISTS (
 SELECT 1 FROM cinema.film_categories fc WHERE fc.category_id = c.category_id
) ORDER BY c.category_id;

-- 7. RIGHT JOIN сохраняет фильмы справа.
SELECT f.film_id, f.title, c.category_id, c.name AS category_name
FROM cinema.categories c
JOIN cinema.film_categories fc ON fc.category_id = c.category_id
RIGHT JOIN cinema.films f ON f.film_id = fc.film_id
ORDER BY f.film_id, c.category_id;
-- Первый LEFT сохраняет пустые категории, FULL добавляет фильмы без категорий.
SELECT c.category_id, c.name AS category_name, f.film_id, f.title
FROM cinema.categories c
LEFT JOIN cinema.film_categories fc ON fc.category_id = c.category_id
FULL OUTER JOIN cinema.films f ON f.film_id = fc.film_id
ORDER BY c.category_id NULLS LAST, f.film_id;
SELECT c.category_id, c.name AS category_name, a.actor_id, a.name AS actor_name
FROM cinema.categories c CROSS JOIN cinema.actors a
ORDER BY c.category_id, a.actor_id;

-- 8. Задача интервью. films не нужна: FK гарантирует существование фильма,
-- а составной PK исключает повтор одной связи. Категории без связей сохраняются.
SELECT c.name AS category_name, COUNT(fc.film_id) AS film_count
FROM cinema.categories c
LEFT JOIN cinema.film_categories fc ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name ORDER BY c.category_id;

-- 9
SELECT c.category_id, c.name, COUNT(*) AS row_count, COUNT(fc.film_id) AS film_count
FROM cinema.categories c
LEFT JOIN cinema.film_categories fc ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name ORDER BY c.category_id;

-- 10. Фильтр в WHERE f.release_year = 2024 убрал бы все нулевые категории.
-- Считаем f.film_id, не fc.film_id: связь со старым фильмом остаётся,
-- но сам старый фильм не проходит условие второго JOIN.
SELECT c.name AS category_name, COUNT(f.film_id) AS film_count
FROM cinema.categories c
LEFT JOIN cinema.film_categories fc ON fc.category_id = c.category_id
LEFT JOIN cinema.films f ON f.film_id = fc.film_id AND f.release_year = 2024
GROUP BY c.category_id, c.name ORDER BY c.category_id;

-- 11. HAVING применяется после группировки.
SELECT c.name AS category_name, COUNT(fc.film_id) AS film_count
FROM cinema.categories c
LEFT JOIN cinema.film_categories fc ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name
HAVING COUNT(fc.film_id) >= 2 ORDER BY c.category_id;

-- 12
SELECT c.name AS category_name, ROUND(AVG(f.duration_min),2) AS avg_duration,
 MIN(f.duration_min) AS min_duration, MAX(f.duration_min) AS max_duration,
 COALESCE(SUM(f.duration_min),0) AS total_duration
FROM cinema.categories c
LEFT JOIN cinema.film_categories fc ON fc.category_id = c.category_id
LEFT JOIN cinema.films f ON f.film_id = fc.film_id
GROUP BY c.category_id, c.name ORDER BY c.category_id;

-- 13. Для Орбиты 2 категории x 2 актёра = 4 строки промежуточного результата.
SELECT f.film_id, f.title, COUNT(DISTINCT fc.category_id) AS category_count,
 COUNT(DISTINCT fa.actor_id) AS actor_count
FROM cinema.films f
LEFT JOIN cinema.film_categories fc ON fc.film_id = f.film_id
LEFT JOIN cinema.film_actors fa ON fa.film_id = f.film_id
GROUP BY f.film_id, f.title ORDER BY f.film_id;
-- Альтернатива: сначала агрегировать каждую связь, затем соединять итоги.
WITH categories AS (
 SELECT film_id, COUNT(*) AS n FROM cinema.film_categories GROUP BY film_id
), actors AS (
 SELECT film_id, COUNT(*) AS n FROM cinema.film_actors GROUP BY film_id
)
SELECT f.film_id, f.title, COALESCE(c.n,0) AS category_count,
 COALESCE(a.n,0) AS actor_count
FROM cinema.films f
LEFT JOIN categories c ON c.film_id=f.film_id
LEFT JOIN actors a ON a.film_id=f.film_id ORDER BY f.film_id;

-- 14
SELECT film_id, title, rating FROM cinema.films
WHERE rating > (SELECT AVG(rating) FROM cinema.films) ORDER BY film_id;

-- 15
SELECT s.subscription_id, u.name AS user_name, p.name AS plan_name,
 s.status, s.starts_at, s.ends_at
FROM billing.subscriptions s
JOIN billing.users u ON u.user_id=s.user_id
JOIN billing.plans p ON p.plan_id=s.plan_id ORDER BY s.subscription_id;

-- 16. Дубль ext-004 намеренно учитывается дважды: это сумма строк,
-- а не гарантированная выручка. SUM(DISTINCT amount) не решение:
-- разные реальные оплаты могут иметь одинаковую сумму.
SELECT u.user_id, u.name, COUNT(p.payment_id) AS success_count,
 COALESCE(SUM(p.amount),0) AS total_paid
FROM billing.users u
LEFT JOIN billing.subscriptions s ON s.user_id=u.user_id
LEFT JOIN billing.payments p ON p.subscription_id=s.subscription_id AND p.status='success'
GROUP BY u.user_id, u.name ORDER BY u.user_id;

-- 17
SELECT s.subscription_id, s.user_id FROM billing.subscriptions s
WHERE s.status='active'
 AND s.starts_at <= DATE '2025-02-15' AND s.ends_at > DATE '2025-02-15'
 AND NOT EXISTS (
  SELECT 1 FROM billing.payments p
  WHERE p.subscription_id=s.subscription_id AND p.status='success'
 ) ORDER BY s.subscription_id;

-- 18
SELECT external_id, COUNT(*) AS duplicate_count FROM billing.payments
GROUP BY external_id HAVING COUNT(*)>1 ORDER BY external_id;
SELECT * FROM billing.payments
WHERE external_id IN (
 SELECT external_id FROM billing.payments GROUP BY external_id HAVING COUNT(*)>1
) ORDER BY payment_id;
-- После проверки и устранения дублей: UNIQUE(external_id).
-- Сейчас создание ограничения завершится ошибкой из-за двух ext-004.

-- 19. Self join; строгое неравенство границ даёт полуоткрытые интервалы.
SELECT a.user_id, a.subscription_id AS first_id, b.subscription_id AS second_id
FROM billing.subscriptions a JOIN billing.subscriptions b
 ON a.user_id=b.user_id AND a.plan_id=b.plan_id
 AND a.subscription_id < b.subscription_id
 AND a.starts_at < b.ends_at AND b.starts_at < a.ends_at
WHERE a.status='active' AND b.status='active'
ORDER BY a.user_id, a.subscription_id, b.subscription_id;

-- 20
WITH ranked AS (
 SELECT s.user_id, p.payment_id, p.status, p.paid_at,
 ROW_NUMBER() OVER (PARTITION BY s.user_id ORDER BY p.paid_at DESC, p.payment_id DESC) AS rn
 FROM billing.subscriptions s
 JOIN billing.payments p ON p.subscription_id=s.subscription_id
)
SELECT u.user_id, u.name, r.payment_id, r.status, r.paid_at
FROM billing.users u LEFT JOIN ranked r ON r.user_id=u.user_id AND r.rn=1
ORDER BY u.user_id;

-- 21. COMMIT сохранил бы изменение; UPDATE без WHERE меняет все строки.
BEGIN;
UPDATE billing.subscriptions SET status='cancelled' WHERE subscription_id=5;
SELECT subscription_id, status FROM billing.subscriptions WHERE subscription_id=5;
ROLLBACK;
SELECT subscription_id, status FROM billing.subscriptions WHERE subscription_id=5;

-- 22. FK с поведением по умолчанию не позволяет удалить родителя с потомком.
BEGIN;
INSERT INTO cinema.categories VALUES (99,'Учебная');
INSERT INTO cinema.film_categories VALUES (7,99);
SELECT f.title, c.name FROM cinema.films f
JOIN cinema.film_categories fc ON fc.film_id=f.film_id
JOIN cinema.categories c ON c.category_id=fc.category_id WHERE c.category_id=99;
DELETE FROM cinema.film_categories WHERE category_id=99;
DELETE FROM cinema.categories WHERE category_id=99;
ROLLBACK;

-- 23. Для ручной проверки выполняй каждый блок ниже ОТДЕЛЬНО,
-- сняв комментарии. После ожидаемой ошибки обязательно выполни ROLLBACK.
-- BEGIN;
-- INSERT INTO cinema.film_categories VALUES (1,1); -- 23505, duplicate PK
-- ROLLBACK;
-- BEGIN;
-- INSERT INTO cinema.film_categories VALUES (999,1); -- 23503, нет фильма
-- ROLLBACK;
-- BEGIN;
-- INSERT INTO billing.payments VALUES (99,1,-1,'success','2025-02-15','negative-test');
-- -- 23514, нарушен CHECK amount > 0
-- ROLLBACK;

-- 24. На маленькой таблице Seq Scan часто дешевле Index Scan.
-- FK не создаёт индекс на ссылающемся столбце автоматически.
-- PK и UNIQUE создают уникальный индекс на своих столбцах.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM billing.payments WHERE subscription_id=2;
BEGIN;
CREATE INDEX payments_subscription_id_idx ON billing.payments(subscription_id);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM billing.payments WHERE subscription_id=2;
ROLLBACK;
