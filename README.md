# ClickHouse Web Analytics Demo

Демо-проект на ClickHouse: схема с MergeTree, аналитические запросы, расчёт продуктовых метрик.

## 🛠️ Технологии

- ClickHouse (движок MergeTree, LowCardinality, партиционирование)
- SQL (агрегации, работа с датами, функции ClickHouse)

## 📊 Схема данных

Таблица `events` хранит логи веб-трафика.

| Колонка       | Тип                    | Описание                        |
|---------------|------------------------|---------------------------------|
| event_time    | DateTime               | Время события                   |
| visitor_id    | UInt64                 | ID посетителя                   |
| event_type    | LowCardinality(String) | Тип события (`pageview`/`click`)|
| url           | String                 | URL страницы                    |
| duration_ms   | UInt32                 | Длительность в миллисекундах    |

### Особенности схемы

- **`PARTITION BY toYYYYMM(event_time)`** — партиционирование по месяцам ускоряет запросы с фильтром по дате.
- **`ORDER BY (event_time, visitor_id)`** — сортировка внутри партиции работает как индекс.
- **`LowCardinality(String)`** — оптимизация для колонки с малым числом уникальных значений.

---

## 🚀 Запуск проекта

Все шаги выполняются в [SQLize.online — ClickHouse](https://sqlize.online/sql/clickhouse/).

### Шаг 1. Создание таблицы

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
