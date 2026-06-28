# E-Commerce Marketing & Product Conversion Funnel Analysis (GA4)

## Introduction
This project focuses on **analyzing user clickstream data** from the official Google Merchandise Store GA4 public dataset in BigQuery. By examining user behavior across the digital retail environment, this project **maps out top-of-funnel acquisition mechanics and bottom-of-funnel e-commerce leaks**.

## Background
In modern digital retail, static sales charts do not tell the full story. Understanding the complete path to purchase—from initial web acquisition channels to granular product page merchandising—is critical for modern conversion rate optimization (CRO). 

This analysis solves three fundamental business gaps:
1. **Friction Identification:** Identifying exactly where potential customers drop out of the purchase process.
2. **Traffic Source Optimization:** Quantifying which marketing campaigns and platforms bring the highest volume of value-generating sessions.
3. **Merchandising Performance Evaluation:** Isolating individual products that possess high purchase intent but suffer from a broken checkout experience.

## Tools I Used
* **Google Cloud BigQuery:** Engineered backend tables, extracted event metadata parameters, and handled high-velocity JSON records using explicit `UNNEST(items)` array joins.
* **Power BI Desktop:** Implemented analytical star schemas, authored performance ratio measures via DAX, and developed high-fidelity layout containers.
* **SQL:** Handled conditional aggregations (`COUNT(DISTINCT CASE WHEN)`), session window logic, and data cleansing.

## The Analysis

### 1. Macro Marketing Funnel & Traffic Slicing

<p align="center">
  <img src="2_outputs/images/Page%201%20(Marketing%20Performance).png" width="80%">
</p>

At the macroscopic level (Page 1: Marketing Performance), the entire storefront captured **353K Total Users** generating **347K Total Sessions** and **$362K in Total Revenue**. 
* **Funnel Stages Explored:** Sessions (346.9K) → Product Views (76.4K) → Add to Cart (15.1K) → Checkout (11.1K) → Purchase (4.8K).
* **Device Traffic Behavior:** A severe volume division exists between device archetypes. **Desktop traffic** vastly dominates storefront engagement with **201K sessions**, compared to **Mobile at 138K sessions** and **Tablet at a nominal 8K sessions**.

<details>
<summary><b>Click to View SQL: Fact Marketing Table (BigQuery)</b></summary>

```sql
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
```

</details>

### 2. Micro Product Conversion Architecture

<p align="center">
  <img src="2_outputs/images/Page%202%20(Product%20Conversion%20Performance).png" width="80%">
</p>

Looking into the itemized layer (Page 2: Product Conversion Performance), individual interactions reveal that raw click traffic does not scale equally to purchases across specific SKUs. Metrics tracked include raw `View Events`, item-level conversion rates (`Add to Cart %`, `Checkout %`, `Purchase %`), and net `Total Revenue`.

<details>
<summary><b>Click to View SQL: Fact Product Table (BigQuery)</b></summary>

```sql
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
```

</details>

## What I Learned
* **Advanced Nested Data Engineering:** GA4 natively logs telemetry as structured nested JSON objects. This project forced me to move past flat datasets and conquer complex cloud workflows using `CROSS JOIN UNNEST(items)` to flatten product variables for aggregation.
* **Contextual E-Commerce Performance Logic:** Developed distinct understanding of critical transactional ratios, specifically separating user-level metrics from repeated session event parameters.
* **Cohesive Executive Interface Design:** Practiced professional dashboard UI/UX patterns, prioritizing explicit margins, visual hierarchies, contextual grouping labels, and dynamic page navigation links (`Go to Product Page` / `Back to Marketing Page`).

## Insight

### Insight 1: The Macro Funnel Leaking Chasm
A stark structural friction point exists at the very top of the conversion tunnel. Across the site, **only 22.02% of users entering a session successfully view an item** (76.4K / 346.9K). Once a customer actually reads a product detail page, the drop-off stabilizes significantly (an impressive **73.5% checkout-to-purchase completion velocity**). This highlights that the ultimate friction point is not the checkout form itself, but early-stage product discovery and site engagement.

### Insight 2: Device-Specific Conversion Divergence
Slicing the macro performance metrics by device categories exposes an immense operational divergence:
* **Desktop Performance:** Captures **205K Users**, converting at **1.34%**, yielding a total of **$209K in Revenue**.
* **Mobile Performance:** Captures **140K Users** with an elevated conversion efficiency of **1.42%**, generating **$147K in Revenue**. 
* **Takeaway:** Mobile users buy at an equal or higher rate once in the funnel. However, because Desktop drives more baseline traffic, it acts as the current revenue anchor.

### Insight 3: Unattributed Revenue Dependency & Channel Discrepancies
When isolating individual traffic streams, massive hidden channel dynamics appear:
* **Unattributed / Direct Traffic:** Stands as the single largest financial driver on the site, yielding **$131K in Revenue**.
* **Google (Organic Search):** Acts as the highest explicit user acquisition engine with **120K Users**, delivering **$105K in Revenue**.
* **The Performance Flaw (Merchandise Store/Referral):** While Referral paths generate a tight macro conversion rate of **2.08%** (delivering **$47K in Revenue**), it suffers from highly restricted traffic scale (**only 28K users** total).

### Insight 4: Product Merchandising Outliers & Anomalies
Granular cross-filtering on the product matrix catches notable performance anomalies:
* **The High-Volume Anchor (Navy Speckled Tee / Zip Hoodie F/C):** The `Navy Speckled Tee` sits at the top of engagement with **56,466 View Events** transforming into **$4,440 in Revenue** at a modest **0.28% Purchase Rate**. Conversely, the `Zip Hoodie F/C` acts as a high-value converter, processing **49,795 View Events** into **$13,788 in Revenue** with an efficient **26.13% Add to Cart Rate**.
* **The Broken Tracking Bug (Noogler Figure):** Under the `Home` category filter, the `Noogler Figure` displays completely impossible tracking data: **1 View Event** resulting in an aggregated **18,600% Add to Cart Rate** and **10,700% Purchase Rate** ($2,016 in Revenue). In a live corporate data environment, this immediately surfaces a breaking tracking configuration error or a duplicated click tag firing on that specific SKU page.
* **The Low-Intent Abandonment (Gift Cards):** Item records like `Gift Card - $100.00` demonstrate highly abnormal customer pathways, logging inflated conversion jumps (**116.67% Add to Cart** and **844.44% Checkout**) but failing to match that momentum into terminal purchases.

## Conclusions
1. **Re-engineer the Discovery Layer:** To capture the missing traffic lost between session starts and product views, optimization resources should immediately pivot to landing page UI clarity, search bar discoverability, and initial page speed loading times.
2. **Audit Tracking Pipelines:** Deploy an analytics engineering fix to debug the event tags tied to the `Noogler Figure` and alternative merchandise objects showing inflated percentages above 100%.
3. **Scale Referral & Mobile Momentum:** Because mobile visitors and referral channels demonstrate strong baseline conversion rates (1.42% and 2.08% respectively), the company should re-allocate marketing spend away from low-converting segments to aggressively fund targeted mobile social and affiliate placement campaigns.