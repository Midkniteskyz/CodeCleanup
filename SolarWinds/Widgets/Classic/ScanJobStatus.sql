SELECT DISTINCT
    si.SubnetId,
    s.DisplayName AS [DNS Server],
    TOLOCAL(si.QueueTimeStamp) AS [Next Scan Time],
    si.ScanInstanceType, 
    si.Status, 
    s.GroupTypeText,
    Concat(Month(TOLOCAL(s.LastDiscovery)), '/', Day(TOLOCAL(s.LastDiscovery)), '/',Year(TOLOCAL(s.LastDiscovery)))  AS [Last Discovered]
FROM 
    IPAM.ScanInstance AS si
JOIN 
    ipam.Subnet AS s ON s.SubnetId = si.SubnetId