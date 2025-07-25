SELECT
    TOP 100
    -- Storage Arrays
    sa.Vendor AS [Vendor],
    CASE
        WHEN sa.Vendor = 'Pure Storage, Inc.' THEN '/NetPerfMon/Images/Vendors/40482.gif'
        WHEN sa.Vendor = 'EMC' THEN '/NetPerfMon/Images/Vendors/1139.gif'
    END AS [_IconFor_Vendor],
    sa.Name AS [Array],
    sa.DetailsUrl AS [_LinkFor_Array],
    CASE
        when sa.IsCluster = 'True' THEN CONCAT('/Orion/SRM/images/StatusIcons/Small-vClusters_icon_', arraystatus.IconPostfix,'.png')
        else CONCAT('/Orion/SRM/images/StatusIcons/Arrays_icon_', arraystatus.IconPostfix,'.png')
    END AS [_IconFor_Array],
    sa.IPAddress as [Array IP],
    sa.Model,

    -- Pools
    sa.Pools.Name as [Pool],
    sa.Pools.DetailsUrl AS [_LinkFor_Pool],
    CONCAT('/Orion/SRM/images/StatusIcons/Small-Storage_Pools_icon_', poolstatus.IconPostfix,'.png') AS [_IconFor_Pool],

    -- vServer
    sa.VServers.Name as [vServer],
    sa.VServers.DetailsUrl AS [_LinkFor_vServer],
    CONCAT('/Orion/SRM/images/StatusIcons/Small-vServer_icon_', vserverstatus.IconPostfix,'.png') AS [_IconFor_vServer],

    case when length(sa.VServers.IPAddress)> 15 then concat(
        SUBSTRING(
        TOUPPER(
            SUBSTRING (
            sa.VServers.IPAddress, 
            1, 
            CASE WHEN CHARINDEX('.', sa.VServers.IPAddress, 1) <= 4 THEN LENGTH(sa.VServers.IPAddress) ELSE (
                CHARINDEX('.', sa.VServers.IPAddress, 1)-1
            ) END
            )
        ), 
        1, 
        25
        ), 
        '...'
        ) else TOUPPER(
            SUBSTRING (
            sa.VServers.IPAddress, 
            1, 
            CASE WHEN CHARINDEX('.', sa.VServers.IPAddress, 1) <= 4 THEN LENGTH(sa.VServers.IPAddress) ELSE (
                CHARINDEX('.', sa.VServers.IPAddress, 1)-1
            ) end
            )
        ) END AS [vServer IP],

    -- LUNs
    sa.LUNs.Name as [LUN],
    sa.LUNs.DetailsUrl AS [_LinkFor_LUN],
    CONCAT('/Orion/SRM/images/StatusIcons/Small-LUN_icon_', LUNstatus.IconPostfix,'.png') AS [_IconFor_LUNs],

    -- Volumes
    sa.volumes.Name as [Volume],
    sa.volumes.DetailsUrl AS [_LinkFor_Volume],
    CONCAT('/Orion/SRM/images/StatusIcons/Small-NAS_volume_icon_', volumestatus.IconPostfix,'.png') AS [_IconFor_volume]

FROM
    Orion.SRM.StorageArrays AS sa

JOIN orion.statusinfo as arraystatus on arraystatus.StatusId = sa.OperStatus
JOIN orion.statusinfo as poolstatus on poolstatus.StatusId = sa.Pools.Operstatus
JOIN orion.statusinfo as vserverstatus on vserverstatus.StatusId = sa.VServers.Operstatus
JOIN orion.statusinfo as LUNstatus on LUNstatus.StatusId = sa.LUNs.Operstatus
JOIN orion.statusinfo as volumestatus on volumestatus.StatusId = sa.volumes.Operstatus

WHERE

sa.Vendor like '%${SEARCH_STRING}%'
OR
sa.Name like '%${SEARCH_STRING}%'
OR
sa.IPAddress like '%${SEARCH_STRING}%'
OR
sa.Model like '%${SEARCH_STRING}%'
OR
sa.Pools.Name like '%${SEARCH_STRING}%'
OR
sa.VServers.Name like '%${SEARCH_STRING}%'
OR
sa.VServers.IPAddress like '%${SEARCH_STRING}%'
OR
sa.LUNs.Name like '%${SEARCH_STRING}%'
OR
sa.volumes.Name like '%${SEARCH_STRING}%'
