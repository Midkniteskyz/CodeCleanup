-- Selects username, login counts over different time periods, and the last login time
SELECT 
    ae.AccountID as [UserName],  -- Displays the username
    COUNT(ae.AccountID) as [Login Count Last 24 Hours],  -- Counts the number of logins per user in the last 24 hours
    (SELECT COUNT(a.AccountID) as [Login Count Last 30 Days]
     FROM Orion.AuditingEvents a
     WHERE a.AccountID = ae.AccountID
       AND a.TimeLoggedUtc > ADDDAY(-30, GETUTCDATE())
       AND a.ActionTypeID = '1') as [Login Count Last 30 Days],  -- Counts the number of logins per user in the last 30 days
    MAX(ae.TimeLoggedUtc) as [Last Login Time]  -- Finds the most recent login time for each user
FROM 
    Orion.AuditingEvents as ae  -- From the AuditingEvents table
WHERE 
    ae.TimeLoggedUtc > ADDDAY(-1, GETUTCDATE())  -- Filters events in the last 24 hours
    AND ae.ActionTypeID = '1'  -- Filters for login actions only
GROUP BY 
    ae.AccountID -- Groups the results by user name
ORDER BY 
    MAX(ae.TimeLoggedUtc) DESC  -- Orders the results by the most recent login time
