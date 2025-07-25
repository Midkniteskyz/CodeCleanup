SELECT 
  CASE CustomPollerName

  WHEN 'upsAdvBatteryReplacementIndicator' THEN 'Replacement Status'
    WHEN 'upsBasicBatteryLastReplaceDate' THEN 'Last Replace Date'
    WHEN 'upsAdvBatteryRecommendedReplaceDate' THEN 'Next Replace Date'
    ELSE CustomPollerName
  END AS [Name],

  CurrentValue AS [Value],  
  CONCAT('/Orion/images/StatusIcons/Small-', StatusDescription,'.gif') AS [_IconFor_Name],
  Uri AS [_linkfor_Name]

FROM Orion.NPM.CustomPollerAssignment 
WHERE 
  NodeID = 82
  AND CustomPollerName IN (
    'upsBasicBatteryLastReplaceDate',
    'upsAdvBatteryRecommendedReplaceDate',
    'upsAdvBatteryReplacementIndicator'
  )
ORDER BY 
  CASE CustomPollerName
  WHEN 'upsAdvBatteryReplacementIndicator' THEN 1
    WHEN 'upsBasicBatteryLastReplaceDate' THEN 2
    WHEN 'upsAdvBatteryRecommendedReplaceDate' THEN 3
    ELSE 99
  END
