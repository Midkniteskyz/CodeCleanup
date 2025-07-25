SELECT 
  n.caption, 
  n.detailsurl, 
  n.Vendor,
  n.model,
  cp.assettag, 
  (
    case when n.assetinventory.enabled = 'true' then 'Yes' else 'No' end
  ) as [Asset Inventory Enabled] 
FROM 
  orion.nodes AS n 
  Join orion.nodescustomproperties as cp on cp.nodeid = n.nodeid
