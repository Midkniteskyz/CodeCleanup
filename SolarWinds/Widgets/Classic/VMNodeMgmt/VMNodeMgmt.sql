SELECT 
  [data].[NodeID] AS [NodeID],
  [data].[DisplayName] AS [VM Name], 
  [data].[Host].[DisplayName] AS [Host Name], 
  [data].[Node].[DisplayName] AS [Node Name], 
  [data].[Host].[Cluster].[DisplayName] AS [Cluster Name], 
  [data].[Host].[Cluster].[DataCenter].[DisplayName] AS [DataCenter Name], 
  [data].[Host].[Cluster].[DataCenter].[VCenter].[DisplayName] AS [vCenter Name]

FROM 
  orion.vim.virtualmachines AS data 

ORDER BY [NodeID], [vCenter Name], [DataCenter Name], [Cluster Name], [Node Name], [Host Name], [VM Name] ASC
