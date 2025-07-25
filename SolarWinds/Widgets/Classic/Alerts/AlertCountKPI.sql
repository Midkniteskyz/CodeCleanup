SELECT 
  Top 10 ad.name as [Alert Name], 
  COUNT(ad.name) AS [Active Count] 
FROM 
  Orion.alertobjects AS ao --AlertObjects is a good starting place to find correlated information about alerts
  JOIN orion.AlertActive AS aa ON aa.alertobjectid = ao.AlertobjectID -- AlertActive Table contains currently active alert information. Whats important is the Acknowledgement information and Trigger time information
  JOIN orion.alertstatus AS stat ON stat.AlertObjectID = ao.alertobjectid -- Similar to the AlertActive table. Has some more information about alerts, also contains the alertdefid. Alert Notes is an important column here
  JOIN orion.AlertDefinitions AS ad ON ad.AlertDefID = stat.AlertDefID -- This is where the actual information about an alerts configuration is at. We need it for the alertname
GROUP BY 
  ad.name;
ORDER BY 
  [Active Count] Desc;



-- Create a pie chart that has the following
-- the count of active alerts
-- Group them by name
-- Color code the groups by their severity
-- add an icon?

-- Get the count of the alerts by...
SELECT 

-- Value Field 
 ad.name as [Alert Name], 
  COUNT(ad.name) AS [Active Count] ,

-- Severity: critical 2, info 0,  serious 3, warning 1, notice 4
ac.severity,

CASE
  WHEN ac.severity = '2' THEN 'D:\Program Files\SolarWinds\Orion\Web\Orion\images\SeverityIcons\critcal.png'
  Else 'Unknown'
  END AS [IconMapping],

-- Color code the groups by their severity
CASE
  When ac.severity = '0' then '#999999' -- A light gray.
  When ac.severity = '1' then '#FEC405' -- A bright yellow, similar to a sunflower.
  When ac.severity = '2' then '#950000' -- A dark red, resembling maroon.
  When ac.severity = '3' then '#DD2C00' -- A bright, vivid orange.
  When ac.severity = '4' then '#176998' -- A deep blue with hints of teal.
  Else '#B8D757'
  END AS [ColorMapping]

FROM 
  Orion.alertobjects AS ao --AlertObjects is a good starting place to find correlated information about alerts
  JOIN orion.AlertActive AS aa ON aa.alertobjectid = ao.AlertobjectID -- AlertActive Table contains currently active alert information. Whats important is the Acknowledgement information and Trigger time information
  JOIN orion.alertstatus AS stat ON stat.AlertObjectID = ao.alertobjectid -- Similar to the AlertActive table. Has some more information about alerts, also contains the alertdefid. Alert Notes is an important column here
  JOIN orion.AlertDefinitions AS ad ON ad.AlertDefID = stat.AlertDefID -- This is where the actual information about an alerts configuration is at. We need it for the alertname

JOIN orion.AlertConfigurations as ac on ac.AlertID = ao.AlertID

-- Category Field 
GROUP BY 
  ad.name;