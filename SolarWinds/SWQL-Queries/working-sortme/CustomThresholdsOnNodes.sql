SELECT 
 
  n.caption, 
  CASE WHEN t.Name = 'Nodes.Stats.CpuLoad' THEN 'Avg CPU Load' WHEN t.Name = 'Nodes.Stats.PercentLoss' THEN 'Percent Packet Loss' WHEN t.Name = 'Nodes.Stats.PercentMemoryUsed' THEN 'Percent Memory Used' WHEN t.Name = 'Nodes.Stats.ResponseTime' THEN 'Response Time' WHEN t.Name = 'Volumes.Stats.PercentDiskUsed' THEN 'Disk Usage' ELSE 'Unknown Threshold' END AS [Threshold Name], 
  CASE WHEN t.ThresholdType = 1 THEN 'Custom' ELSE 'Default' END AS [Threshold Type], 
  CASE WHEN t.WarningEnabled = 1 THEN 'Yes' ELSE 'No' END AS [Warning Enabled], 
  CASE WHEN t.ThresholdType = 1 THEN t.Level1Value ELSE t.GlobalWarningValue END AS [Warning Level], 
  CASE WHEN t.CriticalEnabled = 1 THEN 'Yes' ELSE 'No' END AS [Critical Enabled], 
  CASE WHEN t.ThresholdType = 1 THEN t.Level2Value ELSE t.GlobalCriticalValue END AS [Critical Level] 
FROM 
  Orion.Thresholds AS t 
  join Orion.nodes AS n on n.NodeID = t.InstanceId 
WHERE 
  t.Name IN (
    'Nodes.Stats.CpuLoad', 'Volumes.Stats.PercentDiskUsed', 
    'Nodes.Stats.PercentMemoryUsed', 
    'Nodes.Stats.PercentLoss', 'Nodes.Stats.ResponseTime'
  ) 
  AND (
    t.Level1Value IS NOT NULL 
    OR t.Level2Value IS NOT NULL
  ) 
  and t.ThresholdType = 1 
ORDER BY 
  n.Caption, 
  t.Name;
