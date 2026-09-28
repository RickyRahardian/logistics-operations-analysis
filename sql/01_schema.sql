-- =====================================================================
-- Logistics Operations Database — Schema (DDL)
-- 3-Year Trucking Operations Dataset (2022-2024)
-- =====================================================================
-- Run this first to create the database and all 14 tables with
-- primary keys, foreign keys, and indexes on the columns most used
-- for joins/filtering in the analysis queries.
-- =====================================================================

DROP DATABASE IF EXISTS logistics_ops;
CREATE DATABASE logistics_ops CHARACTER SET utf8mb4;
USE logistics_ops;

-- ---------------------------------------------------------------
-- 1. DRIVERS
-- ---------------------------------------------------------------
CREATE TABLE drivers (
    driver_id           VARCHAR(10)  PRIMARY KEY,
    first_name          VARCHAR(50),
    last_name           VARCHAR(50),
    hire_date           DATE,
    termination_date    DATE NULL,
    license_number      VARCHAR(20),
    license_state       VARCHAR(2),
    date_of_birth       DATE,
    home_terminal       VARCHAR(50),
    employment_status   VARCHAR(20),
    cdl_class           VARCHAR(5),
    years_experience    INT
);

-- ---------------------------------------------------------------
-- 2. TRUCKS
-- ---------------------------------------------------------------
CREATE TABLE trucks (
    truck_id                VARCHAR(10) PRIMARY KEY,
    unit_number             INT,
    make                    VARCHAR(30),
    model_year              INT,
    vin                     VARCHAR(20),
    acquisition_date        DATE,
    acquisition_mileage     INT,
    fuel_type               VARCHAR(20),
    tank_capacity_gallons   INT,
    status                  VARCHAR(20),
    home_terminal           VARCHAR(50)
);

-- ---------------------------------------------------------------
-- 3. TRAILERS
-- ---------------------------------------------------------------
CREATE TABLE trailers (
    trailer_id          VARCHAR(10) PRIMARY KEY,
    trailer_number       INT,
    trailer_type         VARCHAR(30),
    length_feet          INT,
    model_year           INT,
    vin                  VARCHAR(20),
    acquisition_date     DATE,
    status               VARCHAR(20),
    current_location     VARCHAR(50)
);

-- ---------------------------------------------------------------
-- 4. CUSTOMERS
-- ---------------------------------------------------------------
CREATE TABLE customers (
    customer_id                VARCHAR(10) PRIMARY KEY,
    customer_name               VARCHAR(100),
    customer_type                VARCHAR(30),
    credit_terms_days            INT,
    primary_freight_type         VARCHAR(30),
    account_status                VARCHAR(20),
    contract_start_date          DATE,
    annual_revenue_potential      DECIMAL(12,2)
);

-- ---------------------------------------------------------------
-- 5. FACILITIES
-- ---------------------------------------------------------------
CREATE TABLE facilities (
    facility_id        VARCHAR(10) PRIMARY KEY,
    facility_name       VARCHAR(100),
    facility_type        VARCHAR(30),
    city                 VARCHAR(50),
    state                VARCHAR(2),
    latitude             DECIMAL(9,6),
    longitude            DECIMAL(9,6),
    dock_doors           INT,
    operating_hours      VARCHAR(20)
);

-- ---------------------------------------------------------------
-- 6. ROUTES
-- ---------------------------------------------------------------
CREATE TABLE routes (
    route_id                VARCHAR(10) PRIMARY KEY,
    origin_city              VARCHAR(50),
    origin_state             VARCHAR(2),
    destination_city         VARCHAR(50),
    destination_state        VARCHAR(2),
    typical_distance_miles   INT,
    base_rate_per_mile       DECIMAL(6,2),
    fuel_surcharge_rate      DECIMAL(6,3),
    typical_transit_days     INT
);

-- ---------------------------------------------------------------
-- 7. LOADS  (FK: customer_id, route_id)
-- ---------------------------------------------------------------
CREATE TABLE loads (
    load_id                VARCHAR(12) PRIMARY KEY,
    customer_id             VARCHAR(10),
    route_id                VARCHAR(10),
    load_date               DATE,
    load_type               VARCHAR(30),
    weight_lbs              INT,
    pieces                  INT,
    revenue                 DECIMAL(10,2),
    fuel_surcharge          DECIMAL(10,2),
    accessorial_charges     DECIMAL(10,2),
    load_status             VARCHAR(20),
    booking_type            VARCHAR(20),
    CONSTRAINT fk_loads_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_loads_route    FOREIGN KEY (route_id)    REFERENCES routes(route_id)
);

-- ---------------------------------------------------------------
-- 8. TRIPS  (FK: load_id, driver_id, truck_id, trailer_id)
-- ---------------------------------------------------------------
CREATE TABLE trips (
    trip_id                 VARCHAR(12) PRIMARY KEY,
    load_id                 VARCHAR(12),
    driver_id               VARCHAR(10) NULL,
    truck_id                VARCHAR(10) NULL,
    trailer_id              VARCHAR(10) NULL,
    dispatch_date           DATE,
    actual_distance_miles   INT,
    actual_duration_hours   DECIMAL(6,2),
    fuel_gallons_used       DECIMAL(8,2),
    average_mpg             DECIMAL(5,2),
    idle_time_hours         DECIMAL(6,2),
    trip_status             VARCHAR(20),
    CONSTRAINT fk_trips_load    FOREIGN KEY (load_id)    REFERENCES loads(load_id),
    CONSTRAINT fk_trips_driver  FOREIGN KEY (driver_id)  REFERENCES drivers(driver_id),
    CONSTRAINT fk_trips_truck   FOREIGN KEY (truck_id)   REFERENCES trucks(truck_id),
    CONSTRAINT fk_trips_trailer FOREIGN KEY (trailer_id) REFERENCES trailers(trailer_id)
);

-- ---------------------------------------------------------------
-- 9. FUEL_PURCHASES  (FK: trip_id, truck_id, driver_id)
-- ---------------------------------------------------------------
CREATE TABLE fuel_purchases (
    fuel_purchase_id    VARCHAR(12) PRIMARY KEY,
    trip_id              VARCHAR(12),
    truck_id             VARCHAR(10) NULL,
    driver_id            VARCHAR(10) NULL,
    purchase_date        DATETIME,
    location_city        VARCHAR(50),
    location_state       VARCHAR(2),
    gallons              DECIMAL(8,2),
    price_per_gallon     DECIMAL(6,3),
    total_cost           DECIMAL(10,2),
    fuel_card_number     VARCHAR(20),
    CONSTRAINT fk_fuel_trip    FOREIGN KEY (trip_id)   REFERENCES trips(trip_id),
    CONSTRAINT fk_fuel_truck   FOREIGN KEY (truck_id)  REFERENCES trucks(truck_id),
    CONSTRAINT fk_fuel_driver  FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);

-- ---------------------------------------------------------------
-- 10. MAINTENANCE_RECORDS  (FK: truck_id)
-- ---------------------------------------------------------------
CREATE TABLE maintenance_records (
    maintenance_id       VARCHAR(14) PRIMARY KEY,
    truck_id              VARCHAR(10),
    maintenance_date      DATE,
    maintenance_type       VARCHAR(30),
    odometer_reading       INT,
    labor_hours            DECIMAL(6,2),
    labor_cost             DECIMAL(10,2),
    parts_cost             DECIMAL(10,2),
    total_cost             DECIMAL(10,2),
    facility_location       VARCHAR(50),
    downtime_hours          DECIMAL(6,2),
    service_description     VARCHAR(255),
    CONSTRAINT fk_maint_truck FOREIGN KEY (truck_id) REFERENCES trucks(truck_id)
);

-- ---------------------------------------------------------------
-- 11. DELIVERY_EVENTS  (FK: load_id, trip_id, facility_id)
-- ---------------------------------------------------------------
CREATE TABLE delivery_events (
    event_id             VARCHAR(12) PRIMARY KEY,
    load_id               VARCHAR(12),
    trip_id               VARCHAR(12),
    event_type            VARCHAR(20),
    facility_id           VARCHAR(10),
    scheduled_datetime    DATETIME(6),
    actual_datetime       DATETIME(6),
    detention_minutes     INT,
    on_time_flag          BOOLEAN,
    location_city         VARCHAR(50),
    location_state        VARCHAR(2),
    CONSTRAINT fk_delivery_load     FOREIGN KEY (load_id)     REFERENCES loads(load_id),
    CONSTRAINT fk_delivery_trip     FOREIGN KEY (trip_id)     REFERENCES trips(trip_id),
    CONSTRAINT fk_delivery_facility FOREIGN KEY (facility_id) REFERENCES facilities(facility_id)
);

-- ---------------------------------------------------------------
-- 12. SAFETY_INCIDENTS  (FK: trip_id, truck_id, driver_id)
-- ---------------------------------------------------------------
CREATE TABLE safety_incidents (
    incident_id          VARCHAR(12) PRIMARY KEY,
    trip_id               VARCHAR(12),
    truck_id              VARCHAR(10) NULL,
    driver_id             VARCHAR(10) NULL,
    incident_date         DATETIME,
    incident_type         VARCHAR(30),
    location_city         VARCHAR(50),
    location_state        VARCHAR(2),
    at_fault_flag         BOOLEAN,
    injury_flag           BOOLEAN,
    vehicle_damage_cost   DECIMAL(10,2),
    cargo_damage_cost     DECIMAL(10,2),
    claim_amount          DECIMAL(10,2),
    preventable_flag      BOOLEAN,
    description           VARCHAR(255),
    CONSTRAINT fk_safety_trip   FOREIGN KEY (trip_id)   REFERENCES trips(trip_id),
    CONSTRAINT fk_safety_truck  FOREIGN KEY (truck_id)  REFERENCES trucks(truck_id),
    CONSTRAINT fk_safety_driver FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);

-- ---------------------------------------------------------------
-- 13. DRIVER_MONTHLY_METRICS (aggregated, composite key)
-- ---------------------------------------------------------------
CREATE TABLE driver_monthly_metrics (
    driver_id                 VARCHAR(10),
    month                      DATE,
    trips_completed            INT,
    total_miles                INT,
    total_revenue               DECIMAL(12,2),
    average_mpg                 DECIMAL(5,2),
    total_fuel_gallons          DECIMAL(10,2),
    on_time_delivery_rate        DECIMAL(5,3),
    average_idle_hours          DECIMAL(6,2),
    PRIMARY KEY (driver_id, month),
    CONSTRAINT fk_dmm_driver FOREIGN KEY (driver_id) REFERENCES drivers(driver_id)
);

-- ---------------------------------------------------------------
-- 14. TRUCK_UTILIZATION_METRICS (aggregated, composite key)
-- ---------------------------------------------------------------
CREATE TABLE truck_utilization_metrics (
    truck_id             VARCHAR(10),
    month                 DATE,
    trips_completed        INT,
    total_miles             INT,
    total_revenue           DECIMAL(12,2),
    average_mpg             DECIMAL(5,2),
    maintenance_events       INT,
    maintenance_cost         DECIMAL(10,2),
    downtime_hours           DECIMAL(6,2),
    utilization_rate         DECIMAL(5,3),
    PRIMARY KEY (truck_id, month),
    CONSTRAINT fk_tum_truck FOREIGN KEY (truck_id) REFERENCES trucks(truck_id)
);

-- ---------------------------------------------------------------
-- Helpful indexes for common join/filter columns used in analysis
-- ---------------------------------------------------------------
CREATE INDEX idx_loads_customer   ON loads(customer_id);
CREATE INDEX idx_loads_route      ON loads(route_id);
CREATE INDEX idx_loads_date       ON loads(load_date);
CREATE INDEX idx_trips_driver     ON trips(driver_id);
CREATE INDEX idx_trips_truck      ON trips(truck_id);
CREATE INDEX idx_trips_date       ON trips(dispatch_date);
CREATE INDEX idx_fuel_truck       ON fuel_purchases(truck_id);
CREATE INDEX idx_fuel_date        ON fuel_purchases(purchase_date);
CREATE INDEX idx_maint_truck      ON maintenance_records(truck_id);
CREATE INDEX idx_delivery_trip    ON delivery_events(trip_id);
CREATE INDEX idx_safety_driver    ON safety_incidents(driver_id);
