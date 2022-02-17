--------------------------------------------------------------------------------
-- Query - vessel hours by > 400 gt vessels inside the ATBA 
-- between Jan. 1 2019 and June 30 2021
--
-- Author: Cian Luck
--------------------------------------------------------------------------------

WITH 

  ------------------------------------------------------------------------------
  -- activity (hours) by vessels over 400 gross tonnes 
  -- inside the Areas to be Avoided
  ------------------------------------------------------------------------------
  positions AS(
  SELECT 
      *,
      EXTRACT(date FROM timestamp) AS date,
      EXTRACT(month FROM timestamp) AS month,
  FROM 
      `world-fishing-827.scratch_cian.tdc_vessel_traffic_atba_2019_2021`
  WHERE 
  -- restrict to positions inside the ATBA and by vessels over 400 gross tonnes
      inside_atba = 1 AND 
      best_tonnage_gt >= 400)

--------------------------------------------------------------------------------
-- return a summary of the total vessel hours and the total number of vessels
-- within the ATBA by date, and vessel class
--------------------------------------------------------------------------------
SELECT
    date,
    month,
    year, 
    best_vessel_class,
    COUNT(DISTINCT ssvid) as n_vessel,
    SUM(hours) as total_hours
FROM 
    positions
GROUP BY 
    year,
    month,
    date,
    best_vessel_class