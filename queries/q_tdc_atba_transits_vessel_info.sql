--------------------------------------------------------------------------------
-- Query: Append vessel info to transits through the Areas to be Avoided
--
-- Author: Cian Luck
--------------------------------------------------------------------------------

WITH 

    -------------------------------------------------------------
    -- List of ssvids for vessels that transited through the ATBA
    -------------------------------------------------------------
    vessels_of_interest AS(
        SELECT 
            CAST(ssvid AS string) as ssvid, -- vessel id
            year,
            n_transits
        FROM 
            `world-fishing-827.scratch_cian.atba_ssvids`
    ),

    -------------------------------------------------------------
    -- This subquery pulls out the vessel info we need
    -------------------------------------------------------------
    vessel_info AS(
        SELECT
            ssvid,
            year,
            ais_identity.shipname_mostcommon.value as shipname, -- most commonly transmitted shipname
            best.best_flag, -- best known vessel flag
            best.best_vessel_class, -- best estimate of vessel class
            best.best_tonnage_gt -- best estimate of gross tonnage
        FROM 
            `world-fishing-827.gfw_research.vi_ssvid_byyear_v20210706`
    ),

    -------------------------------------------------------------
    -- Join the two by ssvid and year
    -------------------------------------------------------------
    vessel_info_atba AS(
        SELECT *
        FROM vessel_info
        RIGHT JOIN vessels_of_interest 
            USING(ssvid, year)
    )


-------------------------------------------------------------
-- Return vessel info
-------------------------------------------------------------
SELECT *
FROM vessel_info_atba 
    ORDER BY n_transits DESC, best_flag