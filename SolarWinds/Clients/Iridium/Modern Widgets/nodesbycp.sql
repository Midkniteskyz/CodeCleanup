-- Select node details and associated Business Unit for display
SELECT 
  a.Node,           -- The node's name (in uppercase, derived from Caption)
  a.IP_Address,     -- IP address of the node
  a.Model,          -- Model of the device, or fallback to MachineType if not part of a stack
  a.Serial,         -- Serial number of the device, fallback to Service Tag if not part of a stack
  a.Business_Unit   -- Business Unit classification ('Enterprise', 'Commercial', 'Mission', or 'Unknown')
FROM 
  (
    -- Subquery to build node information and determine the Business Unit
    SELECT 
      -- Extract the node name from its caption (everything before the first '.')
      TOUPPER(
        SUBSTRING (
          n.Caption, 
          1, 
          CASE 
            -- If there's no '.' within the first 4 characters, use the full Caption
            WHEN CHARINDEX('.', n.Caption, 1) <= 4 
            THEN LENGTH(n.Caption) 
            -- Otherwise, take the substring up to the first '.'
            ELSE (CHARINDEX('.', n.Caption, 1) - 1) 
          END
        )
      ) AS [Node], 
      
      -- Directly retrieve IP address of the node
      n.IP_Address, 
      
      -- Retrieve model for stacked switches, or fallback to MachineType for non-stack devices
      CASE 
        WHEN n.SwitchStack.SwitchStackMember.Model IS NULL 
        THEN n.MachineType 
        ELSE n.SwitchStack.SwitchStackMember.Model 
      END AS [Model], 
      
      -- Retrieve serial number for stacked switches, or fallback to Service Tag for non-stack devices
      CASE 
        WHEN n.SwitchStack.SwitchStackMember.SerialNumber IS NULL 
        THEN n.HardwareHealthInfos.ServiceTag 
        ELSE n.SwitchStack.SwitchStackMember.SerialNumber 
      END AS [Serial], 
      
      -- Determine the Business Unit from CustomProperties, or label as 'Unknown' if not available
      CASE 
        WHEN n.CustomProperties.Business_Unit IN ('Enterprise', 'Commercial', 'Mission') 
        THEN n.CustomProperties.Business_Unit 
        ELSE 'Unknown' 
      END AS [Business_Unit]
      
    FROM 
      orion.Nodes n  -- The primary table containing node data
  ) a 
WHERE 
  a.Serial IS NOT NULL -- Filter out nodes that don't have a serial number
ORDER BY 
  a.Node; -- Sort results alphabetically by Node name
