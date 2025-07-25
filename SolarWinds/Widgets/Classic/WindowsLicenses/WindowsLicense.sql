SELECTapp.ApplicationID, 
app.Name AS [TemplateName], 
app.Components.name AS [ComponentName], 
app.NodeID, 
app.ApplicationTemplateID, 
app.DetailsUrl, 
app.FullyQualifiedName, 
app.Status as [AppStatus], 
app.StatusDescription as [AppDescription], 
app.Uri as [AppURI], 
app.Components.CurrentStatistics.ErrorMessage as [ComponentMsg], 
app.Components.Status as [ComponentStatus], 
app.Components.StatusDescription as [ComponentDesc], 
app.Components.DetailsUrl as [ComponentURI], 
app.node.NodeName, 
CASEwhen app.Components.CurrentStatistics.ErrorMessage like '%ServerDatacenter%' THEN 'DataCenter Edition' WHEN app.Components.CurrentStatistics.ErrorMessage like '%ServerStandard%' THEN 'Standard Edition' WHEN app.Components.CurrentStatistics.ErrorMessage like '%Office%' THEN 'Office' WHEN app.Components.CurrentStatistics.ErrorMessage like '%Enterprise%' THEN 'Enterprise Edition' WHEN app.Components.CurrentStatistics.ErrorMessage like '%failed%' THEN 'Query failed.' WHEN app.Components.CurrentStatistics.ErrorMessage like '%timeout%' THEN 'Query failed.' WHEN app.Components.CurrentStatistics.ErrorMessage IS NULL THEN 'Unknown' WHEN app.Components.CurrentStatistics.ErrorMessage = '' THEN 'Unknown' ELSE '' end AS LicenseEdition, 
CASEWHEN app.Components.StatusDescription = 'Up' THEN SUBSTRING(
  app.Components.CurrentStatistics.ErrorMessage, 
  (
    CharIndex(
      'date:', app.Components.CurrentStatistics.ErrorMessage
    ) + 6
  ), 
  10
) ELSE 'Unknown' END AS ExpirationDateFROM Orion.APM.Application as Appwhere app.Components.TemplateID = '5816'
