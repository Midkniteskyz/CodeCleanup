SELECT  
e.ServerName 
,substring(JSON,charindex('DisplayName',JSON)+14,charindex('SuiteName',JSON)-charindex('DisplayName',JSON)-17) as [Method] 
,case when Status=2 then  '/Orion/images/StatusIcons/Small-critical.gif' 
      when status=3 then '/Orion/images/StatusIcons/Small-warning.gif' 
      else '/Orion/images/StatusIcons/Small-up.gif' end as [_iconfor_Method] 
,substring(tostring(DATETRUNC('day',enddate)),1,11) as [Test Date] 
FROM Orion.ActiveDiagnosticsDetail ad 
join orion.Engines e on e.EngineID=ad.EngineID 
where status > 1 
and DATETRUNC('day',ad.enddate)=(select DATETRUNC('day',max(enddate)) as [d] from orion.ActiveDiagnosticsDetail) 
  
order by  e.ServerType desc, e.ServerName,  status asc
