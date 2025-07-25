{

    "Orion Servers": [

        {

            "table": "Orion Servers 1",

            "query": "Select Hostname, ServerType as Type from Orion.OrionServers"

        },

        {

            "table": "Orion Servers 2",

            "query": "Select Hostname, ServerType as Type from Orion.OrionServers"

        }

    ],

    "Orion Polling": [

        {

            "table": "Orion Polling",

            "query": "Select ServerName as Name, ServerType as Type, IP, KeepAlive, Elements, Nodes, Interfaces, Volumes from Orion.Engines"

        }

    ],

    "Orion Core": [

        {

            "table": "Discovery",

            "query": "Select ProfileID, Description, LastRun from Orion.DiscoveryProfiles"

        }

    ],

    "NPM": [

        //#region Netpath By Probe
        {

            "table": "NetPath by Probe",

            "query": "Select a.ServiceAssignments.Status, a.ProbeID from Orion.NetPath.Probes a where a.Enabled=1"

        },
        //#endregion

        //#region NPM Elements per Polling Engine
        {
            "table": "NPM Elements per Polling Engine",

            "query": `
            SELECT
                ServerName,
                IP,
                ServerType,
                Elements,
                Nodes,
                Interfaces,
                Volumes
            FROM Orion.Engines
          `
        },
        //#endregion

        //TODO
        //#region NPM Syslog and Traps
        {
            "table": "",

            "query": ""
        },
        //#endregion

        //#region NPM Polling Intervals
        {
            "table": "NPM Polling Intervals (Global)",

            "query": `
            SELECT
    ServerName,
    IP,
    ServerType,
    NodePollInterval,
    InterfacePollInterval,
    VolumePollInterval,
    NodeStatPollInterval,
    InterfaceStatPollInterval,
    VolumeStatPollInterval,
    PollingCompletion
FROM Orion.Engines
            `
        },
        
        //TODO Slightly off on the interface and volume count
        {
            "table": "Full Disparate Table",

            "query": `
            SELECT
            n.PollInterval AS [Polling Rate],
            COUNT(DISTINCT n.NodeID) AS NodeCount,
            COUNT(DISTINCT i.InterfaceID) AS InterfaceCount,
            COUNT(DISTINCT v.VolumeID) AS VolumeCount
        FROM Orion.Nodes n
        LEFT JOIN (
            SELECT DISTINCT NodeID, InterfaceID
            FROM Orion.NPM.Interfaces
        ) i ON n.NodeID = i.NodeID
        LEFT JOIN (
            SELECT DISTINCT NodeID, VolumeID
            FROM Orion.Volumes
        ) v ON n.NodeID = v.NodeID
        GROUP BY n.PollInterval;
            `
        },

        {
            "table": "NPM Node Poll Interval Differences",

            "query": `
            SELECT COUNT(NodeID) AS Nodes,
            PollInterval
FROM Orion.Nodes
GROUP BY
PollInterval
            `
        },

        {
            "table": "NPM Interface Poll Interval Differences",

            "query": `
            SELECT COUNT(InterfaceID) AS Interfaces,
            PollInterval
FROM Orion.NPM.Interfaces
GROUP BY
PollInterval
`
        },

        {
            "table": "NPM Volume Poll Interval Differences",

            "query": `
            SELECT COUNT(VolumeID) AS Volumes,
            PollInterval
FROM Orion.Volumes
GROUP BY
PollInterval
`
        },
        //#endregion

        //#region NPM Statistics Polling Intervals
        {
            "table": "Disparate polling cycles and load for Nodes",

            "query": `
            SELECT COUNT(NodeID) AS Nodes, StatCollection 
            FROM Orion.Nodes 
            GROUP BY StatCollection
            `
        },

        {
            "table": "Disparate polling cycles and load for Interfaces",

            "query": `
            SELECT COUNT(InterfaceID) AS Interfaces, StatCollection 
FROM Orion.NPM.Interfaces 
GROUP BY StatCollection
`
        },

        {
            "table": "Disparate polling cycles and load for Volumes",

            "query": `
            SELECT COUNT(VolumeID) AS Volumes, StatCollection 
FROM Orion.Volumes 
GROUP BY StatCollection
`
        },
        //#endregion

        //TODO Missing the Syslog and Traps
        //#region NPM Data Retention
        {
            "table": "NPM Data Retention",

            "query": `
            SELECT
    CASE
        WHEN SettingID LIKE 'SWNetPerfMon-Settings-Retain Auditing%'
            THEN REPLACE(SettingID, 'SWNetPerfMon-Settings-Retain Auditing Trails', 'Audit Log')
        WHEN SettingID LIKE 'SWNetPerfMon-Settings-Retain Events%'
            THEN REPLACE(SettingID, 'SWNetPerfMon-Settings-Retain ', '')
        WHEN SettingID LIKE 'SWNetPerfMon-Settings-Retain %'
            THEN REPLACE(SettingID, 'SWNetPerfMon-Settings-Retain', 'Node')
        WHEN SettingID LIKE 'NPM_Settings_InterfaceAvailability_Retain_%'
            THEN REPLACE(SettingID, 'NPM_Settings_InterfaceAvailability_Retain_', 'Interface ')
        WHEN SettingID LIKE 'SWNetPerfMon-Settings-Baseline%'
            THEN REPLACE(SettingID, 'SWNetPerfMon-Settings-Baseline Collection Duration', 'Baseline Collection')
        ELSE NULL
    END AS ModifiedSettingID,
    CurrentValue,
    CASE
        WHEN CurrentValue <> DefaultValue THEN 'Yes'
        ELSE 'No'
    END AS ModifiedValue
FROM
    Orion.Settings
WHERE
    SettingID IN ('SWNetPerfMon-Settings-Retain Detail', 'SWNetPerfMon-Settings-Retain Hourly', 'SWNetPerfMon-Settings-Retain Daily', 'NPM_Settings_InterfaceAvailability_Retain_Detail', 'NPM_Settings_InterfaceAvailability_Retain_Hourly', 'NPM_Settings_InterfaceAvailability_Retain_Daily', 'SWNetPerfMon-Settings-Retain Events', 'SWNetPerfMon-Settings-Retain Auditing Trails', 'SWNetPerfMon-Settings-Baseline Collection Duration')

ORDER BY 
    CASE SettingID
        WHEN 'SWNetPerfMon-Settings-Retain Detail' THEN 1
        WHEN 'SWNetPerfMon-Settings-Retain Hourly' THEN 2
        WHEN 'SWNetPerfMon-Settings-Retain Daily' THEN 3
        WHEN 'NPM_Settings_InterfaceAvailability_Retain_Detail' THEN 4
        WHEN 'NPM_Settings_InterfaceAvailability_Retain_Hourly' THEN 5
        WHEN 'NPM_Settings_InterfaceAvailability_Retain_Daily' THEN 6
        WHEN 'SWNetPerfMon-Settings-Retain Events' THEN 7
        WHEN 'SWNetPerfMon-Settings-Retain Auditing Trails' THEN 8
        WHEN 'SWNetPerfMon-Settings-Baseline Collection Duration' THEN 9
    END;

            `
        },
        //#endregion

        //#region NPM Polling Completion
        {
            "table": "NPM Polling Completion",

            "query": `
            SELECT ServerName, IP, ServerType, PollingCompletion
FROM Orion.Engines
`
        },
        //#endregion

        //#region NPM Polling Rate Load
        {
            "table": "NPM Polling Rate Load",

            "query": `
            SELECT 
    EngineID, 
    CONCAT(CurrentUsage, ' %') AS Usage

FROM 
    Orion.PollingUsage
WHERE 
    ScaleFactor LIKE 
        'Orion.Standard.%'
            `
        },
        //#endregion

        //#region NPM Groups
        {
            "table": "Total Groups",

            "query": `
            select count(containerid) as [Groups]
            from orion.Container
            `
        },

        {
            "table": "Total Dynamic Groups",

            "query": `
            select 
            count(distinct cd.ContainerID) as [Dynamic] 
          from 
            orion.ContainerMemberDefinition cd 
          where 
            cd.definition like 'filter%'
            `
        },

        //TODO Subquery for both groups
        /* 
        {
            "table": "NPM Groups",

            "query": `
            SELECT 
  COUNT(DISTINCT c.containerid) AS [Groups], 
  COUNT(DISTINCT cd.ContainerID) as [Dynamic]

FROM 
  orion.Container AS c 
  LEFT JOIN (
    SELECT 
       cd.ContainerID
    FROM 
      orion.ContainerMemberDefinition cd 
    WHERE 
      cd.definition LIKE 'filter%'
  ) cd ON c.ContainerID = cd.ContainerID
            `
        },
        */

        //#endregion NPM Groups

        //#region NPM Dependencies
        {
            "table": "NPM Dependencies",

            "query": `
            SELECT count(DependencyId) as [Total]
,(SELECT count(DependencyId) as [Total]
from orion.Dependencies
where automanaged=1) as [Auto]
FROM Orion.Dependencies
            `
        },
        //#endregion 

    ],

    "SAM": [

        //#region SAM Application Monitors
        {
            "table": "SAM Application Monitors",

            "query": `
            SELECT 
Concat(i.StatusName, ' Total') as StatusName,  
Count(applicationid) as [Count]
FROM Orion.APM.Application a
join orion.StatusInfo i 
on i.StatusId=a.Status
group by 
    GROUPING SETS ((statusname), ())
order by 
    GROUPING(i.StatusName), i.StatusName
    `
        },
        //#endregion

        //TODO
        //#region SAM Data Retention
        {
            "table": "",

            "query": ""
        },
        //#endregion

        //TODO
        //#region SAM Polling Rate (Load)
        {
            "table": "",

            "query": ""
        },
        //#endregion

        //TODO
        //#region AppInsight for SQL Data Retention
        {
            "table": "",

            "query": ""
        },
        //#endregion

        //TODO
        //#region AppInsight for Exchange Data Retention
        {
            "table": "",

            "query": ""
        },
        //#endregion AppInsight for Exchange Data Retention
    ],

    "NCM": [

        //#region NCM Nodes
        {
            "table": "NCM Nodes",

            "query": `
            SELECT COUNT(N.NodeID) AS [NCMCount]
    FROM NCM.Nodes As N
    `
        },
        //#endregion NCM Nodes

        //TODO
        //#region NCM Inventory
        {
            "table": "NCM Inventory",

            "query": ``
        },
        //#endregion 

        //TODO
        //#region NCM Config Backups
        {
            "table": "NCM Config Backups",

            "query": ``
        },
        //#endregion

        //TODO
        //#region NCM Jobs
        {
            "table": "NCM Jobs",

            "query": ``
        },
        //#endregion

        //TODO
        //#region NCM EOS
        {
            "table": "NCM EOS",

            "query": `
            SELECT COUNT(NodeID) AS NumberOfNodesWithEOS
FROM NCM.NodeProperties
WHERE EndOfSupport IS NOT NULL;

            `
        },
        //#endregion
    ],

    "IPAM": [

        //#region IPAM Elements
        {
            "table": "IPAM Elements",

            "query": `
            SELECT count(distinct GroupId) as [Counts], GroupTypeText
FROM IPAM.GroupNode
group by grouptypetext
ORDER BY grouptypetext ASC
            `
        },
        //#endregion

        //TODO
        //#region IPAM Polling Intervals
        {
            "table": "",

            "query": ``
        },
        //#endregion IPAM Polling Intervals

        //TODO
        //#region
        {
            "table": "IPAM Data Retention",

            "query": ``
        }
        //#endregion
    ],

    "UDT": [

        //TODO Try and find the rules table for the watchlist count.
        //#region UDT Elements
        {
            "table": "",

            "query": `
            SELECT 
    COUNT(UDTPorts.PortID) AS NumOfPorts,
    Engines.ServerName 
 
from 
    Orion.Nodes AS Nodes
    JOIN Orion.UDT.Port AS UDTPorts On Nodes.NodeID = UDTPorts.NodeID
    JOIN Orion.Engines AS Engines ON Nodes.EngineID = Engines.EngineID
GROUP BY 
  Engines.ServerName 

            `
        },
        //#endregion

        //TODO
        //#region UDT Polling Intervals
        {
            "table": "",

            "query": ``
        },
        //#endregion

        //#region UDT Data Retention
        {
            "table": "",

            "query": `
            SELECT 
  CASE WHEN SettingName = 'Data-Retention' 
  THEN REPLACE(
      REPLACE(SettingName, '-', ' '), 
      'Data Retention', 
      'History'
  ) ELSE 
    REPLACE(
      REPLACE(SettingName, '-', ' '), 
      'Data Retention Statistics ', 
      ''
    ) END AS DataRetentionName, 
  Concat(SettingValue, ' days') AS RetentionValue 
FROM 
  Orion.UDT.Setting 
WHERE 
  SettingName IN (
    'Data-Retention', 
    'Data-Retention-Statistics-Detail', 
    'Data-Retention-Statistics-Hourly', 
    'Data-Retention-Statistics-Daily'
  ) 

ORDER BY 
    CASE SettingName
        WHEN 'Data-Retention' THEN 1
        WHEN 'Data-Retention-Statistics-Detail' THEN 2
        WHEN 'Data-Retention-Statistics-Hourly' THEN 3
        WHEN 'Data-Retention-Statistics-Daily' THEN 4
    END;

            `
        },
        //#endregion
    ],

    "VNQM": [

        //#region VNMQ Elements
        {
            "table": "VNQM Elements",

            "query": `
            SELECT '' as [ ]
,count(distinct NodeID) as [Nodes]
, count(OperationInstanceID) as [Operations]
,(SELECT count(SiteID) as [Sites] FROM Orion.IpSla.Sites) as [Sites]
,(SELECT count(NodeID) as [CM] FROM Orion.IpSla.CallManagerCurrentStats) as [CallManagers]
,(SELECT count(NodeID) as [G]  FROM Orion.IpSla.VoipGateways) as [Gateways]
FROM Orion.IpSla.Operations
order by [ ]
            `
        },
        //#endregion

        //TODO
        //#region VNMQ Polling Intervals
        {
            "table": "",

            "query": ``
        },
        //#endregion

        //TODO
        //#region VNMQ Data Retention
        {
            "table": "",

            "query": ``
        },
        //#endregion

    ],

    "WPM": [

        //#region WPM Transaction Monitors
        {
            "table": "",

            "query": ``
        },
        //#endregion

        //#region WPM Data Retention
        {
            "table": "",

            "query": ``
        },
        //#endregion
    ],

    "NTA": [

        //#region NTA Sources
        {
            "table": "",

            "query": `
            SELECT COUNT(DISTINCT NodeID) as [Source Nodes]
            ,COUNT(NetflowSourceID) as [Source Interfaces]
            ,(SELECT COUNT(DISTINCT NodeID) as [Source Nodes] FROM Orion.Netflow.Source where DAYDIFF(LastTime,GETDATE())>1) as [Stale Sources]
            ,(SELECT COUNT(IPAddressGroupID) as [Groups] FROM Orion.NetFlow.IPAddressGroupRanges) as [IP Groups]
            
            FROM Orion.Netflow.Source
            `
        },
        //#endregion

        //TODO
        //#region NTA Flows per Second
        {
            "table": "",

            "query": ``
        },
        //#endregion

        //TODO
        //#region IP Address Groups
        {
            "table": "",

            "query": ``
        },
        //#endregion

        //#region Retention Period
        {
            "table": "",

            "query": ``
        },
        //#endregion

    ],

    "VIM": [
                //#region
        //#endregion
    ],

    "OLM": [
                //#region
        //#endregion
    ],

    "SCM": [

                //#region
        //#endregion
    ],

    "SRM": [

                //#region
        //#endregion
    ],

    "VMAN": [

        //#region Elements
        {
            "table": "VMAN Elements",

            "query": `
            SELECT 
  COUNT(ClusterID) AS [Clusters], 
  (
    SELECT 
      COUNT(DataCenterID) AS [SourceDataCenterCount] 
    FROM 
      Orion.VIM.DataCenters
  ) AS [DataCenters], 
  (
    SELECT 
      COUNT(VCenterID) AS [SourceVCenterIDCount] 
    FROM 
      Orion.VIM.VCenters
  ) AS [vCenters], 
  (
    SELECT 
      COUNT(HostID) AS [SourceHostID] 
    FROM 
      Orion.VIM.Hosts
  ) AS [Hosts], 
  (
    SELECT 
      COUNT(ManagedObjectID) AS [SourceVMsID] 
    FROM 
      Orion.VIM.VirtualMachines
  ) AS [VMs] 
FROM 
  Orion.VIM.Clusters
            `
        },
        //#endregion

        //#region Polling Intervals
        {
            "table": "",

            "query": `
            SELECT 
      PollingInterval, 
      COUNT(HostID) AS [HostCount], 
      COUNT(VcenterID) AS [VCenterCount] 
    FROM 
      Orion.VIM.PollingTasks 
    Where 
      LastPoll IS NOT NULL 
    Group BY 
      PollingInterval
            `
        },
        //#endregion Polling Intervals

        //#region Data Retention
        {
            "table": "VMAN Data Retention",

            "query": `
            SELECT
  MAX(CASE WHEN Name = 'VIM Detailed Statistics Retention' THEN CONCAT(CurrentValue, ' Days') END) AS [VIM Detailed Statistics Retention],
  MAX(CASE WHEN Name = 'VIM Hourly Statistics Retention' THEN CONCAT(CurrentValue, ' Days') END) AS [VIM Hourly Statistics Retention],
  MAX(CASE WHEN Name = 'VIM Daily Statistics Retention' THEN CONCAT(CurrentValue, ' Days') END) AS [VIM Daily Statistics Retention]
FROM 
  Orion.Settings
WHERE
  SettingID IN ('VIM_Setting_Detailed_Retain', 'VIM_Setting_Hourly_Retain', 'VIM_Setting_Daily_Retain');
            `
        },
        //#endregion
    ]

}