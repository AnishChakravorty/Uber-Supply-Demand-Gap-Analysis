Create database uber_data;

Select * from uber_cleaned_data_clean;

drop table uber_cleaned_data_clean;

SET SQL_SAFE_UPDATES = 0;

UPDATE uber_cleaned_data_clean
SET `Driver id` = NULL 
WHERE TRIM(`Driver id`) = '' OR LOWER(TRIM(`Driver id`)) IN ('null', 'nan');

ALTER TABLE uber_cleaned_data_clean 
MODIFY COLUMN `Driver id` INT NULL;

UPDATE uber_cleaned_data_clean 
SET `Request date` = NULL 
WHERE TRIM(`Request date`) = '' OR LOWER(TRIM(`Request date`)) IN ('null', 'nan');

ALTER TABLE uber_cleaned_data_clean 
MODIFY COLUMN `Request date` DATE;


UPDATE uber_cleaned_data_clean 
SET `Request hour` = NULL 
WHERE TRIM(`Request hour`) = '' OR LOWER(TRIM(`Request hour`)) IN ('null', 'nan');

ALTER TABLE uber_cleaned_data_clean
MODIFY COLUMN `Request hour` TINYINT;

UPDATE uber_cleaned_data_clean  
SET `Drop date` = NULL 
WHERE TRIM(`Drop date`) = '' OR LOWER(TRIM(`Drop date`)) IN ('null', 'nan');

ALTER TABLE uber_cleaned_data_clean 
MODIFY COLUMN `Drop date` DATE NULL;

UPDATE uber_cleaned_data_clean
SET `Drop hour` = NULL 
WHERE TRIM(`Drop hour`) = '' OR LOWER(TRIM(`Drop hour`)) IN ('null', 'nan');

ALTER TABLE uber_cleaned_data_clean
MODIFY COLUMN `Drop hour` TINYINT NULL;

UPDATE uber_cleaned_data_clean 
SET `Trip duration_min` = NULL 
WHERE TRIM(`Trip duration_min`) = '' OR LOWER(TRIM(`Trip duration_min`)) IN ('null', 'nan');

ALTER TABLE uber_cleaned_data_clean 
MODIFY COLUMN `Trip duration_min` FLOAT NULL;

UPDATE uber_cleaned_data_clean 
SET `Trip duration_hr` = NULL 
WHERE TRIM(`Trip duration_hr`) = '' OR LOWER(TRIM(`Trip duration_hr`)) IN ('null', 'nan');

ALTER TABLE uber_cleaned_data_clean 
MODIFY COLUMN `Trip duration_hr` FLOAT NULL;

-- 1. Total number of requests

SELECT COUNT(*) AS total_requests
FROM  uber_cleaned_data_clean;

-- 2. Request counts by status

SELECT status, COUNT(*) AS count
FROM uber_cleaned_data_clean
GROUP BY status
ORDER BY count DESC;

-- 3. Request counts by pickup point

SELECT `pickup point`, COUNT(*) AS count
FROM uber_cleaned_data_clean
GROUP BY `pickup point`
ORDER BY count DESC;

-- 4. Request counts by pickup point and status

SELECT `pickup point`, status, COUNT(*) AS count
FROM uber_cleaned_data_clean
GROUP BY `pickup point`, status
ORDER BY `pickup point`, count DESC;

-- 5. Hourly demand distribution

SELECT `request hour`, COUNT(*) AS total_requests
FROM uber_cleaned_data_clean
GROUP BY `request hour`
ORDER BY `request hour`;

-- 6. Peak request hours with high cancellation or 'No Cars Available'

SELECT `request hour`, status, COUNT(*) AS count
FROM uber_cleaned_data_clean
WHERE status != 'Trip Completed'
GROUP BY `request hour`, status
ORDER BY `request hour`;

-- 7. Day-wise request breakdown

SELECT `request day`, status, COUNT(*) AS count
FROM uber_cleaned_data_clean
GROUP BY `request day`, status
ORDER BY FIELD(`request day`, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- 8. Trips completed vs not fulfilled (Drop data availability)

SELECT 
  CASE WHEN `Drop date` IS NOT NULL THEN 'Completed' ELSE 'Not Completed' END AS trip_status,
  COUNT(*) AS total
FROM uber_cleaned_data_clean
GROUP BY trip_status;


-- 9. Average trip duration for completed trips

SELECT 
  ROUND(AVG(`Trip duration_min`), 2) AS avg_duration_min,
  ROUND(AVG(`Trip duration_hr`), 2) AS avg_duration_hr
FROM uber_cleaned_data_clean
WHERE status = 'Trip Completed';

-- 10. Top 5 hours with highest number of 'Trip Completed'

SELECT `request hour`, COUNT(*) AS no_car_requests
FROM uber_cleaned_data_clean
WHERE status = 'Trip Completed'
GROUP BY `request hour`
ORDER BY no_car_requests DESC
LIMIT 5;

-- 11. Supply-Demand Gap Calculation

SELECT 
  COUNT(*) AS total_requests,
  SUM(CASE WHEN status = 'Trip Completed' THEN 1 ELSE 0 END) AS trips_completed,
  SUM(CASE WHEN status != 'Trip Completed' THEN 1 ELSE 0 END) AS supply_gap,
  ROUND(SUM(CASE WHEN status != 'Trip Completed' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS gap_percentage
FROM uber_cleaned_data_clean;


-- 12. Driver Utilization Rate

SELECT 
  `Driver id`,
  COUNT(*) AS total_assigned,
  SUM(CASE WHEN status = 'Trip Completed' THEN 1 ELSE 0 END) AS completed_trips,
  ROUND(SUM(CASE WHEN status = 'Trip Completed' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS utilization_rate
FROM uber_cleaned_data_clean
WHERE `Driver id` IS NOT NULL
GROUP BY `Driver id`
ORDER BY utilization_rate DESC
LIMIT 20;

-- 13. Time Slot-wise Performance (Request Hour Timeslot)

SELECT 
  `Request hour timeslot`,
  COUNT(*) AS total_requests,
  SUM(CASE WHEN status = 'Trip Completed' THEN 1 ELSE 0 END) AS completed_trips,
  SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
  SUM(CASE WHEN status = 'No Cars Available' THEN 1 ELSE 0 END) AS no_cars,
  ROUND(SUM(CASE WHEN status != 'Trip Completed' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS failure_rate
FROM uber_cleaned_data_clean
GROUP BY `Request hour timeslot`
ORDER BY total_requests DESC;

-- 14. Cancellation Rate per Pickup Point

SELECT 
  `Pickup point`,
  COUNT(*) AS total_requests,
  SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancellations,
  ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS cancellation_rate
FROM uber_cleaned_data_clean
GROUP BY `Pickup point`
ORDER BY cancellation_rate DESC;
