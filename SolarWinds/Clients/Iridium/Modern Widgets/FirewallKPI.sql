-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'up':
SELECT 
  COUNT(
    CASE WHEN s.statusname = 'Up' THEN 1 END
  ) AS Num -- From the 'orion.nodes' table alias as 'n':
FROM 
  orion.nodes AS n -- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
  JOIN orion.statusinfo AS s ON s.statusid = n.Status -- Filtering the results to include only firewall nodes polled by Commercial pollers:
WHERE 
  n.Engine.ServerName LIKE '%COM%' -- Nodes on servers with 'COM' in the server name
  AND (
    n.Vendor IN (
      'Fortinet, Inc.', 'Check Point Software Technologies Ltd', 
      'Palo Alto Networks'
    ) -- Specific vendors
    OR n.Vendor = 'Cisco' 
    AND (
      n.Machinetype LIKE '%FirePower%' -- Specific Cisco model
      OR n.NodeDescription LIKE '%Cisco Adaptive Security Appliance%' -- Specific Cisco device type
      )
  )

----------------------------------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Critical':
SELECT 
  COUNT(
    CASE WHEN s.StatusName NOT IN ('Up', 'Down', 'Warning', 'Critical') THEN 1 END
  ) AS Num -- From the 'orion.nodes' table alias as 'n':
FROM 
  orion.nodes AS n -- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
  JOIN orion.statusinfo AS s ON s.statusid = n.Status -- Filtering the results to include only firewall nodes polled by Commercial pollers:
WHERE 
  n.Engine.ServerName LIKE '%COM%' -- Nodes on servers with 'COM' in the server name
  AND (
    n.Vendor IN (
      'Fortinet, Inc.', 'Check Point Software Technologies Ltd', 
      'Palo Alto Networks'
    ) -- Specific vendors
    OR n.Vendor = 'Cisco' 
    AND (
      n.Machinetype LIKE '%FirePower%' -- Specific Cisco model
      OR n.NodeDescription LIKE '%Cisco Adaptive Security Appliance%' -- Specific Cisco device type
      )
  )