-- StaySense: Hotel Booking Analytics (MySQL)
-- Revenue queries exclude rows with adr = 0 or total_nights = 0

USE staysense;

-- ========== LeakGuard: revenue at risk from cancellations ==========

-- Overall
SELECT
    ROUND(SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END), 0) AS lost_revenue,
    ROUND(SUM(CASE WHEN is_canceled = 0 THEN total_revenue ELSE 0 END), 0) AS realized_revenue,
    ROUND(100 * SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END)
          / SUM(total_revenue), 1) AS pct_revenue_lost
FROM bookings
WHERE adr > 0 AND total_nights > 0;

-- By hotel type
SELECT hotel,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END), 0) AS revenue_at_risk,
       ROUND(100 * SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END)
             / SUM(total_revenue), 1) AS pct_at_risk
FROM bookings
WHERE adr > 0 AND total_nights > 0
GROUP BY hotel;

-- By market segment
SELECT market_segment,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END), 0) AS revenue_at_risk,
       ROUND(100 * SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END)
             / SUM(total_revenue), 1) AS pct_at_risk
FROM bookings
WHERE adr > 0 AND total_nights > 0
GROUP BY market_segment
ORDER BY revenue_at_risk DESC;

-- ========== LeadLens: cancellation rate by lead time ==========

SELECT lead_time_bucket,
       COUNT(*) AS bookings,
       ROUND(100 * AVG(is_canceled), 1) AS cancel_rate
FROM bookings
GROUP BY lead_time_bucket
ORDER BY MIN(lead_time);

-- Lead time effect within Online TA vs other segments
SELECT lead_time_bucket,
       CASE WHEN market_segment = 'Online TA' THEN 'Online TA' ELSE 'Other' END AS segment_group,
       COUNT(*) AS bookings,
       ROUND(100 * AVG(is_canceled), 1) AS cancel_rate
FROM bookings
GROUP BY lead_time_bucket, segment_group
ORDER BY segment_group, MIN(lead_time);

-- ========== OverbookIQ: monthly cancellation rate and suggested buffer ==========
-- Buffer = 50% of the cancellation rate (an assumed safety factor, not a validated model)

SELECT hotel,
       MONTH(arrival_date) AS month_num,
       COUNT(*) AS bookings,
       ROUND(100 * AVG(is_canceled), 1) AS cancel_rate,
       ROUND(100 * AVG(is_canceled) * 0.5, 1) AS suggested_overbook_pct
FROM bookings
GROUP BY hotel, MONTH(arrival_date)
ORDER BY hotel, month_num;