SELECT
    Name,
    CASE
        WHEN Units IN ('s', 'seconds') THEN CONCAT(CurrentValue, ' sec')
        WHEN Units IN ('m', 'minutes') THEN CONCAT(CurrentValue, ' min')
        WHEN Units IS NULL OR CurrentValue IS NULL THEN 'Invalid Value'
        ELSE CONCAT(CurrentValue, ' day(s)')
    END AS [Retention Time]
FROM
    Orion.Settings
WHERE
    SettingID LIKE '%retain%' 
    AND SettingID NOT IN ('LogAnalyzer-Retention-MigrationStatus',
    'Declarative_AwsSqlDatabase_Daily_Retain',
    'Declarative_AwsSqlDatabase_Detail_Retain',
    'Declarative_AwsSqlDatabase_Hourly_Retain',
    'Declarative_AzureSqlDatabase_Daily_Retain',
    'Declarative_AzureSqlDatabase_Detail_Retain',
    'Declarative_AzureSqlDatabase_Hourly_Retain'
    )
ORDER BY
    SettingID;