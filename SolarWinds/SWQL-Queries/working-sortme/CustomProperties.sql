SELECT 
    CASE
        WHEN cp.TargetEntity = 'Orion.GroupCustomProperties' THEN 'Groups'
        WHEN cp.TargetEntity = 'Orion.NPM.InterfacesCustomProperties' THEN 'Interfaces'
        WHEN cp.TargetEntity = 'Orion.NodesCustomProperties' THEN 'Nodes'
        ELSE 'Other'
    END AS [Object],
    cp.Field AS [Property],
    cp.Description
FROM
    Orion.CustomProperty AS cp
