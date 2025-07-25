-- Grab the licensing and module information for the High Level Design
SELECT
    -- Remove the version number from the module name
    CONCAT(REPLACE(DisplayName, ' v' + Version, ''),' (', LicenseName,')') AS [Module Name (License Name)], 
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