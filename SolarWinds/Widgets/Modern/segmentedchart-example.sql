SELECT
'In - Used' as [Segment], 
Round(InPercentUtil,2) as [Value],
'blue' as color
FROM (
    Select top 1 InPercentUtil, OutPercentUtil, DATETIME
from Orion.NPM.InterfaceTraffic
Where interfaceid = 1276
order by DATETIME DESC
) as t
 
UNION ALL
 
(
SELECT
'In - Available' as [Segment], 
50 - Round(InPercentUtil,2) as [Value],
'white' as color
FROM (
    Select top 1 InPercentUtil, OutPercentUtil, DATETIME
from Orion.NPM.InterfaceTraffic
Where interfaceid = 1276
order by DATETIME DESC
) as t
)
 
Union ALL
 
(
SELECT
'Out - Used' as [Segment], 
Round(OutPercentUtil,2) as [Value],
'orange' as color
FROM (
    Select top 1 InPercentUtil, OutPercentUtil, DATETIME
from Orion.NPM.InterfaceTraffic
Where interfaceid = 1276
order by DATETIME DESC
) as t
)
 
UNION ALL
 
(
SELECT
'Out - Available' as [Segment], 
50 - Round(OutPercentUtil,2) as [Value],
'white' as color
FROM (
    Select top 1 InPercentUtil, OutPercentUtil, DATETIME
from Orion.NPM.InterfaceTraffic
Where interfaceid = 1276
order by DATETIME DESC
) as t
)