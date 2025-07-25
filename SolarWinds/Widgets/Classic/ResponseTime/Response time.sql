SELECT
n.NodeName, 
n.IPAddress, 
n.StatusLED, 
n.StatusDescription as [Status Description], 
n.ObjectSubType AS [Polling Method], 
n.DetailsUrl AS [_linkfor_NodeName], 
'/Orion/images/StatusIcons/Small-' + n.StatusIcon AS [_IconFor_Caption], 
n.PercentLoss, 
concat(percentloss, '%') as [Packet Loss], 
concat(
  '/Orion/NetPerfMon/CustomChart.aspx?chartName=PercentLoss&NetObject=N:', 
  n.nodeid, '&Period=Today'
) as [_linkfor_Packet Loss], 
n.ResponseTime As [Current Response Time], 
n.MinResponseTime, 
n.MaxResponseTime, 
n.ResponseTimeThreshold.Level1Value AS [Warning Threshold], 
n.ResponseTimeThreshold.Level2Value AS [Critical Threshold], 
CASE
    WHEN n.ResponseTime > n.ResponseTimeThreshold.Level1Value THEN 'Warning' 
    WHEN n.ResponseTime > n.ResponseTimeThreshold.Level2Value THEN 'Critical' 
    WHEN n.ResponseTime < 0 THEN 'Unreachable' 
    ELSE 'Ok' 
END AS [Threshold]
FROM Orion.Nodes as n
where n.CustomProperties.DynamicResponseTime = 'TRUE' 
ORDER BY 
  n.ResponseTime DESC
