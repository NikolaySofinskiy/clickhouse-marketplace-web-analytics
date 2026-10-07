-- 1. Создание таблицы
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