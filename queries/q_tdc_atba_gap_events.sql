--------------------------------------------------------------------------------
-- Query: Gaps in AIS transmission linked to suspected disabling of AIS devices
--
-- Author: Cian Luck
--------------------------------------------------------------------------------

WITH 

    ------------------------------------------------------------------------
    -- Define area of interest around Tristan da Cunha
    ------------------------------------------------------------------------
    aoi AS (
    SELECT
      ST_GEOGFROMTEXT( 'MULTIPOLYGON (((-25 -25, 5 -25, 5 -50, -25 -50, -25 -25)))'  ) AS  polygon
    ),
    
    ------------------------------------------------------------------------
    -- shapefile of Tristan EEZ
    ------------------------------------------------------------------------
    eez_poly AS (
    SELECT
        ST_GEOGFROMTEXT(WKT) AS polygon
    FROM
        `world-fishing-827.ocean_shapefiles_all_purpose.tristan_da_cunha_eez` 
    ),

    ------------------------------------------------------------------------
    -- Select gaps near Tristan da Cunha
    ------------------------------------------------------------------------
    gaps AS (
        SELECT *,
        -- add column for positions inside the eez
        CASE
          WHEN ST_CONTAINS((
                  SELECT
                      polygon
                  FROM
                      eez_poly),
                  ST_GEOGPOINT(off_lon, off_lat)) THEN 1 ELSE 0 END AS off_inside_eez,
        CASE
          WHEN ST_CONTAINS((
                  SELECT
                      polygon
                  FROM
                      eez_poly),
                  ST_GEOGPOINT(on_lon, on_lat)) THEN 1 ELSE 0 END AS on_inside_eez,
    FROM `world-fishing-827.proj_ais_gaps_catena.ais_gap_events_features_v20210722`, aoi
    WHERE gap_hours >= 12
        -- spatial filter for distance to shore - set to 10 nm
        AND (off_distance_from_shore_m > 1852*10 AND on_distance_from_shore_m > 1852*10)
        AND (positions_per_day_off > 5 AND positions_per_day_on > 5)
        AND (DATE(gap_start) >= '2019-01-01' AND DATE(gap_end) <= '2021-06-30')
        AND positions_X_hours_before_sat >= 19
       -- spatial filter for only positions within aoi
        AND ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(on_lon, on_lat))
        AND ST_CONTAINS(aoi.polygon, ST_GEOGPOINT(off_lon, off_lat))
    )

------------------------------------------------------------------------
-- Return gaps
------------------------------------------------------------------------
SELECT *
FROM gaps