SELECT 
  TOP 1000 
  -- ***** Account Settings *****
  -- account type
  CoreAccountSettings.AccountType, 
  -- group info
  CoreAccountSettings.GroupInfo, 
  -- Account ID
  CoreAccountSettings.AccountID, 
  -- Account Enabled  
  CoreAccountSettings.Enabled, 
  -- Account Expires  
  CoreAccountSettings.Expires, 
  -- Disable Session Timeout
  CoreAccountSettings.DisableSessionTimeout, 
  -- Lockout Time
  CoreAccountSettings.LockoutTime, 
  -- bad password count
  CoreAccountSettings.BadPwdCount, 
  -- password expiration date
  CoreAccountSettings.PasswordExpirationDate, 
  -- last login
  CoreAccountSettings.LastLogin, 
  -- Allow Administrator Rights
  CoreAccountSettings.AllowAdmin, 
  -- Allow Node Management Rights  
  CoreAccountSettings.AllowNodeManagement, 
  -- Allow management of Network Atlas Maps  
  CoreAccountSettings.AllowMapManagement, 
  -- Allow management of Intelligent Maps  
  CoreAccountSettings.AllowOrionMapsManagement, 
  -- Allow upload of images to Intelligent Maps  
  CoreAccountSettings.AllowUploadImagesToOrionMaps, 
  -- Manage Views  
  CoreAccountSettings.AllowCustomize, 
  -- Manage Dashboards  
  CoreAccountSettings.AllowManageDashboards, 
  
  -- ***** Reports *****
  -- Allow Report Management Rights  
  CoreAccountSettings.AllowReportManagement, 
  -- Report Limitation Category  
  CoreAccountSettings.ReportFolder, 
  
  -- ***** Alerts *****
  -- Allow Alert Management Rights  
  CoreAccountSettings.AllowAlertManagement, 
  -- Alert Limitation Category  
  CoreAccountSettings.AlertCategory, 
  -- Allow Account to Unmanage Objects & Mute Alerts  
  CoreAccountSettings.AllowUnmanage, 
  -- Allow Account to Disable Actions  
  CoreAccountSettings.AllowDisableAction, 
  -- Allow Account to Disable Alerts  
  CoreAccountSettings.AllowDisableAlert, 
  -- Allow Account to Disable All Actions  
  CoreAccountSettings.AllowDisableAllActions, 
  -- Allow Account to Clear/Acknowledge messages  
  CoreAccountSettings.CanClearEvents, 
  -- [TODO] Allow Browser Integration
  -- [TODO] Number of items in the breadcrumb list  
  case
  when WebUserSettings.settingname = 'Breadcrumb_NetOjectsCount' then SettingValue
  end as [Number of items in the breadcrumb list],
  
  -- ***** ACCOUNT LIMITATIONS *****
  CoreAccountSettings.LimitationID1, 
  CoreAccountSettings.LimitationID2, 
  CoreAccountSettings.LimitationID3, 
  
  -- ***** Default Menu Bar and Views *****
  -- HomeTab Menu Bar  
    --   CloudTab Menu Bar	
    --   VoIP & Network QualityTab Menu Bar	
    --   LOGSTab Menu Bar	
    --   NetworkTab Menu Bar	
    --   ApplicationsTab Menu Bar	
    --   Network ConfigurationTab Menu Bar	
    --   Server ConfigurationTab Menu Bar	
    --   WebTab Menu Bar	
    --   IP AddressesTab Menu Bar	
    --   StorageTab Menu Bar	
    --   NetflowTab Menu Bar	
    --   DatabasesTab Menu Bar	
    --   VirtualizationTab Menu Bar	
    --   Device TrackerTab Menu Bar	
    --   SecurityTab Menu Bar	
    --   ToolsetTab Menu Bar	

    --   Show Alerts Menu	
    case
    when UserWebView.WebViewID = 2 Then 'No'

    end as [Show Alerts Menu],

    --   Show Anomaly-Based Alerts Menu	
        case
    when UserWebView.WebViewID = 3 Then 'No'

    end as [Show Anomaly-Based Alerts Menu],

    --   Show Events Menu	
            case
    when UserWebView.WebViewID = 4 Then 'No'

    end as [Show Events Menu],

    --   Show Message Center Menu	
             case
    when UserWebView.WebViewID = 5 Then 'No'

    end as [Show Message Center Menu],

    --   Show Syslogs Menu	
    case
        when UserWebView.WebViewID = 12 Then 'No'

    end as [Show Syslogs Menu],

    --   Show Traps Menu	
        case
        when UserWebView.WebViewID = 13 Then 'No'

    end as [Show Traps Menu],

    --   Show AlertStack Menu	
            case
        when UserWebView.WebViewID = 14 Then 'No'

    end as [Show AlertStack Menu],

    --   Show All Reports Menu	
                case
        when UserWebView.WebViewID = 6 Then 'No'

    end as [Show All Reports Menu],
    --   Tabs ordering	

  --Home Page View
  Concat(
    viewsHomePageViewID.ViewGroupName, 
    ' - ', viewsHomePageViewID.ViewTitle
  ) as [Home Page View], 

    -- Default Network Device

  --Default Summary View
  Concat(
    viewssummaryViewID.ViewGroupName, 
    ' - ', viewssummaryViewID.ViewTitle
  ) as [Default Summary View] 

-- ***** Server & Application Monitor Settings *****
-- Application Summary View
-- Application Details View	
-- Component Details View	
-- SAM User Role	
-- Real-Time Process Explorer	
-- Service Control Manager	
-- Allow Service Actions Rights	
-- Real-Time Event Log Viewer	
-- Allow nodes to be rebooted	
-- Allow IIS Action Rights	
-- AppInsight for SQL Application View	
-- AppInsight for SQL Database View	
-- AppInsight for SQL Database File View	
-- AppInsight for SQL Statistic View	
-- AppInsight for SQL Job Info Details	
-- AppInsight for SQL Query Info Details	
-- AppInsight for Exchange Application View	
-- AppInsight for Exchange Database View	
-- AppInsight for Exchange Statistic View	
-- AppInsight for Exchange Mailbox View	
-- AppInsight for Exchange Database File View	
-- AppInsight for Exchange Database Copy Details	
-- AppInsight for Exchange Replication Status Details	
-- AppInsight for Exchange Mailbox Quota View	
-- Wstm BlackBox Application Details	
-- Wstm BlackBox Component Details	
-- Wstm BlackBox Task Info Details	
-- AppInsight for IIS Application View	
-- AppInsight for IIS Application Pool View	
-- AppInsight for IIS Site View	
-- AppInsight for IIS Statistic View	
-- AppInsight for Active Directory Application View	

FROM 
  Orion.Accounts as CoreAccountSettings 
  join Orion.Views as viewsHomePageViewID on viewsHomePageViewID.ViewID = CoreAccountSettings.HomePageViewID 
  join Orion.Views as viewssummaryViewID on viewssummaryViewID.ViewID = CoreAccountSettings.summaryViewID 
  join Orion.Web.UserWebView as UserWebView on UserWebView.AccountID = CoreAccountSettings.AccountID
    join Orion.WebUserSettings as WebUserSettings on WebUserSettings.AccountID = CoreAccountSettings.AccountID

where 
  CoreAccountSettings.accountid = 'test'
