-- Учебные данные вымышлены. Импорт атомарный; повторный запуск не удаляет данные.
BEGIN;
CREATE SCHEMA cinema;
CREATE SCHEMA billing;

CREATE TABLE cinema.categories (
  category_id integer PRIMARY KEY,
  name text NOT NULL UNIQUE
);
CREATE TABLE cinema.films (
  film_id integer PRIMARY KEY,
  title text NOT NULL,
  release_year integer NOT NULL CHECK (release_year BETWEEN 1900 AND 2100),
  duration_min integer CHECK (duration_min > 0),
  rating numeric(3,1) CHECK (rating BETWEEN 0 AND 10)
);
CREATE TABLE cinema.film_categories (
  film_id integer REFERENCES cinema.films(film_id),
  category_id integer REFERENCES cinema.categories(category_id),
  PRIMARY KEY (film_id, category_id)
);
CREATE TABLE cinema.actors (
  actor_id integer PRIMARY KEY,
  name text NOT NULL
);
CREATE TABLE cinema.film_actors (
  film_id integer REFERENCES cinema.films(film_id),
  actor_id integer REFERENCES cinema.actors(actor_id),
  PRIMARY KEY (film_id, actor_id)
);
INSERT INTO cinema.categories VALUES
 (1,'Драма'),(2,'Комедия'),(3,'Фантастика'),(4,'Документальный'),(5,'Ужасы'),(6,'Анимация');
INSERT INTO cinema.films VALUES
 (1,'Орбита',2023,120,8.2),(2,'Соседи',2022,90,7.1),
 (3,'Тихий город',2020,110,8.0),(4,'Океан',2024,60,9.0),
 (5,'Сигнал',2024,100,7.8),(6,'Выходной',2021,95,6.5),
 (7,'Без категории',2024,80,NULL),(8,'Долгая дорога',2023,140,8.4);
INSERT INTO cinema.film_categories VALUES
 (1,1),(1,3),(2,2),(3,1),(4,4),(5,3),(6,2),(8,1),(8,4);
INSERT INTO cinema.actors VALUES
 (1,'Анна'),(2,'Борис'),(3,'Вера'),(4,'Глеб'),(5,'Дарья'),(6,'Егор');
INSERT INTO cinema.film_actors VALUES
 (1,1),(1,2),(2,2),(2,3),(3,1),(5,3),(5,4),(6,2),(8,1),(8,4),(8,5);

CREATE TABLE billing.users (
 user_id integer PRIMARY KEY,
 name text NOT NULL,
 email text UNIQUE,
 created_at date NOT NULL
);
CREATE TABLE billing.plans (
 plan_id integer PRIMARY KEY,
 name text NOT NULL UNIQUE,
 price numeric(10,2) NOT NULL CHECK (price >= 0)
);
CREATE TABLE billing.subscriptions (
 subscription_id integer PRIMARY KEY,
 user_id integer NOT NULL REFERENCES billing.users(user_id),
 plan_id integer NOT NULL REFERENCES billing.plans(plan_id),
 status text NOT NULL CHECK (status IN ('active','expired','cancelled')),
 starts_at date NOT NULL,
 ends_at date NOT NULL,
 CHECK (ends_at > starts_at)
);
CREATE TABLE billing.payments (
 payment_id integer PRIMARY KEY,
 subscription_id integer NOT NULL REFERENCES billing.subscriptions(subscription_id),
 amount numeric(10,2) NOT NULL CHECK (amount > 0),
 status text NOT NULL CHECK (status IN ('success','failed','pending')),
 paid_at timestamp NOT NULL,
 external_id text NOT NULL
 -- UNIQUE специально отсутствует: ищем повторно обработанное событие.
);
INSERT INTO billing.users VALUES
 (1,'Алиса','alice@example.test','2025-01-01'),
 (2,'Борис','boris@example.test','2025-01-02'),
 (3,'Вера',NULL,'2025-01-03'),
 (4,'Глеб','gleb@example.test','2025-01-04'),
 (5,'Дарья','daria@example.test','2025-01-05');
INSERT INTO billing.plans VALUES (1,'Basic',500),(2,'Pro',1000),(3,'Team',2000);
INSERT INTO billing.subscriptions VALUES
 (1,1,1,'expired','2025-01-01','2025-02-01'),
 (2,1,2,'active','2025-02-01','2025-03-01'),
 (3,2,1,'active','2025-02-01','2025-03-01'),
 (4,3,2,'cancelled','2025-01-10','2025-02-10'),
 (5,5,1,'active','2025-02-01','2025-03-01'),
 (6,2,1,'active','2025-02-10','2025-03-10');
INSERT INTO billing.payments VALUES
 (1,1,500,'success','2025-01-01 10:00','ext-001'),
 (2,2,1000,'failed','2025-02-01 10:00','ext-002'),
 (3,2,1000,'success','2025-02-01 10:05','ext-003'),
 (4,3,500,'success','2025-02-01 11:00','ext-004'),
 (5,3,500,'success','2025-02-01 11:01','ext-004'),
 (6,4,1000,'failed','2025-01-10 10:00','ext-005'),
 (7,5,500,'pending','2025-02-01 12:00','ext-006');
COMMIT;
