--------------------------------------------------------------------------------
-- QUERY - Vessel traffic through Areas to be Avoided (ATBA)
-- around Tristan da Cunha
--
-- Author: Cian Luck
-- Date: 30/07/2021
--------------------------------------------------------------------------------

WITH

    ----------------------------------------------------------------------------
    -- This subquery pulls out the vessel info we need
    ----------------------------------------------------------------------------
    vessel_info AS(
    SELECT
            ssvid, -- vessel id
            year,
            ais_identity.shipname_mostcommon.value as shipname, -- most commonly transmitted shipname
            best.best_flag, -- best known flag
            best.best_vessel_class, -- best estimate at vessel class
            best.best_tonnage_gt -- best estimate of gross tonnage
        FROM 
            `world-fishing-827.gfw_research.vi_ssvid_byyear_v20210706`
    ),


    ----------------------------------------------------------------------------
    -- This subquery identifies good track segments. Good segments are:
    -- more than 10 positions
    -- travel at least 100 meters
    -- average speed greater than 0 knots
    -- average distance to shore greater than 0 meters
    -- longitude not between -0.109225° and 0.109225°
    ----------------------------------------------------------------------------
    good_segments AS (
    SELECT 
        seg_id, -- segment id
        ssvid -- vessel id
    FROM 
    `world-fishing-827.gfw_research.pipe_v20201001_segs` 
    WHERE 
        good_seg
        AND positions > 10 
        -- in the case where two overlapping track segments transmit the same MMSI
        -- we keep the longer segment
        AND NOT overlapping_and_short 
        ),


    ----------------------------------------------------------------------------
    -- This subquery gets all activity between Jan. 1, 2019
    -- and June 30, 2021 
    -- CAUTION: BIG QUERY
    ----------------------------------------------------------------------------
    activity AS (
    SELECT 
        ssvid, -- vessel id
        lat,
        lon,
        timestamp,
        EXTRACT(year FROM timestamp) as year,
        hours, -- hours of vessel presence at this location and time
        speed_knots, -- speed in knots
        heading,
        course,
        distance_from_shore_m -- distance to shore in meters
    FROM 
    -- Have to query the pipe_vYYYYMMDD table since we're interested
    -- in all vessel types - mostly cargo vessels. 
    -- CAUTION: BIG QUERY
    `world-fishing-827.gfw_research.pipe_v20201001` 
    WHERE 
        -- restrict to between Jan. 1, 2019 and June 30, 2021 
        DATE(_PARTITIONTIME) BETWEEN "2019-01-01" AND "2021-06-30"  
        -- only include good semgents
        AND seg_id IN (
        SELECT
            seg_id
        FROM 
            good_segments)),


    ----------------------------------------------------------------------------
    -- Filter activity to only include the vessels in vessel_info
    -- append vessel info to positions
    ----------------------------------------------------------------------------
    activity_filtered AS (
    SELECT *
    FROM activity
    JOIN vessel_info
     USING(ssvid, year)
    ),

    ----------------------------------------------------------------------------
    -- Define area of interest around Tristan da Cunha
    ----------------------------------------------------------------------------
    aoi AS (
    SELECT
      ST_GEOGFROMTEXT( "MULTIPOLYGON (((-20 -30, 0 -30, 0 -50, -20 -50, -20 -30)))"  ) AS  polygon
    ),

    ----------------------------------------------------------------------------
    -- Filter activity to only include activity within the aoi
    ----------------------------------------------------------------------------
    activity_in_aoi AS (
    SELECT
      *
    FROM
      activity_filtered 
    WHERE
    IF
      (ST_CONTAINS( (
          SELECT
            polygon
          FROM
            aoi),
          ST_GEOGPOINT(lon,
            lat)),
        TRUE,
        FALSE)
    ),

    ----------------------------------------------------------------------------
    -- Create fields for positions within EEZ and within ATBA
    ----------------------------------------------------------------------------
    -- Load shapefile of eez
    eez_poly AS (
    SELECT
        ST_GEOGFROMTEXT(WKT) AS polygon
    FROM
        `world-fishing-827.ocean_shapefiles_all_purpose.tristan_da_cunha_eez` 
    ),

    -- Load shapefile of ATBA
    atba_poly AS (
        SELECT
        ST_GEOGFROMTEXT(WKT) AS polygon
    FROM
        `world-fishing-827.ocean_shapefiles_all_purpose.tristan_da_cunha_atba_consolidate`
    ),

    -- create fields for positions within EEZ and within ATBA
    activity_in_aoi_filtered AS (
        SELECT *,
        -- inside_eez (1: inside eez, 0: outside eez)
            CASE
                WHEN ST_CONTAINS((
                        SELECT
                            polygon
                        FROM
                            eez_poly),
                        ST_GEOGPOINT(lon,
                            lat)) THEN 1 ELSE 0 END AS inside_eez,
        -- inside_atba (1: inside atba, 0: outside atba)
            CASE
                WHEN ST_CONTAINS((
                        SELECT
                            polygon
                        FROM
                            atba_poly),
                        ST_GEOGPOINT(lon,
                            lat)) THEN 1 ELSE 0 END AS inside_atba
        FROM activity_in_aoi 
    ),

    ----------------------------------------------------------------------------
    -- Append voyage info to use trip_id to identify individual
    -- transits
    -- the voyages table uses port visits with confidence level 4 to assign trip_id values
    -- see report for details of how port visits are identified
    ----------------------------------------------------------------------------
    voyage_info AS (
        SELECT 
            ssvid,
            trip_start, -- when the vessel left port
            trip_end, -- when the vessel arrived at next port
            trip_id -- trip identifier
        FROM 
            `world-fishing-827.pipe_production_v20201001.voyages`
    ),
    
    -- append the relevant trip_id to each vessel position, matching to vessel id (ssvid)
    -- and timestamp
    activity_in_aoi_filtered_voyages AS (
        SELECT activity_in_aoi_filtered.*, voyage_info.trip_id
            FROM activity_in_aoi_filtered 
        LEFT JOIN voyage_info 
        ON activity_in_aoi_filtered.timestamp >= voyage_info.trip_start AND activity_in_aoi_filtered.timestamp < voyage_info.trip_end
        WHERE 
        activity_in_aoi_filtered.ssvid = voyage_info.ssvid AND
        activity_in_aoi_filtered.timestamp BETWEEN voyage_info.trip_start AND voyage_info.trip_end
    )


--------------------------------------------------------------------------------
-- Return filtered activity data
--------------------------------------------------------------------------------
SELECT *
FROM activity_in_aoi_filtered_voyages