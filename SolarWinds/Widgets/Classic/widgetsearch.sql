SELECT TOP 1000 w.WidgetID, w.Links.DashboardID, w.Subtitle, w.Type, w.Configuration
FROM Orion.Dashboards.Widgets as w
where configuration like '%cred%'