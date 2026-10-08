-- ============================================
-- 4. АНАЛИТИЧЕСКИЕ ЗАПРОСЫ
-- ============================================

-- 4.1. DAU за последний день
SELECT uniq(visitor_id) AS dau
FROM events
WHERE toDate(event_time) = '2026-09-07';

-- 4.2. Топ страниц по просмотрам
SELECT
    url,
    count()                 AS views,
    round(avg(duration_ms)) AS avg_duration_ms
FROM events
WHERE event_type = 'pageview'
GROUP BY url
ORDER BY views DESC
LIMIT 5;

-- 4.3. Динамика по дням
SELECT
    toDate(event_time) AS day,
    count()            AS total_events,
    uniq(visitor_id)   AS unique_visitors
FROM events
GROUP BY day
ORDER BY day;

-- 4.4. Воронка покупки
SELECT
    event_type,
    count()          AS total,
    uniq(visitor_id) AS unique_visitors
FROM events
WHERE event_type IN ('pageview', 'product_view', 'add_to_cart', 'checkout', 'purchase')
GROUP BY event_type
ORDER BY total DESC;

-- 4.5. Топ-5 посетителей по активности
SELECT
    visitor_id,
    count()                 AS events_count,
    round(avg(duration_ms)) AS avg_duration_ms
FROM events
GROUP BY visitor_id
ORDER BY events_count DESC
LIMIT 5;

-- 4.6. Retention
SELECT
    visitor_id,
    uniq(toDate(event_time)) AS active_days
FROM events
GROUP BY visitor_id
HAVING active_days > 1
ORDER BY active_days DESC;

-- 4.7. Средняя длительность по страницам
SELECT
    url,
    round(avg(duration_ms)) AS avg_duration_ms,
    count()                 AS views
FROM events
WHERE event_type = 'pageview'
GROUP BY url
HAVING views >= 2
ORDER BY avg_duration_ms DESC;

-- 4.8. Пользователи, дошедшие до покупки
SELECT
    visitor_id,
    countIf(event_type = 'product_view') AS product_views,
    countIf(event_type = 'add_to_cart')  AS add_to_cart,
    countIf(event_type = 'checkout')     AS checkouts,
    countIf(event_type = 'purchase')     AS purchases
FROM events
GROUP BY visitor_id
HAVING purchases > 0
ORDER BY purchases DESC;

-- 4.9. Просмотры товаров с названием и категорией (JOIN)
SELECT
    e.visitor_id,
    p.product_name,
    p.category,
    p.price,
    e.event_time
FROM events e
JOIN products p ON e.product_id = p.product_id
WHERE e.event_type = 'product_view'
ORDER BY e.event_time
LIMIT 10;

-- 4.10. Топ категорий по просмотрам товаров (JOIN + GROUP BY)
SELECT
    p.category,
    count()             AS product_views,
    uniq(e.visitor_id)  AS unique_visitors,
    round(avg(p.price)) AS avg_price
FROM events e
JOIN products p ON e.product_id = p.product_id
WHERE e.event_type = 'product_view'
GROUP BY p.category
ORDER BY product_views DESC;

-- 4.11. Воронка по категориям (JOIN + условные агрегации)
SELECT
    p.category,
    countIf(e.event_type = 'product_view') AS product_views,
    countIf(e.event_type = 'add_to_cart')  AS add_to_cart,
    countIf(e.event_type = 'purchase')     AS purchases
FROM events e
JOIN products p ON e.product_id = p.product_id
GROUP BY p.category
ORDER BY product_views DESC;