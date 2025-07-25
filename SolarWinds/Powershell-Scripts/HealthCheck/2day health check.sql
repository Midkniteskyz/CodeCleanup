-- Nodes / Observations / Volume Status
SELECT 
  COUNT(v.Type) AS [Total Fixed Disk], 
  COUNT(CASE WHEN Status = 0 THEN 1 END) AS [Unknown], 
  COUNT(CASE WHEN Status = 1 THEN 1 END) AS [Up], 
  COUNT(CASE WHEN Status = 2 THEN 1 END) AS [Down], 
  COUNT(CASE WHEN Status = 3 THEN 1 END) AS [Warning], 
  COUNT(CASE WHEN Status = 9 THEN 1 END) AS [Unmanaged], 
  COUNT(CASE WHEN Status = 12 THEN 1 END) AS [Unreachable], 
  COUNT(CASE WHEN Status = 14 THEN 1 END) AS [Critical] 
FROM 
  Orion.Volumes v 
WHERE 
  v.Type = 'Fixed Disk';

-- Nodes / Observations / Interface Status
SELECT 
  COUNT(i.InterfaceID) AS [Total Interface], 
  COUNT(CASE WHEN i.Status = 0 THEN 1 END) AS [Unknown], 
  COUNT(CASE WHEN i.OperStatus = 1 THEN 1 END) AS [Up], 
  COUNT(CASE WHEN i.OperStatus = 2 THEN 1 END) AS [Down], 
  COUNT(CASE WHEN Status = 3 THEN 1 END) AS [Warning], 
  COUNT(CASE WHEN i.AdminStatus = 4 THEN 1 END) AS [Shutdown],
  COUNT(CASE WHEN Status = 9 THEN 1 END) AS [Unmanaged],  
  COUNT(CASE WHEN Status = 10 THEN 1 END) AS [Unplugged], 
  COUNT(CASE WHEN Status = 12 THEN 1 END) AS [Unreachable] 
FROM 
  Orion.NPM.Interfaces i 
--WHERE 
--  i.ObjectSubType = 'SNMP';
--  i.ObjectSubType = 'WMI';

-- Nodes / Observations / Nodes not responding to CPU

SELECT
  COUNT(CASE WHEN ((n.objectsubtype != 'SNMP' AND n.community = '') OR n.objectsubtype = 'SNMP') THEN 1 END) AS [SNMPv2 Community Count],
  COUNT(CASE WHEN NOT ((n.objectsubtype != 'SNMP' AND n.community = '') OR n.objectsubtype = 'SNMP') THEN 1 END) AS [WMI Count]
FROM
  orion.nodes n
WHERE
  n.status <> '2'
  AND n.status <> '9'
  AND n.objectsubtype != 'ICMP'
  AND minutediff(lastsystemuptimepollUTC, getutcdate()) > 20;

-- Nodes / Observations / Unneeded Interfaces

SELECT 
  COUNT(CASE WHEN Name LIKE '%Loopback%' OR Name LIKE '%lo%' THEN 1 END) AS [Loopbacks],
  COUNT(CASE WHEN Name LIKE '%null%' THEN 1 END) AS [Nulls],
  COUNT(CASE WHEN Name LIKE '%pot%' THEN 1 END) AS [Pots],
  COUNT(CASE WHEN Name LIKE '%unrouted%' THEN 1 END) AS [Unrouted],
  COUNT(CASE WHEN Name LIKE '%uncontrolled%' THEN 1 END) AS [Uncontrolled],
  COUNT(CASE WHEN Name LIKE '%window%' THEN 1 END) AS [Windows]

FROM 
  Orion.NPM.Interfaces i;


-- Alerting

-- Last 7 days
select 
ac.name
,ao.entitycaption
,count(*) as [alert count]
FROM Orion.AlertHistory ah
JOIN Orion.AlertObjects ao ON ao.AlertObjectID = ah.alertobjectid
JOIN Orion.Alertconfigurations ac ON ac.AlertID = ao.alertid
WHERE ah.TimeStamp >= AddDay(-7,GetDate())
GROUP BY ao.entitycaption
ORDER BY [Alert Count] DESC;

select 
  ao.EntityCaption, 
  ac.Name, 
  ac.Description, 
  ah.Message, 
  ac.AlertMessage, 
  ac.Enabled, 
  ac.Severity,
  ao.TriggeredCount, 
  ah.TimeStamp, 
  ao.LastTriggeredDateTime
FROM Orion.AlertHistory ah
JOIN Orion.AlertObjects ao ON ao.AlertObjectID = ah.alertobjectid
JOIN Orion.Alertconfigurations ac ON ac.AlertID = ao.alertid

--top triggered
SELECT TOP 5 Name, EntityCaption,TriggeredCount, LastTriggeredDateTime
FROM Orion.AlertObjects ao
Join orion.AlertConfigurations ac
    on ac.AlertID = ao.AlertID
order by Triggeredcount DESC



--failed
SELECT TOP 1000 [History].AlertObjects.EntityCaption AS [Triggering Entity]
     , [History].AlertObjects.EntityDetailsUrl AS [Triggering Deatils]
     , [History].EventType
     , [Actions].Description
     , [History].Message
     , [History].TimeStamp
FROM Orion.AlertHistory AS [History]
LEFT JOIN Orion.Actions AS [Actions]
     ON [History].ActionID = [Actions].ActionID
ORDER BY [History].TimeStamp DESC

-- top trigger
SELECT top 10
 EntityCaption,TriggeredCount, LastTriggeredDateTime
FROM Orion.AlertObjects ao
order by triggeredcount desc

-- Disabled Session timeouts count
SELECT 
    Count(Case When DisableSessionTimeout = 'Y' Then 1 end) AS [DisabledTimeouts]
FROM Orion.Accounts

--controller count
SELECT 
count(IPAddress)as [controllercount]
--ThinAPsCount
FROM Orion.Wireless.Controllers

-- NCM Vendor Count
SELECT
    Vendor,
    COUNT(NodeID) AS NodeCount
FROM Cirrus.NCMNodeLicenseStatus ncmlic
JOIN orion.Nodes nodes ON nodes.nodeid = ncmlic.nodeid
WHERE ncmlic.LicensedByNCM = 'Yes'
GROUP BY Vendor;


