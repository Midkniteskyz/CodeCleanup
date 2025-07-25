SELECT TOP 1000 
CASE
    WHEN ((MinutesSinceLastSync * 60) > PollInterval) THEN 'Status'
    WHEN (MinutesSinceLastSync > StatCollection) THEN 'Statistics'
    ELSE 'None'
END as [Polling Issue]
, n.Engine.ServerName as [Polling Engine]
, ObjectSubType
, Caption
, IPAddress
, VendorIcon
, Status
, ResponseTime
, PercentLoss
, LastSync
, NextPoll
, SkippedPollingCycles
, MinutesSinceLastSync
, DetailsUrl
, ModernIcon
, EntityLink
, Uri
FROM Orion.Nodes