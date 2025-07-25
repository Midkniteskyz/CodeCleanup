SELECT 
  'Enabled' AS Status, 
  COUNT(
    CASE WHEN n.assetinventory.enabled = 'true' THEN 1 END
  ) AS Num 
FROM 
  orion.nodes AS n 
UNION ALL 
  (
    SELECT 
      'NotEnabled' AS Status, 
      COUNT(
        CASE WHEN n.assetinventory.enabled <> 'true' 
        or n.assetinventory.enabled is null THEN 1 END
      ) AS Num 
    FROM 
      orion.nodes AS n
  )