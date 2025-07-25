SELECT
  -- Custom-friendly date label
  CASE
    WHEN DAYDIFF(DATETRUNC('day', AH.Timestamp), GETDATE()) = 0 THEN 'Since Midnight'
    WHEN DAYDIFF(DATETRUNC('day', AH.Timestamp), GETDATE()) = 1 THEN 'Yesterday'
    ELSE CONCAT(
      MONTH(DATETRUNC('day', AH.Timestamp)), '/', 
      DAY(DATETRUNC('day', AH.Timestamp)), '/', 
      YEAR(DATETRUNC('day', AH.Timestamp))
    )
  END AS [Date],

  SUM(CASE WHEN AH.EventType = 0 THEN 1 ELSE 0 END) AS [Triggered],
  SUM(CASE WHEN AH.EventType = 1 THEN 1 ELSE 0 END) AS [Reset],
  SUM(CASE WHEN AH.EventType = 2 THEN 1 ELSE 0 END) AS [Acknowledged],
  SUM(CASE WHEN AH.EventType = 3 THEN 1 ELSE 0 END) AS [Note],
  SUM(CASE WHEN AH.EventType = 4 THEN 1 ELSE 0 END) AS [AddedToIncident],
  SUM(CASE WHEN AH.EventType = 5 THEN 1 ELSE 0 END) AS [ActionFailed],
  SUM(CASE WHEN AH.EventType = 6 THEN 1 ELSE 0 END) AS [ActionSucceeded],
  SUM(CASE WHEN AH.EventType = 7 THEN 1 ELSE 0 END) AS [Unacknowledged],
  SUM(CASE WHEN AH.EventType = 8 THEN 1 ELSE 0 END) AS [Cleared],
  SUM(CASE WHEN AH.EventType = 9 THEN 1 ELSE 0 END) AS [ActionDisabled]

FROM
  Orion.AlertHistory AS AH

WHERE
  DAYDIFF(AH.Timestamp, GETDATE()) < 30

GROUP BY
  CASE
    WHEN DAYDIFF(DATETRUNC('day', AH.Timestamp), GETDATE()) = 0 THEN 'Since Midnight'
    WHEN DAYDIFF(DATETRUNC('day', AH.Timestamp), GETDATE()) = 1 THEN 'Yesterday'
    ELSE CONCAT(
      MONTH(DATETRUNC('day', AH.Timestamp)), '/', 
      DAY(DATETRUNC('day', AH.Timestamp)), '/', 
      YEAR(DATETRUNC('day', AH.Timestamp))
    )
  END

ORDER BY
  MAX(DATETRUNC('day', AH.Timestamp)) DESC
