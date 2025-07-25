select 
  n.Caption, 
  n.IP_Address, 
  c.detailsurl as [_linkfor_Caption], 
  '/Orion/images/StatusIcons/Small-' + n.StatusIcon AS [_IconFor_Caption], 
    CASE 
        when cpuload < 0 then 'Not Polled' 
        else concat(cpuload, '%') 
    end as [CPU Load], 
  concat(
    '/Orion/NetPerfMon/CustomChart.aspx?chartName=HostAvgCPULoad&NetObject=N:', 
    n.nodeid, '&Period=Today'
  ) as [_linkfor_CPU Load], 
   
   -- Threshold
    CASE 
        WHEN cpuload >= n.CpuLoadThreshold.Level2Value THEN '/Orion/images/StatusIcons/Small-Down.gif' 
        WHEN cpuload < n.CpuLoadThreshold.Level2Value and cpuload >= n.CpuLoadThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Warning.gif'
        WHEN cpuload < n.CpuLoadThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Up.gif' 
    END AS [_IconFor_CPU Load], 
  --Memory
    case 
        when percentmemoryused < 0 then 'Not Polled' 
        else concat(percentmemoryused, '%') 
    end as [Memory Used], 
  
  concat(
    '/Orion/NetPerfMon/CustomChart.aspx?chartName=HostAvgPercentMemoryUsed&NetObject=N:', 
    n.nodeid, '&Period=Today'
  ) as [_linkfor_Memory Used], 
    
    CASE 
        WHEN percentmemoryused >= n.percentmemoryusedThreshold.Level2Value THEN '/Orion/images/StatusIcons/Small-Down.gif' 
        WHEN percentmemoryused < n.percentmemoryusedThreshold.Level2Value and percentmemoryused >= n.percentmemoryusedThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Warning.gif' 
        WHEN percentmemoryused < n.percentmemoryusedThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Up.gif' 
    END AS [_IconFor_Memory Used], 
 
 
  concat(responsetime, 'ms') as [Latency], 
  concat(
    '/Orion/NetPerfMon/CustomChart.aspx?chartName=AvgRt&NetObject=N:', 
    n.nodeid, '&Period=Today'
  ) as [_linkfor_Latency], 
    CASE 
        WHEN responsetime >= n.responsetimeThreshold.Level2Value THEN '/Orion/images/StatusIcons/Small-Down.gif' 
        WHEN responsetime < n.responsetimeThreshold.Level2Value and responsetime >= n.responsetimeThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Warning.gif' 
        WHEN responsetime < n.responsetimeThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Up.gif' 
    END AS [_IconFor_Latency], 
  concat(percentloss, '%') as [Packet Loss], 
  concat(
    '/Orion/NetPerfMon/CustomChart.aspx?chartName=PercentLoss&NetObject=N:', 
    n.nodeid, '&Period=Today'
  ) as [_linkfor_Packet Loss], 
    CASE 
        WHEN percentloss >= n.percentlossThreshold.Level2Value THEN '/Orion/images/StatusIcons/Small-Down.gif' 
        WHEN percentloss < n.percentlossThreshold.Level2Value and percentloss >= n.percentlossThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Warning.gif' 
        WHEN percentloss < n.percentlossThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Up.gif' 
    END AS [_IconFor_Packet Loss] 
from 
  orion.nodes n 
  join orion.nodescustomproperties cp on cp.nodeid = n.nodeid 
  join Orion.ContainerMembers c on c.memberprimaryid = n.nodeid where MemberEntityType like 'orion.nodes' and c.containerid like ${id} 
  --and n.caption like '%${SEARCH_STRING}%'  order by n.caption
