--------------------------------------------------------------------------------
-- QUERY - Full port-to-port voyages of squid jiggers AIS gap events near 
-- Tristan da Cunha
--
-- Author: Cian Luck
--------------------------------------------------------------------------------

WITH

    ----------------------------------------------------------------------------
    -- This subquery pulls out the vessel info we need
    ----------------------------------------------------------------------------
    vessel_info AS(
    SELECT
            ssvid,
            year,
            ais_identity.shipname_mostcommon.value as shipname,
            best.best_flag,
            best.best_vessel_class,
            best.best_tonnage_gt
        FROM 
            `world-fishing-827.gfw_research.vi_ssvid_byyear_v20210913`
    ),


    ----------------------------------------------------------------------------
    -- This subquery identifies good track segments
    ----------------------------------------------------------------------------
    good_segments AS (
    SELECT 
        seg_id,
        ssvid
    FROM 
    `world-fishing-827.gfw_research.pipe_v20201001_segs` 
    WHERE 
        good_seg
        AND positions > 10
        AND NOT overlapping_and_short),


    ----------------------------------------------------------------------------
    -- This subquery gets all activity between 1st Jan 2019
    -- and 30th June 2021 
    -- CAUTION: BIG QUERY - must query pipe table
    ----------------------------------------------------------------------------
    activity AS (
    SELECT 
        ssvid,
        lat,
        lon,
        timestamp,
        EXTRACT(year FROM timestamp) as year,
        hours,
        speed_knots,
        heading,
        course,
        distance_from_shore_m
    FROM 
    -- Have to query the pipe_vYYYYMMDD table since we're interested
    -- in all vessel types - mostly cargo vessels. 
    -- CAUTION: BIG QUERY
    `world-fishing-827.gfw_research.pipe_v20201001_fishing` 
    WHERE 
        DATE(_PARTITIONTIME) BETWEEN '2019-01-01' AND '2020-12-31'  
        -- only include good semgents
        AND seg_id IN (
        SELECT
            seg_id
        FROM 
            good_segments)
        AND ssvid IN ({ssvid_squid*})),


    ----------------------------------------------------------------------------
    -- Filter activity to only include the vessels
    ----------------------------------------------------------------------------
    activity_filtered AS (
    SELECT *
    FROM activity
    JOIN vessel_info
     USING(ssvid, year)
    ),


    ----------------------------------------------------------------------------
    -- Create fields for within EEZ and within ATBA
    -- Load shapefile of eez
    ----------------------------------------------------------------------------
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
            CASE
                WHEN ST_CONTAINS((
                        SELECT
                            polygon
                        FROM
                            eez_poly),
                        ST_GEOGPOINT(lon,
                            lat)) THEN 1 ELSE 0 END AS inside_eez,
            CASE
                WHEN ST_CONTAINS((
                        SELECT
                            polygon
                        FROM
                            atba_poly),
                        ST_GEOGPOINT(lon,
                            lat)) THEN 1 ELSE 0 END AS inside_atba
        FROM activity_filtered 
    ),

    ----------------------------------------------------------------------------
    -- Append voyage info to use trip_id to identify individual
    -- transits
    ----------------------------------------------------------------------------
    voyage_info AS (
        SELECT 
            ssvid,
            trip_start,
            trip_end,
            trip_id
        FROM 
            `world-fishing-827.pipe_production_v20201001.voyages`
    ),

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
-- Return activity data
--------------------------------------------------------------------------------
SELECT *
FROM activity_in_aoi_filtered_voyages