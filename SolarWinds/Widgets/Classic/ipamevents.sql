SELECT
    DISTINCT CASE
        WHEN Name = 'Events.MaxLife' THEN 'IPAM Events'
        ELSE 'IPAM Events (Default)'
    END AS [Retention Name],
    CASE
        WHEN Value IS NULL THEN '90 Days'
        ELSE CONCAT(ToString(Value), ' Days')
    END AS [Retention Interval]
FROM
    IPAM.Setting
WHERE
    Name = 'Events.MaxLife'
UNION
ALL (
    SELECT
        DISTINCT CASE
            WHEN Name = 'IPHistory.MaxLife' THEN 'History'
            ELSE 'History (Default)'
        END AS [Retention Name],
        CASE
            WHEN Value IS NULL THEN '365 Days'
            ELSE CONCAT(ToString(Value), ' Days')
        END AS [Retention Interval]
    FROM
        IPAM.Setting
    WHERE
        Name = 'IPHistory.MaxLife'
)