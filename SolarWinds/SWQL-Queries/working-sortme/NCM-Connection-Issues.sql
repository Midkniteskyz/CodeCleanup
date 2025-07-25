SELECT
    si.ShortDescription AS nodestatus,
    np.Nodes.Caption,
    np.nodes.IP,
    np.nodes.vendor,
    np.nodes.MachineType,
    np.LoginStatus
FROM
    NCM.NodeProperties AS np
    JOIN orion.StatusInfo AS si ON si.StatusId = np.nodes.status
WHERE
    np.LoginStatus != 'Login OK'
ORDER BY
    si.ShortDescription,
    np.nodes.vendor,
    np.nodes.MachineType,
    np.Nodes.IP