--------------------------------------------------------------------------------
-- Query scratch_cian.tdc_longliner_dist_2016_2021
-- fishing effort over time
--------------------------------------------------------------------------------

-- Author: Cian Luck
-- Date: 25 Nov 2021

WITH

  ----------------------------------------------------------
  -- Define a smaller area of interest around Tristan da Cunha
  ----------------------------------------------------------
  aoi AS (
    SELECT
      ST_GEOGFROMTEXT( "MULTIPOLYGON (((-25 -20, 20 -20, 20 -50, -25 -50, -25 -20)))"  ) AS  polygon
    ),
    
  ----------------------------------------------------------
  -- Define a smaller area of interest around Tristan da Cunha
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
  fishing AS (
    SELECT
      *,
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
      `scratch_cian.tdc_longliner_dist_2016_2021`, aoi
    WHERE
      ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(lon_bin, lat_bin))
  )
  

----------------------------------------------------------  
-- Pull fishing effort within this AOI
----------------------------------------------------------
SELECT *
FROM fishing