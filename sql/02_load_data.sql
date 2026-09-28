-- =====================================================================
-- Logistics Operations Database — Data Import
-- =====================================================================
-- Run 01_schema.sql first. Then edit the path below to point to your
-- local copy of the /data folder, and run this script.
--
-- IMPORTANT — before running, enable local file loading:
--   1) In MySQL Workbench: Edit > Preferences > SQL Editor >
--      check "Allow LOAD LOCAL INFILE", then reconnect.
--   2) On the server side, run once: SET GLOBAL local_infile = 1;
--   3) Replace the path below (must use forward slashes, even on
--      Windows), e.g. 'D:/Projects/logistics_ops/data/drivers.csv'
-- =====================================================================

USE logistics_ops;
SET FOREIGN_KEY_CHECKS = 0;   -- allow loading in convenient order, re-enabled at the end

SET @data_path = '   C:/path/to/your/data';  -- <-- EDIT THIS

-- 1. DRIVERS  (termination_date can be blank -> NULL)
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/drivers.csv'
INTO TABLE drivers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(driver_id, first_name, last_name, hire_date, @termination_date, license_number,
 license_state, date_of_birth, home_terminal, employment_status, cdl_class, years_experience)
SET termination_date = NULLIF(@termination_date, '');

-- 2. TRUCKS
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/trucks.csv'
INTO TABLE trucks
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(truck_id, unit_number, make, model_year, vin, acquisition_date, acquisition_mileage,
 fuel_type, tank_capacity_gallons, status, home_terminal);

-- 3. TRAILERS
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/trailers.csv'
INTO TABLE trailers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(trailer_id, trailer_number, trailer_type, length_feet, model_year, vin,
 acquisition_date, status, current_location);

-- 4. CUSTOMERS
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_name, customer_type, credit_terms_days, primary_freight_type,
 account_status, contract_start_date, annual_revenue_potential);

-- 5. FACILITIES
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/facilities.csv'
INTO TABLE facilities
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(facility_id, facility_name, facility_type, city, state, latitude, longitude,
 dock_doors, operating_hours);

-- 6. ROUTES
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/routes.csv'
INTO TABLE routes
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(route_id, origin_city, origin_state, destination_city, destination_state,
 typical_distance_miles, base_rate_per_mile, fuel_surcharge_rate, typical_transit_days);

-- 7. LOADS
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/loads.csv'
INTO TABLE loads
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(load_id, customer_id, route_id, load_date, load_type, weight_lbs, pieces,
 revenue, fuel_surcharge, accessorial_charges, load_status, booking_type);

-- 8. TRIPS  (driver_id / truck_id / trailer_id can be blank -> NULL)
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/trips.csv'
INTO TABLE trips
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(trip_id, load_id, @driver_id, @truck_id, @trailer_id, dispatch_date, actual_distance_miles,
 actual_duration_hours, fuel_gallons_used, average_mpg, idle_time_hours, trip_status)
SET driver_id  = NULLIF(@driver_id, ''),
    truck_id   = NULLIF(@truck_id, ''),
    trailer_id = NULLIF(@trailer_id, '');

-- 9. FUEL_PURCHASES  (truck_id / driver_id can be blank -> NULL)
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/fuel_purchases.csv'
INTO TABLE fuel_purchases
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(fuel_purchase_id, trip_id, @truck_id, @driver_id, purchase_date, location_city,
 location_state, gallons, price_per_gallon, total_cost, fuel_card_number)
SET truck_id  = NULLIF(@truck_id, ''),
    driver_id = NULLIF(@driver_id, '');

-- 10. MAINTENANCE_RECORDS
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/maintenance_records.csv'
INTO TABLE maintenance_records
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(maintenance_id, truck_id, maintenance_date, maintenance_type, odometer_reading,
 labor_hours, labor_cost, parts_cost, total_cost, facility_location, downtime_hours,
 service_description);

-- 11. DELIVERY_EVENTS  (on_time_flag is text 'True'/'False' -> boolean)
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/delivery_events.csv'
INTO TABLE delivery_events
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(event_id, load_id, trip_id, event_type, facility_id, scheduled_datetime, actual_datetime,
 detention_minutes, @on_time_flag, location_city, location_state)
SET on_time_flag = (@on_time_flag = 'True');

-- 12. SAFETY_INCIDENTS  (3 boolean text columns; truck_id/driver_id can be blank)
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/safety_incidents.csv'
INTO TABLE safety_incidents
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(incident_id, trip_id, @truck_id, @driver_id, incident_date, incident_type, location_city,
 location_state, @at_fault_flag, @injury_flag, vehicle_damage_cost, cargo_damage_cost,
 claim_amount, @preventable_flag, description)
SET truck_id         = NULLIF(@truck_id, ''),
    driver_id        = NULLIF(@driver_id, ''),
    at_fault_flag    = (@at_fault_flag = 'True'),
    injury_flag      = (@injury_flag = 'True'),
    preventable_flag = (@preventable_flag = 'True');

-- 13. DRIVER_MONTHLY_METRICS
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/driver_monthly_metrics.csv'
INTO TABLE driver_monthly_metrics
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(driver_id, month, trips_completed, total_miles, total_revenue, average_mpg,
 total_fuel_gallons, on_time_delivery_rate, average_idle_hours);

-- 14. TRUCK_UTILIZATION_METRICS
LOAD DATA LOCAL INFILE '   C:/path/to/your/data/truck_utilization_metrics.csv'
INTO TABLE truck_utilization_metrics
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(truck_id, month, trips_completed, total_miles, total_revenue, average_mpg,
 maintenance_events, maintenance_cost, downtime_hours, utilization_rate);

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------
-- Verification: row counts should match the source CSVs
-- ---------------------------------------------------------------
SELECT 'drivers' AS tbl, COUNT(*) AS row_count FROM drivers
UNION ALL SELECT 'trucks', COUNT(*) FROM trucks
UNION ALL SELECT 'trailers', COUNT(*) FROM trailers
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'facilities', COUNT(*) FROM facilities
UNION ALL SELECT 'routes', COUNT(*) FROM routes
UNION ALL SELECT 'loads', COUNT(*) FROM loads
UNION ALL SELECT 'trips', COUNT(*) FROM trips
UNION ALL SELECT 'fuel_purchases', COUNT(*) FROM fuel_purchases
UNION ALL SELECT 'maintenance_records', COUNT(*) FROM maintenance_records
UNION ALL SELECT 'delivery_events', COUNT(*) FROM delivery_events
UNION ALL SELECT 'safety_incidents', COUNT(*) FROM safety_incidents
UNION ALL SELECT 'driver_monthly_metrics', COUNT(*) FROM driver_monthly_metrics
UNION ALL SELECT 'truck_utilization_metrics', COUNT(*) FROM truck_utilization_metrics;

-- Expected counts:
-- drivers 150 | trucks 120 | trailers 180 | customers 200 | facilities 50 | routes 58
-- loads 85410 | trips 85410 | fuel_purchases 196442 | maintenance_records 2920
-- delivery_events 170820 | safety_incidents 170
-- driver_monthly_metrics 4464 | truck_utilization_metrics 3312
