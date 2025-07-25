-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'up':
SELECT
    COUNT(CASE WHEN s.statusname = 'Up' THEN 1 END) AS Num

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf'

---------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Down':
SELECT
    COUNT(CASE WHEN s.statusname = 'Down' THEN 1 END) AS Num

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf'

---------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Warning':
SELECT
    COUNT(CASE WHEN s.statusname = 'Warning' THEN 1 END) AS Num

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf'

---------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Warning':
SELECT
    COUNT(CASE WHEN s.statusname = 'Warning' THEN 1 END) AS Num

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf'

---------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Unmanaged':
SELECT
    COUNT(CASE WHEN s.statusname = 'Unmanaged' THEN 1 END) AS Num

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf'

---------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Unreachable':
SELECT
    COUNT(CASE WHEN s.statusname = 'Unreachable' THEN 1 END) AS Num

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf'

---------------------------------------------------------------
