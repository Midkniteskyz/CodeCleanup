SELECT
	 n.NodeID
	,n.Caption AS [DisplayName]
	,n.SysName AS [Hostname]
	,n.IP_Address AS [IP Address]
	,n.ObjectSubType AS [Monitoring Method]
	,n.Community AS [Snmpv1/2c-RO]
	,n.RWCommunity AS [Snmpv1/2c-RW]
	,c1.Name AS [SNMPv3-RO]
	,c2.Name AS [SNMPv3-RW]
	,c3.Name AS [WMI-Cred]
FROM Orion.Nodes AS n
LEFT JOIN Orion.NodeSettings AS ns1 ON ns1.NodeID = n.NodeID AND ns1.SettingName = 'ROSNMPCredentialID'
LEFT JOIN Orion.NodeSettings AS ns2 ON ns2.NodeID = n.NodeID AND ns2.SettingName = 'RWSNMPCredentialID'
LEFT JOIN Orion.NodeSettings AS ns3 ON ns3.NodeID = n.NodeID AND ns3.SettingName = 'WMICredential'
LEFT JOIN Orion.Credential AS c1 ON c1.ID = ns1.SettingValue
LEFT JOIN Orion.Credential AS c2 ON c2.ID = ns2.SettingValue
LEFT JOIN Orion.Credential AS c3 ON c3.ID = ns3.SettingValue
WHERE (
( n.Community IS NOT NULL AND n.Community != '' ) OR
( n.RWCommunity IS NOT NULL AND n.RWCommunity != '' ) OR
( c1.Name IS NOT NULL AND c1.Name != '' ) OR
( c2.Name IS NOT NULL AND c2.Name != '' ) OR
( c3.Name IS NOT NULL AND c3.Name != '' ) )