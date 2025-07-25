SELECT 
  CASE CustomPollerName
    WHEN 'upsBasicBatteryStatus' THEN 'Battery Status'
    WHEN 'upsAdvBatteryCapacity' THEN 'Capacity'
    WHEN 'upsAdvBatteryRunTimeRemaining' THEN 'Remaining Runtime'
    WHEN 'upsBasicBatteryTimeOnBattery' THEN 'Time on Battery'
    WHEN 'upsAdvBatteryTemperature' THEN 'Temperature (C°)'
    WHEN 'upsBasicOutputStatus' THEN 'Output Status'
    ELSE CustomPollerName
  END AS [Name],

  CurrentValue AS [Value],  
  CONCAT('/Orion/images/StatusIcons/Small-', StatusDescription,'.gif') AS [_IconFor_Name],
  Uri AS [_linkfor_Name]

FROM Orion.NPM.CustomPollerAssignment 
WHERE 
  NodeID = 82
  AND CustomPollerName IN (
    'upsBasicBatteryStatus',
    'upsAdvBatteryCapacity', 
    'upsAdvBatteryRunTimeRemaining',
    'upsBasicBatteryTimeOnBattery',
    'upsAdvBatteryTemperature',
    'upsBasicOutputStatus'
  )
ORDER BY 
  CASE CustomPollerName
    WHEN 'upsBasicBatteryStatus' THEN 1
    WHEN 'upsAdvBatteryCapacity' THEN 2
    WHEN 'upsAdvBatteryRunTimeRemaining' THEN 3
    WHEN 'upsBasicBatteryTimeOnBattery' THEN 4
    WHEN 'upsAdvBatteryTemperature' THEN 5
    WHEN 'upsBasicOutputStatus' THEN 6
    ELSE 99
  END
