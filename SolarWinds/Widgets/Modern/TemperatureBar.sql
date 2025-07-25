SELECT
    -- Weighted arithmetic mean of node scores. Weights by Status: Down - 1, Critical - 0.66 , Warning - 0.33, Up - 0
    ROUND(
        (
            SUM(
                CASE
                    WHEN n.Status IN (1, 22, 31, 42) THEN 0
                END
            ) + SUM(
                CASE
                    WHEN n.Status IN (3, 15, 16, 17, 28, 32, 33, 37, 41, 43, 44) THEN 0.33
                END
            ) + SUM(
                CASE
                    WHEN n.Status IN (8, 14, 38, 39) THEN 0.66
                END
            ) + SUM(
                CASE
                    WHEN n.Status IN (2) THEN 1
                END
            )
        ) / COUNT(*) * 100,
        2
    ) AS HealthPercentage
FROM
    Orion.Nodes AS n