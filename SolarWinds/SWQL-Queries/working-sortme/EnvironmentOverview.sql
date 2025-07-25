-- Grab the licensing and module information for the High Level Design
SELECT
    DisplayName AS [Module Name], 
    LicenseName AS [License Name], 
    Version,  
    CASE
        WHEN IsEval = 'True' THEN 'X'
        ELSE '-'
    END AS [Evaluation],
    DaysRemaining AS [Days Left], 
    CASE
        WHEN IsExpired = 'True' THEN 'X'
        ELSE '-'
    END AS [Expired]
FROM Orion.InstalledModule

ORDER BY LicenseName