SELECT 
    -- Device Vendor
    Nodes.Caption AS [Caption],
    -- Count of monitored ports (IsMonitored = True)
    SUM(CASE WHEN Ports.IsMonitored = TRUE THEN 1 ELSE 0 END) AS [Ports Monitored],
    -- Count of unmonitored ports (IsMonitored = False)
    SUM(CASE WHEN Ports.IsMonitored = FALSE THEN 1 ELSE 0 END) AS [Ports Not Monitored],
    -- Total ports for reference
    COUNT(Ports.IsMonitored) AS [Total Ports]
FROM 
    Orion.Nodes AS Nodes
JOIN 
    Orion.UDT.Port AS Ports ON Ports.NodeID = Nodes.NodeID
WHERE 
    Nodes.NodeID = ${NodeID}
GROUP BY 
    Nodes.Caption;