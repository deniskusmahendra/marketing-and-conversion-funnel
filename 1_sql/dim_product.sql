CREATE OR REPLACE TABLE
`project-3-500608.marketing_funnel_and_conversion_analysis.dim_product` AS

SELECT
    i.item_id,

    ANY_VALUE(i.item_name) AS item_name,

    ANY_VALUE(NULLIF(i.item_brand, '')) AS item_brand,

    ANY_VALUE(NULLIF(i.item_category, '')) AS item_category,

    ANY_VALUE(NULLIF(i.item_category2, '')) AS item_category2,

    ANY_VALUE(NULLIF(i.item_category3, '')) AS item_category3,

    ANY_VALUE(NULLIF(i.item_category4, '')) AS item_category4,

    ANY_VALUE(NULLIF(i.item_category5, '')) AS item_category5,

    ANY_VALUE(NULLIF(i.item_variant, '')) AS item_variant,

    MAX(i.price) AS price

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS i

WHERE
    i.item_id IS NOT NULL

GROUP BY
    i.item_id;