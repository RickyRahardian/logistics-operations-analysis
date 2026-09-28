-- =====================================================================
-- Logistics Operations Database — Business Analysis Queries
-- Run after 01_schema.sql and 02_load_data.sql
-- Organized by the 8 analytical use cases in DATABASE_SCHEMA.txt
-- =====================================================================
USE logistics_ops;

-- =====================================================================
-- 1. DRIVER PERFORMANCE — on-time rate, MPG, revenue per mile
-- =====================================================================

-- 1a. Overall leaderboard: revenue per mile, MPG (Mile per Galon), on-time rate per driver
SELECT
	d.driver_id,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    d.years_experience,
    COUNT(DISTINCT t.trip_id) AS total_trips,
    SUM(t.actual_distance_miles) as total_miles,
    ROUND(AVG(t.average_mpg), 2) AS avg_mpg,
    ROUND(SUM(l.revenue) / NULLIF(SUM(actual_distance_miles), 0), 2) AS revenue_per_mile
FROM trips t
JOIN drivers d ON d.driver_id = t.driver_id
JOIN loads l ON l.load_id = t.load_id
GROUP BY d.driver_id, driver_name, d.years_experience
ORDER BY revenue_per_mile DESC
LIMIT 20;


-- 1b. On-time delivery rate per driver (from delivery_events, via trips)
SELECT
    d.driver_id,
    CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    COUNT(de.event_id) AS total_events,
    SUM(CASE WHEN de.on_time_flag THEN 1 ELSE 0 END) AS on_time_events,
    ROUND(SUM(CASE WHEN de.on_time_flag THEN 1 ELSE 0 END) / COUNT(de.event_id), 3) AS on_time_rate
FROM delivery_events de
JOIN trips t   ON t.trip_id = de.trip_id
JOIN drivers d ON d.driver_id = t.driver_id
GROUP BY d.driver_id, driver_name
HAVING total_events >= 20
ORDER BY on_time_rate DESC
LIMIT 20;

-- 1c. Monthly trend for a given driver (SWAP DRIVER ID IF YOU NEED IT)
SELECT 
	month, trips_completed, total_miles, total_revenue, average_mpg, on_time_delivery_rate
FROM driver_monthly_metricsdriver_monthly_metrics
WHERE driver_id = 'DRV00001'
ORDER BY month;


-- =====================================================================
-- 2. ROUTE PROFITABILITY — revenue vs. cost by lane
-- =====================================================================

-- 2a. Revenue, fuel cost and margin per route
SELECT
    r.route_id,
    CONCAT(r.origin_city, ', ', r.origin_state, ' -> ', r.destination_city, ', ', r.destination_state) AS lane,
    r.typical_distance_miles,
    COUNT(l.load_id) AS total_loads,
    ROUND(SUM(l.revenue), 2) AS total_revenue,
    ROUND(SUM(fp.total_cost), 2) AS total_fuel_cost,
    ROUND(SUM(l.revenue) - SUM(fp.total_cost), 2) AS gross_margin,
    ROUND(SUM(l.revenue) / NULLIF(SUM(t.actual_distance_miles), 0), 2) AS revenue_per_mile
FROM routes r
JOIN loads l ON l.route_id = r.route_id
JOIN trips t ON t.load_id  = l.load_id
LEFT JOIN fuel_purchases fp ON fp.trip_id = t.trip_id
GROUP BY r.route_id, lane, r.typical_distance_miles
ORDER BY total_revenue DESC
LIMIT 20;

-- 2b. Least profitable lanes (lowest revenue per mile, min 100 loads)
SELECT
    r.route_id,
    CONCAT(r.origin_city, ' -> ', r.destination_city) AS lane,
    COUNT(l.load_id) AS total_loads,
    ROUND(SUM(l.revenue) / NULLIF(SUM(t.actual_distance_miles), 0), 2) AS revenue_per_mile
FROM routes r
JOIN loads l  ON l.route_id = r.route_id
JOIN trips t  ON t.load_id  = l.load_id
GROUP BY r.route_id, lane
HAVING total_loads >= 100
ORDER BY revenue_per_mile ASC
LIMIT 10;


-- =====================================================================
-- 3. FLEET UTILIZATION — miles per truck, revenue per asset
-- =====================================================================

-- 3a. Utilization ranking per truck (lifetime)
SELECT
    tr.truck_id, tr.make, tr.model_year, tr.status,
    COUNT(t.trip_id) AS total_trips,
    SUM(t.actual_distance_miles) AS total_miles,
    ROUND(SUM(l.revenue), 2) AS total_revenue,
    ROUND(SUM(l.revenue) / NULLIF(SUM(t.actual_distance_miles), 0), 2) AS revenue_per_mile
FROM trucks tr
JOIN trips t ON t.truck_id = tr.truck_id
JOIN loads l ON l.load_id  = t.load_id
GROUP BY tr.truck_id, tr.make, tr.model_year, tr.status
ORDER BY total_revenue DESC
LIMIT 20;

-- 3b. Average monthly utilization rate by truck (from aggregated table)
SELECT
    truck_id,
    ROUND(AVG(utilization_rate), 3) AS avg_utilization_rate,
    ROUND(AVG(total_miles), 0) AS avg_monthly_miles,
    ROUND(AVG(total_revenue), 2) AS avg_monthly_revenue
FROM truck_utilization_metrics
GROUP BY truck_id
ORDER BY avg_utilization_rate DESC
LIMIT 20;


-- =====================================================================
-- 4. MAINTENANCE ANALYSIS — cost per mile, downtime impact
-- =====================================================================

-- 4a. Total maintenance cost & downtime per truck vs. miles driven
SELECT
    tr.truck_id,
    SUM(m.total_cost) AS total_maintenance_cost,
    SUM(m.downtime_hours) AS total_downtime_hours,
    COALESCE(mi.lifetime_miles, 0) AS lifetime_miles,
    ROUND(SUM(m.total_cost) / NULLIF(mi.lifetime_miles, 0), 4) AS maintenance_cost_per_mile
FROM trucks tr
JOIN maintenance_records m ON m.truck_id = tr.truck_id
LEFT JOIN (
    SELECT truck_id, SUM(actual_distance_miles) AS lifetime_miles
    FROM trips
    GROUP BY truck_id
) mi ON mi.truck_id = tr.truck_id
GROUP BY tr.truck_id, mi.lifetime_miles
ORDER BY maintenance_cost_per_mile DESC
LIMIT 20;

-- 4b. Cost by maintenance type
SELECT
    maintenance_type,
    COUNT(*) AS num_events,
    ROUND(SUM(total_cost), 2) AS total_cost,
    ROUND(AVG(total_cost), 2) AS avg_cost_per_event,
    ROUND(AVG(downtime_hours), 2) AS avg_downtime_hours
FROM maintenance_records
GROUP BY maintenance_type
ORDER BY total_cost DESC;


-- =====================================================================
-- 5. FUEL EFFICIENCY — MPG trends, fuel cost by route
-- =====================================================================

-- 5a. Monthly average MPG and total fuel cost across the fleet
SELECT
    DATE_FORMAT(t.dispatch_date, '%Y-%m') AS month,
    ROUND(AVG(t.average_mpg), 2) AS avg_mpg,
    ROUND(SUM(fp.total_cost), 2) AS total_fuel_cost,
    ROUND(SUM(fp.gallons), 2) AS total_gallons
FROM trips t
LEFT JOIN fuel_purchases fp ON fp.trip_id = t.trip_id
GROUP BY month
ORDER BY month;

-- 5b. Average fuel price paid by state (spot for regional price differences)
SELECT
    location_state,
    COUNT(*) AS num_purchases,
    ROUND(AVG(price_per_gallon), 3) AS avg_price_per_gallon,
    ROUND(SUM(total_cost), 2) AS total_spent
FROM fuel_purchases
GROUP BY location_state
ORDER BY avg_price_per_gallon DESC
LIMIT 15;


-- =====================================================================
-- 6. CUSTOMER ANALYSIS — revenue by customer, service levels
-- =====================================================================

-- 6a. Top customers by revenue and on-time service rate
SELECT
    c.customer_id, c.customer_name, c.customer_type, c.account_status,
    COUNT(l.load_id) AS total_loads,
    ROUND(SUM(l.revenue), 2) AS total_revenue,
    ROUND(AVG(de.on_time_events_rate), 3) AS avg_on_time_rate
FROM customers c
JOIN loads l ON l.customer_id = c.customer_id
LEFT JOIN (
    SELECT load_id, AVG(CASE WHEN on_time_flag THEN 1 ELSE 0 END) AS on_time_events_rate
    FROM delivery_events
    GROUP BY load_id
) de ON de.load_id = l.load_id
GROUP BY c.customer_id, c.customer_name, c.customer_type, c.account_status
ORDER BY total_revenue DESC
LIMIT 20;

-- 6b. Revenue by customer type and freight type
SELECT
    customer_type, primary_freight_type,
    COUNT(DISTINCT c.customer_id) AS num_customers,
    ROUND(SUM(l.revenue), 2) AS total_revenue
FROM customers c
JOIN loads l ON l.customer_id = c.customer_id
GROUP BY customer_type, primary_freight_type
ORDER BY total_revenue DESC;


-- =====================================================================
-- 7. SAFETY METRICS — incident rates, preventable accidents
-- =====================================================================

-- 7a. Incident count and cost per driver
SELECT
    d.driver_id, CONCAT(d.first_name, ' ', d.last_name) AS driver_name,
    COUNT(si.incident_id) AS total_incidents,
    SUM(CASE WHEN si.preventable_flag THEN 1 ELSE 0 END) AS preventable_incidents,
    SUM(CASE WHEN si.injury_flag THEN 1 ELSE 0 END) AS injury_incidents,
    ROUND(SUM(si.claim_amount), 2) AS total_claim_amount
FROM safety_incidents si
JOIN drivers d ON d.driver_id = si.driver_id
GROUP BY d.driver_id, driver_name
ORDER BY total_incidents DESC
LIMIT 20;

-- 7b. Incident rate per 100,000 miles driven, fleet-wide
SELECT
    ROUND(COUNT(si.incident_id) / (SUM(t.actual_distance_miles) / 100000), 3) AS incidents_per_100k_miles,
    SUM(CASE WHEN si.preventable_flag THEN 1 ELSE 0 END) AS preventable_incidents,
    COUNT(si.incident_id) AS total_incidents
FROM trips t
LEFT JOIN safety_incidents si ON si.trip_id = t.trip_id;

-- 7c. Incident type breakdown
SELECT incident_type, COUNT(*) AS num_incidents, ROUND(AVG(claim_amount), 2) AS avg_claim,
       ROUND(SUM(claim_amount), 2) AS total_claim
FROM safety_incidents
GROUP BY incident_type
ORDER BY total_claim DESC;


-- =====================================================================
-- 8. SEASONAL PATTERNS — load volume, rate fluctuations
-- =====================================================================

-- 8a. Monthly load volume and revenue trend (2022-2024)
SELECT
    DATE_FORMAT(load_date, '%Y-%m') AS month,
    COUNT(*) AS load_count,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_revenue_per_load
FROM loads
GROUP BY month
ORDER BY month;

-- 8b. Seasonality by calendar month (averaged across the 3 years)
SELECT
    MONTH(load_date) AS calendar_month,
    ROUND(AVG(revenue), 2) AS avg_revenue_per_load,
    COUNT(*) AS total_loads
FROM loads
GROUP BY calendar_month
ORDER BY calendar_month;

-- 8c. Year-over-year growth in load volume and revenue
SELECT
    YEAR(load_date) AS yr,
    COUNT(*) AS load_count,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM loads
GROUP BY yr
ORDER BY yr;
