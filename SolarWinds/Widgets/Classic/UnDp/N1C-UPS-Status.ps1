SELECT
CASE
WHEN cpa.CustomPollerName LIKE 'ups1bypass%' THEN 'Bypass'
WHEN cpa.CustomPollerName LIKE 'ups1input%' THEN 'Input'
WHEN cpa.CustomPollerName LIKE 'ups1output%' THEN 'Output'
WHEN cpa.CustomPollerName LIKE 'ups1battery%' OR cpa.CustomPollerName LIKE 'ups1remainingCapacity%' THEN 'Battery'
ELSE 'Other'
END AS [Component Group]

, CASE
WHEN cpa.CustomPollerName LIKE '%Voltage%' THEN 'Voltage'
WHEN cpa.CustomPollerName LIKE '%Current%' THEN 'Current'
WHEN cpa.CustomPollerName LIKE '%Frequency%' THEN 'Frequency'
WHEN cpa.CustomPollerName LIKE '%ActivePower%' THEN 'Active Power'
WHEN cpa.CustomPollerName LIKE '%Temperature%' THEN 'Temperature'
WHEN cpa.CustomPollerName LIKE '%Status%' THEN 'Status'
WHEN cpa.CustomPollerName LIKE '%Capacity%' THEN 'Capacity'
WHEN cpa.CustomPollerName LIKE '%LoadRate%' THEN 'Load Rate'
WHEN cpa.CustomPollerName LIKE '%TimeRemaining%' THEN 'Time Remaining'
ELSE 'Other'
END AS [Metric Type]

, CASE
WHEN cpa.CustomPollerName = 'ups1bypassUPhaseActivePower' THEN 'Bypass Phase Active Power'
WHEN cpa.CustomPollerName = 'ups1bypassUPhaseCurrent' THEN 'Bypass Phase Current'
WHEN cpa.CustomPollerName = 'ups1bypassUPhaseVoltage' THEN 'Bypass Phase Voltage'
WHEN cpa.CustomPollerName = 'ups1outputFrequency' THEN 'Output Frequency'
WHEN cpa.CustomPollerName = 'ups1batteryTemperature' THEN 'Battery Temperature'
WHEN cpa.CustomPollerName = 'ups1batteryVoltage' THEN 'Battery Voltage'
WHEN cpa.CustomPollerName = 'ups1batteryOperationStatus' THEN 'Battery Status'
WHEN cpa.CustomPollerName = 'ups1batteryChargingAndDischargingCurrent' THEN 'Battery Charge/Discharge Current'
WHEN cpa.CustomPollerName = 'ups1remainingCapacityOfBattery' THEN 'Battery Remaining Capacity'
WHEN cpa.CustomPollerName = 'ups1inputUPhaseCurrent' THEN 'Input Phase Current'
WHEN cpa.CustomPollerName = 'ups1inputUPhaseFrequency' THEN 'Input Phase Frequency'
WHEN cpa.CustomPollerName = 'ups1inputUPhaseVoltage' THEN 'Input Phase Voltage'
WHEN cpa.CustomPollerName = 'ups1outputUPhaseVoltage' THEN 'Output Phase Voltage'
WHEN cpa.CustomPollerName = 'ups1outputUPhaseCurrent' THEN 'Output Phase Current'
WHEN cpa.CustomPollerName = 'ups1outputUPhaseActivePower' THEN 'Output Phase Active Power'
WHEN cpa.CustomPollerName = 'ups1outputUPhaseLoadRate' THEN 'Output Phase Load Rate'
WHEN cpa.CustomPollerName = 'ups1batteryTimeRemaining' THEN 'Battery Time Remaining'
WHEN cpa.CustomPollerName = 'ups1bypassFrequency' THEN 'Bypass Frequency'
ELSE cpa.CustomPollerName
END AS [Poller]

, CASE 
WHEN cpa.CustomPollerName LIKE '%Voltage%' THEN CONCAT (CurrentValue, ' V')
WHEN cpa.CustomPollerName LIKE '%Current%' THEN CONCAT (CurrentValue, ' A')
WHEN cpa.CustomPollerName LIKE '%Frequency%' THEN CONCAT (CurrentValue, ' Hz')
WHEN cpa.CustomPollerName LIKE '%ActivePower%' THEN CONCAT (CurrentValue, ' kW')
WHEN cpa.CustomPollerName LIKE '%Temperature%' THEN CONCAT (CurrentValue, ' °C')
WHEN cpa.CustomPollerName LIKE '%Capacity%'
OR cpa.CustomPollerName LIKE '%LoadRate%' THEN CONCAT (CurrentValue, ' %')
WHEN cpa.CustomPollerName LIKE '%TimeRemaining%' THEN CONCAT (CurrentValue, ' min')
ELSE CurrentValue
END AS [Value]

, '/Orion/NPM/Admin/UnDP/UnDPThresholdsManager.aspx' AS [_linkfor_Poller]

, CONCAT (
'/Orion/Charts/CustomChart.aspx?ChartName=CustomPollerChart_Node&rpCustomPollerID='
	,${CustomPollerID}
	,'&Rows=&SubsetColor=FF0000&NetObject=N:'
	,${NodeId}
	,'&ChartTitle=${cpa.CustomPollerName}&ChartSubTitle=${ZoomRange}'
) AS [_linkfor_Value]

, cpa.StatusDescription AS [Status]

, CONCAT (
    '/Orion/images/StatusIcons/Small-'
    , cpa.StatusDescription
    , '.gif'
) AS [_iconfor_Status]

, CONCAT(
    Month(cps.DateTime), '/', 
    Day(cps.DateTime), '/', 
    Year(cps.DateTime), ' ',
    CASE 
      WHEN Hour(cps.DateTime) < 10 THEN CONCAT('0' , ToString(Hour(cps.DateTime))) 
      ELSE ToString(Hour(cps.DateTime)) 
    END, ':',
    CASE 
      WHEN Minute(cps.DateTime) < 10 THEN CONCAT('0' , ToString(Minute(cps.DateTime))) 
      ELSE ToString(Minute(cps.DateTime)) 
    END
  ) AS [Last Poll Time]

FROM Orion.NPM.CustomPollerAssignment AS cpa

JOIN Orion.NPM.CustomPollerStatus AS cps on cps.CustomPollerAssignmentID = cpa.CustomPollerAssignmentID

WHERE cpa.NodeID = ${NodeId}

ORDER BY 
[Component Group]
, [Metric Type]
