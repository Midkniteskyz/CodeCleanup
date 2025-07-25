SELECT 
  -- Col 1; Orion Entity, Icon -> Status
  n.caption AS [Node Name], 
  n.Status AS [Node Status], 
  n.DetailsUrl AS [Node Details URL], 
  -- Col 2; Orion Entity, Icon -> Vendor 
  hinfo.Model AS [Vendor Model], 
  n.VendorIcon AS [Vendor Icon], 
  hinfo.DetailsUrl AS [Vendor URL], 
  -- Col 3: Orion Entity, Icon -> Status
  hitem.Name AS [HW Name], 
  hinfo.LastPollStatus AS [HW Status], 
  hitem.DetailsUrl AS [HW Details URL], 
  -- Col 4: Temperature Simple Number -> Temperature; Use ALT+0176 for the degrees symbol
  hitem.Value AS [Temperature], 
  -- Col 5: Status
  hitem.OriginalStatus AS [Status Code] 
FROM 
  orion.nodes as N;
Join orion.HardwareHealth.HardwareInfoBase as hinfo on n.NodeID = hinfo.ParentObjectID 
JOIN orion.HardwareHealth.HardwareItemBase as hitem on hitem.HardwareInfoID = hinfo.ID 
WHERE 
  hitem.HardwareCategoryID = '4'
