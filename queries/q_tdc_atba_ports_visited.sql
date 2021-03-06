-------------------------------------------------------------------
-- Query: Identify ports visited by vessels before and after
-- transiting through the ATBA around Tristan da Cunha
--
-- Author: Cian Luck
-------------------------------------------------------------------

  WITH
      --------------------------------------------------------------------------
      -- voyages 
      -- this selects all available information on port-to-port trips
      -- included in transits_post_atba
      --------------------------------------------------------------------------
      voyages AS (
        SELECT 
            *
        FROM 
            `world-fishing-827.pipe_production_v20201001.voyages`
        WHERE 
            DATE(trip_end) >= '2020-04-01'
            AND trip_id IN ({transits_post_atba*})
      ),
      
      --------------------------------------------------------------------------
      -- these subqueries appends the port information of the origin and destination ports
      -- to the trip information
      --------------------------------------------------------------------------
      -- port of origin
      ports_1 AS (
        SELECT
          *
        FROM voyages
        LEFT JOIN(
          SELECT
            s2id AS trip_start_anchorage_id,
            label AS trip_start_anchorage_label,
            lat AS trip_start_anchorage_lat,
            lon AS trip_start_anchorage_lon,
            iso3 AS trip_start_anchorage_country
        FROM
            `world-fishing-827.gfw_research.named_anchorages`
        )
          USING (trip_start_anchorage_id)
      ),

      -- append destination port info
      ports_2 AS(
        SELECT
           *
        FROM ports_1
                LEFT JOIN(
          SELECT
            s2id AS trip_end_anchorage_id,
            label AS trip_end_anchorage_label,
            lat AS trip_end_anchorage_lat,
            lon AS trip_end_anchorage_lon,
            iso3 AS trip_end_anchorage_country
        FROM
            `world-fishing-827.gfw_research.named_anchorages`
        )
          USING (trip_end_anchorage_id)
      )


--------------------------------------------------------------------------
-- return ports_2
--------------------------------------------------------------------------
SELECT *
FROM ports_2