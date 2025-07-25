-- This query retrieves and color-codes an expiration date value from the APIPoller system,
-- based on how close it is to expiration. The styling is meant for display in a web-based widget or report.

-- Replace '##' with the appropriate ValueToMonitorId

DECLARE @exp_date AS DATETIME = (
    SELECT
        -- Convert raw text format to a datetime
        TRY_CONVERT(datetime2(0),
            STUFF(
                STUFF(
                    LEFT(STUFF(V.Text,1,8,''), 12),      -- Clean up raw date string
                    3, 0, RIGHT(V.Text, 5)               -- Insert time formatting
                ),
                3, 0, SUBSTRING(V.Text, 4, 4)            -- Re-insert year
            ),
        113) AS ConvertedDate
    FROM APIPoller_StringToNumberTransformationRule V
    WHERE V.ValueToMonitorId = ##                      -- Replace with actual ID
)

-- Calculate number of days until expiration
DECLARE @diffy AS INT = (
    SELECT DATEDIFF(day, GETDATE(), @exp_date)
)

-- Output the styled expiration date and matching ValueToMonitor name
SELECT TOP 1
    CASE 
        WHEN @diffy > 90 THEN CONCAT('<a style="color:DarkGreen;font-size:150%;">', Text, '</a>')
        WHEN @diffy > 45 AND @diffy <= 90 THEN CONCAT('<a style="color:Orange;font-size:200%;">', Text, '</a>')
        WHEN @diffy <= 45 THEN CONCAT('<a style="color:Crimson;font-size:400%;">', Text, '</a>')
    END AS [Date],
    vtm.Name
FROM dbo.APIPoller_StringToNumberTransformationRule stn
JOIN APIPoller_ValueToMonitor vtm ON vtm.Id = stn.ValueToMonitorID
WHERE stn.ValueToMonitorId = ##                        -- Replace with actual ID
