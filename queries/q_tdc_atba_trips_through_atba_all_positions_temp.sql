--------------------------------------------------------------------------------
-- Query: all positions from trips that passed within the ATBA
--
-- Author: Cian Luck
--------------------------------------------------------------------------------

WITH

    ----------------------------------------------------------------------------
    -- pull out the list of trip_ids that passed that passed
    -- through the ATBA
    ----------------------------------------------------------------------------
    trips_in_atba AS(
        SELECT 
            DISTINCT(trip_id)
        FROM
            `world-fishing-827.scratch_cian.tdc_vessel_traffic_atba_2019_2021`
        WHERE inside_atba = 1
    ),

    ----------------------------------------------------------------------------
    -- positions of trips that passed through ATBA
    ----------------------------------------------------------------------------
    positions AS (
        SELECT 
            ssvid, -- vessel id
            lat, 
            lon, 
            timestamp,
            year,
            hours,
            speed_knots,
            shipname,
            best_flag,
            best_vessel_class,
            best_tonnage_gt,
            inside_eez,
            inside_atba,
            trip_id,
            distance_from_shore_m AS dist_from_shor_m_bq
        FROM
            `world-fishing-827.scratch_cian.tdc_vessel_traffic_atba_2019_2021`
        WHERE 
        -- limit to only trips that passed through the ATBA
            trip_id IN(
                SELECT  trip_id
                FROM    trips_in_atba) 
        -- and vessels > 400 gross tonnes
            AND best_tonnage_gt >= 400
    )
    
--------------------------------------------------------------------------------
-- return positions
--------------------------------------------------------------------------------
SELECT * 
FROM positions