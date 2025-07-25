SELECT 
-- Get the Name of the vCenter
-- Get the build number
-- Which credential is it using
-- Which polling engine is polling it
-- whats its current polling status
-- whats the polling method
-- 
  Name, 
  VMwareProductVersion, 
  CredentialID, 
  IPAddress, 
  ConnectionState, 
  PollingSource, 
  StatusMessage, 
  ManagedStatus, 
  ManagedStatusMessage, 
  TriggeredAlarmDescription, 
  OrionIdPrefix, 
  OrionIdColumn, 
  DetailsUrl 
FROM 
  Orion.VIM.VCenters
