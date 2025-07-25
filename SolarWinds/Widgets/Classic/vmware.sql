-- Overall
-- Number of Hosts
SELECT 
    'Number of Hosts (Overall)' AS Col1,
    COUNT(
        hosts.hostid
    ) AS Col2
FROM Orion.VIM.Hosts as hosts

-- Number of VM's
UNION ALL
    (SELECT 
        'VM Count' AS Total,
         SUM(
            hosts.VMCount
        ) AS V1
    From Orion.VIM.Hosts as hosts 
    )

-- Number of VM's Running
UNION ALL
    (SELECT 
        'VMs Running' AS Total,
         SUM(
            hosts.VMRunningCount
        ) AS V1
    From Orion.VIM.Hosts as hosts 
    )

-- Total Number of Physical CPU Cores
UNION ALL
    (SELECT 
        'CPU Core Count' AS Total,
         SUM(
            hosts.CpuCoreCount
        ) AS V1
    From Orion.VIM.Hosts as hosts 
    )

-- Total RAM
UNION ALL
    (SELECT 
        'Total RAM' AS TOTAL,
        ROUND(SUM(hosts.MemorySize) / (1024 * 1024 * 1024),1) AS V1
    FROM Orion.Vim.Hosts as hosts
    )

-- Last Poll

-- VMware
-- Number of Virtual Centers
UNION ALL
    (SELECT 
        'vCenter Count' AS TOTAL,
        COUNT(
            vcenters.vcenterid
        ) AS V1
    FROM Orion.Vim.vcenters as vcenters
    )

-- Number of Clusters
UNION ALL
    (SELECT 
        'Clusters' AS TOTAL,
        COUNT(
            clusters.DataCenterID
        ) AS V1
    FROM Orion.VIM.Clusters as clusters
    )

-- Number of vSAN Clusters
UNION ALL
    (SELECT 
        'vSAN Clusters' AS TOTAL,
        COUNT(
            clusters.DataCenterID
        ) AS V1
    FROM Orion.VIM.Clusters as clusters
    where clusters.VsanEnabled = TRUE
    )

-- Resource Pools
UNION ALL
    (SELECT 
        'Resource Pools' AS TOTAL,
        COUNT(
            rp.ResourcePoolID
        ) AS V1
    FROM Orion.VIM.ResourcePools as rp
    )
-- Number of ESX Hosts (Clustered)
UNION ALL
    (SELECT
        'Clustered ESXi Hosts' AS Total,
        COUNT(
            CASE WHEN h.ClusterID IS NOT NULL THEN 1 END
        ) AS V1
    FROM Orion.VIM.Hosts as h
    WHERE h.VMwareProductName LIKE '%vmware%'
    )

-- Number of ESX Hosts (Non-Clustered)
UNION ALL
    (SELECT
        'Non-Clustered ESXi Hosts' AS Total,
        COUNT(
            CASE WHEN h.ClusterID IS NULL THEN 1 END
        ) AS V1
    FROM Orion.VIM.Hosts as h
    WHERE h.VMwareProductName LIKE '%vmware%'
    )

-- Number of VMs (Total)
UNION ALL
    (SELECT 
        'VMware VMs Total' AS Total,
         SUM(
            hosts.VmCount
        ) AS V1
    From Orion.VIM.Hosts as hosts 
    WHERE hosts.VMwareProductName LIKE '%vmware%'
    )

-- Number of VMs (Running)
UNION ALL
    (SELECT 
        'VMware VMs Running' AS Total,
         SUM(
            hosts.VmRunningCount
        ) AS V1
    From Orion.VIM.Hosts as hosts 
    WHERE hosts.VMwareProductName LIKE '%vmware%'
    )

-- Total Number of Physical CPU Cores
UNION ALL
    (SELECT 
        'CPU Core Count' AS Total,
         SUM(
            hosts.CpuCoreCount
        ) AS V1
    From Orion.VIM.Hosts as hosts 
    WHERE hosts.VMwareProductName LIKE '%vmware%'
    )

-- Total RAM
UNION ALL
    (SELECT 
        'Total RAM' AS TOTAL,
        SUM(hosts.MemorySize) / (1024 * 1024 * 1024) AS V1
    FROM Orion.Vim.Hosts as hosts
    WHERE hosts.VMwareProductName LIKE '%vmware%'
    )

-- Last Poll

UNION ALL
    (SELECT 
        'Last Poll' AS TOTAL,
        MINUTEDIFF(pt.LastPoll, GETUTCDATE()) AS V1
    FROM Orion.Vim.pollingtasks as pt
    Where pt.vcenterid is not null and pt.lastpoll is not null
    )