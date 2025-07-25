SELECT 
  your_datetime_column, 
  CONCAT(
    DATEDIFF(
      MINUTE, 
      your_datetime_column, 
      GETDATE()
    ), 
    ' minutes ago'
  ) AS time_ago 
FROM 
  your_table;
