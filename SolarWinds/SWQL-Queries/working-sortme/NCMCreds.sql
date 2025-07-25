-- This query retrieves detailed information for nodes from specific vendors and models

SELECT 
    Nodes.caption,                    -- Node caption
    Nodes.sysname,                    -- System name of the node
    Nodes.ipaddress,                  -- System ipaddress of the node
    Nodes.nodedescription,            -- Description of the node
    Nodes.machinetype,                -- Machine type
    Nodes.vendor,                     -- Vendor name
    Nodes.Engine.ServerName,          -- Polling Engine Assignment
    Nodes.objectsubtype,              -- Object subtype
    Nodes.snmpversion,                -- SNMP version used
    snmp.Username,                    -- SNMP v3 username
    snmp.Context,                     -- SNMP v3 context
    snmp.PrivacyMethod,               -- SNMP v3 privacy method
    snmp.PrivacyKey,                  -- SNMP v3 privacy key
    snmp.AuthenticationMethod,        -- SNMP v3 authentication method
    snmp.AuthenticationKey            -- SNMP v3 authentication key

FROM 
    Orion.Nodes AS Nodes             -- Main node table

LEFT JOIN 
    Orion.SNMPv3Credentials AS snmp  -- Joining table for SNMPv3 credentials
    ON snmp.NodeID = Nodes.nodeid    -- Matching nodes with their SNMPv3 settings

WHERE
    -- Filter for specific vendors or Cisco FirePower models
    (Nodes.Vendor IN ('Fortinet, Inc.','Check Point Software Technologies Ltd','Palo Alto Networks') 
     OR 
     (Nodes.Vendor = 'Cisco' AND Nodes.Machinetype LIKE '%FirePower%' OR Nodes.NodeDescription LIKE '%Cisco Adaptive Security Appliance%'))

ORDER BY 
    MachineType, SysName