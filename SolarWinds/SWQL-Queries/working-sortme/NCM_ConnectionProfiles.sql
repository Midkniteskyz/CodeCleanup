SELECT

nd.NodeID

,nd.IP_Address

,nd.Caption

,ncmcp.Name AS 'Connection Profile'

,ncmnp.ConnectionProfile

,nd.Community

,nd.Vendor

,nd.Description

,nd.EngineID

,nd.MachineType

,ncmnp.NodeID

,ncmnp.CoreNodeID

,ncmnp.UseUserDeviceCredentials

,ncmnp.DeviceTemplate

FROM dbo.NodesData AS nd

JOIN dbo.NodesCustomProperties AS ncp ON nd.NodeID=ncp.NodeID

JOIN dbo.NCM_NodeProperties AS ncmnp ON nd.NodeID=ncmnp.CoreNodeID

JOIN dbo.NCM_ConnectionProfiles AS ncmcp ON ncmnp.ConnectionProfile=ncmcp.ID