CREATE OR REPLACE TABLE
`project-3-500608.marketing_funnel_and_conversion_analysis.fact_product_funnel` AS

SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,

    i.item_id,

    COUNTIF(event_name = 'view_item') AS view_events,

    COUNT(DISTINCT IF(event_name = 'view_item', user_pseudo_id, NULL)) AS unique_viewers,

    COUNTIF(event_name = 'add_to_cart') AS add_to_cart_events,

    COUNTIF(event_name = 'begin_checkout') AS checkout_events,

    COUNTIF(event_name = 'purchase') AS purchase_events,

    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)) AS unique_buyers,

    SUM(IF(event_name = 'purchase', COALESCE(i.quantity, 0), 0)) AS units_sold,

    ROUND(
        SUM(IF(event_name = 'purchase', COALESCE(i.item_revenue, 0), 0)),
        2
    ) AS revenue

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
UNNEST(items) AS i

WHERE
    event_name IN (
        'view_item',
        'add_to_cart',
        'begin_checkout',
        'purchase'
    )
    AND i.item_id IS NOT NULL

GROUP BY
    event_date,
    i.item_id;