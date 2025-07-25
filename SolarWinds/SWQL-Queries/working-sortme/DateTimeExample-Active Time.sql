  FLOOR(SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) / 86400.0) AS Days,
  FLOOR((SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) - (FLOOR(SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) / 86400.0) * 86400)) / 3600.0) AS Hours,
  FLOOR((SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) - 
         (FLOOR(SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) / 86400.0) * 86400) - 
         (FLOOR((SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) - 
                (FLOOR(SecondDiff(TOUTC(aa.TriggeredDateTime), GETUTCDATE()) / 86400.0) * 86400)) / 3600.0) * 3600)
        ) / 60.0) AS Minutes,