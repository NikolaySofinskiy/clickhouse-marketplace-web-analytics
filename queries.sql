-- 3. Проверка данных
SELECT * FROM events;

-- 4. DAU за сегодня
SELECT uniq(visitor_id) AS dau
FROM events
WHERE toDate(event_time) = today();

-- 5. Топ страниц по просмотрам
SELECT
    url,
    count()                 AS views,
    round(avg(duration_ms)) AS avg_duration_ms
FROM events
WHERE event_type = 'pageview'
GROUP BY url
ORDER BY views DESC
LIMIT 5;

-- 6. Динамика по дням
SELECT
    toDate(event_time) AS day,
    count()            AS total_events,
    uniq(visitor_id)   AS unique_visitors
FROM events
GROUP BY day
ORDER BY day;

-- 7. Воронка: просмотр → клик
SELECT
    event_type,
    count() AS total
FROM events
WHERE event_type IN ('pageview', 'click')
GROUP BY event_type
ORDER BY total DESC;

-- 8. Топ-5 посетителей по активности
SELECT
    visitor_id,
    count()                 AS events_count,
    round(avg(duration_ms)) AS avg_duration_ms
FROM events
GROUP BY visitor_id
ORDER BY events_count DESC
LIMIT 5;

-- 9. Retention
SELECT
    visitor_id,
    uniq(toDate(event_time)) AS active_days
FROM events
GROUP BY visitor_id
HAVING active_days > 1
ORDER BY active_days DESC;

-- 10. Средняя длительность по страницам
SELECT
    url,
    round(avg(duration_ms)) AS avg_duration_ms,
    count()                 AS views
FROM events
WHERE event_type = 'pageview'
GROUP BY url
HAVING views >= 3
ORDER BY avg_duration_ms DESC;