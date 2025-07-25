Select 
n.DNS AS [Identity]
,MAX(n.DetailsUrl) as [_linkfor_Identity]
,MAX(CONCAT('/Orion/images/StatusIcons/Small-', n.StatusIcon)) as [_iconfor_Identity]

-- Netlogon Service
, MAX(CASE WHEN n.Applications.Components.Name = 'Netlogon Service' THEN n.Applications.Components.StatusDescription END) AS [Netlogon Service] 
, MAX(CASE WHEN n.Applications.Components.Name = 'Netlogon Service' THEN n.Applications.Components.DetailsUrl ELSE NULL END) as [_linkfor_Netlogon Service]
, MAX(CASE WHEN n.Applications.Components.Name = 'Netlogon Service' THEN CONCAT('/Orion/images/StatusIcons/Small-', n.Applications.Components.StatusDescription, '.gif') ELSE NULL END) as [_iconfor_Netlogon Service]

-- NTDS Service
, MAX(CASE WHEN n.Applications.Components.Name = 'NTDS Service' THEN n.Applications.Components.StatusDescription END) AS [NTDS Service] 
, MAX(CASE WHEN n.Applications.Components.Name = 'NTDS Service' THEN n.Applications.Components.DetailsUrl ELSE NULL END) as [_linkfor_NTDS Service]
, MAX(CASE WHEN n.Applications.Components.Name = 'NTDS Service' THEN CONCAT('/Orion/images/StatusIcons/Small-', n.Applications.Components.StatusDescription, '.gif') ELSE NULL END) as [_iconfor_NTDS Service]

-- DNS Service
, MAX(CASE WHEN n.Applications.Components.Name = 'DNS Service' THEN n.Applications.Components.StatusDescription END) AS [DNS Service] 
, MAX(CASE WHEN n.Applications.Components.Name = 'DNS Service' THEN n.Applications.Components.DetailsUrl ELSE NULL END) as [_linkfor_DNS Service]
, MAX(CASE WHEN n.Applications.Components.Name = 'DNS Service' THEN CONCAT('/Orion/images/StatusIcons/Small-', n.Applications.Components.StatusDescription, '.gif') ELSE NULL END) as [_iconfor_DNS Service]

-- Netlogon DCDiag
, MAX(CASE WHEN n.Applications.Components.Name = 'Netlogon DCDiag' THEN n.Applications.Components.StatusDescription END) AS [Netlogon DCDiag] 
, MAX(CASE WHEN n.Applications.Components.Name = 'Netlogon DCDiag' THEN n.Applications.Components.DetailsUrl ELSE NULL END) as [_linkfor_Netlogon DCDiag]
, MAX(CASE WHEN n.Applications.Components.Name = 'Netlogon DCDiag' THEN CONCAT('/Orion/images/StatusIcons/Small-', n.Applications.Components.StatusDescription, '.gif') ELSE NULL END) as [_iconfor_Netlogon DCDiag]

-- Replication DCDiag
, MAX(CASE WHEN n.Applications.Components.Name = 'Replications DCDiag' THEN n.Applications.Components.StatusDescription END) AS [Replications DCDiag] 
, MAX(CASE WHEN n.Applications.Components.Name = 'Replications DCDiag' THEN n.Applications.Components.DetailsUrl ELSE NULL END) as [_linkfor_Replications DCDiag]
, MAX(CASE WHEN n.Applications.Components.Name = 'Replications DCDiag' THEN CONCAT('/Orion/images/StatusIcons/Small-', n.Applications.Components.StatusDescription, '.gif') ELSE NULL END) as [_iconfor_Replications DCDiag]

-- Services DCDiag
, MAX(CASE WHEN n.Applications.Components.Name = 'Services DCDiag' THEN n.Applications.Components.StatusDescription END) AS [Services DCDiag] 
, MAX(CASE WHEN n.Applications.Components.Name = 'Services DCDiag' THEN n.Applications.Components.DetailsUrl ELSE NULL END) as [_linkfor_Services DCDiag]
, MAX(CASE WHEN n.Applications.Components.Name = 'Services DCDiag' THEN CONCAT('/Orion/images/StatusIcons/Small-', n.Applications.Components.StatusDescription, '.gif') ELSE NULL END) as [_iconfor_Services DCDiag]

-- Advertising DCDiag
, MAX(CASE WHEN n.Applications.Components.Name = 'Advertising DCDiag' THEN n.Applications.Components.StatusDescription END) AS [Advertising DCDiag] 
, MAX(CASE WHEN n.Applications.Components.Name = 'Advertising DCDiag' THEN n.Applications.Components.DetailsUrl ELSE NULL END) as [_linkfor_Advertising DCDiag]
, MAX(CASE WHEN n.Applications.Components.Name = 'Advertising DCDiag' THEN CONCAT('/Orion/images/StatusIcons/Small-', n.Applications.Components.StatusDescription, '.gif') ELSE NULL END) as [_iconfor_Advertising DCDiag]

-- FSMO DCDiag
, MAX(CASE WHEN n.Applications.Components.Name = 'FSMO DCDiag' THEN n.Applications.Components.StatusDescription END) AS [FSMO DCDiag] 
, MAX(CASE WHEN n.Applications.Components.Name = 'FSMO DCDiag' THEN n.Applications.Components.DetailsUrl ELSE NULL END) as [_linkfor_FSMO DCDiag]
, MAX(CASE WHEN n.Applications.Components.Name = 'FSMO DCDiag' THEN CONCAT('/Orion/images/StatusIcons/Small-', n.Applications.Components.StatusDescription, '.gif') ELSE NULL END) as [_iconfor_FSMO DCDiag]

-- Last Boot Time
, MAX(SUBSTRING(TOSTRING(n.LastBoot),1,11)) AS [Last Reboot]
, MAX(CONCAT(DAYDIFF(n.LastBoot,GETDATE()),' days')) AS [Uptime]

from orion.nodes as n

where n.Applications.name = 'FD Active Directory Health Check' 

GROUP BY 
    n.DNS

ORDER BY
    n.DNS