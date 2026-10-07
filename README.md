# ClickHouse Web Analytics

Аналитический проект на ClickHouse: расчёт продуктовых метрик веб-трафика (DAU, воронка, retention) на схеме с MergeTree.

## 📖 О проекте

Проект показывает полный цикл работы с ClickHouse: проектирование схемы, загрузку данных и расчёт метрик. Цель — продемонстрировать навыки работы с колоночной СУБД и понимание того, чем аналитическая (OLAP) нагрузка отличается от транзакционной (OLTP).

Проект отвечает на вопросы: как спроектировать таблицу под аналитику, как эффективно хранить данные и как считать продуктовые метрики на диалекте ClickHouse. В качестве примера используется веб-аналитика: логи посещений сайта с просмотрами страниц и кликами. Такой сценарий хорошо знаком любому продукту и позволяет показать реальные метрики: DAU, топ страниц, воронку, retention.

## 🛠️ Технологии

- **ClickHouse** — движок MergeTree, LowCardinality, партиционирование
- **SQL** — агрегации, работа с датами, функции ClickHouse
- **SQLize.online** — онлайн-песочница для запуска

## 📊 Схема данных

Таблица `events` хранит логи веб-трафика.

| Колонка       | Тип                    | Описание                          |
|---------------|------------------------|-----------------------------------|
| event_time    | DateTime               | Время события                     |
| visitor_id    | UInt64                 | ID посетителя                     |
| event_type    | LowCardinality(String) | Тип события (`pageview`/`click`)  |
| url           | String                 | URL страницы                      |
| duration_ms   | UInt32                 | Длительность в миллисекундах      |

> **О данных:** Набор данных синтетический и создан исключительно для демонстрации возможностей ClickHouse. Все `visitor_id`, URL и временные метки сгенерированы. Проект не использует реальные логи, персональные данные или коммерческую информацию.

> **О датах:** В `INSERT` используются относительные даты (`now() - INTERVAL N DAY`), чтобы проект оставался актуальным при любом запуске. В реальных проектах даты обычно фиксируют для воспроизводимости.

Особенности схемы: `PARTITION BY toYYYYMM(event_time)` разбивает данные по месяцам и ускоряет запросы с фильтром по дате; `ORDER BY (event_time, visitor_id)` задаёт сортировку внутри партиции, которая работает как индекс; `LowCardinality(String)` оптимизирует колонку с малым числом уникальных значений; `UInt32` и `UInt64` заменяют тяжёлые строковые и целочисленные типы, экономя память.

### Пример данных

Несколько строк из таблицы `events` для наглядности:

| event_time          | visitor_id | event_type | url      | duration_ms |
|---------------------|------------|------------|----------|-------------|
| 2026-10-04 16:59:51 | 101        | pageview   | /home    | 1200        |
| 2026-10-04 16:59:51 | 101        | pageview   | /pricing | 3400        |
| 2026-10-04 16:59:51 | 101        | click      | /buy     | 0           |
| 2026-10-04 16:59:51 | 102        | pageview   | /home    | 1500        |
| 2026-10-04 16:59:51 | 102        | pageview   | /blog    | 5000        |
| 2026-10-04 16:59:51 | 103        | pageview   | /home    | 900         |
| 2026-10-04 16:59:51 | 103        | click      | /signup  | 0           |


## 🚀 Запуск проекта

Все шаги выполняются в [SQLize.online — ClickHouse](https://sqlize.online/sql/clickhouse/).

> ⚠️ **Важно:** SQLize.online не сохраняет состояние между отдельными запусками. Каждый `Run` создаёт новую временную базу данных. Поэтому весь код ниже нужно выполнить за один запуск, а не по частям.

### Создание таблицы

```sql
CREATE TABLE events
(
    event_time  DateTime,
    visitor_id  UInt64,
    event_type  LowCardinality(String),
    url         String,
    duration_ms UInt32
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_time)
ORDER BY (event_time, visitor_id);
```

### Вставка данных

```sql
INSERT INTO events VALUES
(now() - INTERVAL 3 DAY, 101, 'pageview', '/home',     1200),
(now() - INTERVAL 3 DAY, 101, 'pageview', '/pricing',  3400),
(now() - INTERVAL 3 DAY, 101, 'click',    '/buy',         0),
(now() - INTERVAL 3 DAY, 102, 'pageview', '/home',     1500),
(now() - INTERVAL 3 DAY, 102, 'pageview', '/blog',     5000),
(now() - INTERVAL 3 DAY, 103, 'pageview', '/home',      900),
(now() - INTERVAL 3 DAY, 103, 'click',    '/signup',      0),
(now() - INTERVAL 3 DAY, 107, 'pageview', '/docs',     4200),
(now() - INTERVAL 3 DAY, 108, 'pageview', '/home',     1300),
(now() - INTERVAL 2 DAY, 101, 'pageview', '/home',     1100),
(now() - INTERVAL 2 DAY, 101, 'pageview', '/pricing',  2900),
(now() - INTERVAL 2 DAY, 104, 'pageview', '/home',     2000),
(now() - INTERVAL 2 DAY, 104, 'pageview', '/docs',     7000),
(now() - INTERVAL 2 DAY, 104, 'click',    '/buy',         0),
(now() - INTERVAL 2 DAY, 105, 'pageview', '/home',      800),
(now() - INTERVAL 2 DAY, 107, 'pageview', '/blog',     3600),
(now() - INTERVAL 2 DAY, 108, 'pageview', '/pricing',  2500),
(now() - INTERVAL 2 DAY, 108, 'click',    '/signup',      0),
(now() - INTERVAL 1 DAY, 101, 'pageview', '/home',     1050),
(now() - INTERVAL 1 DAY, 102, 'pageview', '/blog',     4800),
(now() - INTERVAL 1 DAY, 103, 'pageview', '/pricing',  3100),
(now() - INTERVAL 1 DAY, 105, 'pageview', '/docs',     6100),
(now() - INTERVAL 1 DAY, 105, 'click',    '/buy',         0),
(now() - INTERVAL 1 DAY, 107, 'pageview', '/home',     1400),
(now() - INTERVAL 1 DAY, 109, 'pageview', '/home',     1700),
(now() - INTERVAL 1 DAY, 109, 'pageview', '/pricing',  3300),
(now() - INTERVAL 1 DAY, 109, 'click',    '/buy',         0),
(now(),                 101, 'pageview', '/home',     1000),
(now(),                 102, 'pageview', '/pricing',  3100),
(now(),                 106, 'pageview', '/home',     1800),
(now(),                 106, 'click',    '/signup',      0),
(now(),                 107, 'pageview', '/docs',     5200),
(now(),                 108, 'pageview', '/home',     1250),
(now(),                 109, 'pageview', '/blog',     4400),
(now(),                 109, 'click',    '/buy',         0);
```

### Проверка данных

```sql
SELECT * FROM events;
```

## 📈 Аналитические запросы

### 1. DAU за сегодня

```sql
SELECT uniq(visitor_id) AS dau
FROM events
WHERE toDate(event_time) = today();
```

**Результат:**

| dau |
|-----|
| 6   |


### 2. Топ страниц по просмотрам

```sql
SELECT
    url,
    count()                 AS views,
    round(avg(duration_ms)) AS avg_duration_ms
FROM events
WHERE event_type = 'pageview'
GROUP BY url
ORDER BY views DESC
LIMIT 5;
```

**Результат:**

| url      | views | avg_duration_ms |
|----------|-------|-----------------|
| /home    | 13    | 1308            |
| /pricing | 6     | 3050            |
| /docs    | 4     | 5625            |
| /blog    | 4     | 4450            |

### 3. Динамика по дням

```sql
SELECT
    toDate(event_time) AS day,
    count()            AS total_events,
    uniq(visitor_id)   AS unique_visitors
FROM events
GROUP BY day
ORDER BY day;
```

**Результат:**

| day        | total_events | unique_visitors |
|------------|--------------|-----------------|
| 2026-10-04 | 9            | 5               |
| 2026-10-05 | 9            | 5               |
| 2026-10-06 | 9            | 6               |
| 2026-10-07 | 8            | 6               |

### 4. Воронка: просмотр → клик

```sql
SELECT
    event_type,
    count() AS total
FROM events
WHERE event_type IN ('pageview', 'click')
GROUP BY event_type
ORDER BY total DESC;
```

**Результат:**

| event_type | total |
|------------|-------|
| pageview   | 27    |
| click      | 8     |

**Конверсия:** `8 / 27 ≈ 30%`

### 5. Топ-5 посетителей по активности

```sql
SELECT
    visitor_id,
    count()                 AS events_count,
    round(avg(duration_ms)) AS avg_duration_ms
FROM events
GROUP BY visitor_id
ORDER BY events_count DESC
LIMIT 5;
```

**Результат:**

| visitor_id | events_count | avg_duration_ms |
|------------|--------------|-----------------|
| 101        | 7            | 1521            |
| 109        | 5            | 1880            |
| 102        | 4            | 3600            |
| 107        | 4            | 3600            |
| 108        | 4            | 1262            |


### 6. Retention

```sql
SELECT
    visitor_id,
    uniq(toDate(event_time)) AS active_days
FROM events
GROUP BY visitor_id
HAVING active_days > 1
ORDER BY active_days DESC;
```

**Результат:** 

| visitor_id | active_days |
|------------|-------------|
| 107        | 4           |
| 101        | 4           |
| 108        | 3           |
| 102        | 3           |
| 105        | 2           |
| 109        | 2           |
| 103        | 2           |


### 7. Средняя длительность по страницам

```sql
SELECT
    url,
    round(avg(duration_ms)) AS avg_duration_ms,
    count()                 AS views
FROM events
WHERE event_type = 'pageview'
GROUP BY url
HAVING views >= 3
ORDER BY avg_duration_ms DESC;
```

**Результат:**

| url      | avg_duration_ms | views |
|----------|-----------------|-------|
| /docs    | 5625            | 4     |
| /blog    | 4450            | 4     |
| /pricing | 3050            | 6     |
| /home    | 1308            | 13    |

## 📁 Структура проекта

```
clickhouse-web-analytics/
├── README.md
├── schema.sql        # CREATE TABLE
├── insert_data.sql   # INSERT
└── queries.sql       # аналитические запросы
```

## 📌 Что демонстрирует проект

- Понимание разницы между OLTP и OLAP (PostgreSQL vs ClickHouse).
- Навык проектирования схемы под аналитические нагрузки.
- Умение писать аналитические запросы на диалекте ClickHouse.
- Знание оптимизаций: партиционирование, `LowCardinality`, `ORDER BY` как индекс.
- Работа с продуктовыми метриками: DAU, воронка, retention, топы.

## 🔗 Интерактивная демонстрация

[Открыть в SQLize.online](https://sqlize.online/sql/clickhouse/53419c6ba7aca5f3d95736cf34936877)
