 Concat(
    Month(
      tolocal(ah.TimeStamp)
    ), 
    '/', 
    Day(
      tolocal(ah.TimeStamp)
    ), 
    '/', 
    Year(
      tolocal(ah.TimeStamp)
    ), 
    ' ', 
    CASE WHEN Hour(
      tolocal(ah.TimeStamp)
    ) = 0 THEN 12WHEN Hour(
      tolocal(ah.TimeStamp)
    ) > 12 THEN (
      Hour(
        tolocal(ah.TimeStamp)
      ) -12
    ) ELSE Hour(
      tolocal(ah.TimeStamp)
    ) END, 
    ':', 
    CASE 
    WHEN Minute(tolocal(ah.TimeStamp)) < 10 THEN CONCAT('0', Minute(tolocal(ah.TimeStamp)))
    else Minute(tolocal(ah.TimeStamp))
    end, 
    CASE WHEN Hour(
      tolocal(ah.TimeStamp)
    ) >= 12 THEN ' PM' ELSE ' AM' END
  ) AS [Reset Time] 