SELECT
    Nodes.Uri 
    , Nodes.DisplayName
--   ,nt.Name AS [Threshold Name]
--   ,nt.Level1Value AS [Warning Value]
--   ,nt.IsLevel1State AS [Is Warning]
--   ,nt.CurrentValue AS [Current Value]
--   ,nt.GlobalWarningValue AS [Global Warning Value]

FROM Orion.Nodes AS Nodes

JOIN Orion.NodesThresholds AS nt ON Nodes.NodeID = nt.InstanceID

WHERE 
  nt.ThresholdType = 1 -- Custom Threshold
  AND nt.WarningEnabled = 1
  AND nt.Name IN ('Nodes.Stats.CpuLoad', 'Nodes.Stats.PercentMemoryUsed')
  AND nt.IsLevel1State = 1 -- In warning state