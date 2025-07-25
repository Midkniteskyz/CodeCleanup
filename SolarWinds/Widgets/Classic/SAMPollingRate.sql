SELECT TOP 1000 EngineID, ScaleFactor, CurrentUsage
FROM Orion.PollingUsage
where scalefactor like '%APM%'