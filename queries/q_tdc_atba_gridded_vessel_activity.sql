--------------------------------------------------------------------------------
-- Query: Vessel activity near Tristan da Cunha
-- between Jan. 1, 2019 and June 30, 2021 
-- aggregated to 0.1° resolution
--
-- Author: Cian Luck
--------------------------------------------------------------------------------

WITH

  ------------------------------------------------------------------------------
  -- all vessel activity between Jan. 2019 and June 2021
  ------------------------------------------------------------------------------
  traffic AS (
  SELECT
    ssvid, -- vessel id
    /*
    Assign lat/lon bins at desired resolution (here 10th degree)
    FLOOR takes the smallest integer after converting to units of
    0.1 degree - e.g. 37.42 becomes 374 10th degree units
    */
    FLOOR(lat * 10) as lat_bin,
    FLOOR(lon * 10) as lon_bin,
    EXTRACT(date FROM timestamp) as date,
    EXTRACT(year FROM timestamp) as year,
    hours,
  FROM
    `world-fishing-827.scratch_cian.tdc_vessel_traffic_atba_2019_2021`
    where
    timestamp BETWEEN '2019-01-01' AND '2021-06-30' 
  ),

------------------------------------------------------------------------------
-- sum vessel activity per grid cell and convert coordinates back to decimal
-- degrees
------------------------------------------------------------------------------
traffic_binned AS (
  SELECT
  /*
    Convert lat/lon bins to units of degrees from 10th of degrees.
    374 now becomes 37.4 instead of the original 37.42
    */
    lat_bin/10 as lat_bin,
    lon_bin/10 as lon_bin,
    SUM(hours) as hours,
  FROM traffic
  GROUP BY lat_bin, lon_bin
  )


--------------------------
-- Return traffic_binned
--------------------------
SELECT *
FROM traffic_binned