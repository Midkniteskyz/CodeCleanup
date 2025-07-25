-- Retrieve email action configuration details for enabled node alerts

SELECT
    aa.ActionID,                                 -- Unique ID for the action
    aa.ParentID AS AlertID,                      -- Associated alert ID
    ac.ObjectType AS AlertType,                  -- Type of alert target (e.g., Node)
    ac.Name AS AlertName,                        -- Name of the alert
    ac.Description AS AlertDescription,          -- Description of the alert
    aa.CategoryType AS ActionType,               -- Type of action (Trigger, Reset, etc.)
    aa.action.ActionTypeID,                      -- Type of action (e.g., Email, Syslog)
    aa.action.Title AS ActionName,               -- Friendly name of the action
    aa.action.Enabled AS IsActionEnabled,        -- Whether the action is currently active

    -- Email action details aggregated by property name
    MAX(CASE WHEN aa.action.properties.propertyname = 'EmailTo' 
             THEN aa.action.properties.PropertyValue END) AS EmailTo,

    MAX(CASE WHEN aa.action.properties.propertyname = 'EmailCC' 
             THEN aa.action.properties.PropertyValue END) AS EmailCC,

    MAX(CASE WHEN aa.action.properties.propertyname = 'EmailBCC' 
             THEN aa.action.properties.PropertyValue END) AS EmailBCC,

    MAX(CASE WHEN aa.action.properties.propertyname = 'EmailFrom' 
             THEN aa.action.properties.PropertyValue END) AS EmailFrom,

    MAX(CASE WHEN aa.action.properties.propertyname = 'Subject' 
             THEN aa.action.properties.PropertyValue END) AS EmailSubject,

    MAX(CASE WHEN aa.action.properties.propertyname = 'EmailMessage' 
             THEN aa.action.properties.PropertyValue END) AS EmailMessage

FROM Orion.ActionsAssignments AS aa

    -- Join with the associated alert configuration
    INNER JOIN Orion.AlertConfigurations AS ac 
        ON ac.AlertID = aa.ParentID

WHERE 
    ac.Enabled = 1                                 -- Only include enabled alerts
    AND aa.action.ActionTypeID = 'Email'           -- Only include Email actions
    AND aa.CategoryType = 'Trigger'                -- Only include Trigger actions
    AND ac.ObjectType = 'Node'                     -- Only for Node-based alerts

GROUP BY 
    aa.ActionID,
    aa.ParentID,
    ac.ObjectType,
    aa.CategoryType,
    aa.action.ActionTypeID,
    aa.action.Title,
    aa.action.Enabled,
    ac.Name,
    ac.Description

ORDER BY 
    aa.ActionID ASC;
