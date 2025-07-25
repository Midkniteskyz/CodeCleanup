SELECT

    CASE
        WHEN Name = 'RetainDetail' THEN 'Detail'
        WHEN Name = 'RetainHourly' THEN 'Hourly'
        WHEN Name = 'DataRetention' THEN 'Daily'
        WHEN Name = 'DataRetentionEventLog' THEN 'Event Log'
        WHEN Name = 'BaselineDataCollectionDuration' THEN 'Baseline Collection'
        WHEN Name = 'SQLBB_RetainDetachedDBDays' THEN 'SQL - Detached DBs'
        WHEN Name = 'SQLBB_RetainHistoryDays' THEN 'SQL - History'
        WHEN Name = 'SQLBB_RetainDetailTablesDays' THEN 'SQL - Detail'
        WHEN Name = 'EXBB_RetainDeletedDBDays' THEN 'Exchange - Detached DBs'
        WHEN Name = 'EXBB_RetainMailboxHistoryDays' THEN 'Exchange - History'
        WHEN Name = 'EXBB_RetainDetailTablesDays' THEN 'Exchange - Detail'
        WHEN Name = 'IISBB_RetainDetailTablesDays' THEN 'IIS - Detail'
        ELSE Name
    END AS [Name],  
    CONCAT(ToString(Value), ' days') AS [Current Value],  -- Column 3: Current value of the setting
    CASE
        WHEN Value = DefaultValue THEN 'Yes'  -- Column 4: If CurrentValue equals DefaultValue, show 'Yes'
        ELSE CONCAT(TOSTRING(DefaultValue), ' days')  -- Otherwise, show DefaultValue
    END AS [Default Value]

FROM 
    Orion.APM.Config

WHERE 
    (
        Name = 'RetainDetail'
        OR Name = 'RetainHourly'
        OR Name = 'DataRetention'
        OR Name = 'DataRetentionEventLog'
        OR Name = 'BaselineDataCollectionDuration'
        OR Name = 'SQLBB_RetainDetachedDBDays'
        OR Name = 'SQLBB_RetainHistoryDays'
        OR Name = 'SQLBB_RetainDetailTablesDays'
        OR Name = 'EXBB_RetainDeletedDBDays'
        OR Name = 'EXBB_RetainMailboxHistoryDays'
        OR Name = 'EXBB_RetainDetailTablesDays'
        OR Name = 'IISBB_RetainDetailTablesDays'
    )

ORDER By Name