-- Count of active alerts by severity level
-- Currently filtering for only Informational alerts (Severity = 0)

SELECT 
--  ao.AlertConfigurations.Severity,                  -- Uncomment to see numeric severity
--  CASE ao.AlertConfigurations.Severity              -- Map severity number to label
--      WHEN 0 THEN 'Information'
--      WHEN 1 THEN 'Warning'
--      WHEN 2 THEN 'Critical'
--      WHEN 3 THEN 'Serious'
--      WHEN 4 THEN 'Notice'
--      ELSE 'Unknown'
--  END AS SeverityLabel,

    COUNT(*) AS AlertCount                             -- Total number of active alerts

FROM 
    Orion.AlertObjects AS ao

WHERE 
    ao.IsActiveAlert = 1                               -- Only currently active alerts
    AND ao.AlertConfigurations.Severity = 0            -- Filter to Informational only

GROUP BY 
    ao.AlertConfigurations.Severity                    -- Group by severity type

ORDER BY 
    ao.AlertConfigurations.Severity;
