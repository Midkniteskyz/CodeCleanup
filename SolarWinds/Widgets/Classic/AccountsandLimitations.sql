     SELECT a.AccountID
          , lt1.name as [Limitation Name 1]
          , l1.WhereClause as [Limitation Definition 1]
          , lt2.name as [Limitation Name 2]
          , l2.WhereClause as [Limitation Definition 2]
          , lt3.name as [Limitation Name 3]
          , l3.WhereClause as [Limitation Definition 3]
       FROM Orion.Accounts AS a
  LEFT JOIN Orion.Limitations AS l1
         ON a.LimitationID1 = l1.LimitationID
  LEFT JOIN Orion.Limitations AS l2
         ON a.LimitationID2 = l2.LimitationID
  LEFT JOIN Orion.Limitations AS l3
         ON a.LimitationID3 = l3.LimitationID
  LEFT JOIN Orion.LimitationTypes AS lt1
         ON l1.LimitationTypeID = lt1.LimitationTypeID
  LEFT JOIN Orion.LimitationTypes AS lt2
         ON l2.LimitationTypeID = lt2.LimitationTypeID
  LEFT JOIN Orion.LimitationTypes AS lt3
         ON l3.LimitationTypeID = lt3.LimitationTypeID
      --  0 = System
      --  1 = SolarWinds individual
      --  2 = Windows Individual
      --  3 = Windows group
      --  4 = Windows group individual
      WHERE 1=1
        AND a.AccountType = 3
;

