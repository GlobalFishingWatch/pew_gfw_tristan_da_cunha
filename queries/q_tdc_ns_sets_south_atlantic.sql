--------------------------------------------------------------------------------
-- Query: Select all longline sets within the South Atlantic
-- between Jan. 01 2019 and June 30 2021
--
-- This table includes the output of new model which can differentiate between
-- setting and hauling activity in longline sets
--
-- This query pulls from a table which includes setting activity only
--
-- Author: Cian Luck
--------------------------------------------------------------------------------

SELECT 
      *
  FROM 
      `world-fishing-827.scratch_joanna.sets_24hr_categorised_v20210830`
  WHERE 
      start_time BETWEEN '2019-01-01 00:00:00 UTC' AND '2021-06-30 00:00:00 UTC'
      AND region = 'South_Atlantic'