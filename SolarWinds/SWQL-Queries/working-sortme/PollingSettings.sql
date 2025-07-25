SELECT 
    CASE
        WHEN Name = 'Default Asset Inventory Poll Interval' THEN 'Asset Inventory Collection'
        WHEN Name = 'Deafult Poll Interval for Interfaces' THEN 'Interface Response Time and Status'
        WHEN Name = 'Default Node Poll Interval' THEN 'Node Response Time and Status'
        WHEN Name = 'Default Volume Poll Interval' THEN 'Volume Response Time and Status'
        WHEN Name = 'Default Hardware Health Stat Poll Interval' THEN 'Hardware Health Statistic Collection'
        WHEN Name = 'Default Interface Statistics Poll Interval' THEN 'Interface Statistic Collection'
        WHEN Name = 'Default Node Stat Poll Interval' THEN 'Node Statistic Collection'
        WHEN Name = 'Default Volume Stat Poll Interval' THEN 'Volume Statistic Collection'
        WHEN Name = 'VeloCloud - Default Tunnel Statistics poll interval' THEN 'VeloCloud Tunnel Statistic Collection'
        WHEN Name = 'Default multicast routing tables poll interval' THEN 'Multicast Route Table Statistic Collection'
        WHEN Name = 'Default Node Topology Poll Interval' THEN 'Collect Topology Data for Nodes'
        WHEN Name = 'Default routing neighbors poll interval' THEN 'Update Routing Neighbor Data'
        WHEN Name = 'Default routing table poll interval' THEN 'Update Routing Table Data'
        WHEN Name = 'Default VRF poll interval' THEN 'Update VRF Information'
        WHEN Name = 'Meraki - Default Interface Statistics poll interval' THEN 'Meraki Interface Statistic Collection'
        WHEN Name = 'Default Client RSSI Poll Interval' THEN 'Collect Wireless Client Signal Strength'
        ELSE 'Unknown Setting'
    END AS [Name],
    CASE
        WHEN Units IN ('s', 'seconds') THEN CONCAT(CurrentValue, ' sec')
        WHEN Units IN ('m', 'minutes') THEN CONCAT(CurrentValue, ' min')
        ELSE CONCAT(CurrentValue, ' day(s)')
    END AS [Setting]
FROM 
    Orion.Settings
WHERE 
    SettingID IN (
        -- Default Node Poll Interval
        'SWNetPerfMon-Settings-Default Node Poll Interval',
        -- Default Interface Poll Interval
        'SWNetPerfMon-Settings-Default Interface Poll Interval',
        -- Default Volume Poll Interval
        'SWNetPerfMon-Settings-Default Volume Poll Interval',
        -- Default Asset Inventory Poll Interval
        'AssetInventory-PollIntervalDays',
        -- Default Node Topology Poll Interval
        'SWNetPerfMon-Settings-Default Node Topology Poll Interval',
        -- Default Node Statistics Poll Interval
        'SWNetPerfMon-Settings-Default Node Stat Poll Interval',
        -- Default Interface Statistics Poll Interval
        'SWNetPerfMon-Settings-Default Interface Stat Poll Interval',
        -- Default Volume Statistics Poll Interval
        'SWNetPerfMon-Settings-Default Volume Stat Poll Interval',
        -- Default Hardware Health Statistics Poll Interval
        'HardwareHealth-StatisticsPollInterval',
        -- Default Meraki Interface Statistics Poll Interval
        'Meraki_Setting_PollInterfaceStatDefaultInterval',
        -- Default Multicast Route Table Poll Interval
        'NPM_Settings_MulticastRouting_MulticastRouteTable_PollInterval',
        -- Default Routing Neighbor Poll Interval
        'NPM_Settings_Routing_Neighbor_PollInterval',
        -- Default Routing Table Poll Interval
        'NPM_Settings_Routing_RouteTable_PollInterval',
        -- Default VRF Update Poll Interval
        'NPM_Settings_Routing_VRF_PollInterval',
        -- Default VeloCloud Tunnel Statistics Poll Interval
        'VeloCloud_Setting_PollTunnelStatDefaultInterval',
        -- Default Wireless Heatmap Client Signal Strength Poll Interval
        'NPM_Settings_WLHM_ClientLocation_PollInterval'
    )
ORDER BY 
    SettingID;
