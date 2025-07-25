SELECT 

    -- 'Information'
  COUNT(CASE WHEN ao.AlertConfigurations.Severity = 0 THEN 1 END) AS AlertCount
    -- 'Warning'
  --COUNT(CASE WHEN ao.AlertConfigurations.Severity = 1 THEN 1 END) AS AlertCount
    -- 'Critical'
  --COUNT(CASE WHEN ao.AlertConfigurations.Severity = 2 THEN 1 END) AS AlertCount
    -- 'Serious'
  --COUNT(CASE WHEN ao.AlertConfigurations.Severity = 3 THEN 1 END) AS AlertCount
    -- 'Notice'
  --COUNT(CASE WHEN ao.AlertConfigurations.Severity = 4 THEN 1 END) AS AlertCount

FROM 
  Orion.AlertObjects AS ao

WHERE 
  ao.IsActiveAlert = 1
