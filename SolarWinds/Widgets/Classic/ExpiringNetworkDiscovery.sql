SELECT 
  dp.Name, 
  dp.LastRun, 
  (
    SELECT 
      CurrentValue AS RetentionSetting 
    FROM 
      Orion.Settings 
    WHERE 
      SettingID = 'SWNetPerfMon-Settings-Retain Discovery'
  )- DAYDIFF(
    dp.LastRun, 
    GETDATE()
  ) AS DaysTilDeletionIfNotRun 
FROM 
  Orion.DiscoveryProfiles AS dp 
WHERE 
  DAYDIFF(
    dp.LastRun, 
    GETDATE()
  )>(
    SELECT 
      CurrentValue - 7 AS RetentionSetting 
    FROM 
      Orion.Settings 
    WHERE 
      SettingID = 'SWNetPerfMon-Settings-Retain Discovery'
  )
