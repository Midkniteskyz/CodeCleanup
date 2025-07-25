SELECT
n.Router.Caption as [Node Name]
, n.NeighborIP as [Neighbor IP]
, n.LastChange as [Last Change]
, n.ProtocolName
, n.DetailsUrl as [_Linkfor_Node Name]

FROM Orion.Routing.Neighbors as n

where 
(n.isdeleted = 1 or n.protocolorionstatus != 1)
 and 
(n.router.caption like '%${SEARCH_STRING}%' or n.neighborip like '%${SEARCH_STRING}%')

Order by n.LastChange desc