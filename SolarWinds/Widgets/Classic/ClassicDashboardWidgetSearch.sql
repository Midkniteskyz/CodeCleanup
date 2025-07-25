SELECT --[ClassicDashboards].ViewID
     -- , [ClassicDashboards].ViewKey
     [ClassicDashboards].ViewTitle AS [Dashboard Name]
     --     , [ClassicDashboards].ViewGroupName AS [Parent View]
     --     , [ClassicDashboards].ViewGroup AS [Parent View ID]
     --     , [ClassicDashboards].ViewType
     --     , [ClassicDashboards].ViewGroupPosition
     -- , [ClassicDashboards].ViewIcon
     , CASE 
          WHEN IsNull([ClassicDashboards].ViewIcon, '') <> ''
               THEN CONCAT (
                         '/Orion/Images/SubViewIcons/'
                         , [ClassicDashboards].ViewIcon
                         )
          ELSE NULL
          END AS [_IconFor_Dashboard Name]
     , CASE 
          WHEN (
                    [ClassicDashboards].ViewType LIKE '%Summary%'
                    AND IsNull([ClassicDashboards].ViewKey, '') <> ''
                    )
               THEN CONCAT (
                         '/Orion/SummaryView.aspx?ViewKey='
                         , [ClassicDashboards].ViewKey
                         )
          WHEN (
                    [ClassicDashboards].ViewType LIKE '%Summary%'
                    AND IsNull([ClassicDashboards].ViewKey, '') = ''
                    )
               THEN CONCAT (
                         '/Orion/SummaryView.aspx?ViewID='
                         , [ClassicDashboards].ViewID
                         )
          ELSE NULL
          END AS [_LinkFor_Dashboard Name]
     -- We don't need Column information
     --     , [ClassicDashboards].Columns
     --     , [ClassicDashboards].Column1Width
     --     , [ClassicDashboards].Column2Width
     --     , [ClassicDashboards].Column3Width
     --     , [ClassicDashboards].Column4Width
     --     , [ClassicDashboards].Column5Width
     --     , [ClassicDashboards].Column6Width
     --     These don't look like they serve a purpose
     --     , [ClassicDashboards].System
     --     , [ClassicDashboards].Customizable
     --
     --     Limitations Linking - still working on this
     --     , [ClassicDashboards].LimitationID
     --     , [Limitations].Definition
     --     , [LimitationTypes].Name
     , CASE 
          WHEN [ClassicDashboards].NOCView = 'TRUE'
               THEN CONCAT (
                         [ClassicDashboards].ViewGroupName
                         , ' - NOC'
                         )
          ELSE NULL
          END AS [NOC]
     , CASE 
          WHEN [ClassicDashboards].NOCView = 'TRUE'
               THEN CONCAT (
                         '/Orion/SummaryView.aspx?ViewID='
                         , [ClassicDashboards].ViewID
                         , '&isNOCView=true'
                         )
          ELSE NULL
          END AS [_LinkFor_NOC]
     , CASE 
          WHEN [ClassicDashboards].NOCView = 'TRUE'
               THEN '/Orion/images/noc_icon16x16.png'
          ELSE NULL
          END AS [_IconFor_NOC]
     --     , [ClassicDashboards].NOCViewRotationInterval
     --     , [ClassicDashboards].Feature
     , [ClassicWidgets].ViewColumn AS [Column]
     , [ClassicWidgets].Position AS [Position]
     , [ClassicWidgets].ResourceName AS [Widget Type]
     , [ClassicWidgets].ResourceTitle AS [Widget Name]
     , [ClassicWidgets].ResourceSubTitle AS [Widget Subtitle]
FROM Orion.VIEWS AS [ClassicDashboards]
LEFT JOIN Orion.Resources AS [ClassicWidgets]
     ON [ClassicDashboards].ViewID = [CLassicWidgets].ViewID
-- Limitations - still working
--LEFT JOIN Orion.Limitations AS [Limitations]
--     ON [ClassicDashboards].LimitationID = [Limitations].LimitationID
--LEFT JOIN Orion.LimitationTypes AS [LimitationTypes]
--  ON [Limitations].LimitationTypeId = [LimitationTypes].LimitationTypeId
WHERE [ClassicDashboards].IsActive = 'TRUE'
     --AND IsNull([ClassicWidgets].ViewColumn, 0) >= 1
     -- Uncomment the below to use the search
     -- ******************************************
     --AND (
     --     [ClassicWidgets].ResourceName LIKE '%${SEARCH_STRING}%'
     --     OR [ClassicWidgets].ResourceTitle LIKE '%${SEARCH_STRING}%'
     --     OR [ClassicWidgets].ResourceSubTitle LIKE '%${SEARCH_STRING}%'
     --     OR [ClassicDashboards].ViewGroupName LIKE '%${SEARCH_STRING}%'
     --     )
     -- ******************************************
     -- Uncomment the above to use the search
ORDER BY [ClassicDashboards].ViewTitle
     , [ClassicWidgets].ViewColumn
     , [ClassicWidgets].Position
