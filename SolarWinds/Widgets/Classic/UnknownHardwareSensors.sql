SELECT 
  -- NodeID
  -- ID
  -- HardwareInfoID
  -- HardwareCategoryStatusID
  -- UniqueName
  hi.node.caption as [Node], 
  hi.DetailsUrl AS [_linkfor_Node], 
  hi.Name AS [Sensor Name], 
  -- Link to Chart for sensor
  concat(
    '/Orion/Charts/CustomChart.aspx?ChartName=HardwareHealthSensorAvailability&NetObject=N%3a', 
    ${hi.NodeID}, '&NetObjectPrefix=HHSA&SampleSize=30&Width=640&rpElementList=', 
    ${hi.ID}, '&ResourceTitle=', ${hi.FullyQualifiedName}
  ) AS [_linkfor_Sensor Name], 
  -- hi.FullyQualifiedName
  -- hi.Status
  hi.StatusDescription AS [Status], 
  '/Orion/HardwareHealth/SensorManagement.aspx' AS [_linkfor_Status], 
  hi.HardwareCategory.Name as [Hardware Category], 
  Case When hi.UnManaged = '1' then 'Yes' Else 'No' end AS [Maintenance Mode], 
  Case When hi.IsDisabled = '1' then 'Yes' Else 'No' end AS [Disabled] 
  -- hi.Uri 
FROM 
  Orion.HardwareHealth.HardwareItem as hi 
where 
  hi.Status not in (3, 8, 15, 32, 33, 37, 41, 1, 22, 31, 42, 43, 14)
