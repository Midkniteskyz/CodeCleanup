SELECT
 
pdut.Volume.Node.caption as [Node Name],
concat('/Orion/images/StatusIcons/Small-', pdut.Volume.Node.statusicon) as [_iconfor_Node Name],
pdut.Volume.Node.detailsurl as [_linkfor_Node Name],

pdut.Volume.FullName as [Volume Name],
Concat('/Orion/NetPerfMon/VolumeDetails.aspx?NetObject=V:',pdut.InstanceId) as [_linkfor_Volume Name],
 
round(pdut.CurrentValue, 2) as [Used Space],
 
 
CASE
when pdut.IsLevel2State = 1 then 'Critical Threshold Exceeded'
else 'Warning Threshold Exceeded'
end as [Status],
Concat('/Orion/Nodes/VolumeProperties.aspx?Volumes=',pdut.InstanceId) as [_linkfor_Status],
 
case 
when pdut.IsLevel2State = 1 then '/Orion/images/StatusIcons/Small-Critical.gif'
else '/Orion/images/StatusIcons/Small-Warning.gif'
end as [_iconfor_Status],
 
case
when pdut.IsLevel2State = 1 then pdut.Level2Value
else pdut.Level1Value
end as [Threshold]
 
 
FROM Orion.PercentDiskUsedThreshold AS pdut
where 
((pdut.WarningEnabled = 1 AND pdut.IsLevel1State = 1) OR (pdut.CriticalEnabled = 1 and pdut.IsLevel2State = 1)) and pdut.volume.fullname like '%${SEARCH_STRING}%'