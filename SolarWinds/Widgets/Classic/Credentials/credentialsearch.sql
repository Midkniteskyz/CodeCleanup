SELECT 
  n.caption AS [Node Name], 
  n.detailsurl AS [_linkfor_Node], 
  n.status AS [Node Status], 
  n.objectsubtype AS [Polling Method], 
  CASE WHEN n.objectsubtype IN ('ICMP', 'WMI') THEN 'None' ELSE n.community END AS [SNMP Credential], 
  '/Orion/Nodes/NodeProperties.aspx?Nodes=' + ToString(n.NodeID) as [_linkfor_SNMP Credential], 
  CASE WHEN n.objectsubtype = 'WMI' THEN cn.Name ELSE 'None' END AS [WMI Credential], 
  '/Orion/Nodes/NodeProperties.aspx?Nodes=' + ToString(n.NodeID) as [_linkfor_WMI Credential], 
  CASE WHEN a.name IS null THEN 'None Assigned' ELSE a.name END AS [Application], 
  a.detailsurl AS [_linkfor_Application], 
  a.status AS [_IconFor_Application], 
  CASE WHEN aset.value = '-3' THEN 'Inherit From Node' WHEN aset.value IS null 
  AND c.name IS NOT null THEN 'Set by Componet' WHEN a.name IS null THEN 'None Assigned' ELSE ca.name END AS [Application Credential], 
  '/Orion/APM/Admin/Edit/EditApplication.aspx?id=' + tostring(a.applicationid) as [_linkfor_Application Credential], 
  CASE WHEN c.name IS null THEN 'None Assigned' ELSE c.name END AS [Componet], 
  c.detailsurl as [_linkfor_Component], 
  c.status AS [_IconFor_Component], 
  CASE WHEN a.ApplicationTemplateID in (8, 9, 10) THEN 'Set by Application' WHEN cs.value = '-3' THEN 'Inherit From Node' WHEN c.name is null THEN 'None Assigned' else cc.name end as [Component Credential], 
  '/Orion/APM/Admin/Edit/EditApplication.aspx?id=' + tostring(a.applicationid) as [_linkfor_Component Credential] 
FROM 
  orion.nodes n 
  left join Orion.NodeSettings ns ON n.NodeID = ns.NodeID 
  and settingname = 'WMICredential' 
  left join Orion.Credential cn ON ns.SettingValue = cn.ID 
  left join orion.apm.application a on n.nodeid = a.nodeid 
  left join Orion.APM.ApplicationSettings as aset on aset.applicationid = a.applicationid 
  and (
    aset.key = 'CredentialSetId' 
    or aset.key = 'SqlCredentialSetId'
  ) 
  left join Orion.Credential ca ON aset.Value = ca.ID 
  left join orion.apm.component c on c.applicationid = a.applicationid 
  left join orion.apm.componentsetting cs on cs.componentid = c.componentid 
  and cs.key = '__CredentialSetId' 
  left join orion.apm.componenttemplatesetting cts on cts.componenttemplateid = c.templateid 
  and cts.key = '__CredentialSetId' 
  left join Orion.Credential cc ON cs.Value = cc.ID 
  or cc.id = cts.value 
WHERE 
  n.objectsubtype IN ('WMI', 'SNMP')
