-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'up':
SELECT 
    n.caption
    ,n.status
    ,n.DetailsUrl
    ,n.CPULoad
    ,n.PercentMemoryUsed
    ,n.ResponseTime
    ,n.PercentLoss 

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf' and s.statusname = 'Up'

------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Down':
SELECT 
    n.caption
    ,n.status
    ,n.DetailsUrl
    ,n.CPULoad
    ,n.PercentMemoryUsed
    ,n.ResponseTime
    ,n.PercentLoss 

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf' and s.statusname = 'Down'

------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Warning':
SELECT 
    n.caption
    ,n.status
    ,n.DetailsUrl
    ,n.CPULoad
    ,n.PercentMemoryUsed
    ,n.ResponseTime
    ,n.PercentLoss 

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf' and s.statusname = 'Warning'

------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Critical':
SELECT 
    n.caption
    ,n.status
    ,n.DetailsUrl
    ,n.CPULoad
    ,n.PercentMemoryUsed
    ,n.ResponseTime
    ,n.PercentLoss 

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf' and s.statusname = 'Critical'

------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Unmanaged':
SELECT 
    n.caption
    ,n.status
    ,n.DetailsUrl
    ,n.CPULoad
    ,n.PercentMemoryUsed
    ,n.ResponseTime
    ,n.PercentLoss 

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf' and s.statusname = 'Unmanaged'

------------------------------------------------------------

-- To see a list of the different statuses, use the query below:
-- SELECT StatusId, StatusName FROM orion.statusinfo 

-- Selecting the count of nodes with status 'Unreachable':
SELECT 
    n.caption
    ,n.status
    ,n.DetailsUrl
    ,n.CPULoad
    ,n.PercentMemoryUsed
    ,n.ResponseTime
    ,n.PercentLoss 

-- From the 'orion.nodes' table alias as 'n':
FROM orion.nodes AS n

-- Joining the 'orion.nodescustomproperties' table alias as 'cp' based on the 'nodeid' column:
JOIN orion.nodescustomproperties AS cp ON cp.nodeid = n.nodeid

-- Joining the 'orion.statusinfo' table alias as 's' based on the 'Status' column:
JOIN orion.statusinfo AS s ON s.statusid = n.Status

-- Filtering the results to include only nodes with 'switch_function' equal to 'idf':
WHERE cp.switch_function = 'idf' and s.statusname = 'Unreachable'