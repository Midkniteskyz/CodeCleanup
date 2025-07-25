SELECT TOP 100
    --p.NodeID,
    n.Caption,
    status_n.StatusName AS [Node Status],
    i.Name AS [InterfaceName],
    i.TypeDescription AS [Interface Type],
    status_i_admin.StatusName AS [Interface Admin Status],
    status_i_oper.StatusName AS [Interface Operational Status],
    p.name AS [Port Name],
    p.IsMonitored AS [Is Monitored],
    status_p_admin.StatusName AS [Port Administrative Status],
    status_p_oper.StatusName AS [Port Operational Status]


FROM 
    orion.udt.port AS p
JOIN 
    orion.Nodes AS n ON p.NodeID = n.NodeID
JOIN 
    orion.NPM.Interfaces AS i ON p.NodeID = i.NodeID
LEFT JOIN 
    orion.statusinfo AS status_p_admin ON p.AdministrativeStatus = status_p_admin.StatusId
LEFT JOIN 
    orion.statusinfo AS status_p_oper ON p.OperationalStatus = status_p_oper.StatusId
LEFT JOIN 
    orion.statusinfo AS status_n ON n.Status = status_n.StatusId
LEFT JOIN 
    orion.statusinfo AS status_i_admin ON i.AdminStatus = status_i_admin.StatusId
LEFT JOIN 
    orion.statusinfo AS status_i_oper ON i.OperStatus = status_i_oper.StatusId;