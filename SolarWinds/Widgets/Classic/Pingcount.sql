SELECT 
  COUNT(nodeid) AS ICMP, 
--   objectsubtype, 
--   ipaddress, 
--   caption, 
--   sysname 
FROM 
  Orion.Nodes 
Where 
  objectsubtype = 'ICMP'

SELECT 
  COUNT(nodeid) AS Agent, 
--   objectsubtype, 
--   ipaddress, 
--   caption, 
--   sysname 
FROM 
  Orion.Nodes 
Where 
  objectsubtype = 'Agent'

SELECT 
  COUNT(nodeid) AS SNMP, 
--   objectsubtype, 
--   ipaddress, 
--   caption, 
--   sysname 
FROM 
  Orion.Nodes 
Where 
  objectsubtype = 'SNMP'

SELECT 
--   COUNT(nodeid) AS WMI, 
  objectsubtype, 
  ipaddress, 
  caption, 
  sysname 
FROM 
  Orion.Nodes 
Where 
  objectsubtype = 'WMI'

SELECT 
  COUNT(nodeid) AS Total 
--   objectsubtype, 
--   ipaddress, 
--   caption, 
--   sysname 
FROM 
  Orion.Nodes 
-- Where 
--   objectsubtype = 'WMI'
