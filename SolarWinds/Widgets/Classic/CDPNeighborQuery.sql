select 
  top 1 ' ' as search 
from 
  orion.nodes

  

SELECT 
  CDP.Interfaces.InterfaceName AS [Local Interface], 
  RemoteIPAddress AS [IP Address], 
  RemoteDevice AS Device, 
  RemotePort AS [Remote Interface], 
  N.DetailsURL AS [_LinkFor_Device] 
FROM 
  NCM.CiscoCdp CDP 
  JOIN Orion.Nodes N ON (CDP.Node.CoreNodeID = N.NodeID) 
WHERE 
  (
    N.caption LIKE '${SEARCH_STRING}' 
    or N.ip LIKE '${SEARCH_STRING}'
  ) 
Order by 
  N.NodeID
