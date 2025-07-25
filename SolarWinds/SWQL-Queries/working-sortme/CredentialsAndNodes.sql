SELECT 
    dn.SysName,
    dn.IPAddress,
    c.Name AS CredentialName
FROM 
    Orion.DiscoveredNodes dn
JOIN 
    Orion.Credential c ON dn.CredentialID = c.ID
ORDER BY 
    dn.SysName

SELECT 

CredentialOwner
, CredentialType
, Description
, DisplayName
, ID
 
FROM Orion.Credential
