SELECT 
  COUNT([AH].AlertHistoryID) AS [Alerts], 
  SUBSTRING(
    TOSTRING(
      DATETRUNC('day', [AH].Timestamp)
    ), 
    1, 
    6
  ) AS [date] 
FROM 
  Orion.AlertHistory AS [AH] 
WHERE 
  DAYDIFF(
    [AH].Timestamp, 
    GETDATE()
  ) < 30 
GROUP BY 
  DATETRUNC('day', [AH].Timestamp) 
ORDER BY 
  DATETRUNC('day', [AH].Timestamp)

