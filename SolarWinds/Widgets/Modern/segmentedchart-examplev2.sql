SELECT
'In' as [Direction],
ROUND(InPercentUtil, 2)/2 as [Utilization],
'blue' as color
FROM (
    Select top 1 InPercentUtil, OutPercentUtil, DATETIME
from Orion.NPM.InterfaceTraffic
Where interfaceid = 2307
order by DATETIME DESC
) as t
 
 
union ALL
(
SELECT top 1
'Out' as [Direction],
ROUND(OutPercentUtil, 2)/2 as [Utilization],
'orange' as color
FROM (
    Select top 1 InPercentUtil, OutPercentUtil, DATETIME
from Orion.NPM.InterfaceTraffic
Where interfaceid = 2307
order by DATETIME DESC
) as t
)
 
 
union ALL
(
SELECT top 1
'Remaining' as [Direction],
100-round(percentutil,2) as [Utilization],
'gray' as color
FROM (
    Select top 1 InPercentUtil, OutPercentUtil,PercentUtil, DATETIME
from Orion.NPM.InterfaceTraffic
Where interfaceid = 2307
order by DATETIME DESC
) as t
)