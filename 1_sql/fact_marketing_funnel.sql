CREATE OR REPLACE TABLE
`project-3-500608.marketing_funnel_and_conversion_analysis.fact_marketing_funnel` AS

SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,

    COALESCE(NULLIF(traffic_source.source, ''), '(direct)') AS source,

    COALESCE(NULLIF(traffic_source.medium, ''), '(none)') AS medium,

    COALESCE(NULLIF(traffic_source.name, ''), '(not set)') AS campaign,

    device.category AS device_category,

    COUNT(DISTINCT user_pseudo_id) AS users,

    COUNT(DISTINCT IF(event_name = 'session_start', user_pseudo_id, NULL)) AS sessions,

    COUNT(DISTINCT IF(event_name = 'view_item', user_pseudo_id, NULL)) AS view_item_users,

    COUNT(DISTINCT IF(event_name = 'add_to_cart', user_pseudo_id, NULL)) AS add_to_cart_users,

    COUNT(DISTINCT IF(event_name = 'begin_checkout', user_pseudo_id, NULL)) AS checkout_users,

    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)) AS purchasers,

    COUNTIF(event_name = 'purchase') AS purchase_events,

    ROUND(
        SUM(
            IF(event_name = 'purchase',
               COALESCE(ecommerce.purchase_revenue, 0),
               0)
        ),
        2
    ) AS revenue

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

GROUP BY
    event_date,
    source,
    medium,
    campaign,
    device_category;