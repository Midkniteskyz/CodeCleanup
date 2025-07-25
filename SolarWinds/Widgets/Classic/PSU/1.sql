SELECT 
  DisplayName,

  CASE
  When 'upsAdvBatteryCapacity' Then 'Capacity' 
  When 'upsAdvBatteryRunTimeRemaining' Then 'Remaining RunTime' 
  When 'upsBasicBatteryStatus' Then 'Status'
  When 'upsBasicBatteryTimeOnBattery' Then 'Time On Battery'
  When 'upsBasicBatteryLastReplaceDate' Then 'Last Replace Date'
  When 'upsAdvBatteryTemperature' Then 'Temperature'
 When  'upsAdvBatteryRecommendedReplaceDate' Then 'Next Replace Date'
  When 'upsAdvBatteryReplacementIndicator' Then 'Replacement Status'
  END as [Name],


  CurrentValue, 
  StatusDescription, 
  Status, 
  '/Orion/images/StatusIcons/Small-' + Status AS [_IconFor_Name],
  Uri as [_linkfor_Name]
FROM 
  Orion.NPM.CustomPollerAssignment 
where 
  nodeid = 82
  AND CustomPollerName IN (
  'upsAdvBatteryCapacity', 
  'upsAdvBatteryRunTimeRemaining',
  'upsBasicBatteryStatus',
  'upsBasicBatteryTimeOnBattery',
  'upsBasicBatteryLastReplaceDate',
  'upsAdvBatteryCapacity',
  'upsAdvBatteryTemperature',
  'upsAdvBatteryRecommendedReplaceDate',
  'upsAdvBatteryRunTimeRemaining',
  'upsAdvBatteryReplacementIndicator',
  'upsBasicOutputStatus'
  )
ORDER By CustomPollerOid 
