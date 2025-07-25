SELECT 
    nodes.nodeid, 
    nodes.caption,
    nodes.ipaddress,
    SUBSTRING(IPAddress, 1, CHARINDEX('.', IPAddress) - 1) AS [Octet1],
    SUBSTRING(IPAddress, CHARINDEX('.', IPAddress) + 1, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) - CHARINDEX('.', IPAddress) - 1) AS [Octet2],
    SUBSTRING(IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1) - CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) - 1) AS Octet3,
    SUBSTRING(IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress, CHARINDEX('.', IPAddress) + 1) + 1) + 1, LENGTH(IPAddress)) AS Octet4,
FROM 
    orion.Nodes Nodes

