-- /Orion/images/{0}.gif

SELECT 
  -- Account Details
  a.AccountID, 
  CASE WHEN a.Enabled = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Enabled],
  a.Expires AS [Account Expire Date],
  a.LastLogin AS [Last Login], 
  CASE 
    WHEN a.AccountType = 0 THEN 'System'
    WHEN a.AccountType = 1 THEN 'SolarWinds Platform'
    WHEN a.AccountType = 2 THEN 'Windows User'
    WHEN a.AccountType = 3 THEN 'Windows Group'
    WHEN a.AccountType = 4 THEN 'Windows Group Account'
    WHEN a.AccountType = 5 THEN 'SAML User'
    WHEN a.AccountType = 6 THEN 'SAML Group'
    ELSE 'Unknown'
  END AS [Account Type], 
  a.GroupInfo AS [Parent Group],
  a.PasswordExpirationDate AS [Password Expire Date],
  a.BadPwdCount AS [Bad Password Count], 

  -- Platform Rights
  CASE WHEN a.DisableSessionTimeout = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Disable Session Timeout], 
  CASE WHEN a.AllowAdmin = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Admin],
  CASE WHEN a.AllowNodeManagement = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Manage Nodes], 
  CASE WHEN a.AllowMapManagement = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Manage Atlas Maps], 
  CASE WHEN a.AllowOrionMapsManagement = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Manage Orion Maps], 
  CASE WHEN a.AllowUploadImagesToOrionMaps = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Upload Images To Orion Maps], 
  CASE WHEN a.AllowCustomize = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Manage Views], 
  CASE WHEN a.AllowManageDashboards = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Manage Dashboards], 
  
  -- Report Rights
  CASE WHEN a.AllowReportManagement = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Manage Reports], 
  a.ReportFolder AS [Report Limitation], 
  
  -- Alert Rights
  CASE WHEN a.AllowAlertManagement = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Manage Alerts], 
  a.AlertCategory AS [Alert Limitation], 
  CASE WHEN a.AllowUnmanage = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Unmanage Objects & Mute Alerts], 
  CASE WHEN a.AllowDisableAction = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Disable Alert Actions], 
  CASE WHEN a.AllowDisableAlert = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Disable Alerts], 
  CASE WHEN a.AllowDisableAllActions = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Disable All Alert Actions], 
  CASE WHEN a.CanClearEvents = 'Y' THEN 'Check.Green' ELSE 'Check.Lock' END AS [Clear & Acknowledge Alert Messages], 
  -- TODO: Allow Browser Integration
  MAX(CASE WHEN us.SettingName = 'Breadcrumb_NetOjectsCount' THEN us.SettingValue END) AS [Breadcrumb Count],

  -- Account Limitations
  case when a.LimitationID1 = 0 then NULL else a.LimitationID1 end AS [Account Limitation 1], 
  case when a.LimitationID2 = 0 then NULL else a.LimitationID2 end AS [Account Limitation 2], 
  case when a.LimitationID3 = 0 then NULL else a.LimitationID3 end AS [Account Limitation 3], 

  -- Default Menu Bar and Views
  a.MenuName AS [Home Menu]

-- CloudTab Menu Bar	
-- VoIP & Network QualityTab Menu Bar	
-- LOGSTab Menu Bar	
-- NetworkTab Menu Bar	
-- ApplicationsTab Menu Bar	
-- Network ConfigurationTab Menu Bar	
-- Server ConfigurationTab Menu Bar	
-- WebTab Menu Bar	
-- IP AddressesTab Menu Bar	
-- StorageTab Menu Bar	
-- NetflowTab Menu Bar	
-- DatabasesTab Menu Bar	
-- VirtualizationTab Menu Bar	
-- Device TrackerTab Menu Bar	
-- SecurityTab Menu Bar	
-- ToolsetTab Menu Bar	

-- Show Alerts Menu	
-- Show Anomaly-Based Alerts Menu	
-- Show Events Menu	
-- Show Message Center Menu	
-- Show Syslogs Menu	
-- Show Traps Menu	
-- Show AlertStack Menu	
-- Show All Reports Menu	

-- Home Page View	
-- Default Network Device
-- Default Summary View	

-- Server & Application Monitor Settings
-- Application Summary View	
-- Application Details View	
-- Component Details View	

-- SAM User Role	
-- User

-- Real-Time Process Explorer	
-- Do not allow

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
	
-- Cloud Monitoring Settings
-- Cloud Summary View	
	
-- Database Performance Analyzer Integration Module Settings
-- Databases Summary View	
-- DB Storage Summary View	
-- DPA Database Instance Details	
-- DPA Server Details	
	
-- Quality of Experience Settings
-- QoE Application Details View	
-- QoE Application Category Details View	
-- QoE Productivity Rating Details View	
-- QoE Risk Level Details View	
	
-- IP Address Manager Settings
-- IPAM Summary View	 
-- IPAM Address Details View	 
-- IPAM DHCP Server View	 

-- IPAM Roles & Permissions
-- Admin
-- Power User
-- Operator
-- Read Only
-- Hide
-- Custom
	
-- Network Configuration Manager Settings
-- NCM Role	
-- Administrator
-- Engineer
-- WebUploader
-- WebDownloader
-- WebViewer
-- None

-- NCM Summary View	
-- NCM Config Details View	
-- NCM Compliance Report View	
-- NCM Compliance Report Result View	
-- NCM EW Chart Details View	
-- NCM Find Connected Port for End Host Result View	
-- NCM Execute Config Change Template View	
-- NCM Config Change Templates View	
-- NCM Shared Config Change Templates on thwack View	
-- NCM Security Policy Details View	
	
-- General Settings
-- Node Details View	
-- Volume Details View	
-- Group Details View	
-- Active Alert Details View	
	
-- Network Performance Monitor Settings
-- VSAN Details View	
-- Multicast Group Details	
	
-- Log Manager for SolarWinds Platform Settings
-- Log Entry Details View	
	
-- Server Configuration Monitor Settings
-- SCM User Role	
-- Allow account to set a baseline	
-- Server Configuration Monitor Home View	
	
-- Security Settings
-- Security User Role	
-- Administrator
-- User
-- None
	
-- Web Performance Monitor Settings
-- WPM Summary View	
-- WPM Transaction Details View	
-- WPM Transaction Step Details View	
-- WPM Transaction Location Details View	
-- Allow Recordings Management rights	
	
-- Storage Resource Monitor Settings
-- Storage Resource Monitor Home View	
-- Provider Details View	
-- Array Details View	
-- Cluster Details View	
-- File Storage View	
-- Block Storage View	
-- LUN Details View	
-- Block Storage View	
-- File Storage View	
-- Performance Dashboard	
-- Capacity Dashboard	
-- Storage Main Console	
-- Storage Pool Details View	
-- NAS Volume Details View	
-- File Share Details View	
-- Vserver Details View	
-- Vserver File Storage Details View	
-- Vserver Block Storage Details View	
-- Controller Details View	
-- Storage Controller Port Details View	
	
-- Toolset Settings
-- This user doesn't have Toolset enabled.
	
-- NetFlow Traffic Analyzer Settings
-- NetFlow Traffic Analyzer View	
-- NetFlow Node Details	
-- NetFlow Application Details	
-- NetFlow Interface Details	
-- NetFlow Conversation	
-- NetFlow Country	
-- NetFlow Domain	
-- NetFlow Endpoint	
-- NetFlow IPAddressGroup	
-- NetFlow Protocol	
-- NetFlow Type of Service	
-- NetFlow CBQoS	
-- NetFlow Autonomous Systems	
-- NetFlow Autonomous System Conversations	
-- NetFlow NBAR2 Application Details	
	
-- User Device Tracker Settings
-- User Device Tracker	
-- Device Tracker Port Details View	
-- Device Tracker User Details View	
-- Device Tracker Endpoint Details View	
-- Device Tracker Access Point Details View	
-- Device Tracker SSID Details View	
	
-- Virtualization Manager Settings
-- Integrated Virtualization Manager Summary View	
-- Virtualization Manager Summary View	
-- Virtualization Manager VMware Summary View	
-- Virtualization Manager Hyper-V Summary View	
-- Virtualization Manager Nutanix Summary View	
-- Host Details View	
-- Virtual Machine Details View	
-- Cluster Details View	
-- Datacenter Details View	
-- Datastore Details View	
-- Virtualization Manager Storage Summary View	
-- Virtualization Manager Sprawl View	

-- Virtual Machine Power Management	
-- Snapshot Management	
-- Resources Settings Management	
-- Delete virtual machines and datastore files	
-- Migration Management	
	
-- VoIP and Network Quality Manager Settings
-- VoIP Call Path View	
-- VoIP Site View	
-- VoIP Summary View	
-- Network Service Assurance Operations Summary View	
-- Top XX Network Service Assurance Operations	
-- Network Service Assurance Web Summary	
-- VoIP CallManager View	
-- SIP Trunk Details	
-- VoIP Gateway SIP Trunk Details	
-- Network Service Assurance Operation Details View	
-- VoIP CallManager Gateway	
-- Location View	
-- VoIP Phone Details	
-- VoIP Call Details	
-- VoIP Gateway View	
	
-- F5 Settings
-- F5 Server Detail	
-- F5 LTM Detail	
-- F5 Virtual Server Detail	
-- F5 Pool Detail	
-- F5 Pool Member Details	
-- F5 GTM Detail	
-- F5 Service	
	
-- Hardware Health Package Settings
-- Temperature Unit	
	
-- Hardware Health Baseboard Management Controller Settings
-- Chassis Details View	
	
-- Network Interface Settings
-- Interface Details View	
	
-- Performance Analysis Settings
-- Allow Real-Time Polling	
	
-- Power Control Unit Settings
-- Temperature unit	
	
-- Recommendations Settings
-- Allow Recommendations	
	
-- SSH Settings
-- SSH Access	
	
-- Cloud Monitoring per Provider Settings
-- AWS Cloud Instance Details View	
-- Azure Cloud VM Details View	
-- GCP Cloud Instance Details View	
	
-- Wireless Settings
-- Wireless Thin AP View	
	
-- Wireless Heat Map Settings
-- Wireless Heat Map	

FROM 
  Orion.Accounts AS a

LEFT JOIN Orion.UserSettings AS us ON us.AccountID = a.AccountID

WHERE a.AccountID = 'Admin'

GROUP BY 
  a.AccountID, a.Enabled, a.Expires, a.LastLogin, a.AccountType, a.GroupInfo, 
  a.PasswordExpirationDate, a.BadPwdCount, a.DisableSessionTimeout,
  a.AllowAdmin, a.AllowNodeManagement, a.AllowMapManagement, a.AllowOrionMapsManagement,
  a.AllowUploadImagesToOrionMaps, a.AllowCustomize, a.AllowManageDashboards,
  a.AllowReportManagement, a.ReportFolder, a.AllowAlertManagement, a.AlertCategory,
  a.AllowUnmanage, a.AllowDisableAction, a.AllowDisableAlert, a.AllowDisableAllActions,
  a.CanClearEvents, a.LimitationID1, a.LimitationID2, a.LimitationID3, a.MenuName

