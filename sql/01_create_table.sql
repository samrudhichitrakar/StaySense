CREATE DATABASE staysense;
USE staysense;

CREATE TABLE bookings (
    hotel VARCHAR(20),
    is_canceled TINYINT,
    lead_time INT,
    arrival_date_year INT,
    arrival_date_month VARCHAR(15),
    arrival_date_week_number INT,
    arrival_date_day_of_month INT,
    stays_in_weekend_nights INT,
    stays_in_week_nights INT,
    adults INT,
    children INT,
    babies INT,
    meal VARCHAR(15),
    country VARCHAR(15),
    market_segment VARCHAR(25),
    distribution_channel VARCHAR(25),
    is_repeated_guest TINYINT,
    previous_cancellations INT,
    previous_bookings_not_canceled INT,
    reserved_room_type VARCHAR(5),
    assigned_room_type VARCHAR(5),
    booking_changes INT,
    deposit_type VARCHAR(20),
    agent INT,
    days_in_waiting_list INT,
    customer_type VARCHAR(25),
    adr DECIMAL(10,2),
    required_car_parking_spaces INT,
    total_of_special_requests INT,
    reservation_status VARCHAR(20),
    reservation_status_date DATE,
    has_revenue TINYINT,
    total_nights INT,
    total_revenue DECIMAL(12,2),
    arrival_date DATE,
    lead_time_bucket VARCHAR(10)
);

SELECT COUNT(*) FROM staysense.bookings;
SELECT ROUND(AVG(is_canceled)*100, 1) FROM staysense.bookings;    
SELECT * FROM staysense.bookings LIMIT 5;

SELECT COUNT(*) AS zero_night_bookings,
       ROUND(AVG(is_canceled)*100, 1) AS cancel_rate
FROM staysense.bookings
WHERE total_nights = 0;


SELECT
    ROUND(SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END), 0) AS lost_revenue,
    ROUND(SUM(CASE WHEN is_canceled = 0 THEN total_revenue ELSE 0 END), 0) AS realized_revenue,
    ROUND(100 * SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END)
          / SUM(total_revenue), 1) AS pct_revenue_lost
FROM staysense.bookings
WHERE adr > 0 AND total_nights > 0;

-- By hotel type
SELECT hotel,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END), 0) AS revenue_at_risk,
       ROUND(100 * SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END)
             / SUM(total_revenue), 1) AS pct_at_risk
FROM staysense.bookings
WHERE adr > 0 AND total_nights > 0
GROUP BY hotel;

-- By market segment
SELECT market_segment,
       ROUND(SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END), 0) AS revenue_at_risk,
       ROUND(100 * SUM(CASE WHEN is_canceled = 1 THEN total_revenue ELSE 0 END)
             / SUM(total_revenue), 1) AS pct_at_risk
FROM staysense.bookings
WHERE adr > 0 AND total_nights > 0
GROUP BY market_segment
ORDER BY revenue_at_risk DESC;

SELECT lead_time_bucket,
       COUNT(*) AS bookings,
       ROUND(100 * AVG(is_canceled), 1) AS cancel_rate
FROM staysense.bookings
GROUP BY lead_time_bucket
ORDER BY MIN(lead_time);

SELECT lead_time_bucket,
       CASE WHEN market_segment = 'Online TA' THEN 'Online TA' ELSE 'Other' END AS segment_group,
       COUNT(*) AS bookings,
       ROUND(100 * AVG(is_canceled), 1) AS cancel_rate
FROM staysense.bookings
GROUP BY lead_time_bucket, segment_group
ORDER BY segment_group, MIN(lead_time);

SELECT hotel,
       MONTH(arrival_date) AS month_num,
       COUNT(*) AS bookings,
       ROUND(100 * AVG(is_canceled), 1) AS cancel_rate,
       ROUND(100 * AVG(is_canceled) * 0.5, 1) AS suggested_overbook_pct
FROM staysense.bookings
GROUP BY hotel, MONTH(arrival_date)
ORDER BY hotel, month_num;