SELECT 
  i.FullName AS FullName,
  sn.StatusName AS NodeStatus,
  i.ObjectSubType AS PollingMethod, 
  i.Type AS InterfaceType, 
  i.TypeName AS InterfaceTypeName, 
  i.StatusDescription AS InterfaceStatus, 
  sa.StatusName AS AdminStatusDescription,
  so.StatusName AS OperStatusDescription,
  i.UnPluggable, 
  i.DetailsUrl, 
  i.Uri

FROM Orion.NPM.Interfaces AS i

LEFT JOIN Orion.StatusInfo AS sa ON sa.StatusId = i.AdminStatus
LEFT JOIN Orion.StatusInfo AS so ON so.StatusId = i.OperStatus
LEFT JOIN Orion.StatusInfo AS sn ON sn.StatusId = i.Node.Status