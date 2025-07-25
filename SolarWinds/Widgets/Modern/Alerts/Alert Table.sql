SELECT 
  case WHEN aa.AlertObjects.AlertConfigurations.Severity = 0 THEN 'Information' WHEN aa.AlertObjects.AlertConfigurations.Severity = 1 THEN 'Warning' WHEN aa.AlertObjects.AlertConfigurations.Severity = 2 THEN 'Critical' WHEN aa.AlertObjects.AlertConfigurations.Severity = 3 THEN 'Serious' WHEN aa.AlertObjects.AlertConfigurations.Severity = 4 THEN 'Notice' END AS [Severity], 
  aa.AlertObjects.AlertConfigurations.Severity as [Severity Value], 
  case when aa.AlertObjects.AlertConfigurations.Severity = 0 then '/Orion/images/ActiveAlerts/InformationalAlert.png' when aa.AlertObjects.AlertConfigurations.Severity = 1 then '/Orion/images/ActiveAlerts/Warning.png' when aa.AlertObjects.AlertConfigurations.Severity = 2 then '/Orion/images/ActiveAlerts/Critical.png' when aa.AlertObjects.AlertConfigurations.Severity = 3 then '/Orion/images/ActiveAlerts/Serious.png' when aa.AlertObjects.AlertConfigurations.Severity = 4 then '/Orion/images/ActiveAlerts/Notice.png' end as [_iconFor_Severity], 
  aa.AlertObjects.AlertConfigurations.Name as [Alert Name], 
  CONCAT(
    '/Orion/View.aspx?NetObject=AAT:', 
    aa.AlertObjectID
  ) as [_Linkfor_Alert Name], 
  aa.AlertObjects.EntityCaption as [Trigger Object], 
  aa.AlertObjects.EntityDetailsUrl as [_Linkfor_Trigger Object], 
  aa.AlertObjects.RelatedNodeCaption as [Parent Object], 
  aa.AlertObjects.RelatedNodeDetailsUrl as [_Linkfor_Parent Object], 
  CONCAT(
    FLOOR(
      SecondDiff(
        TOUTC(aa.TriggeredDateTime), 
        GETUTCDATE()
      ) / 86400.0
    ), 
    'd ', 
    FLOOR(
      (
        SecondDiff(
          TOUTC(aa.TriggeredDateTime), 
          GETUTCDATE()
        ) - (
          FLOOR(
            SecondDiff(
              TOUTC(aa.TriggeredDateTime), 
              GETUTCDATE()
            ) / 86400.0
          ) * 86400
        )
      ) / 3600.0
    ), 
    'h ', 
    FLOOR(
      (
        SecondDiff(
          TOUTC(aa.TriggeredDateTime), 
          GETUTCDATE()
        ) - (
          FLOOR(
            SecondDiff(
              TOUTC(aa.TriggeredDateTime), 
              GETUTCDATE()
            ) / 86400.0
          ) * 86400
        ) - (
          FLOOR(
            (
              SecondDiff(
                TOUTC(aa.TriggeredDateTime), 
                GETUTCDATE()
              ) - (
                FLOOR(
                  SecondDiff(
                    TOUTC(aa.TriggeredDateTime), 
                    GETUTCDATE()
                  ) / 86400.0
                ) * 86400
              )
            ) / 3600.0
          ) * 3600
        )
      ) / 60.0
    ), 
    'm'
  ) as [Active Time], 
  Concat(
    Month(
      tolocal(aa.TriggeredDateTime)
    ), 
    '/', 
    Day(
      tolocal(aa.TriggeredDateTime)
    ), 
    '/', 
    Year(
      tolocal(aa.TriggeredDateTime)
    ), 
    ' ', 
    CASE 
    WHEN Hour(tolocal(aa.TriggeredDateTime)) = 0 THEN 12 
    WHEN Hour(tolocal(aa.TriggeredDateTime)) > 12 THEN (Hour(tolocal(aa.TriggeredDateTime)) -12) 
    ELSE Hour(tolocal(aa.TriggeredDateTime)) 
    END, 
    ':', 
    CASE 
    WHEN Minute(tolocal(aa.TriggeredDateTime)) < 10 THEN CONCAT('0', Minute(tolocal(aa.TriggeredDateTime)))
    else Minute(tolocal(aa.TriggeredDateTime))
    end, 
    CASE WHEN Hour(tolocal(aa.TriggeredDateTime)) >= 12 THEN ' PM' 
    ELSE ' AM' 
    END
  ) AS [Triggered Time], 
  CASE when aa.Acknowledged is not null then aa.AcknowledgedBy else '-' end as [Acknowledged By], 
  CASE when aa.Acknowledged is not null then Concat(
    Month(
      tolocal(aa.AcknowledgedDateTime)
    ), 
    '/', 
    Day(
      tolocal(aa.AcknowledgedDateTime)
    ), 
    '/', 
    Year(
      tolocal(aa.AcknowledgedDateTime)
    ), 
    ' ', 
    CASE WHEN Hour(
      tolocal(aa.AcknowledgedDateTime)
    ) = 0 THEN 12WHEN Hour(
      tolocal(aa.AcknowledgedDateTime)
    ) > 12 THEN (
      Hour(
        tolocal(aa.AcknowledgedDateTime)
      ) -12
    ) ELSE Hour(
      tolocal(aa.AcknowledgedDateTime)
    ) END, 
    ':', 
    CASE 
    WHEN Minute(tolocal(aa.AcknowledgedDateTime)) < 10 THEN CONCAT('0', Minute(tolocal(aa.AcknowledgedDateTime)))
    else Minute(tolocal(aa.AcknowledgedDateTime))
    end, 
    CASE WHEN Hour(
      tolocal(aa.AcknowledgedDateTime)
    ) >= 12 THEN ' PM' ELSE ' AM' END
  ) else '-' end AS [Acknowledged Time] 
FROM 
  Orion.AlertActive as aa
