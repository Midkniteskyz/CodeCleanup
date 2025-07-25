SELECT
    TOP 100 ah.AlertObjects.AlertConfigurations.Name AS [Alert Name],
    concat(
        '/Orion/NetPerfMon/ActiveAlertDetails.aspx?NetObject=AAT:',
        ah.AlertObjectID
    ) AS [_linkfor_Alert Name],
    ah.AlertObjects.Entitycaption AS [Object],
    ah.AlertObjects.EntityDetailsUrl AS [_linkfor_Object],
    Concat(
        MONTH(tolocal(ah.TimeStamp)),
        '/',
        DAY(tolocal(ah.TimeStamp)),
        '/',
        Year(tolocal(ah.TimeStamp)),
        ' ',
        CASE
            WHEN HOUR(tolocal(ah.TimeStamp)) = 0 THEN 12WHEN HOUR(tolocal(ah.TimeStamp)) > 12 THEN (HOUR(tolocal(ah.TimeStamp)) -12)
            ELSE HOUR(tolocal(ah.TimeStamp))
        END,
        ':',
        CASE
            WHEN MINUTE(tolocal(ah.TimeStamp)) < 10 THEN CONCAT('0', MINUTE(tolocal(ah.TimeStamp)))
            ELSE MINUTE(tolocal(ah.TimeStamp))
        END,
        CASE
            WHEN HOUR(tolocal(ah.TimeStamp)) >= 12 THEN ' PM'
            ELSE ' AM'
        END
    ) AS [Reset Time]
FROM
    Orion.AlertHistory AS ah
WHERE
    --alert resets 
    eventtype = 1
    AND (
        ah.AlertObjects.AlertConfigurations.Name LIKE '%${SEARCH_STRING}%' OR
        OR ah.AlertObjects.Entitycaption LIKE '%${SEARCH_STRING}%'
    )
ORDER BY
    TimeStamp DESC