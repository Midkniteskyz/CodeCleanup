SELECT
    CASE
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 0 THEN 'Information'
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 1 THEN 'Warning'
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 2 THEN 'Critical'
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 3 THEN 'Serious'
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 4 THEN 'Notice'
    END AS [Severity],
    CASE
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 0 THEN '/Orion/images/ActiveAlerts/InformationalAlert.png'
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 1 THEN '/Orion/images/ActiveAlerts/Warning.png'
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 2 THEN '/Orion/images/ActiveAlerts/Critical.png'
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 3 THEN '/Orion/images/ActiveAlerts/Serious.png'
        WHEN aa.AlertObjects.AlertConfigurations.Severity = 4 THEN '/Orion/images/ActiveAlerts/Notice.png'
    END AS [_iconFor_Severity],
    aa.AlertObjects.AlertConfigurations.Name AS [Alert Name],
    CONCAT(
        '/Orion/View.aspx?NetObject=AAT:',
        aa.AlertObjectID
    ) AS [_Linkfor_Alert Name],
    aa.AlertObjects.EntityCaption AS [Trigger Object],
    aa.AlertObjects.EntityDetailsUrl AS [_Linkfor_Trigger Object],
    aa.AlertObjects.RelatedNodeCaption AS [Parent Object],
    aa.AlertObjects.RelatedNodeDetailsUrl AS [_Linkfor_Parent Object],
    CONCAT(
        FLOOR(
            SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) / 86400.0
        ),
        'd ',
        FLOOR(
            (
                SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) - (
                    FLOOR(
                        SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) / 86400.0
                    ) * 86400
                )
            ) / 3600.0
        ),
        'h ',
        FLOOR(
            (
                SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) - (
                    FLOOR(
                        SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) / 86400.0
                    ) * 86400
                ) - (
                    FLOOR(
                        (
                            SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) - (
                                FLOOR(
                                    SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) / 86400.0
                                ) * 86400
                            )
                        ) / 3600.0
                    ) * 3600
                )
            ) / 60.0
        ),
        'm'
    ) AS [Active Time],
    aa.TriggeredDateTime AS [Triggered Time],
    aa.Acknowledged AS [Acknowledged By] ,
    aa.AcknowledgedDateTime AS [Acknowledged Time]
FROM
    Orion.AlertActive AS aa
WHERE
    aa.Acknowledged IS NULL
    AND (
        aa.AlertObjects.AlertConfigurations.Name LIKE '%${SEARCH_STRING}%' OR
        aa.AlertObjects.EntityCaption LIKE '%${SEARCH_STRING}%' OR
        aa.AlertObjects.RelatedNodeCaption LIKE '%${SEARCH_STRING}%'
    )
ORDER BY
    aa.TriggeredDateTime DESC