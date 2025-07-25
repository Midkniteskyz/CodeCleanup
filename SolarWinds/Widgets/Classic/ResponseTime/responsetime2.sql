SELECT 
  -- Node Column
  n.NodeName AS [Node], 
  n.DetailsUrl AS [_linkfor_Node], 
  '/Orion/images/StatusIcons/Small-' + n.StatusIcon AS [_IconFor_Node], 
  -- END Node Column
  -- Response Time column
  concat(n.responsetime, 'ms') as [Latency], 
  concat(
    '/Orion/NetPerfMon/CustomChart.aspx?chartName=AvgRt&NetObject=N:', 
    n.nodeid, '&Period=Today'
  ) as [_linkfor_Latency], 
  CASE WHEN n.responsetime >= n.responsetimeThreshold.Level2Value THEN '/Orion/images/StatusIcons/Small-Down.gif' WHEN n.responsetime < n.responsetimeThreshold.Level2Value 
  and n.responsetime >= n.responsetimeThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Warning.gif' WHEN n.responsetime < n.responsetimeThreshold.Level1Value 
  AND n.ResponseTime >= 0 THEN '/Orion/images/StatusIcons/Small-Up.gif' ELSE '/Orion/images/StatusIcons/Small-Unknown.gif' END AS [_IconFor_Latency], 
  -- END Response Time column
  -- Percent Loss column
  concat(n.percentloss, '%') as [Packet Loss], 
  concat(
    '/Orion/NetPerfMon/CustomChart.aspx?chartName=PercentLoss&NetObject=N:', 
    n.nodeid, '&Period=Today'
  ) as [_linkfor_Packet Loss], 
  CASE WHEN n.percentloss >= n.percentlossThreshold.Level2Value THEN '/Orion/images/StatusIcons/Small-Down.gif' WHEN n.percentloss < n.percentlossThreshold.Level2Value 
  and n.percentloss >= n.percentlossThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Warning.gif' WHEN n.percentloss < n.percentlossThreshold.Level1Value THEN '/Orion/images/StatusIcons/Small-Up.gif' END AS [_IconFor_Packet Loss] 
  -- End Percent Loss column
FROM 
  Orion.Nodes AS n 
ORDER BY 
  n.PercentLoss DESC, 
  n.ResponseTime DESC
