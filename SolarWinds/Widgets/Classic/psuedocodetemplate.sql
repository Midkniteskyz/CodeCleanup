-- Description: [Brief description of the query's purpose]

-- Step 1: Selecting columns and transformations
SELECT
    -- Column 1: [Description of the first column, e.g., customer name]
    [column_name_1] AS [alias_name_1],

    -- Column 2: [Description of the second column, e.g., order date]
    [column_name_2] AS [alias_name_2],

    -- Column 3: [Description of the third column, e.g., total amount]
    [column_name_3] AS [alias_name_3]

-- Step 2: From clause and joins
FROM
    -- Table 1: [Description of the main table or source]
    [table_name_1] AS [alias_1]

    -- Join type: [Description of the join type, e.g., INNER JOIN]
    [JOIN_TYPE] [table_name_2] AS [alias_2]
    ON [alias_1].[join_column] = [alias_2].[join_column]

-- Step 3: Filtering rows
WHERE
    -- Condition 1: [Description of the first condition, e.g., filter by date range]
    [condition_1]

    -- Logical operator: [AND / OR]
    AND/OR

    -- Condition 2: [Description of the second condition, e.g., filter by customer type]
    [condition_2]

-- Step 4: Grouping rows
GROUP BY
    -- Grouping column 1: [Description of the grouping column, e.g., customer name]
    [group_by_column_1]

    -- Grouping column 2: [Description of another grouping column, if applicable]
    ,[group_by_column_2]

-- Step 5: Aggregating data
HAVING
    -- Aggregation condition 1: [Description of the aggregation condition, e.g., sum of total amount > 1000]
    [aggregation_condition_1]

-- Step 6: Ordering results
ORDER BY
    -- Order by column 1: [Description of the order, e.g., order by order date descending]
    [order_by_column_1] DESC,

    -- Order by column 2: [Description of another order, if applicable]
    [order_by_column_2] ASC;
