SELECT
    -- Determine the type of polling issue
    --CASE
        --WHEN ((n.MinutesSinceLastSync * 60) > n.PollInterval) THEN 'Status'
        --WHEN (n.MinutesSinceLastSync > n.StatCollection) THEN 'Statistics'
        --ELSE 'None'
    --END AS [Polling Issue],

    -- Node details
    n.ObjectSubType AS [Polling Method],
    n.IPAddress AS [IP Address],
    n.Caption AS [Node Name],
    --n.VendorIcon AS [Vendor Icon],
    --n.PolledStatus AS [Polled Status],
    si.ShortDescription,
    --n.StatusLED AS [Status LED],
    n.LastSync AS [Last Sync Time],
    --n.DetailsUrl AS [Node Details URL],

    -- Polling engine details
    n.Engine.DisplayName AS [Polling Engine],
    n.Engine.IP AS [Polling Engine IP],
ncsc.Name,
ncsc.Status,
sincsc.StatusName
    

FROM Orion.Nodes AS n

JOIN Orion.StatusInfo as si ON si.StatusId = n.PolledStatus 
Join Orion.NodeChildStatusContributors as ncsc on ncsc.NodeID = n.NodeID
JOIN Orion.StatusInfo as sincsc ON sincsc.StatusId = ncsc.Status 

-- WHERE n.PolledStatus != 1 AND (((n.MinutesSinceLastSync * 60) > n.PollInterval) OR (n.MinutesSinceLastSync > n.StatCollection))
WHERE si.ShortDescription != 'Up'
