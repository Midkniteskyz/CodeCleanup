SELECT
-- All Settings returned are from the 'Global SRM Settings' located at "/Orion/SRM/Admin/Default.aspx"
-- Columns used from Orion.Settings : SettingID, Name, CurrentValue, DefaultValue, Units
-------------------------------------------------------------
-- Column 1: Category based on SettingID
CASE 
    WHEN SettingID LIKE 'SRM_Array_%' THEN 'Array'
    WHEN SettingID LIKE 'SRM_Pool_%' THEN 'Pool'
    WHEN SettingID LIKE 'SRM_Lun_%' THEN 'LUN'
    WHEN SettingID LIKE 'SRM_NASVolume_%' THEN 'NAS Volume'
    WHEN SettingID LIKE 'SRM_FileShare_%' THEN 'File Share'
    WHEN SettingID LIKE 'SRM_Vserver_%' THEN 'Vserver'
    WHEN SettingID LIKE 'SRM_StorageController_%' AND SettingID NOT LIKE '%Port%' THEN 'Storage Controller'
    WHEN SettingID LIKE 'SRM_StorageControllerPort_%' THEN 'Storage Controller Port'
END AS [Category],
-------------------------------------------------------------
-- Column 2: Setting name based on Name
CASE 
    WHEN Name LIKE '%Cache Hit Ratio%' THEN 'Cache Hit Ratio'
    WHEN Name LIKE '%Disk Busy%' THEN 'Disk Busy'
    WHEN Name LIKE '%File System Used Capacity%' THEN 'File System Used Capacity'
    WHEN Name LIKE '%IOPS Distribution%' THEN 'IOPS Distribution'
    WHEN Name LIKE '%IOPS Other%' THEN 'IOPS (Other)'
    WHEN Name LIKE '%IOPS Read%' THEN 'IOPS (Read)'
    WHEN Name LIKE '%IOPS Total%' THEN 'IOPS (Total)'
    WHEN Name LIKE '%IOPS Write%' THEN 'IOPS (Write)'
    WHEN Name LIKE '%IOSize Read%' THEN 'IO Size (Read)'
    WHEN Name LIKE '%IOSize Total%' THEN 'IO Size (Total)'
    WHEN Name LIKE '%IOSize Write%' THEN 'IO Size (Write)'
    WHEN Name LIKE '%Latency Other%' THEN 'Latency (Other)'
    WHEN Name LIKE '%Latency Read%' THEN 'Latency (Read)'
    WHEN Name LIKE '%Latency Total%' THEN 'Latency (Total)'
    WHEN Name LIKE '%Latency Write%' THEN 'Latency (Write)'
    WHEN Name LIKE '%Provisioned Capacity%' THEN 'Provisioned Capacity'
    WHEN Name LIKE '%Queue Length Read%' THEN 'Queue Length (Read)'
    WHEN Name LIKE '%Queue Length Total%' THEN 'Queue Length (Total)'
    WHEN Name LIKE '%Queue Length Write%' THEN 'Queue Length (Write)'
    WHEN Name LIKE '%R/W IOPS Ratio%' THEN 'R/W IOPS Ratio'
    WHEN Name LIKE '%Throughput Distribution%' THEN 'Throughput Distribution'
    WHEN Name LIKE '%Throughput Read%' THEN 'Throughput (Read)'
    WHEN Name LIKE '%Throughput Total%' THEN 'Throughput (Total)'
    WHEN Name LIKE '%Throughput Write%' THEN 'Throughput (Write)'
    WHEN Name LIKE '%Utilization%' THEN 'Utilization'
END AS [Setting Name],
-------------------------------------------------------------
-- Column 3: Current Warning Threshold based on CurrentValue
MAX(CASE
    When Name LIKE '%Warning Level%' THEN 
        CONCAT(ToString(
            Case
                When Units = 'IOPS' AND ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN (CurrentValue / 1000)
                When Units = 'IOPS' AND ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN (CurrentValue / 1000000)
                WHEN Units LIKE '%B%' and ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN (CurrentValue / 1000)
                WHEN Units LIKE '%B%' and ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN (CurrentValue / 1000000)  
                WHEN Units LIKE '%B%' and ABS(CurrentValue) >= 1000000000 AND ABS(CurrentValue) < 1000000000000 THEN (CurrentValue / 1000000000)          
                ELSE CurrentValue
            END
            ), ' ',
            CASE
                When Units = 'IOPS' AND ABS(CurrentValue) < 1000 THEN ''
                When Units = 'IOPS' AND ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN 'k'
                When Units = 'IOPS' AND ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN 'mil'
                WHEN Units = 'B' AND ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN 'kB'
                WHEN Units = 'B' AND ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN 'MB'
                WHEN Units = 'B' AND ABS(CurrentValue) >= 1000000000 AND ABS(CurrentValue) < 1000000000000 THEN 'GB'
                WHEN Units LIKE '%/s%' and ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN 'kB/s'
                WHEN Units LIKE '%/s%' and ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN 'MB/s'
                WHEN Units LIKE '%/s%' and ABS(CurrentValue) >= 1000000000 AND ABS(CurrentValue) < 1000000000000 THEN 'GB/s'
                ELSE Units
            END
            )
END) AS [Warning Threshold],
-------------------------------------------------------------
-- Column 4: Current Default Warning Threshold based on DefaultValue
MAX(CASE
    When Name LIKE '%Warning Level%' AND ABS(CurrentValue) <> ABS(DefaultValue) THEN 
        CONCAT(ToString(
            Case
                When Units = 'IOPS' AND ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN (DefaultValue / 1000)
                When Units = 'IOPS' AND ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN (DefaultValue / 1000000)
                WHEN Units LIKE '%B%' and ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN (DefaultValue / 1000)
                WHEN Units LIKE '%B%' and ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN (DefaultValue / 1000000)  
                WHEN Units LIKE '%B%' and ABS(DefaultValue) >= 1000000000 AND ABS(DefaultValue) < 1000000000000 THEN (DefaultValue / 1000000000)          
                ELSE DefaultValue
            END
            ), ' ',
            CASE
                When Units = 'IOPS' AND ABS(DefaultValue) < 1000 THEN ''
                When Units = 'IOPS' AND ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN 'k'
                When Units = 'IOPS' AND ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN 'mil'
                WHEN Units = 'B' AND ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN 'kB'
                WHEN Units = 'B' AND ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN 'MB'
                WHEN Units = 'B' AND ABS(DefaultValue) >= 1000000000 AND ABS(DefaultValue) < 1000000000000 THEN 'GB'
                WHEN Units LIKE '%/s%' and ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN 'kB/s'
                WHEN Units LIKE '%/s%' and ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN 'MB/s'
                WHEN Units LIKE '%/s%' and ABS(DefaultValue) >= 1000000000 AND ABS(DefaultValue) < 1000000000000 THEN 'GB/s'
                ELSE Units
            END
            )
    WHEN Name LIKE '%Warning Level%' AND ABS(CurrentValue) = ABS(DefaultValue) THEN 'Same'
END) AS [Default Warning Threshold],
-------------------------------------------------------------
-- Column 5: Current Critical Threshold based on CurrentValue
MAX(CASE
    When Name LIKE '%Critical Level%' THEN 
        CONCAT(ToString(
            Case
                When Units = 'IOPS' AND ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN (CurrentValue / 1000)
                When Units = 'IOPS' AND ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN (CurrentValue / 1000000)
                WHEN Units LIKE '%B%' and ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN (CurrentValue / 1000)
                WHEN Units LIKE '%B%' and ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN (CurrentValue / 1000000)  
                WHEN Units LIKE '%B%' and ABS(CurrentValue) >= 1000000000 AND ABS(CurrentValue) < 1000000000000 THEN (CurrentValue / 1000000000)          
                ELSE CurrentValue
            END
            ), ' ',
            CASE
                When Units = 'IOPS' AND ABS(CurrentValue) < 1000 THEN ''
                When Units = 'IOPS' AND ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN 'k'
                When Units = 'IOPS' AND ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN 'mil'
                WHEN Units = 'B' AND ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN 'kB'
                WHEN Units = 'B' AND ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN 'MB'
                WHEN Units = 'B' AND ABS(CurrentValue) >= 1000000000 AND ABS(CurrentValue) < 1000000000000 THEN 'GB'
                WHEN Units LIKE '%/s%' and ABS(CurrentValue) >= 1000 AND ABS(CurrentValue) < 1000000 THEN 'kB/s'
                WHEN Units LIKE '%/s%' and ABS(CurrentValue) >= 1000000 AND ABS(CurrentValue) < 1000000000 THEN 'MB/s'
                WHEN Units LIKE '%/s%' and ABS(CurrentValue) >= 1000000000 AND ABS(CurrentValue) < 1000000000000 THEN 'GB/s'
                ELSE Units
            END
            )
END) AS [Critical Threshold],
-------------------------------------------------------------
-- Column 6: Current Default Critcal Threshold based on DefaultValue
MAX(CASE
    When Name LIKE '%Critical Level%' AND ABS(CurrentValue) <> ABS(DefaultValue) THEN 
        CONCAT(ToString(
            Case
                When Units = 'IOPS' AND ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN (DefaultValue / 1000)
                When Units = 'IOPS' AND ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN (DefaultValue / 1000000)
                WHEN Units LIKE '%B%' and ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN (DefaultValue / 1000)
                WHEN Units LIKE '%B%' and ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN (DefaultValue / 1000000)  
                WHEN Units LIKE '%B%' and ABS(DefaultValue) >= 1000000000 AND ABS(DefaultValue) < 1000000000000 THEN (DefaultValue / 1000000000)          
                ELSE DefaultValue
            END
            ), ' ',
            CASE
                When Units = 'IOPS' AND ABS(DefaultValue) < 1000 THEN ''
                When Units = 'IOPS' AND ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN 'k'
                When Units = 'IOPS' AND ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN 'mil'
                WHEN Units = 'B' AND ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN 'kB'
                WHEN Units = 'B' AND ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN 'MB'
                WHEN Units = 'B' AND ABS(DefaultValue) >= 1000000000 AND ABS(DefaultValue) < 1000000000000 THEN 'GB'
                WHEN Units LIKE '%/s%' and ABS(DefaultValue) >= 1000 AND ABS(DefaultValue) < 1000000 THEN 'kB/s'
                WHEN Units LIKE '%/s%' and ABS(DefaultValue) >= 1000000 AND ABS(DefaultValue) < 1000000000 THEN 'MB/s'
                WHEN Units LIKE '%/s%' and ABS(DefaultValue) >= 1000000000 AND ABS(DefaultValue) < 1000000000000 THEN 'GB/s'
                ELSE Units
            END
            )
    WHEN Name LIKE '%Critical Level%' AND ABS(CurrentValue) = ABS(DefaultValue) THEN 'Same'
END) AS [Default Critical Threshold]
-------------------------------------------------------------
FROM 
  Orion.Settings 
-------------------------------------------------------------
-- Filter out all settings that do not appear in Global SRM Settings
WHERE 
  SettingID LIKE '%srm%' 
  AND SettingID NOT IN (
    'SRM_Array_ControllerInterval', 
    'SRM_Array_RediscoveryInterval', 
    'SRM_Array_StatCollection', 'SRM_Array_TopologyInterval', 
    'SRM_Array_Thresholds_IOSize_Other_Critical', 
    'SRM_Array_Thresholds_IOSize_Other_Warning', 
    'SRM_Array_Thresholds_Throughput_Other_Critical', 
    'SRM_Array_Thresholds_Throughput_Other_Warning', 
    'SRM_Pool_Thresholds_IOSize_Other_Critical', 
    'SRM_Pool_Thresholds_IOSize_Other_Warning', 
    'SRM_Pool_Thresholds_Throughput_Other_Critical', 
    'SRM_Pool_Thresholds_Throughput_Other_Warning', 
    'SRM_Lun_Thresholds_FileSystemUsedCapacity_Critical', 
    'SRM_Lun_Thresholds_FileSystemUsedCapacity_Warning', 
    'SRM_Lun_Thresholds_IOSize_Other_Critical', 
    'SRM_Lun_Thresholds_IOSize_Other_Warning', 
    'SRM_Lun_Thresholds_ProvisionedCapacity_Critical', 
    'SRM_Lun_Thresholds_ProvisionedCapacity_Warning', 
    'SRM_Lun_Thresholds_Throughput_Other_Critical', 
    'SRM_Lun_Thresholds_Throughput_Other_Warning', 
    'SRM_NasVolume_Thresholds_IOSize_Other_Critical', 
    'SRM_NasVolume_Thresholds_IOSize_Other_Warning', 
    'SRM_NasVolume_Thresholds_Throughput_Other_Critical', 
    'SRM_NasVolume_Thresholds_Throughput_Other_Warning', 
    'SRM_Vserver_Thresholds_CacheHitRatio_Critical', 
    'SRM_Vserver_Thresholds_CacheHitRatio_Warning', 
    'SRM_Vserver_Thresholds_IOSize_Other_Critical', 
    'SRM_Vserver_Thresholds_IOSize_Other_Warning', 
    'SRM_Vserver_Thresholds_Throughput_Other_Critical', 
    'SRM_Vserver_Thresholds_Throughput_Other_Warning', 
    'SRM_StorageController_Thresholds_IOSize_Other_Critical', 
    'SRM_StorageController_Thresholds_IOSize_Other_Warning', 
    'SRM_CriticalThreshold_CapacityRunOut', 
    'SRM_CriticalThresholdDays', 'SRM_CriticalThresholdLatencyMS', 
    'SRM_Provider_PollingInterval', 
    'SRM_RunOutTimePeriod_Arrays', 
    'SRM_RunOutTimePeriod_Luns', 'SRM_RunOutTimePeriod_Pools', 
    'SRM_RunOutTimePeriod_Volumes', 
    'SRM_RunOutTimePeriod_Vservers', 
    'SRM_WarningThreshold_CapacityRunOut', 
    'SRM_WarningThresholdDays', 'SRM_WarningThresholdLatencyMS'
  )
-------------------------------------------------------------
-- Grouping must be declared based off the original select statements.
GROUP BY
-- Column 1: Category
CASE 
    WHEN SettingID LIKE 'SRM_Array_%' THEN 'Array'
    WHEN SettingID LIKE 'SRM_Pool_%' THEN 'Pool'
    WHEN SettingID LIKE 'SRM_Lun_%' THEN 'LUN'
    WHEN SettingID LIKE 'SRM_NASVolume_%' THEN 'NAS Volume'
    WHEN SettingID LIKE 'SRM_FileShare_%' THEN 'File Share'
    WHEN SettingID LIKE 'SRM_Vserver_%' THEN 'Vserver'
    WHEN SettingID LIKE 'SRM_StorageController_%' AND SettingID NOT LIKE '%Port%' THEN 'Storage Controller'
    WHEN SettingID LIKE 'SRM_StorageControllerPort_%' THEN 'Storage Controller Port'
END,
-- Column 2: Setting name
CASE 
    WHEN Name LIKE '%Cache Hit Ratio%' THEN 'Cache Hit Ratio'
    WHEN Name LIKE '%Disk Busy%' THEN 'Disk Busy'
    WHEN Name LIKE '%File System Used Capacity%' THEN 'File System Used Capacity'
    WHEN Name LIKE '%IOPS Distribution%' THEN 'IOPS Distribution'
    WHEN Name LIKE '%IOPS Other%' THEN 'IOPS (Other)'
    WHEN Name LIKE '%IOPS Read%' THEN 'IOPS (Read)'
    WHEN Name LIKE '%IOPS Total%' THEN 'IOPS (Total)'
    WHEN Name LIKE '%IOPS Write%' THEN 'IOPS (Write)'
    WHEN Name LIKE '%IOSize Read%' THEN 'IO Size (Read)'
    WHEN Name LIKE '%IOSize Total%' THEN 'IO Size (Total)'
    WHEN Name LIKE '%IOSize Write%' THEN 'IO Size (Write)'
    WHEN Name LIKE '%Latency Other%' THEN 'Latency (Other)'
    WHEN Name LIKE '%Latency Read%' THEN 'Latency (Read)'
    WHEN Name LIKE '%Latency Total%' THEN 'Latency (Total)'
    WHEN Name LIKE '%Latency Write%' THEN 'Latency (Write)'
    WHEN Name LIKE '%Provisioned Capacity%' THEN 'Provisioned Capacity'
    WHEN Name LIKE '%Queue Length Read%' THEN 'Queue Length (Read)'
    WHEN Name LIKE '%Queue Length Total%' THEN 'Queue Length (Total)'
    WHEN Name LIKE '%Queue Length Write%' THEN 'Queue Length (Write)'
    WHEN Name LIKE '%R/W IOPS Ratio%' THEN 'R/W IOPS Ratio'
    WHEN Name LIKE '%Throughput Distribution%' THEN 'Throughput Distribution'
    WHEN Name LIKE '%Throughput Read%' THEN 'Throughput (Read)'
    WHEN Name LIKE '%Throughput Total%' THEN 'Throughput (Total)'
    WHEN Name LIKE '%Throughput Write%' THEN 'Throughput (Write)'
    WHEN Name LIKE '%Utilization%' THEN 'Utilization'
END
-------------------------------------------------------------
ORDER BY [Category], [Setting Name] ASC
