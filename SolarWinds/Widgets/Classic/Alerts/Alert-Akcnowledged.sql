SELECT
    aa.AlertObjects.AlertConfigurations.Name AS [Alert Name],
    CONCAT(
        '/Orion/View.aspx?NetObject=AAT:',
        aa.AlertObjectID
    ) AS [_Linkfor_Alert Name],
    CASE
        WHEN aa.Acknowledged IS NOT NULL THEN aa.AcknowledgedBy
        ELSE '-'
    END AS [Acknowledged By],
    CASE
        WHEN aa.Acknowledged IS NOT NULL THEN Concat(
            MONTH(tolocal(aa.AcknowledgedDateTime)),
            '/',
            DAY(tolocal(aa.AcknowledgedDateTime)),
            '/',
            Year(tolocal(aa.AcknowledgedDateTime)),
            ' ',
            CASE
                WHEN HOUR(tolocal(aa.AcknowledgedDateTime)) = 0 THEN 12WHEN HOUR(tolocal(aa.AcknowledgedDateTime)) > 12 THEN (HOUR(tolocal(aa.AcknowledgedDateTime)) -12)
                ELSE HOUR(tolocal(aa.AcknowledgedDateTime))
            END,
            ':',
            CASE
                WHEN MINUTE(tolocal(aa.AcknowledgedDateTime)) < 10 THEN CONCAT('0', MINUTE(tolocal(aa.AcknowledgedDateTime)))
                ELSE MINUTE(tolocal(aa.AcknowledgedDateTime))
            END,
            CASE
                WHEN HOUR(tolocal(aa.AcknowledgedDateTime)) >= 12 THEN ' PM'
                ELSE ' AM'
            END
        )
        ELSE '-'
    END AS [Acknowledged Time],
    aa.AlertObjects.AlertNote
FROM
    Orion.AlertActive AS aa
WHERE
    aa.Acknowledged IS NOT NULL
ORDER BY
    aa.AcknowledgedDateTime DESC