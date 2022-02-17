-------------------------------------------------------------
-- QUERY: FISHING EFFORT

-- Calculate gridded fishing effort of longliners
-- operating around Tristan da Cunha.
--
-- Interested in inter-annual variation in the distribution of 
-- longline effort
-------------------------------------------------------------

-- DESCRIPTION:
-- This query demonstrates how to extract valid positions
-- and calculate fishing hours. The key features of the
-- query include the following:

-- 1) Identify good segments and active non-noise fishing vessels
-- 2) Get all fishing activity for a defined period of time. Use gfw_research.pipe_vYYYYMMDD_fishing for smaller query and filter to good segments
-- 2) Identify "fishing" positions and calculate hours using night loitering for squid jiggers, and neural net score for all other vessels. 
-- 4) Filter positions to only the list of fishing vessels
-- 5) Calculate fishing hours using night loitering for squid jiggers, neural net score for all other vessels
-- 5) Bin the data to desired resolution

WITH

  ----------------------------------------------------------
  -- Define area of interest around Tristan da Cunha
  ----------------------------------------------------------
  aoi AS (
    SELECT
      ST_GEOGFROMTEXT( "MULTIPOLYGON (((-25 0, 20 0, 20 -50, -25 -50, -25 0)))"  ) AS  polygon
    ),

  ----------------------------------------------------------
  -- This subquery identifies good track segments. Good segments are:
  -- more than 10 positions
  -- travel at least 100 meters
  -- average speed greater than 0 knots
  -- average distance to shore greater than 0 meters
  -- longitude not between -0.109225° and 0.109225°
  ----------------------------------------------------------
  good_segments AS (
  SELECT
    seg_id
  FROM
    `gfw_research.pipe_v20201001_segs`
  WHERE
    good_seg
    AND positions > 10
    -- in the case where two overlapping track segments transmit the same MMSI
    -- we keep the longer segment
    AND NOT overlapping_and_short),

  ----------------------------------------------------------
  -- Get the list of active fishing vessels that pass the noise filters
  ----------------------------------------------------------
  fishing_vessels AS (
  SELECT
    ssvid,
    year,
    best_flag,
    best_vessel_class
  FROM 
    `gfw_research.fishing_vessels_ssvid_v20210706`
  WHERE
  -- restrict to longline vessels only
    best_vessel_class = 'drifting_longlines'
  ),
  
  ----------------------------------------------------------
  -- This subquery fishing query gets all fishing from 01 Jan 2016 to 31 Oct 2021
  -- It queries the pipe_vYYYYMMDD_fishing table, which includes only likely
  -- fishing vessels.
  ---------------------------------------------------------- 
  fishing AS (
  SELECT
    ssvid,
    /*
    Assign lat/lon bins at desired resolution (here 10th degree)
    FLOOR takes the smallest integer after converting to units of
    0.1 degree - e.g. 37.42 becomes 374 10th degree units
    */
    FLOOR(lat * 10) as lat_bin,
    FLOOR(lon * 10) as lon_bin,
    EXTRACT(date FROM _partitiontime) as date,
    EXTRACT(year FROM _partitiontime) as year,
    hours,
    -- neural net score from fishing detection model
    -- 1: fishing, 0: not fishing
    nnet_score,
    -- rule-based algorithm to identify vessels loitering in a location at night
    -- used to infer fishing activity in squid jigger vessels
    night_loitering
  /*
  Query the pipe_vYYYYMMDD_fishing table to reduce query
  size since we are only interested in fishing vessels
  */
  FROM
    `gfw_research.pipe_v20201001_fishing`, aoi
  -- Restrict query to specific time range
  WHERE _partitiontime BETWEEN "2016-01-01" AND '2021-12-31'
  -- Use spatial join to restrict to aoi
  AND ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(lon, lat))
  -- Use good_segments subquery to only include positions from good segments
  AND seg_id IN (
    SELECT
      seg_id
    FROM
      good_segments)),
      
  ----------------------------------------------------------
  -- Filter fishing to just the list of active fishing vessels in that year
  -- append vessel information to positions
  ----------------------------------------------------------
  fishing_filtered AS (
  SELECT *
  FROM fishing
  JOIN fishing_vessels
  -- Only keep positions for fishing vessels active that year
  USING(ssvid, year)
  ),
  
  ----------------------------------------------------------
  -- Create fishing_hours attribute. Use night_loitering instead of nnet_score as indicator of fishing for squid jiggers
  -- not needed for this query, but included as best practice
  ----------------------------------------------------------
  fishing_hours_filtered AS (
  SELECT *,
    CASE
      WHEN best_vessel_class = 'squid_jigger' and night_loitering = 1 THEN hours
      WHEN best_vessel_class != 'squid_jigger' and nnet_score > 0.5 THEN hours
      ELSE NULL
    END
    AS fishing_hours
  FROM fishing_filtered
  ),

  ----------------------------------------------------------
  -- This subquery sums fishing hours and converts coordinates back to
  -- decimal degrees
  ----------------------------------------------------------
  fishing_binned AS (
  SELECT
    date,
    -- keep ssvid as we're interested in counting number of vessels
    ssvid,
    /*
    Convert lat/lon bins to units of degrees from 10th of degrees.
    374 now becomes 37.4 instead of the original 37.42
    */
    lat_bin / 10 as lat_bin,
    lon_bin / 10 as lon_bin,
    best_vessel_class,
    best_flag,
    SUM(hours) as hours,
    SUM(fishing_hours) as fishing_hours
  FROM fishing_hours_filtered
  GROUP BY date, ssvid, lat_bin, lon_bin, best_vessel_class, best_flag
  ),
  

  ----------------------------------------------------------
  -- Define the north and south fishing areas
  ----------------------------------------------------------
  aoi_north AS (
    SELECT
      ST_GEOGFROMTEXT( "MULTIPOLYGON (((-20 -30, 10 -30, 10 -40, -20 -40, -20 -30)))"  ) AS  polygon
  ),
  
  -- note the extended longitude of the southern AOI
  aoi_south AS (
    SELECT
      ST_GEOGFROMTEXT( "MULTIPOLYGON (((-20 -40, 15 -40, 15 -50, -20 -50, -20 -40)))"  ) AS  polygon
  ),
  
  ----------------------------------------------------------  
  -- Pull fishing effort within this AOI
  ----------------------------------------------------------
  fishing_binned_aoi AS (
    SELECT
      *,
      -- create a column called `aoi`
      -- `north`: position inside northern fishing area
      -- `south`: position inside southern fishing area
      CASE
        WHEN ST_CONTAINS((SELECT
                            polygon
                          FROM
                            aoi_north),
                          ST_GEOGPOINT(lon_bin, lat_bin)) THEN 'north' 
        WHEN ST_CONTAINS((SELECT
                            polygon
                          FROM
                            aoi_south),
                          ST_GEOGPOINT(lon_bin, lat_bin)) THEN 'south' 
        ELSE NULL 
      END AS aoi,
    FROM 
      fishing_binned, aoi
    WHERE
      ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(lon_bin, lat_bin))
  )
  

----------------------------------------------------------  
-- Pull fishing effort within this AOI
----------------------------------------------------------
SELECT *
FROM fishing_binned_aoi
