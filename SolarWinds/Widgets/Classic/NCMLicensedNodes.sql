SELECT n.caption, n.ipaddress, n.NCMLicenseStatus.LicensedByNCM
FROM Orion.Nodes as n
where n.objectsubtype = 'icmp' and n.NCMLicenseStatus.LicensedByNCM = 'Yes'
--where machinetype not like '%9300%' and vendor = 'Cisco'