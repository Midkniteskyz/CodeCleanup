SELECT
  parent.Name         AS ParentGroup,
  subgroup.Name       AS SubGroup,
  md.Name             AS MemberName,
  md.Definition       AS MemberDefinition,
  
  -- Extract Site value
  SUBSTRING(
    md.Definition,
    CHARINDEX("CustomProperties.Site='", md.Definition) + LENGTH("CustomProperties.Site='"),
    CHARINDEX("'", md.Definition, CHARINDEX("CustomProperties.Site='", md.Definition) + LENGTH("CustomProperties.Site='")) 
      - (CHARINDEX("CustomProperties.Site='", md.Definition) + LENGTH("CustomProperties.Site='"))
  ) AS Site,

  -- Extract Topology value
  SUBSTRING(
    md.Definition,
    CHARINDEX("CustomProperties.Topology='", md.Definition) + LENGTH("CustomProperties.Topology='"),
    CHARINDEX("'", md.Definition, CHARINDEX("CustomProperties.Topology='", md.Definition) + LENGTH("CustomProperties.Topology='")) 
      - (CHARINDEX("CustomProperties.Topology='", md.Definition) + LENGTH("CustomProperties.Topology='"))
  ) AS Topology

FROM
  Orion.Container AS parent
JOIN
  Orion.ContainerMemberDefinition AS link ON parent.ContainerID = link.ContainerID
JOIN
  Orion.Container AS subgroup ON link.Definition = subgroup.Uri
LEFT JOIN
  Orion.ContainerMemberDefinition AS md ON subgroup.ContainerID = md.ContainerID
WHERE
  parent.Name = 'Sites'
ORDER BY
  Site, Topology, SubGroup
