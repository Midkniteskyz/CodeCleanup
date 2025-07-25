SELECT TOP 100 
n.caption
, count(n.Interfaces.InterfaceID) as [int count]
,n.Engine.ServerName
FROM Orion.Nodes as n
 
where n.Interfaces.InterfaceID > 1 and n.Engine.EngineID = 3
 
group by n.caption,n.Engine.ServerName
 
Order by count(n.Interfaces.InterfaceID) Desc