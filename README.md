# PostgreSQL: тренажёр по собеседованию

Это комплект для самостоятельной практики: PostgreSQL в Docker, готовые данные, 24 задания и отдельные решения. Все имена и платежи вымышлены.

В расшифровке SQL-блок сосредоточен на JOIN, ключах, агрегатах и подсчёте фильмов по категориям, включая категории без фильмов. Первые 14 заданий закрывают эти темы. Платежи, транзакции и индексы — дополнительная практика для QA, а не перечень реально заданных на интервью вопросов.

## 1. Как развернуть локально

PostgreSQL — сервер базы данных. Он запускается в Docker, отдельно ставить PostgreSQL не нужно. `psql` — его консольный клиент, он уже есть внутри контейнера. Ниже установка с нуля на macOS: сначала Docker, затем сам тренажёр.

На компьютере должен работать один сервер Docker. Colima и Docker Desktop вместе не запускай: клиент `docker` подключается только к одному из них.

### Установить Docker через Colima

Этот вариант не требует Docker Desktop. Colima поднимает виртуальную машину, в которой работает Docker. Команды `docker` и `docker compose` ставятся отдельно и обращаются к ней.

Если Homebrew ещё нет, установи его и следуй подсказке в конце установки про `PATH`:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Дальше поставь клиент Docker, Compose и Colima, затем запусти виртуальную машину:

```bash
brew install docker docker-compose colima
colima start --cpu 2 --memory 4 --disk 20
docker info
```

`docker info` должен показать блок `Server`, а не ошибку про docker daemon. Диск `20` — размер диска виртуальной машины в гигабайтах, не диска Mac. Учебной базе этого хватает. Если Colima уже создана с другим диском, повторный `colima start` старые параметры не меняет.

### Либо установить Docker Desktop

Вместо Colima можно поставить [Docker Desktop для Mac](https://docs.docker.com/desktop/setup/install/mac-install/). Скачай версию под свой процессор, открой скачанный файл и перенеси Docker в «Программы». Запусти Docker и дождись статуса, что сервер работает. После этого в терминале тоже должна проходить команда `docker info`.

Через Homebrew тот же вариант ставится так:

```bash
brew install --cask docker
open -a Docker
```

### Скачать тренажёр и запустить базу

```bash
git clone https://github.com/RbBobby/sql-practice.git
cd sql-practice
docker compose up -d --wait
docker compose ps
```

Если папка `sql-practice` уже есть, `git clone` не нужен: открой терминал в этой папке и выполни две команды `docker compose`.

При первом запуске Docker скачает образ PostgreSQL 16 (Alpine), создаст базу `interview_lab` и автоматически выполнит `init/01_data.sql`. Дождись статуса `healthy`. Порт `55432` открыт только на этом компьютере. Это не сайт: адрес `http://127.0.0.1:55432` в браузере открывать не нужно, браузер покажет пустую страницу. Учебный пароль находится в `compose.yaml`.

Если `docker compose` пишет `Cannot connect to the Docker daemon`, сервер Docker не запущен. Для Colima перезапусти машину. Сообщение `already running` при мёртвой машине как раз лечится принудительной остановкой:

```bash
colima stop --force
colima start
```

Для Docker Desktop открой приложение и дождись, пока оно запустится. Ошибки самой базы смотри командой `docker compose logs db`. Если порт `55432` занят, поменяй в `compose.yaml` только левое число, например на `55433`, и используй новый порт в клиенте.

Подключиться через терминал:

```bash
docker compose exec db psql -U student -d interview_lab
```

Команды внутри `psql`:

```sql
\dn
\dt cinema.*
\dt billing.*
\d cinema.film_categories
SELECT * FROM cinema.categories ORDER BY category_id;
\q
```

`\d` показывает столбцы, ключи и ограничения; `\q` закрывает клиент. SQL-запрос заканчивается `;`. Если случайно начал незавершённый запрос, `\r` очистит буфер. Команды с обратным слешем — команды psql, в обычный SQL-редактор их вставлять не нужно.

Для подключения из графического клиента PostgreSQL:

| Поле | Значение |
|---|---|
| Host | `127.0.0.1` |
| Port | `55432` |
| Database | `interview_lab` |
| User | `student` |
| Password | `practice_local_only` |
| SSL | Для этого локального стенда отключить |

Графический клиент для этих параметров — [DBeaver Community](https://dbeaver.io/download/). Платная редакция не нужна. После установки создай подключение PostgreSQL и впиши таблицу выше. В поле SSL выбери `disable`.

Открывай SQL-редактор именно для базы `interview_lab`. Вверху редактора в списке баз должна быть выбрана `interview_lab`, не служебная база `postgres`. В запросах используй полные имена таблиц: `cinema.films`, `billing.users`. Схема `cinema` — это не отдельная база, поэтому запрос `SELECT * FROM cinema` завершится ошибкой. Левая панель DBeaver возвращается через **Window → Show View → Database Navigator**. Если панели нет в коротком списке, открой **Other…** и найди `Database Navigator`. Сбросить расположение окон: **Window → Perspective → Reset Perspective**.

Остановка с сохранением данных:

```bash
docker compose stop
```

Повторный запуск:

```bash
docker compose up -d --wait
```

Остановить саму виртуальную машину Colima, когда тренажёр больше не нужен:

```bash
colima stop
```

Следующий запуск снова начинается с `colima start`, затем `docker compose up -d --wait`. Docker Desktop вместо этого просто оставляй запущенным или выходи из приложения.

## 2. Как импортировать учебную базу

Для запуска через приложенный Compose импорт уже автоматический. Дополнительно загружать дампы из интернета не нужно. Одна база содержит два набора связанных таблиц в схемах `cinema` и `billing`. Обычный JOIN соединяет таблицы внутри одной базы; отдельные базы здесь не нужны.

Проверка после импорта:

```sql
SELECT 'cinema.films' AS table_name, COUNT(*) FROM cinema.films
UNION ALL
SELECT 'cinema.categories', COUNT(*) FROM cinema.categories
UNION ALL
SELECT 'billing.users', COUNT(*) FROM billing.users
UNION ALL
SELECT 'billing.payments', COUNT(*) FROM billing.payments;
```

Ожидается соответственно 8, 6, 5 и 7 строк данных.

Если хочешь использовать собственный установленный PostgreSQL, создай отдельную пустую базу `interview_lab`, затем импортируй файл клиентом `psql` (подставь своего пользователя):

```bash
createdb -h localhost -p 5432 -U YOUR_USER interview_lab
psql -h localhost -p 5432 -U YOUR_USER -d interview_lab -v ON_ERROR_STOP=1 -f init/01_data.sql
```

Это альтернативный вариант. Не запускай импорт повторно поверх автоматически загруженных данных: схемы уже существуют, и он завершится ошибкой. Скрипт обёрнут в транзакцию, существующие таблицы он не удаляет.

### Восстановить исходные данные

Инициализация Docker выполняется только на пустом каталоге данных; простой перезапуск контейнера не возвращает данные к исходным. Данные сохраняются в `postgres-data/` рядом с Compose-файлом. Этот каталог не нужно редактировать вручную или добавлять в Git.

Чтобы восстановить исходный набор, выполни команды ниже. Первая **удаляет обе учебные схемы со всеми сделанными в них изменениями**, вторая импортирует их заново. Другие схемы и базы не затрагиваются.

```bash
docker compose exec -T db psql -U student -d interview_lab -v ON_ERROR_STOP=1 -c 'DROP SCHEMA cinema, billing CASCADE;'
docker compose exec -T db psql -U student -d interview_lab -v ON_ERROR_STOP=1 < init/01_data.sql
```

`docker compose down` останавливает и удаляет контейнер, но сохраняет данные в папке. Следующий `up` подключит их снова.

## 3. Что находится в базе

```text
cinema.categories 1 ── N cinema.film_categories N ── 1 cinema.films
cinema.actors     1 ── N cinema.film_actors     N ── 1 cinema.films

billing.users 1 ── N billing.subscriptions N ── 1 billing.plans
                          1
                          │
                          N
                    billing.payments
```

В кино есть пустые категории, фильм без категории, актёр без фильмов, фильм с несколькими категориями и актёрами, рейтинг NULL. Это специально подобранные случаи для проверки JOIN и агрегатов.

В платежах есть пользователь без подписок, неудачная и ожидающая оплаты, подписка без платежей, повтор события оплаты и пересекающиеся активные подписки. Ограничения FK при этом соблюдены: ошибки здесь бизнесовые.

| Таблица | Важные столбцы |
|---|---|
| cinema.categories | category_id (PK), name |
| cinema.films | film_id (PK), title, release_year, duration_min, rating (может быть NULL) |
| cinema.film_categories | film_id (FK), category_id (FK); вместе составляют PK |
| cinema.actors | actor_id (PK), name |
| cinema.film_actors | film_id (FK), actor_id (FK); вместе составляют PK |
| billing.users | user_id (PK), name, email (может быть NULL), created_at |
| billing.plans | plan_id (PK), name, price |
| billing.subscriptions | subscription_id (PK), user_id (FK), plan_id (FK), status, starts_at, ends_at |
| billing.payments | payment_id (PK), subscription_id (FK), amount, status, paid_at, external_id |

Для воспроизводимости все проверки подписок делаем **на 15 февраля 2025 года**, а не на сегодняшнюю дату. Интервалы подписок: `[starts_at, ends_at)`, то есть начало включено, конец исключён. Статус `active` сам по себе не гарантирует, что дата попадает в период. Для упражнений `paid_at` означает время записи попытки оплаты, в том числе неуспешной.

## 4. Как заниматься

Открой `ЗАДАНИЯ.md`, а `РЕШЕНИЯ.sql` оставь закрытым. Для каждого задания сначала предскажи результат, потом напиши запрос, выполни его и объясни вслух. Контрольные результаты находятся в конце файла с заданиями.

- День 1, 45–60 минут: задания 1–7, ключи и обычные соединения.
- День 2, 45–60 минут: 8–14, пустые категории и агрегаты. Главная задача интервью — № 8.
- День 3, 60 минут: 15–20, проверки платежей и подписок.
- День 4, 45–60 минут: 21–24, изменения данных, ограничения и план выполнения.
- День 5, 20 минут без подсказок: повторить 8, 10 и 17; устно ответить на вопросы из задания 1.

Свои запросы можно писать в `мои_запросы.sql`, затем запускать из папки тренажёра:

```bash
docker compose exec -T db psql -U student -d interview_lab -v ON_ERROR_STOP=1 < мои_запросы.sql
```

Эталонные решения можно выполнять по одному в редакторе или весь файл:

```bash
docker compose exec -T db psql -U student -d interview_lab -v ON_ERROR_STOP=1 < РЕШЕНИЯ.sql
```

Изменения в эталонных решениях обёрнуты в `BEGIN` / `ROLLBACK`. Они не меняют исходные данные после завершения файла.

## 5. Короткая памятка для интервью

- **PRIMARY KEY** однозначно идентифицирует строку: уникален и не допускает NULL. Может состоять из нескольких столбцов. Таблицу технически можно создать без PK; фраза «он есть в каждой таблице» неверна.
- **FOREIGN KEY** проверяет ссылочную целостность: ненулевое значение должно ссылаться на допустимый ключ другой (или этой же) таблицы. Обычно это PK, но может быть и подходящий UNIQUE. FK — не «first key». JOIN не требует наличия FK: он соединяет строки по условию `ON`.
- **INNER JOIN** выдаёт совпавшие пары. **LEFT JOIN** выдаёт все совпавшие пары и сохраняет строки слева без совпадений, подставляя NULL справа. Если справа три совпадения, строка слева даст три строки результата.
- **RIGHT JOIN** сохраняет правую сторону; **FULL OUTER JOIN** — обе. **CROSS JOIN** даёт все сочетания. `ALTER JOIN` не существует. `OUTER` — часть названий LEFT/RIGHT/FULL, а не отдельный пятый вид.
- **COUNT(*)** считает строки результата. **COUNT(column)** считает ненулевые значения. После LEFT JOIN у пустой категории есть одна строка с NULL справа: `COUNT(*) = 1`, а `COUNT(fc.film_id) = 0`.
- **GROUP BY** объединяет строки по группам; `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` вычисляют значения внутри групп. `AVG`, а не `AVERAGE`. Без GROUP BY агрегат может считать всю выборку одной группой. Неагрегированные поля SELECT обычно нужно включить в GROUP BY; PostgreSQL также допускает отдельные случаи функциональной зависимости от PK.
- **WHERE** фильтрует строки до группировки, **HAVING** — группы после неё. Условие `WHERE f.release_year = 2024` отбрасывает NULL-строки внешнего соединения; чтобы сохранить пустые категории, фильтр по фильму можно поместить в `ON`.
- **NULL** означает отсутствие/неизвестность значения. Проверка — `IS NULL`, не `= NULL`. Большинство агрегатов пропускает NULL; `SUM` пустой выборки возвращает NULL, `COUNT` — 0. `COALESCE` позволяет явно задать замену.

Официальные источники: [образ PostgreSQL и правила инициализации](https://hub.docker.com/_/postgres), [PostgreSQL в Docker](https://docs.docker.com/guides/postgresql/), [JOIN](https://www.postgresql.org/docs/16/tutorial-join.html), [агрегаты](https://www.postgresql.org/docs/16/functions-aggregate.html), [ограничения](https://www.postgresql.org/docs/16/ddl-constraints.html).
