--SET ANSI_WARNINGS ON
-- UPDATED 8/21/2022
-- Replace 'EngOrionLog' with client LA database
DECLARE @LAdb nvarchar(max)
set @LAdb = 'SolarWindsOrionLog'

DECLARE @OrionServers nvarchar(max)
DECLARE @OrionPolling nvarchar(max)
DECLARE @OrionCore nvarchar(max)
DECLARE @Query nvarchar(max)

DECLARE @isNPM nvarchar(max)
DECLARE @NPM nvarchar(max)
DECLARE @isSAM nvarchar(max)
DECLARE @SAM nvarchar(max)
DECLARE @isNCM nvarchar(max)
DECLARE @NCM nvarchar(max)
DECLARE @isUDT nvarchar(max)
DECLARE @UDT nvarchar(max)
DECLARE @isVNQM nvarchar(max)
DECLARE @VNQM nvarchar(max)
DECLARE @isVMAN nvarchar(max)
DECLARE @VMAN nvarchar(max)
DECLARE @isLA nvarchar(max)
DECLARE @LA nvarchar(max)
DECLARE @isNTA nvarchar(max)
DECLARE @NTA nvarchar(max)
DECLARE @isSRM nvarchar(max)
DECLARE @SRM nvarchar(max)
DECLARE @isIPAM nvarchar(max)
DECLARE @IPAM nvarchar(max)
DECLARE @isWPM nvarchar(max)
DECLARE @WPM nvarchar(max)
DECLARE @isSCM nvarchar(max)
DECLARE @SCM nvarchar(max)


-- Completed
SET @isNPM  = (SELECT case when ProductName='NPM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='NPM')
SET @isSAM  = (SELECT case when ProductName='SAM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='SAM')
SET @isNCM  = (SELECT case when ProductName='NCM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='NCM')
SET @isIPAM = (SELECT case when ProductName='IPAM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='IPAM')
SET @isUDT  = (SELECT case when ProductName='UDT' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='UDT')
SET @isVNQM = (SELECT case when ProductName='VNQM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='VNQM')
SET @isWPM =  (SELECT case when ProductName='WPM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='WPM')
SET @isNTA  = (SELECT case when ProductName='Orion NetFlow Traffic Analyzer' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='Orion NetFlow Traffic Analyzer')
SET @isVMAN = (SELECT case when ProductName='VM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='VM')
SET @isLA   = (SELECT case when ProductName='LM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='LM')
SET @isSCM  = (SELECT case when ProductName='SCM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='SCM')
SET @isSRM  = (SELECT case when ProductName='STM' then 'Installed' else 'NotInstalled' end from Licensing_LicenseAssignments where ProductName='STM')


--********************************************************************************
--  ORION SERVERS - start
--********************************************************************************
SET @OrionServers='
select '' ''  as [Description], '' ''  as [Value]
union all select ''*************************'' ,''*************************''
union all select ''*** A - ORION SERVERS ***'' ,''*** A - ORION SERVERS ***''
union all select ''*************************'' ,''*************************''

union all select '''',''''
union all select ''=== MODULES ==='',''''
Union all select b.c ,b.v  from (
(select top 1000 a.c as [c] ,version as [v] from
(select top 1000 concat(Hostname,'' ('',ServerType,'')'') as [c]
,concat(Acronym,'' (''
,CASE WHEN HotFix IS NULL THEN [ReleaseVersion]
      ELSE [ReleaseVersion] + '' HF'' + [HotFix] END,'')'') AS [Version]
,[Acronym] as Acronym ,OrionServerID ,ServerType
FROM [OrionServers] with (nolock)
CROSS APPLY OPENJSON([Details]) WITH ([Product] VARCHAR(50) ''$.Name'', [Acronym] VARCHAR(5) ''$.ShortName''
      ,[ReleaseVersion] VARCHAR(25) ''$.Version'', [Hotfix] VARCHAR(5) ''$.HotfixVersionNumber'') AS VersionInfo
-- Remove ''features'' that are erroneously listed as a ''product''
WHERE [Product] NOT IN (''Cloud Monitoring'', ''Quality of Experience'', ''NetPath'')
ORDER BY (case when servertype=''MainPoller'' then 1 else 2 end)
) a
join Licensing_LicenseAssignments ls on ls.orionserverid=a.orionserverid
where Acronym in (select productname from Licensing_LicenseAssignments)
group by a.c, version, servertype
order by (case when servertype=''MainPoller'' then 1 else 2 end)
)) b


union all select ''=== POLLER SERVERS ==='',''''
union all select cast(Servername as varchar(50)), cast(Value as varchar(50))
FROM (
      select concat(e.servername,'''') as [Servername]
	        ,convert(sql_variant, concat(''ServerType: '',e.servertype,'''')) as [ServerType]
			,convert(sql_variant, concat(e.IP,'''')) as [IP]
	        ,convert(sql_variant, concat(e.WindowsVersion,'''')) as [MachineType]
	        ,convert(sql_variant, concat(''Last Boot: ''   ,(select cast(n.lastboot as varchar) from nodes n where n.IP_Address=e.IP and n.CPUCount>0))) as [LastBoot]
            ,convert(sql_variant, concat(''CPU: '' , (select concat(n.CPUCount,''  ('',n.CPULoad,''% used)'') FROM nodes n where n.IP_Address=e.ip and n.CPUCount>0))) as [CPU]
	        ,convert(sql_variant, concat(''MEM: '' , (select concat(round(TotalMemory/1024/1024/1024,2), '' GB  ('',PercentMemoryUsed,''% used)'') from nodes n where n.IP_Address=e.ip and n.CPUCount>0)))  as [Mem]
			,convert(sql_variant, (select top 1 concat(substring(v.caption,1,3),'' '',round(v.VolumeSize/1024/1024/1024,0),'' GB ('',round(v.VolumePercentUsed,0),''% used)'') from nodes n join volumes v on v.nodeid=n.nodeid where n.ip_address=e.IP and v.VolumeTypeID=4)) as [Drive1]
			,convert(sql_variant, case when (select count(v.Caption) from nodes n join volumes v on v.nodeid=n.nodeid where n.ip_address=e.IP and v.VolumeTypeID=4)>1 
			                           then (select concat(substring(v.caption,1,3),'' '',round(v.VolumeSize/1024/1024/1024,0),'' GB ('',round(v.VolumePercentUsed,0),''% used)'') from nodes n join volumes v on v.nodeid=n.nodeid and v.VolumeTypeID=4 where n.ip_address=e.IP and v.VolumeTypeID=4 order by 1 offset 1 rows fetch next 1 rows only ) 
                                       else ''No Additional Drive''
									   end)
									   as [Drive2]
			,convert(sql_variant, '' '') as [Blank]
      from engines e with (nolock)
      ) as t
unpivot
   ( value for val in (servertype, IP,  MachineType, LastBoot, CPU, mem, Drive1, Drive2, Blank)
) as unpiv

--union all select ''=== POLLER VOLUMES ===='',''''
--union all (select e.servername ,concat(v.Caption,''  -  '',round(v.VolumeSize/1024/1024/1024,0),'' GB ('',round(v.VolumePercentUsed,0),'' % used)'') as [x]
--           from engines e with (nolock) join nodes n with (nolock) on n.IP_Address=e.IP join volumes v on v.NodeID=n.nodeid where v.VolumeSize >0 and v.VolumeType like ''Fixed%'')

union all select ''=== WEB SERVERS ==='',''''
union all select cast(Servername as varchar(50)), cast(Value as varchar(50))
FROM (
      select concat(w.servername,'''') as [Servername]
	        ,convert(sql_variant, concat(''AWE'','''')) as [ServerType]
			,convert(sql_variant, concat(n.ip_address,'''')) as [IP]
	        ,convert(sql_variant, concat(n.MachineType,'''')) as [MachineType]
	        ,convert(sql_variant, concat(''Last Boot: '',cast(n.LastBoot as varchar))) as [LastBoot]
            ,convert(sql_variant, concat(''CPU: '' , n.CPUCount,''  ('',n.CPULoad,''% used)'')) as [CPU]
	        ,convert(sql_variant, concat(''MEM: '' , concat(round(TotalMemory/1024/1024/1024,2), '' GB  ('',PercentMemoryUsed,''% used)'')))  as [Mem]
			,convert(sql_variant, (select top 1 concat(substring(v.caption,1,3),'' '',round(v.VolumeSize/1024/1024/1024,0),'' GB ('',round(v.VolumePercentUsed,0),''% used)'') from nodes n join volumes v on v.nodeid=n.nodeid where n.caption=w.ServerName and v.VolumeTypeID=4)) as [Drive1]
			,convert(sql_variant, case when (select count(v.Caption) from nodes n join volumes v on v.nodeid=n.nodeid where n.caption=w.ServerName and v.VolumeTypeID=4)>1 
			                           then (select concat(substring(v.caption,1,3),'' '',round(v.VolumeSize/1024/1024/1024,0),'' GB ('',round(v.VolumePercentUsed,0),''% used)'') from nodes n join volumes v on v.nodeid=n.nodeid and v.VolumeTypeID=4 where n.caption=w.ServerName and v.VolumeTypeID=4 order by 1 offset 1 rows fetch next 1 rows only ) 
                                       else ''No Additional Drive''
									   end)
									   as [Drive2]
			,convert(sql_variant, '' '') as [Blank]
      from websites w with (nolock)
	  left join nodes n on n.caption=w.servername
      ) as t
unpivot
   ( value for val in (servertype, IP,  MachineType, LastBoot, CPU, mem, Drive1, Drive2)
) as unpiv

--union all select ''=== WEB VOLUMES ===='',''''
--union all select n.caption,concat(v.Caption,''  -  '',round(v.VolumeSize/1024/1024/1024,0),'' GB ('',round(v.VolumePercentUsed,0),'' % used)'') as [x]
--from websites w  
--join nodes n on n.caption=w.servername 
--join volumes v on v.NodeID=n.nodeid 
--where v.VolumeSize >0 and v.VolumeType like ''Fixed%''

union all select '''',''''
union all select ''=== SQL ==='','' ''
union all select ''SQL Server'', case when charindex(''\'',srvname)>1 then substring(srvname,1,charindex(''\'',srvname)-1) else  srvname end from sysservers with (nolock)
union all SELECT ''IP Address'',(select local_net_address FROM sys.dm_exec_connections  WHERE session_id = @@SPID)
union all select ''OS version'', MachineType COLLATE Latin1_General_CI_AS from nodes with (nolock) where caption = (select case when charindex(''\'',srvname)>1 then substring(srvname,1,charindex(''\'',srvname)-1) else srvname COLLATE Latin1_General_CI_AS end from sysservers)
union all select ''SQL version'', (select @@version) 
union all select ''Instance'', case when charindex(''\'',srvname)>0 then substring(srvname, charindex(''\'',srvname)+1,99) else concat(srvname,''(MSSQLSERVER)'') end from sysservers
union all select ''CPU'', concat(CPUCount,''  (load: '',CPULoad,''%)'') from nodes where caption = (select case when charindex(''\'',srvname)>1 then substring(srvname,1,charindex(''\'',srvname)-1) else  srvname end from sysservers with (nolock) )
union all select ''MEM'', concat(round(TotalMemory/1024/1024/1024,2), '' GB  ('',PercentMemoryUsed,''% used)'')  from nodes where caption = (select case when charindex(''\'',srvname)>1 then substring(srvname,1,charindex(''\'',srvname)-1) else  srvname end from sysservers with (nolock) )
union all SELECT replace(replace(v.volumedescription,substring(v.VolumeDescription,charindex(''Serial Number'',v.VolumeDescription),99),''''),''Label:'','''') as [c] 
,concat(round(v.VolumeSize/1000/1000/1000,0),'' GB ('',round(v.VolumePercentUsed,0),''% used)'') as [v]
            FROM nodes n with (nolock) join Volumes v with (nolock) on v.nodeid=n.NodeID and v.VolumeType like ''Fixed%''
            where n.caption=(select case when charindex(''\'',srvname)>1 then substring(srvname,1,charindex(''\'',srvname)-1) else srvname end from sysservers with (nolock) )

union all SELECT ''Username'', SYSTEM_USER
union all select ''Catalog'', DB_NAME(db_id())
union all SELECT ''Database Size'', CONCAT(CAST(round(SUM(CAST( (size * 8.0/1024) AS DECIMAL(15,2))),0) AS VARCHAR(20)),'' MB'') AS [database_size] FROM sys.database_files with (nolock)
union all select ''Last Boot'', concat(lastboot,'''') from nodes where caption = (select case when charindex(''\'',srvname)>1 then substring(srvname,1,charindex(''\'',srvname)-1) else  srvname end from sysservers with (nolock) )

union all SELECT ''Max Server Memory (MB)'', concat(convert(varchar(10),value),'''') as [v] FROM sys.configurations cf WHERE cf.name = ''max server memory (MB)''
union all SELECT ''Cost Threshold for Parallelism'', case when value_in_use<>50 then concat(convert(varchar(10),value_in_use),'' <50'') else concat(convert(varchar(10),value_in_use),'''') end as [v] FROM sys.configurations cf WHERE cf.name = ''cost threshold for parallelism''

union all SELECT ''Max Degree of Parallelism'', case when (SELECT case when (SELECT CAST(SERVERPROPERTY(''EngineEdition'') AS INT))=4 then (SELECT cpu_count FROM sys.dm_os_sys_info) else (SELECT cpu_count FROM sys.dm_os_sys_info)/(COUNT(mn.memory_node_id)-1) end 
      FROM  sys.dm_os_memory_nodes mn)<>value_in_use then 
	  concat(convert(varchar(10),value_in_use),'' <'',(SELECT case when (SELECT CAST(SERVERPROPERTY(''EngineEdition'') AS INT))=4 then (SELECT cpu_count FROM sys.dm_os_sys_info) else (SELECT cpu_count FROM sys.dm_os_sys_info)/(COUNT(mn.memory_node_id)-1) end 
      FROM  sys.dm_os_memory_nodes mn))
	  else concat(convert(varchar(10),value_in_use),'''') end
	  as [v]  
FROM sys.configurations cf  WHERE cf.name = ''max degree of parallelism''
union all SELECT ''Optimize for Ad Hoc Workloads'', case when value_in_use <>1 then concat(convert(varchar(10),value_in_use),'' <1'') else concat(convert(varchar(10),value_in_use),'''') end as [v] FROM sys.configurations cf WHERE cf.name = ''optimize for ad hoc workloads''
union all SELECT ''Query Optimizer Hotfixes'', case when value <>1 then concat(convert(varchar(10),value),'' <1'') else concat(convert(varchar(10),value),'''') end as [v]  FROM sys.database_scoped_configurations dsc WHERE dsc.[name] = ''QUERY_OPTIMIZER_HOTFIXES''


union all SELECT ''recom_tempdb_file_cnt'', concat(case when (SELECT CAST(SERVERPROPERTY(''EngineEdition'') AS INT))=4 then (SELECT cpu_count FROM sys.dm_os_sys_info) else (SELECT cpu_count FROM sys.dm_os_sys_info)/(COUNT(mn.memory_node_id)-1) end,'' '') 
      FROM  sys.dm_os_memory_nodes mn

union all SELECT ''Tempdb Data File Size'', concat(MAX(mf.size)/128,'''') FROM sys.master_files mf WHERE mf.database_id=2 AND mf.type=0
union all SELECT ''Tempdb data file autogrowth'', concat(MAX(mf.growth)/128,'''') FROM sys.master_files mf WHERE mf.database_id=2 AND mf.type=0
union all SELECT ''Tempdb data file count'', concat(COUNT(mf.name),'''') FROM sys.master_files mf WHERE mf.database_id=2 AND mf.type=0

union all select ''=== Top 5 Tables (rows) ==='', ''''
Union all
select 
  pass1.*
from (
      SELECT top 5 
	    t.NAME as [Table]
		--,concat(p.rows,'' rows'') as [Rows1]
		--,case when p.rows < 10000000  then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', ''''),'''')
		--      when p.rows >= 10000000 then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', '' < 10k+''), '''')
		--	end	 as [Rows] 
		,case when p.rows < 10000000  then concat(cast(round(p.rows/1000000.0,2) as decimal(8,2)), '' Mrows'')
		      when p.rows >= 10000000 then concat(cast(round(p.rows/1000000.0,2) as decimal(8,2)), '' Mrows'', '' < 10k+'')
			end	 as [Rows] 
      FROM  sys.tables t with (nolock) 
      INNER JOIN sys.indexes i with (nolock)  ON t.OBJECT_ID = i.object_id
      INNER JOIN sys.partitions p with (nolock)  ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
      INNER JOIN sys.allocation_units a with (nolock)  ON p.partition_id = a.container_id
      WHERE  t.NAME NOT LIKE ''dt%'' AND t.is_ms_shipped = 0 AND i.OBJECT_ID > 255  and p.rows > 100000
      GROUP BY  p.Rows, t.Name 
	  order by p.Rows desc
	 ) as pass1

union all select ''=== Top TABLES BY FUNCTION (GB) ==='', ''''

union all 
(
select 
  --name as [Table],rows as [Rows], sum(total_pages)*8 as [Reserved], sum(used_pages)*8 as [Used]
  ''UDT'',   concat(cast(round(sum(rows)/1000000.0,2) as decimal(8,2)), '' GB ('',cast(round(sum(rows)/1000000.0,2) as decimal(8,2)),'' Mrows)'') as [Reserved]
from (
      SELECT top 50 
	    t.NAME, p.rows, a.total_pages, a.used_pages
		--,case when p.rows < 10000000  then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', ''''),'''')
		--      when p.rows >= 10000000 then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', '' < 10k+''), '''')
		--	end	 as [Rows] 
      FROM  sys.tables t with (nolock) 
      INNER JOIN sys.indexes i with (nolock)  ON t.OBJECT_ID = i.object_id
      INNER JOIN sys.partitions p with (nolock)  ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
      INNER JOIN sys.allocation_units a with (nolock)  ON p.partition_id = a.container_id
      WHERE  t.NAME NOT LIKE ''dt%'' AND t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 -- and p.rows > 100000
	  AND t.name like ''UDT%''
      GROUP BY  p.Rows, t.Name, a.total_pages, a.used_pages
	  order by p.Rows desc
	 ) as pass1
--	 group by rows
	 --order by [reserved] desc
)


union all 
(
select 
  --name as [Table],rows as [Rows], sum(total_pages)*8 as [Reserved], sum(used_pages)*8 as [Used]
  ''Interfaces'',   concat(cast(round(sum(rows)/1000000.0,2) as decimal(8,2)), '' GB ('',cast(round(sum(rows)/1000000.0,2) as decimal(8,2)),'' Mrows)'') as [Reserved]
from (
      SELECT top 50 
	    t.NAME, p.rows, a.total_pages, a.used_pages
		--,case when p.rows < 10000000  then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', ''''),'''')
		--      when p.rows >= 10000000 then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', '' < 10k+''), '''')
		--	end	 as [Rows] 
      FROM  sys.tables t with (nolock) 
      INNER JOIN sys.indexes i with (nolock)  ON t.OBJECT_ID = i.object_id
      INNER JOIN sys.partitions p with (nolock)  ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
      INNER JOIN sys.allocation_units a with (nolock)  ON p.partition_id = a.container_id
      WHERE  t.NAME NOT LIKE ''dt%'' AND t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 -- and p.rows > 100000
	  AND t.name like ''Interface%''
      GROUP BY  p.Rows, t.Name, a.total_pages, a.used_pages
	  order by p.Rows desc
	 ) as pass1
--	 group by rows
	 --order by [reserved] desc
)
union all 
(
select 
  --name as [Table],rows as [Rows], sum(total_pages)*8 as [Reserved], sum(used_pages)*8 as [Used]
  ''syslog(legacy)'',   concat(cast(round(sum(rows)/1000000.0,2) as decimal(8,2)), '' GB ('',cast(round(sum(rows)/1000000.0,2) as decimal(8,2)),'' Mrows)'') as [Reserved]
from (
      SELECT top 50 
	    t.NAME, p.rows, a.total_pages, a.used_pages
		--,case when p.rows < 10000000  then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', ''''),'''')
		--      when p.rows >= 10000000 then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', '' < 10k+''), '''')
		--	end	 as [Rows] 
      FROM  sys.tables t with (nolock) 
      INNER JOIN sys.indexes i with (nolock)  ON t.OBJECT_ID = i.object_id
      INNER JOIN sys.partitions p with (nolock)  ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
      INNER JOIN sys.allocation_units a with (nolock)  ON p.partition_id = a.container_id
      WHERE  t.NAME NOT LIKE ''dt%'' AND t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 -- and p.rows > 100000
	  AND t.name like ''syslog%''
      GROUP BY  p.Rows, t.Name, a.total_pages, a.used_pages
	  order by p.Rows desc
	 ) as pass1
--	 group by rows
	 --order by [reserved] desc
)
union all 
(
select 
  --name as [Table],rows as [Rows], sum(total_pages)*8 as [Reserved], sum(used_pages)*8 as [Used]
  ''traps(legacy)'',   concat(cast(round(sum(rows)/1000000.0,2) as decimal(8,2)), '' GB ('',cast(round(sum(rows)/1000000.0,2) as decimal(8,2)),'' Mrows)'') as [Reserved]
from (
      SELECT top 50 
	    t.NAME, p.rows, a.total_pages, a.used_pages
		--,case when p.rows < 10000000  then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', ''''),'''')
		--      when p.rows >= 10000000 then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', '' < 10k+''), '''')
		--	end	 as [Rows] 
      FROM  sys.tables t with (nolock) 
      INNER JOIN sys.indexes i with (nolock)  ON t.OBJECT_ID = i.object_id
      INNER JOIN sys.partitions p with (nolock)  ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
      INNER JOIN sys.allocation_units a with (nolock)  ON p.partition_id = a.container_id
      WHERE  t.NAME NOT LIKE ''dt%'' AND t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 -- and p.rows > 100000
	  AND t.name like ''trap%''
      GROUP BY  p.Rows, t.Name, a.total_pages, a.used_pages
	  order by p.Rows desc
	 ) as pass1
--	 group by rows
	 --order by [reserved] desc
)
union all 
(
select 
  --name as [Table],rows as [Rows], sum(total_pages)*8 as [Reserved], sum(used_pages)*8 as [Used]
  ''CustomPoller'',   concat(cast(round(sum(rows)/1000000.0,2) as decimal(8,2)), '' GB ('',cast(round(sum(rows)/1000000.0,2) as decimal(8,2)),'' Mrows)'') as [Reserved]
from (
      SELECT top 50 
	    t.NAME, p.rows, a.total_pages, a.used_pages
		--,case when p.rows < 10000000  then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', ''''),'''')
		--      when p.rows >= 10000000 then concat(REPLACE(CONVERT(varchar(20), (CAST(p.rows AS money)), 1), ''.00'', '' < 10k+''), '''')
		--	end	 as [Rows] 
      FROM  sys.tables t with (nolock) 
      INNER JOIN sys.indexes i with (nolock)  ON t.OBJECT_ID = i.object_id
      INNER JOIN sys.partitions p with (nolock)  ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
      INNER JOIN sys.allocation_units a with (nolock)  ON p.partition_id = a.container_id
      WHERE  t.NAME NOT LIKE ''dt%'' AND t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 -- and p.rows > 100000
	  AND t.name like ''CustomPoller%''
      GROUP BY  p.Rows, t.Name, a.total_pages, a.used_pages
	  order by p.Rows desc
	 ) as pass1
--	 group by rows
	 --order by [reserved] desc
)




'

--********************************************************************************
--  ORION POLLING - Start
--********************************************************************************
SET @OrionPolling=
'
union all select '''',''''
union all select '''',''''
union all select ''*************************'' ,''*************************''
union all select ''*** B - ORION POLLING ***'' ,''*** B - ORION POLLING ***''
union all select ''*************************'' ,''*************************''
union all select '''',''''
union all select ''=== POLLER ELEMENTS ==='',''''
union all 
select Servername, Value
FROM (
      select concat(e.servername,'''') as [Servername]
	        ,convert(sql_variant, concat((select top 1 substring(Statusled,1,CHARINDEX(''.'',statusled)-1) from nodes where ip_address = e.ip),'' - status'')) as [Status]
			,convert(sql_variant, concat(e.servertype,'''')) as [ServerType]
			,convert(sql_variant, concat(e.IP,'''')) as [IP]
	        ,convert(sql_variant, concat(e.WindowsVersion,'''')) as [Server]
	        ,convert(sql_variant, concat(''Keepalive '',e.KeepAlive,'''')) as [KeepAlive]
            ,convert(sql_variant, concat(e.elements,'' (e)'')) as [Elements]
	        ,convert(sql_variant, concat(e.nodes,'' (n)''))  as [Nodes]
			,convert(sql_variant, concat(e.Interfaces,'' (i)''))  as [Interfaces]
			,convert(sql_variant, concat(e.volumes,'' (v)''))  as [Volumes]
			,convert(sql_variant, concat((SELECT isNULL(count(*),0) as [v] FROM AgentManagement_Agents a where e.engineid=a.pollingengineid),'' (a)''))  as [Agents]
			,convert(sql_variant, concat(e.PollingCompletion,''% Polling completion''))  as [Polling]
			,convert(sql_variant, concat((select ISNULL(ep.PropertyValue,0) as [x] from Engines ee join EngineProperties ep on ep.EngineID=e.EngineID where ep.PropertyName=''Orion.Standard.Polling'' and ee.engineid=e.engineid),''% NPM Polling Rate'')) as [NPMpolling]
			,convert(sql_variant, concat((select ISNULL(ep.PropertyValue,0) as [x] from Engines ee join EngineProperties ep on ep.EngineID=e.EngineID where ep.PropertyName=''APM.Components.Polling'' and ee.engineid=e.engineid),''% SAM Polling Rate'')) as [SAMpolling]
			,convert(sql_variant, concat((select ISNULL(ep.PropertyValue,0) as [x] from Engines ee join EngineProperties ep on ep.EngineID=e.EngineID where ep.PropertyName=''HardwareHealth.Polling'' and ee.engineid=e.engineid),''% Hardware Polling Rate'')) as [Hardpolling]
			,convert(sql_variant, ''Cycle(avg) - RUN SolarWinds.Diagnostics.DBResponse.exe'') as [B1]
			,convert(sql_variant, ''Connection(avg) - RUN SolarWinds.Diagnostics.DBResponse.exe'') as [B2]
			,convert(sql_variant, ''CloseWait - RUN powerShell script'') as [B3]
			,convert(sql_variant, ''TimeWait - RUN powerShell script'') as [B4]
			,convert(sql_variant, ''DCOM Errors - RUN powerShell script'') as [B5]
			,convert(sql_variant, '' '') as [B6]
      from engines e with (nolock)
      ) as t
unpivot
   ( value for val in ([status], servertype, ip, Server, Keepalive, elements, nodes, interfaces, Volumes, agents, polling, NPMpolling, SAMpolling, HardPolling, B1, B2, B3, B4, B5, B6)
 ) as unpiv




union all (select '''', ''''  )
union all (select ''== POLLING INTERVAL =='', ''''  )
union all (select ''Node Polling'', case when currentvalue<> 120 then concat(CurrentValue,'' '',Units,'' <120'') else concat(CurrentValue,'' '',Units) end from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Default Node Poll Interval'' group by currentvalue, units )
union all (select ''Interface Polling'', case when currentvalue<>120 then concat(CurrentValue,'' '',Units,'' <120'') else concat(CurrentValue,'' '',Units) end from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Default Interface Poll Interval''  group by currentvalue, units )
union all (select ''Volume Polling'', case when currentvalue<>120 then concat(CurrentValue,'' '',Units,'' <120'') else concat(CurrentValue,'' '',Units) end from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Default Volume Poll Interval''  group by currentvalue, units )
union all (select ''Rediscovery Interval'', case when currentvalue<>30 then concat(CurrentValue,'' '',Units,'' <30'') else concat(CurrentValue,'' '',Units) end from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Default Rediscovery Interval''  group by currentvalue, units )

union all (select ''== POLLING STATISTICS INTERVAL =='', ''''  )
union all (select ''Node'', concat(CurrentValue,'' '',Units,case when CurrentValue<>defaultvalue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Default Node Stat Poll Interval''  group by currentvalue, units,defaultvalue )
union all (select ''Interface'', concat(CurrentValue,'' '',Units,case when CurrentValue<>defaultvalue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Default Interface Stat Poll Interval''  group by currentvalue, units,defaultvalue )
union all (select ''Volume'', concat(CurrentValue,'' '',Units,case when CurrentValue<>defaultvalue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Default Volume Stat Poll Interval''  group by currentvalue, units,defaultvalue )
union all (select ''Topology'', concat(CurrentValue,'' '',Units,case when CurrentValue<>defaultvalue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Default Node Topology Poll Interval''  group by currentvalue, units,defaultvalue )

union all (select ''=== NODE STATUS CALCULATION ==='',''''  )
union all (select ''Node Status'', (case when CurrentValue=1 then ''Enhanced  <be careful'' else ''Classic'' end) from Settings with (nolock) where settingid = ''EnhancedNodeStatusCalculation''  group by currentvalue, units )

union all (select ''=== DATABASE SETTINGS  ==='',''''  )
union all (select ''Node Detailed'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Retain Detail'' group by currentvalue, units, DefaultValue )
union all (select ''Node Hourly'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock)  where settingid = ''SWNetPerfMon-Settings-Retain Hourly''  group by currentvalue, units, DefaultValue )
union all (select ''Node Daily'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Retain Daily''  group by currentvalue, units, DefaultValue )
union all (select ''------'',''------''  )

union all (select ''Container Detailed'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Retain Container Detail'' group by currentvalue, units, DefaultValue )
union all (select ''Container Hourly'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Retain Container Hourly'' group by currentvalue, units, DefaultValue )
union all (select ''Container Daily'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue) else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Retain Container Daily'' group by currentvalue, units, DefaultValue )
union all (select ''------'',''------''  )

union all (select ''Interface Detailed'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''NPM_Settings_InterfaceAvailability_Retain_Detail'' group by currentvalue, units, DefaultValue )
union all (select ''Interface Hourly'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''NPM_Settings_InterfaceAvailability_Retain_Hourly'' group by currentvalue, units, DefaultValue )
union all (select ''Interface Daily'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''NPM_Settings_InterfaceAvailability_Retain_Daily'' group by currentvalue, units, DefaultValue )
union all (select ''Delete Stale Interface'', (case when CurrentValue=1 then ''YES <NO)'' else ''No'' end) from Settings with (nolock) where settingid = ''NPM_Settings_StaleInterfaces_RemovalEnabled'' group by currentvalue, units )
union all (select ''Delete Interface After'', concat(CurrentValue,'' '',Units) from Settings with (nolock) where settingid = ''NPM_Settings_StaleInterfaces_RemovalIntervalDays'' group by currentvalue, units )
union all (select ''Delete Stale Volumes'', (case when CurrentValue=1 then ''YES <NO'' else ''No'' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-StaleVolume-RemovalEnabled'' group by currentvalue, units )
union all (select ''Delete Volumes After'', concat(CurrentValue,'' '',Units) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-StaleVolume-RemovalIntervalDays'' group by currentvalue, units )
union all (select ''------'',''------''  )

union all (select ''UnDP Detailed'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''NPM_Settings_UnDP_Retain_Detail'' group by currentvalue, units, DefaultValue )
union all (select ''UnDP Hourly'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''NPM_Settings_UnDP_Retain_Hourly'' group by currentvalue, units, DefaultValue )
union all (select ''UnDP Daily'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''NPM_Settings_UnDP_Retain_Daily'' group by currentvalue, units, DefaultValue )
union all (select ''------'',''------''  )

union all (select ''Wireless Detailed'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''NPM_Settings_Wireless_Retain_Detail'' group by currentvalue, units, DefaultValue )
union all (select ''Wireless Hourly'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''NPM_Settings_Wireless_Retain_Hourly'' group by currentvalue, units, DefaultValue )
union all (select ''Wireless Daily'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''NPM_Settings_Wireless_Retain_Daily'' group by currentvalue, units, DefaultValue )
union all (select ''Disappeared AP Rention'',concat(CurrentValue,'' days'') from settings where settingid= ''NPM_Settings_Wireless_Retain_Disappeared_AccessPoints'')
union all (select ''------'',''------''  )


union all (select ''Events Retention'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Retain Events'' group by currentvalue, units, DefaultValue )
union all (select ''Auditing Trail'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Retain Auditing Trails'' group by currentvalue, units, DefaultValue )
union all (select ''Syslog'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''SysLog-MaxMessageAge'' group by currentvalue, units, DefaultValue )
union all (select ''Traps'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''Trap-MaxMessageAge'' group by currentvalue, units, DefaultValue )
union all (select ''Baseline'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Baseline Collection Duration'' group by currentvalue, units, DefaultValue )
union all (select ''Node Warning Level'', concat(CurrentValue,'' '',Units,case when CurrentValue<>120 then '' <120)'' else '''' end) from Settings with (nolock) where settingid = ''SWNetPerfMon-Settings-Default Fast Poll Interval''  group by currentvalue, units )
union all (select '''',''''  )

union all (select ''=== HARDWARE HEALTH  ==='','''' )
union all (select ''Hardware Statistics Polling'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''HardwareHealth-StatisticsPollInterval'' group by currentvalue, units, DefaultValue )
union all (select ''Hardware Detailed'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''HardwareHealth-RetainDetail'' group by currentvalue, units, DefaultValue )
union all (select ''Hardware Hourly'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''HardwareHealth-RetainHourly'' group by currentvalue, units, DefaultValue )
union all (select ''Hardware Daily'', concat(CurrentValue,'' '',Units,case when CurrentValue<>DefaultValue then concat('' <'',defaultvalue,'')'') else '''' end) from Settings with (nolock) where settingid = ''HardwareHealth-RetainDaily'' group by currentvalue, units, DefaultValue )
union all (select ''Preferred Cisco MIB'', (case when CurrentValue=1 then ''Sensor'' else ''Envmon'' end) from Settings with (nolock) where settingid = ''HardwareHealth.PreferredCiscoMIB'' group by currentvalue, units )
'
--********************************************************************************
--  ORION POLLING - end
--********************************************************************************


--********************************************************************************
--  ORION CORE - start
--********************************************************************************
SET @OrionCore='
union all select '''',''''
union all select '''',''''
union all select ''*************************'' ,''*************************''
union all select ''*** C - ORION CORE ***'' ,''*** C - ORION CORE ***''
union all select ''*************************'' ,''*************************''
union all select '''','''' 
union all (select ''== DISCOVERY  =='', '''' )
union all SELECT ''Total'', concat(isNULL(count(*),0),'' '') as [r] FROM DiscoveryProfiles  with (nolock)
union all SELECT ''Blank'', concat(isNULL(count(*),0),'' '') as [r] FROM DiscoveryProfiles  with (nolock) where name=''''
union all SELECT ''Failed Discovery'' as [c], concat(isNULL(count(*),0),'' '') as [v]
FROM DiscoveryLogs dl  with (nolock)
join (SELECT profileid, max(FinishedUTC) as [q] FROM DiscoveryLogs  with (nolock) group by ProfileID) a on a.ProfileID=dl.ProfileID and a.q=dl.FinishedUTC
where dl.result=1
group by dl.profileid, result
union all SELECT ''Scheduled'', concat(isNULL(count(*),0),'' '') as [v]  FROM DiscoveryProfiles  with (nolock) where jobid<>''00000000-0000-0000-0000-000000000000''

union all (select '''', '''' )
union all (select ''=== VENDOR ==='', '''' )
union all (select concat(vendor,'''') as [v], concat(count(*),'''') from nodes  with (nolock) group by vendor )

union all (select ''=== NODE STATUS ==='', '''' )
union all (select ''TOTAL NODES'', concat(isNULL(count(*),0),'' '') from nodes with (nolock))
union all (select * from (select top 20 concat(Statusinfo.StatusName,'''') as [s], case when Statusinfo.StatusName in (''Unknown'',''Down'',''Warning'',''Critical'') and count(*) >0 then concat(count(*),'' <='') 
       else concat(count(*),'''') end as [v]
          from nodes  with (nolock) join statusinfo on statusinfo.StatusId=nodes.Status 
		  group by StatusInfo.StatusId, StatusInfo.StatusName order by statusinfo.StatusId asc) as tmp )

union all (select ''=== INTERFACE STATUS ==='', '''' )
union all (select ''TOTAL INTERFACES'', concat(isNULL(count(*),0),'' '') from interfaces with (nolock))
union all (select * from (select top 20 concat(Statusinfo.StatusName,'''') as [s], case when Statusinfo.StatusName in (''Unknown'',''Down'',''Warning'',''Critical'') and count(*) >0 then concat(count(*),'' <='') 
       else concat(count(*),'''') end as [v]
	   from interfaces  with (nolock) join statusinfo on statusinfo.StatusId=interfaces.status 
       group by StatusInfo.StatusId, StatusInfo.StatusName order by statusinfo.StatusId asc) a)

union all (select ''=== VOLUME STATUS ==='', '''' )
union all (select ''TOTAL VOLUMES(DISK)'', concat(isNULL(count(*),0),'' '') from volumes  with (nolock) where VolumeType like ''fixed%'')
union all (select * from ( select top 20 concat(Statusinfo.StatusName,'''') as [s],case when Statusinfo.StatusName in (''Unknown'',''Down'',''Warning'',''Critical'') and count(*) >0 then concat(count(*),'' <='') 
       else concat(count(*),'''') end as [v] 
	   from volumes  with (nolock) join statusinfo on statusinfo.StatusId=volumes.status where VolumeType like ''fixed%''
	   group by StatusInfo.StatusId, StatusInfo.StatusName order by statusinfo.StatusId asc) a)

union all (select ''=== Nodes with issues ==='', '''' )
union all select ''TOTAL'',concat(count(*),'''') as [v] from nodes
union all select ''issues'',concat(sum(case when StatusDescription<>''Node status is Up.'' then 1 else 0 end),'''') as [s] from nodes



union all (select ''=== Polling Method ==='', '''' )
union all (select concat(ObjectSubType,'''') as [p], concat(count(*),'''') from nodes  with (nolock)group by ObjectSubType )

union all (select ''== AGENTS =='', '''' )
union all (SELECT ''TOTAL Agents'', concat(isnull(count(*),0),'''') as [x] FROM AgentManagement_Agents  with (nolock))
union all (SELECT ''connected'', concat(sum(case when AgentManagement_Agents.ConnectionStatus=1 then 1 else 0 end),'''') as [x] FROM AgentManagement_Agents  with (nolock))
union all (SELECT ''not connected'', case when sum(case when AgentManagement_Agents.ConnectionStatus=2 then 1 else 0 end)>0 
                                          then concat(sum(case when AgentManagement_Agents.ConnectionStatus=2 then 1 else 0 end),'' <='') 
										  else concat(sum(case when AgentManagement_Agents.ConnectionStatus=2 then 1 else 0 end),'''') 
										  end as [x] 
           FROM AgentManagement_Agents  with (nolock))
union all (SELECT ''not used'', case when count(*) >0 then concat(isnull(count(*),0),'' <='')
                                else concat(isnull(count(*),0),'''')
								end as [x] 
                   FROM AgentManagement_Agents a join nodes n on n.nodeid=a.nodeid where n.objectsubtype <> ''agent'')

union all (select ''== AGENTS Status=='', '''' )
union all (select agentstatusmessage, case when agentstatusmessage in (''Reboot pending'',''Unknown'') and count(*)>0 then concat(isnull(count(*),0),'' <='')
                                            else concat(isnull(count(*),0),'''')
											end as [x]
           FROM AgentManagement_Agents group by agentstatusmessage)

union all (select ''== AGENTS per Poller =='', '''' )
union all select a.* from (
select top 50 case when  e.ServerType=''primary'' then concat(e.servername,'' (primary)'') else e.ServerName end as [Poller] , concat(isnull(count(*),0),'''') as [agents] from AgentManagement_Agents a
join nodes n on n.nodeid=a.nodeid
join engines e on e.EngineID=n.EngineID
group by e.ServerName, e.ServerType
order by (case when  e.ServerType=''primary'' then 0 else 1 end), e.ServerName
) a

union all (select ''=== SNMP Version ==='', '''' )
union all (select * from (select top 10 concat(''SNMPv'',SNMPVersion,'''') as [c]
                                      , case when SNMPVersion <3 then concat(count(*),'' <='')
									         else concat(count(*),'''')
											 end as [v] 
						  from nodes with (nolock) group by SNMPVersion order by SNMPVersion) a )

union all (select ''=== SNMP Community ==='', '''' )
--union all (select concat(Community COLLATE Latin1_General_CI_AS,'''') as [c]
--,concat(count(*), case when (concat(Community COLLATE Latin1_General_CI_AS,'''')=''public'' or concat(Community COLLATE Latin1_General_CI_AS,'''')=''private'') and count(*)>0 then ''  <==== avoid'' end) from nodes  with (nolock) where community not like '''' group by Community )
union all (
select
case when concat(Community COLLATE Latin1_General_CI_AS,'''') in (''public'',''private'') then concat(Community COLLATE Latin1_General_CI_AS,'''') else ''OTHER'' end as [c]
,concat(count(*),'''') as [v]
from nodes  with (nolock) 
where community not like '''' 
group by (case when concat(Community COLLATE Latin1_General_CI_AS,'''') in (''public'',''private'') then concat(Community COLLATE Latin1_General_CI_AS,'''') else ''OTHER'' end)
)

union all (select ''=== Credentials used==='', '''' )
union all select ''SNMPv2 TOTAL'', concat(isnull(count(*),0),'''') from Credential where CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV2'' and CredentialOwner=''orion''
union all select ''SNMPv2 used'', concat(isnull(count(*),0),'''') from (
select  name as [v]   from Credential c
left join  (
select settingvalue, SettingName from nodesettings where settingname=''ROSNMPCredentialID''
) a on a.settingvalue=cast(c.id as nvarchar)
where credentialtype=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV2'' and CredentialOwner=''orion''
group by name
) b

union all select ''SNMPv2 Not used'', concat(isnull(count(*),0),'''') from Credential c 
left join (select community from nodes group by community) a on c.name COLLATE Latin1_General_CI_AS=a.community COLLATE Latin1_General_CI_AS
where c.CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV2''  and c. CredentialOwner=''orion'' and a.Community is NULL




union all select ''SNMPv3 TOTAL'', concat(isnull(count(*),0),'''') from Credential where CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV3'' and CredentialOwner=''orion''
union all select ''SNMPv3 used'', concat(isnull(count(*),0),'''') from (
select  name as [v]   from Credential c
join  (
select settingvalue from nodesettings where settingname=''ROSNMPCredentialID''
) a on a.settingvalue=cast(c.id as nvarchar)
where credentialtype=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV3'' and CredentialOwner=''orion''
group by name
) b

union all select ''Windows TOTAL'', concat(isnull(count(*),0),'''') from Credential where CredentialType=''SolarWinds.Orion.Core.SharedCredentials.Credentials.UsernamePasswordCredential'' and CredentialOwner=''orion''
--union all select ''Windows used'', concat(isnull(count(*),0),'''') from (
--select  name, count(*) as [v]   from Credential c
--join  (
--select settingvalue from nodesettings where settingname=''WMICredential''
--) a on a.settingvalue=c.id
--where CredentialType=''SolarWinds.Orion.Core.SharedCredentials.Credentials.UsernamePasswordCredential'' and CredentialOwner=''orion''
--group by name
--) b

union all (select ''== CREDENTIALS =='', '''' )
UNION ALL SELECT ''SNMPV2 - TOTAL'',concat((select count(*) FROM Credential  with (nolock) where CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV2''),'''') 
UNION ALL   
select ''SNMPv2 Unused'',a.name
from 
(SELECT Name FROM Credential  with (nolock) where CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV2'') a
full outer join 
(select distinct community from nodes  with (nolock) where ObjectSubType =''SNMP'') b on b.Community COLLATE SQL_Latin1_General_CP1_CS_AS=a.Name COLLATE SQL_Latin1_General_CP1_CS_AS
where b.Community is null
UNION ALL SELECT ''SNMPV3 - TOTAL'',concat((select count(*) FROM Credential  with (nolock) where CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV3''),'''') 
union all select ''SNMPV3 - unused'', name FROM Credential  with (nolock) 
left join (select * from NodeSettings where settingname like ''%snmp%'') a on a.settingvalue=cast(ID as nvarchar)
where CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV3'' and a.NodeID is NULL
union all select ''Windows TOTAL'', concat(isnull(count(*),0),'''') from Credential where CredentialType=''SolarWinds.Orion.Core.SharedCredentials.Credentials.UsernamePasswordCredential'' and CredentialOwner=''orion''
union all select ''Windows - unused'', name from Credential 
left join (select SettingValue from nodesettings where settingname=''WMICredential'' group by settingvalue) a on a.SettingValue=cast(ID as nvarchar)
where CredentialType=''SolarWinds.Orion.Core.SharedCredentials.Credentials.UsernamePasswordCredential'' and CredentialOwner=''orion'' and a.SettingValue is NULL



--union all select ''Windows used'', concat(isnull(count(*),0),'''') from (
--select  name, count(*) as [v]   from Credential c
--join  (
--select settingvalue from nodesettings where settingname=''WMICredential''
--) a on a.settingvalue=c.id
--where CredentialType=''SolarWinds.Orion.Core.SharedCredentials.Credentials.UsernamePasswordCredential'' and CredentialOwner=''orion''
--group by name
--) b


union all (select ''=== Nodes not responding to CPU ==='', '''' )
UNION ALL (select poll_type as [Poll Type], case when count(*) > 0 then concat(isnull(count(*),0),'' <='') else concat(isnull(count(*),0),'' '') end as [d]
           from (SELECT n.ObjectSubType as Poll_Type FROM Nodes n  with (nolock)
                 Inner join CPUload c  with (nolock) on c.NodeID = n.NodeID
                 WHERE n.status = 1 and (n.ObjectSubType = ''wmi'' or n.ObjectSubType = ''snmp'')
                 GROUP BY n.ObjectSubType, n.Caption 
                 Having DateDiff(mi,MAX(c.datetime),getdate()) > 15
                ) a 
            group by a.Poll_Type)

union all select ''=== MisMatched Names ==='' ,''''
union all (select ''Node Name Different from DNS'' , case when count(*)>0 then concat(isNULL(count(*),0),'' <='') else concat(isNULL(count(*),0),'''') end as [c]
from nodes n  with (nolock)
where (isnull(n.DNS,'''') not like '''' and isnull(n.SysName,'''') not like '''') 
 and  
 ( 
SUBSTRING(n.caption,1,case charindex(''.'',n.caption,1) when 0 then len(n.caption) else (charindex(''.'',n.caption,1)-1) end) != 
SUBSTRING(n.dns,1,case charindex(''.'',n.dns,1) when 0 then len(n.dns) else (charindex(''.'',n.dns,1)-1) end) 
or  
SUBSTRING(n.caption,1,case charindex(''.'',n.caption,1) when 0 then len(n.caption) else (charindex(''.'',n.caption,1)-1) end) != 
SUBSTRING(n.sysname,1,case charindex(''.'',n.sysname,1) when 0 then len(n.sysname) else (charindex(''.'',n.sysname,1)-1) end) 
) 
)		

union all (select ''=== UnNeeded Interfaces ==='', ''''  )
union all select ''Loopback'', case when count(*)>0 then concat(isNULL(count(*),0),'' <='') else concat(isNULL(count(*),0),'''') end as [c] from interfaces i  with (nolock) where i.caption like ''%loop%''
union all select ''Null'', case when count(*)>0 then concat(isNULL(count(*),0),'' <='') else concat(isNULL(count(*),0),'''') end as [c] from interfaces i  with (nolock) where i.caption like ''%null%''
union all select ''Pots'', case when count(*)>0 then concat(isNULL(count(*),0),'' <='') else concat(isNULL(count(*),0),'''') end as [c] from interfaces i  with (nolock) where i.caption like ''%pots%''
union all select ''Unrouted'', case when count(*)>0 then concat(isNULL(count(*),0),'' <='') else concat(isNULL(count(*),0),'''') end as [c] from interfaces i  with (nolock) where i.caption like ''%unrouted%''
union all select ''Uncontrolled'', case when count(*)>0 then concat(isNULL(count(*),0),'' <='') else concat(isNULL(count(*),0),'''') end as [c] from interfaces i  with (nolock) where i.caption like ''%uncontrolled%''
union all select ''Windows'', case when count(*)>0 then concat(isNULL(count(*),0),'' <='') else concat(isNULL(count(*),0),'''') end as [c] from interfaces i  with (nolock) where i.caption like ''%0000%''

union all (select ''=== ACCOUNT LIMITATIONS Used ==='', ''''  )
union all (SELECT LimitationTypetable, concat(count(*),'''') as [v] FROM LimitationTypes where system=''n'' group by LimitationTypetable)

union all (select ''=== HardWare sensors ==='', ''''  )
union all SELECT ''TOTAL'', concat(isnULL(count(*),0),'' '') FROM HWH_HardwareItem  with (nolock) where isdeleted=0
union all SELECT ''Disabled'', concat(isnULL(count(*),0),'' '') FROM HWH_HardwareItem  with (nolock) where isdeleted=0 and IsDisabled=1
union all SELECT ''Up'', concat(isnULL(count(*),0),'' '') FROM HWH_HardwareItem  with (nolock) where isdeleted=0 and IsDisabled=0 and Status=1
union all SELECT ''Warning'', concat(isnULL(count(*),0),'' '') FROM HWH_HardwareItem  with (nolock) where isdeleted=0 and IsDisabled=0 and Status=3
union all SELECT ''Critical'', concat(isnULL(count(*),0),'' '') FROM HWH_HardwareItem  with (nolock) where isdeleted=0 and IsDisabled=0 and Status=14

union all (select ''=== Hardware sensors by vendor ==='', ''''  )
union all (SELECT n.Vendor, concat(isnull(count(*),0),'''') as [v]
FROM HWH_HardwareItem hi  with (nolock)
left join HWH_HardwareInfo hinfo  with (nolock) on hinfo.id= hi.HardwareInfoID
left join nodes n  with (nolock) on n.nodeid=hinfo.NetObjectID
where isdeleted=0   
group by n.vendor
)

union all (select ''=== POLLERS ==='', ''''  )
union all (SELECT concat(''Custom:'',dp.name), concat(isnull(count(*),0),'''') as [v] FROM DeviceStudio_Pollers dp
join DeviceStudio_PollerAssignments ps on ps.PollerID= dp.pollerid and ps.Enabled=1
where author <> ''SolarWinds'' group by dp.name)
union all ( select * from (
SELECT top 100
case when pollertype=''N.EnergyWise.SNMP.Cisco'' then ''EnergyWise''
when pollertype=''N.Status.Agent.Native'' then ''Status & Response Time - Agent''
when pollertype=''N.Status.ICMP.Native'' then ''Status & Response Time - ICMP''
when pollertype=''N.Status.SNMP.Native'' then ''Status & Response Time - SNMP''
end as [c]
,concat(isnull(count(*),0),'''') as [v]
  FROM Pollers
  where enabled=1
and pollertype in (''N.EnergyWise.SNMP.Cisco'',''N.Status.Agent.Native'',''N.Status.ICMP.Native'',''N.Status.SNMP.Native'')
group by pollertype
order by 1) a 
)

union all (select ''=== Web Console ==='', ''''  )
union all SELECT ''Session Timeout'', case when SettingValue<>25 then concat(convert(nvarchar, SettingValue),'' mins < 25'') else ''25 mins'' end FROM WebSettings where settingname=''Session Timeout''
union all SELECT ''Windows Account Login'', case when settingvalue=''0'' then ''Disabled'' else ''Enabled'' end  FROM WebSettings where settingname=''WindowsAccountLogin''
union all SELECT ''Page Refresh'', case when settingvalue<>5 then concat(convert(nvarchar, SettingValue),'' mins <5'') else ''5 mins'' end FROM WebSettings where settingname=''Auto Refresh''
union all SELECT ''Modern Page Refresh'', case when settingvalue<>45 then concat(convert(nvarchar, SettingValue),'' secs'') else ''45 secs'' end FROM WebSettings where settingname=''Modern Widget Refresh Rate''
union all SELECT ''Enable Audit Trails'', case when currentvalue=''1'' then ''Enabled'' else ''Disabled'' end FROM Settings where settingid=''SWNetPerfMon-AuditingTrails''

union all (SELECT ''=== World Map ==='', '' ''  )
union all (SELECT ''Automatic Geolocation'',case when CurrentValue=1 then ''ENABLED'' else ''DISABLED'' end as [x] FROM Settings where settingid=''AutomaticGeolocation-Enable'')
union all select ''World Map Nodes'', concat(isnull(count(*),0),'''') from WorldMapPoints  where Instance=''Orion.Nodes''
union all select ''World Map Groups'', concat(isnull(count(*),0),'''') from WorldMapPoints  where Instance=''Orion.Groups''
union all select ''World Map Maps'', concat(isnull(count(*),0),'''') from WorldMapPoints  where Instance=''Orion.WorldMap.PointLabel''

union all (SELECT ''=== Orion Maps ==='', '' ''  )
union all (SELECT [AccountID], concat(isnull(count(*),0),'' maps'') as [c] FROM Maps_Projects group by accountid)
	   
--union all (select ''=== Node StatusDescription ==='', ''''  )
--union all (select * from (select top 20 concat(''Status: '',StatusDescription) as [s], concat(count(*),'''') as [v] from nodes  with (nolock) group by StatusDescription order by count(*) desc) a  )
--union all (select '''', ''''  )


--union all (select ''== CREDENTIALS =='', '''' )
--UNION ALL SELECT ''SNMPV2 - TOTAL'',concat(''Total ['',(select count(*) FROM Credential  with (nolock) where CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV2''),'']'') 
--UNION ALL   
--select ''SNMPv2 Unused'',a.name
--from 
--(SELECT Name FROM Credential  with (nolock) where CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV2'') a
--full outer join 
--(select distinct community from nodes  with (nolock) where ObjectSubType =''SNMP'') b on b.Community COLLATE SQL_Latin1_General_CP1_CS_AS=a.Name COLLATE SQL_Latin1_General_CP1_CS_AS
--where b.Community is null
--UNION ALL SELECT ''SNMPV3 - TOTAL'',concat(''Total['',(select count(*) FROM Credential  with (nolock) where CredentialType=''SolarWinds.Orion.Core.Models.Credentials.SnmpCredentialsV3''),'']'') 

union all (select ''== CUSTOM POPERTIES =='', '''' )  -- CHECK
union all SELECT ''Nodes'',concat(isNULL(COUNT(*)-1,0),'''') FROM INFORMATION_SCHEMA.COLUMNS  with (nolock)      WHERE table_name = ''NodesCustomProperties''
union all SELECT ''Interfaces'',concat(isNULL(COUNT(*)-70,0),'''') FROM INFORMATION_SCHEMA.COLUMNS  with (nolock)WHERE table_name = ''Interfaces''
union all SELECT ''Volumes'',concat(isNULL(COUNT(*)-40,0),'''') FROM INFORMATION_SCHEMA.COLUMNS  with (nolock)     WHERE table_name = ''Volumes''
union all SELECT ''Groups'',concat(isNULL(COUNT(*)-1,0),'''') FROM INFORMATION_SCHEMA.COLUMNS  with (nolock)     WHERE table_name = ''ContainerCustomProperties''
union all SELECT ''Alerts'',concat(isNULL(COUNT(*)-1,0),'''') FROM INFORMATION_SCHEMA.COLUMNS  with (nolock)     WHERE table_name = ''AlertConfigurationsCustomProperties''
union all SELECT ''Reports'',concat(isNULL(COUNT(*)-1,0),'''') FROM INFORMATION_SCHEMA.COLUMNS   with (nolock)    WHERE table_name = ''ReportDefinitions''

union all (select ''== NODE CUSTOM POPERTIES UTILIZATION =='', '''' )
union all select 
ColumnName as [NodeCustomProperty]
,concat(round(Row_Count*100/(select count(*) as [c] from NodesCustomProperties),0),''% ('',Distinct_values,'' unique)'') as [PercentPopulated]
from (
Select ColumnName=Item, Row_Count= sum(1), Distinct_values=count(distinct value)
 From  (
        Select C.*
         From NodesCustomProperties A
         Cross Apply ( values (cast((Select A.* for XML RAW) as xml))) B(XMLData)
         Cross Apply (
                        Select Item  = replace(xAttr.value(''local-name(.)'', ''varchar(100)''),''_x0020_'','' '')
                              ,Value = xAttr.value(''.'',''varchar(max)'')
                         From  XMLData.nodes(''//@*'') xNode(xAttr)
                     ) C
        where c.Item <> ''NodeID''
       ) A
 Left Join  (
        Select * from sys.dm_exec_describe_first_result_set(''Select * from NodesCustomProperties'',null,null )  
       ) B on A.Item=B.name
 Group By A.Item
         ,B.column_ordinal 
 ) x

union all (select ''== GROUPS =='', '''')
union all (select ''Total'', concat(count(ContainerID),'''')  from Containers with (nolock) )
union all (select ''Dynamic'', concat(count(distinct ContainerID),'''')  from ContainerMemberDefinitions cd  with (nolock) where cd.definition like ''filter%'' )

union all (select ''== DEPENDENCIES =='', '''' )
union all (select ''Total'', concat(count(isNULL(DependencyId,0)),'''')  from Dependencies  with (nolock))
union all (select ''Calculated Automatically'', case when count(*)>0 then concat(count(*),'' <='') else concat(count(*),'''') end from Dependencies  with (nolock) where AutoManaged=1 )
union all (select ''User-Defined'',concat(count(*),'''') from Dependencies  with (nolock) where automanaged=0 )

union all (select ''=== API POLLERS ==='','''' )
union all (SELECT ''TOTAL'', concat(isnull(count(*),0),'''') as [v] FROM APIPoller_ApiPoller ap)
union all (SELECT si.StatusName, concat(isnull(count(*),0),'''') as [v] FROM APIPoller_ApiPoller ap join StatusInfo si on si.StatusId=ap.status group by si.StatusName)

union all (select ''== ALERTS =='', '''' )
Union all (select ''Total'', concat((select count(*) from AlertDefinitionsView  with (nolock)),''''))
Union all (select ''Enabled'', concat((select count(*) from AlertDefinitionsView with (nolock) where enabled=1),''''))  
union all (select ''Active'', concat(count(*),'''') from AlertActive  with (nolock))
union all (select ''Oldest'', concat(min(TriggeredDateTime),'''') from AlertActive  with (nolock))
union all (select ''Newest'', concat(max(TriggeredDateTime),'''') from AlertActive  with (nolock))

--union all (select ''== ALERTS Eval Frequency SUMMARY==='', '''' )
union all select ''Eval Freq Less than 60 sec'',concat(isnull(count(*),0),'''') as [v] from AlertDefinitionsView  with (nolock) where executeinterval<60
union all select ''Eval Freq 60 seconds'',concat(isnull(count(*),0),'''') as [v] from AlertDefinitionsView  with (nolock)  where executeinterval=60
union all select ''Eval Freq More than 60 sec'' ,concat(isnull(count(*),0),'''') as [v] from AlertDefinitionsView  with (nolock) where executeinterval>60 
--union all (select ''== ALERTS Eval Frequency ==='', '''' )
--union all (select concat(executeinterval, '' seconds''), concat(count(executeinterval),'''') from AlertDefinitionsView  with (nolock) group by ExecuteInterval )
--union all (select ''== ALERTS Trigger Frequency ==='', '''' )
--union all (select  ''Alerts: > 1 year'', concat(count(*),'''') from AlertActive  with (nolock) where datediff(dd,TriggeredDateTime,getdate())>365 )
--union all (select  ''Alerts: > 6 months'', concat(count(*),'''') from AlertActive  with (nolock) where datediff(dd,TriggeredDateTime,getdate())>182 )
--union all (select  ''Alerts: > 3 months'', concat(count(*),'''') from AlertActive  with (nolock) where datediff(dd,TriggeredDateTime,getdate())>90 )
--union all (select  ''Alerts: < 30 days'', concat(count(*),'''') from AlertActive  with (nolock) where datediff(dd,TriggeredDateTime,getdate())<30 )
--union all (select  ''Alerts: < 15 days'', concat(count(*),'''') from AlertActive  with (nolock) where datediff(dd,TriggeredDateTime,getdate())<15 )
--union all (select  ''Alerts: < 7 days'', concat(count(*),'''') from AlertActive  with (nolock) where datediff(dd,TriggeredDateTime,getdate())<7 )
--union all (select  ''Alerts:   today'', concat(count(*),'''') from AlertActive  with (nolock) where datediff(dd,TriggeredDateTime,getdate())=0 )

union all (select ''=== ALERT Triggers last 7 days ==='', ''Last 7 days'' )  
union all (
select a.date, concat(isnull(sum(a.Triggered),0),'''') from (SELECT convert(varchar,ah.TimeStamp,107)  as [date]
           ,count(*) as [Triggered]  FROM AlertHistory ah  with (nolock)
           where DATEDIFF(day,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),ah.TimeStamp),getdate()) <6
           AND ah.eventtype=0
           group by ah.TimeStamp) a
		   group by date
)

union all (select ''=== ALERT NAME Top 5 ==='', ''TRIGGERED TODAY'' )  
union all(  select a, concat(isnull(Triggered,0),'''') from (SELECT top 5 ac.Name as [a]
           ,count(*) as [Triggered]  FROM AlertHistory ah  with (nolock)
           join AlertObjects ao  with (nolock) on ao.AlertObjectID=ah.AlertObjectID
           join AlertConfigurations ac  with (nolock) on ac.AlertID=ao.AlertID
           where DATEDIFF(day,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()),ah.TimeStamp),getdate()) =0 and ac.Name is not null 
           AND ah.eventtype=0
           group by ac.name
		   order by sum(case when ah.eventtype=0 then 1 end) desc
           ) as tmp)
union all (select ''=== ALERT ACTION FAILED Top 5 ==='', ''TRIGGERED TODAY'' )
union all (select a, concat(isnull(Action_Fail,0),'''') from (SELECT top 5 ac.Name as [a] 
           ,count(*) as Action_Fail FROM AlertHistory ah  with (nolock)
           left join AlertActions act  with (nolock) on act.ActionID=ah.ActionID 
           join AlertObjects ao  with (nolock) on ao.AlertObjectID=ah.AlertObjectID
           join AlertConfigurations ac  with (nolock) on ac.AlertID=ao.AlertID
           where datediff(dd,ah.TimeStamp,GETDATE()) =0
		   AND ah.EventType=5
           group by ac.name
           order by count(case when ah.EventType=5 then 1 else null end) desc
           ) as tmp )

union all (select ''=== Triggered NODE Top 5 ==='', ''TRIGGERED TODAY'' )
union all (select a, concat(isnull(triggered,0),'''') from (SELECT top 5 n.caption as [a]
           ,count(*)  as [Triggered] FROM AlertHistory ah  with (nolock)
           join AlertObjects ao  with (nolock) on ao.AlertObjectID=ah.AlertObjectID
           join nodes n  with (nolock) on n.nodeid=ao.RelatedNodeId
           where DATEDIFF(dd,ah.TimeStamp,GETDATE()) =0 and n.caption is not null 
		   AND ah.eventtype=0
           group by n.caption
		   order by count(case when ah.eventtype=0 then 1 else null end) desc
           ) as tmp )

union all (select ''=== ACTIVE ALERT BY OBJECT ==='', '''' )
union all (SELECT ObjectType as [c], count(*) as [v] FROM AlertStatusView group by objecttype)



--union all (select ''===  EVENTS  ==='','''' )
--union all(select tmp.device, concat(''Today:'',isnull(tmp.Last0days,0),''    7 days:'',isnull(tmp.last7days,0),''    30 days:'',isnull(tmp.lasfe0days,0)) as [Last 30 days] 
--          from (select  top 5
--                concat(''Events: '',n.Caption, '' ('',n.IP_Address,'')'') as [device]
--               ,isnull(last0days.Events,0) as[Last0days] , isnull(last7days.Events,0) as [Last7days], isnull(lasfe0days.Events,0) as [Lasfe0days] 
--               from Nodes n  with (nolock)
--               left join (select n.nodeid  ,count(*) as [Events] 
--                           from Events e join nodes n  with (nolock) on n.NodeID=e.NetworkNode where datediFF(dd,e.EventTime,getdate()) = 0 
--                           group by n.Caption, n.nodeid) last0days on last0days.nodeid = n.nodeid 
--               left join (select n.nodeid ,count(*) as [Events] 
--                           from Events e join nodes n  with (nolock) on n.NodeID=e.NetworkNode where dateDIFF(dd,e.EventTime,getdate()) <= 7 
--                           group by n.Caption, n.nodeid) last7days on last7days.nodeid = n.nodeid 
--               left join (select n.nodeid ,count(*) as [Events] 
--                           from Events e join nodes n  with (nolock) on n.NodeID=e.NetworkNode where dateDIFF(dd,e.EventTime,getdate()) <= 30 
--                           group by n.Caption, n.nodeid) lasfe0days on lasfe0days.nodeid = n.nodeid 
--	  	       order by isnull(last0days.Events,0) desc, isnull(last7days.Events,0) desc, isnull(lasfe0days.Events,0) desc
--		   ) tmp  group by device, Last0days, Last7days, Lasfe0days )
union all (select ''===  REPORTS  ==='','''' )
union all(select ''TOTAL'', concat(count(*),'''') from ReportDefinitions  with (nolock) )
union all(select ''Scheduled'', concat(count(*),'''') from ReportJobs  with (nolock))
union all(select ''Active Scheduled'', concat(count(*),'''') from ReportJobs  with (nolock) where Enabled=1 )
union all(select ''Custom'', concat(count(*),'''') from ReportDefinitions with (nolock) where Category like ''%custom%'' )

union all (select ''===  Accounts  ==='','''' )
union all(select case when AccountType=0 then ''Orion Service Account'' when AccountType=1 then ''Local Orion'' when AccountType=2 then ''AD Individual'' when AccountType=3 then ''AD Group'' when AccountType=6 then ''SAML'' end , concat(count(*),'''') from Accounts  with (nolock) where AccountType in (''0'',''1'',''2'',''3'',''6'') group by accounttype )
union all (select ''===  Account TimeOuts  ==='','''' )
union all (select ''Timeout'', case when isNULL(count(*),0) >0 then 
concat(isNULL(count(*),0),'' <=='') else concat(isNULL(count(*),0),'''') end as [t] from accounts where accountenabled=''y'' and disablesessiontimeout=''y'')
union all (select ''===  Views  ==='','''' )
union all select ''Thwack'',concat(isNULL(count(*),0),'''') as [v] from resources  with (nolock) where resourcename like ''%thwack%''
union all select ''Whats New'',concat(isNULL(count(*),0),'''') as [v] from resources  with (nolock) where resourcename like ''%what''''s new%''
union all select ''Sample Map'',concat(isNULL(count(*),0),'''') as [v] from resources  with (nolock) where resourcename like ''%sample%''
union all select ''Custom Object'',concat(isNULL(count(*),0),'''') as [v] from resources  with (nolock) where resourcename like ''%custom object%''
union all select ''Current Top 10'',''Get from Orion Web''
union all select ''Views by Device Type'',''Get from Orion Web''

union all (select ''===  Top 5 Views by number of widgets  ==='','''' )
union all select * from (SELECT top 5 concat(v.viewtype,''('',v.viewtitle,'') ViewID:'',r.ViewID) as [c] ,concat(isNULL(count(*),0),'''') as [Num of Widgets] FROM Resources r
         join Views v on v.ViewID=r.viewid group by r.viewid, v.viewtype, v.viewtitle order by count(*) desc) a


--union all (select ''===  Interface Type  ==='','''' )
--union all (select * from (select top 100 concat(it.Description,'' ('',case when wan=1 then ''WAN'' when lan=1 then ''LAN'' when it.name=''ieee8023adLag'' then ''Link Aggerate''
--	                                              when it.name=''ieee80211'' then ''Wireless'' when wan=0 and lan=0 then ''Other''
--	                                              end,'')'') as [WAN/LAN],  concat(count(*),'''') as [Count] from interfaces i  with (nolock)
--           join InterfaceTypes it  with (nolock) on it.Type=i.InterfaceType group by it.name, wan, lan, it.Description order by count(*) desc) a)

union all (select ''=== UnDP ==='','''' )
union all (SELECT ''TOTAL'', concat(count(*),'''')  from CustomPollers cp with (nolock) )
union all (SELECT ''Enabled'', concat(count(*),'''') from CustomPollers cp with (nolock) where enabled=1 )
--union all (SELECT ''=== UnDP: Node Count by Custom Poller ==='', '' ''  )
--union all (SELECT concat(''UnDP: '',cp.GroupName,'' - '',custompollername) , concat(isnull(count(nodeid),0),'''') from CustomPollerAssignmentView cpa with (nolock) join custompollers cp on cp.CustomPollerID=cpa.CustomPollerID where status=1 group by CustomPollerName, cp.GroupName )
--union all (SELECT ''=== UnDP: Count by Custom Node ==='', '' ''  )
--union all (SELECT   concat(''UnDP: '',n.vendor) , concat(isnull(count(cpa.NodeID),0),'''')  from CustomPollerAssignmentView cpa with (nolock) join nodes n on n.nodeid=cpa.NodeID where cpa.status=1 group by n.Vendor )
union all (select ''=== UnDP Polling Interval==='','''' )
union all
(
select
concat(pollinterval, '' minutes'') as [c]
,concat(sum([NumOfDevcies]), '' pollers'') as [d]
from (
SELECT 
case when pollinterval is NULL or pollinterval=0 then 10 else pollinterval end as [PollInterval]
, count(*) as [NumOfDevcies] FROM [dbo].[CustomPollers] group by pollinterval
) a
group by pollinterval
)
union all (select ''=== UnDP Polling Interval (for <>10mins)'','''' )
union all
(
SELECT UniqueName, 
case when includeHistoricStatistics=1 then concat(pollinterval,'' mins (hist)'')
     else concat(pollinterval,'' mins'') end
FROM CustomPollers
where pollinterval>0
)

union all (select ''=== UnDP: Poller, num of nodes, interval ==='','''' )

union all 
(
SELECT 
concat(''UnDP: '',cp.GroupName,'' - '',custompollername)
,concat(isnull(count(nodeid),0),'' nodes  @'',cp.PollInterval,'' mins'') 
from CustomPollerAssignmentView cpa with (nolock) 
join custompollers cp on cp.CustomPollerID=cpa.CustomPollerID 
where status=1 
group by CustomPollerName, cp.GroupName, PollInterval
)



union all (SELECT ''=== Active Diagnostics: Problems ==='', '' ''  )
union all select 
concat(tmp2.Engine,'' - TOTAL'')
,concat(count(*),'''') as [Status]
from engines ee with (nolock) 
join (
   select
      JSON_VALUE(tmp1.json, ''$.DisplayName'') as [Diagonistic Name]
      ,tmp1.Engine as [Engine], tmp1.Engineid
      ,tmp1.EndDate 
      ,tmp1.StatusDescription 
      ,JSON_VALUE(tmp1.json, ''$.Explanation'') as [Explataion]
      ,tmp1.Status
    from (
           SELECT ad.MethodName,e.ServerName as [Engine], e.engineid, ad.EndDate,  ad.Status, s.StatusName,ad.Json
              ,case when ad.Status=1 then ''Healthy Check''
                    when ad.status=2 then ''Problem''
                    when ad.status=3 then ''Potential Issue''
               end as [StatusDescription]
              ,rank() over (partition by ad.methodname, ad.engineid order by ad.enddate desc) as [Rank]
            FROM ActiveDiagnosticsDetail ad with (nolock) 
           join engines e with (nolock) on e.EngineID=ad.EngineID 
           join StatusInfo s with (nolock) on s.StatusId=ad.Status
         ) tmp1
   where tmp1.rank=1   
   ) tmp2 on tmp2.EngineID=ee.EngineID
where tmp2.StatusDescription = ''Problem''
group by tmp2.Engine

union all (
select 
tmp2.Engine
,concat(convert(varchar,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), tmp2.EndDate),107),''   ['',tmp2.[Diagonistic Name],'']   '', tmp2.Explataion) as [Status]
from engines ee with (nolock) 
join (
   select
      JSON_VALUE(tmp1.json, ''$.DisplayName'') as [Diagonistic Name]
      ,tmp1.Engine as [Engine], tmp1.Engineid
      ,tmp1.EndDate 
      ,tmp1.StatusDescription 
      ,JSON_VALUE(tmp1.json, ''$.Explanation'') as [Explataion]
      ,tmp1.Status
    from (
           SELECT ad.MethodName,e.ServerName as [Engine], e.engineid, ad.EndDate,  ad.Status, s.StatusName,ad.Json
              ,case when ad.Status=1 then ''Healthy Check''
                    when ad.status=2 then ''Problem''
                    when ad.status=3 then ''Potential Issue''
               end as [StatusDescription]
              ,rank() over (partition by ad.methodname, ad.engineid order by ad.enddate desc) as [Rank]
            FROM ActiveDiagnosticsDetail ad with (nolock) 
           join engines e with (nolock) on e.EngineID=ad.EngineID 
           join StatusInfo s with (nolock) on s.StatusId=ad.Status
         ) tmp1
   where tmp1.rank=1   
   ) tmp2 on tmp2.EngineID=ee.EngineID
where tmp2.StatusDescription = ''Problem''
--where tmp2.StatusDescription <> ''Healthy Check''
--order by tmp2.EngineID, tmp2.status asc, tmp2.[Diagonistic Name]
)
union all (SELECT ''=== Active Diagnostics: Potential Issue ==='', '' ''  )
union all (
select 
concat(tmp2.Engine,'' - TOTAL'')
,concat(count(*),'''') as [Status]
from engines ee with (nolock) 
join (
   select
      JSON_VALUE(tmp1.json, ''$.DisplayName'') as [Diagonistic Name]
      ,tmp1.Engine as [Engine], tmp1.Engineid
      ,tmp1.EndDate 
      ,tmp1.StatusDescription 
      ,JSON_VALUE(tmp1.json, ''$.Explanation'') as [Explataion]
      ,tmp1.Status
    from (
           SELECT ad.MethodName,e.ServerName as [Engine], e.engineid, ad.EndDate,  ad.Status, s.StatusName,ad.Json
              ,case when ad.Status=1 then ''Healthy Check''
                    when ad.status=2 then ''Problem''
                    when ad.status=3 then ''Potential Issue''
               end as [StatusDescription]
              ,rank() over (partition by ad.methodname, ad.engineid order by ad.enddate desc) as [Rank]
            FROM ActiveDiagnosticsDetail ad with (nolock) 
           join engines e with (nolock) on e.EngineID=ad.EngineID 
           join StatusInfo s with (nolock) on s.StatusId=ad.Status
         ) tmp1
   where tmp1.rank=1   
   ) tmp2 on tmp2.EngineID=ee.EngineID
where tmp2.StatusDescription = ''Potential Issue''
group by tmp2.engine
--where tmp2.StatusDescription <> ''Healthy Check''
--order by tmp2.EngineID, tmp2.status asc, tmp2.[Diagonistic Name]
)

union all (
select 
tmp2.Engine
,concat(convert(varchar,DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), tmp2.EndDate),107),''   ['',tmp2.[Diagonistic Name],'']   '', tmp2.Explataion) as [Status]
from engines ee with (nolock) 
join (
   select
      JSON_VALUE(tmp1.json, ''$.DisplayName'') as [Diagonistic Name]
      ,tmp1.Engine as [Engine], tmp1.Engineid
      ,tmp1.EndDate 
      ,tmp1.StatusDescription 
      ,JSON_VALUE(tmp1.json, ''$.Explanation'') as [Explataion]
      ,tmp1.Status
    from (
           SELECT ad.MethodName,e.ServerName as [Engine], e.engineid, ad.EndDate,  ad.Status, s.StatusName,ad.Json
              ,case when ad.Status=1 then ''Healthy Check''
                    when ad.status=2 then ''Problem''
                    when ad.status=3 then ''Potential Issue''
               end as [StatusDescription]
              ,rank() over (partition by ad.methodname, ad.engineid order by ad.enddate desc) as [Rank]
            FROM ActiveDiagnosticsDetail ad with (nolock) 
           join engines e with (nolock) on e.EngineID=ad.EngineID 
           join StatusInfo s with (nolock) on s.StatusId=ad.Status
         ) tmp1
   where tmp1.rank=1   
   ) tmp2 on tmp2.EngineID=ee.EngineID
where tmp2.StatusDescription = ''Potential Issue''
--where tmp2.StatusDescription <> ''Healthy Check''
--order by tmp2.EngineID, tmp2.status asc, tmp2.[Diagonistic Name]
)

'
--********************************************************************************
--  ORION CORE - end
--********************************************************************************


--********************************************************************************
--  NPM - start
--********************************************************************************
SET @NPM =
'
union all (select '''', ''''  )
union all (select '''', ''''  )
UNION ALL select ''**** NPM ********************************************''  as [Description],''**** NPM ********************************************'' as [Value]
union all select ''**** NPM ********************************************'',''**** NPM ********************************************''
union all (select ''=== NetPath by Probe==='', '''' )
--https://support.solarwinds.com/SuccessCenter/s/article/Status-Mapping-for-NetPath?language=en_US
union all (SELECT  
concat(case when ServiceName is NULL then HostName else ServiceName end, '' <-- '',
 case when p.name is NULL then p.description else name end) as [NetPath]
--,p.status
,case when p.status = 0 then ''Unknown''
      when p.status = 1 then ''Up''
      when p.status = 2 then ''Warning''
      when p.status = 100 then ''Critical''
      when p.status = 102 then ''DNSError''
      when p.status = 103 then ''HostUnreachable''
      when p.status = 104 then ''PortClosed''
      when p.status = 101 then ''ProbeDown''
	  when p.status = 106 then ''UnsupportedOS''
      when p.status = 107 then ''AgentFailed''
      when p.status = 108 then ''JobFailure''
      when p.status = 109 then ''NotLicensed''
	  end as [Status]
FROM NetPath_EndpointServices  eps
join NetPath_EndpointServiceAssignments esa on esa.EndpointServiceID=eps.EndpointServiceID
join NetPath_Probes p on p.ProbeID=esa.Probeid
--order by [Service]
)



--union all (select a.start
--,concat(''Total['',count(es.Status),'']  Up['',sum(case when es.status=1 then 1 else 0 end)
--	                           ,'']  Down['',sum(case when es.status=2 then 1 else 0 end)
--							   ,'']  Warning['',sum(case when es.status=3 then 1 else 0 end)
--							   ,'']  Critical['',sum(case when es.status=14 then 1 else 0 end)
--							   ,'']'') as [Status]
--From NetPath_EndpointServiceAssignments es
--join (
--SELECT [ProbeID]
--	  ,case when agentid is NULL then (select servername from engines where engineid=p.engineid)
--	             else (select hostname from AgentManagement_Agents where agentid=p.agentid)
--				 end as [start]
--  FROM NetPath_Probes p
--  where p.Enabled=1
--  ) a on a.ProbeID=es.ProbeID
--  group by a.start
--)
union all (select ''=== NetPath ==='', '''' )
union all
select p.name
,concat(''Total['',count(es.Status),'']  Up['',sum(case when es.status=1 then 1 else 0 end)
	                           ,'']  Down['',sum(case when es.status=2 then 1 else 0 end)
							   ,'']  Warning['',sum(case when es.status=3 then 1 else 0 end)
							   ,'']  Critical['',sum(case when es.status=14 then 1 else 0 end)
							   ,'']  Undefined['',sum(case when es.status=17 then 1 else 0 end)
							   ,'']'') as [Status]
from NetPath_EndpointServiceAssignments sa
join NetPath_Probes p on p.ProbeID=sa.ProbeID
join NetPath_EndpointServices es on es.EndpointServiceID=sa.EndpointServiceID
where sa.Enabled=1 and es.ServiceName is not Null and es.ServiceName <> ''''
group by p.name

union all (select ''===  Wireless  ==='','''' )
union all(select ''Controllers'', concat((select isNULL(count(*),0) from Wireless_Controllers with (nolock) ),'' '') )
union all(select ''Access Points'', concat((select isNULL(count(*),0) from Wireless_AccessPoints with (nolock) ),'' '') )
union all(select ''Rouge APs'', concat((select isNULL(count(*),0) from Wireless_Rogues with (nolock) ),'' '') )
union all (select ''===  LOAD BALANCER  ==='','''' )
UNION ALL SELECT ''F5'', concat(COUNT(*),'''') AS [C] FROM F5_System_Device with (nolock) 
union all (select ''===  VLANS  ==='','''' )
union all select ''TOTAL VLANs'', concat(isNULL(COUNT(*),0),'''') AS [v] FROM NodeVlans with (nolock)
union all select ''VLAN 1 devices'', concat(isNULL(COUNT(*),0),'''') AS [v] FROM NodeVlans  with (nolock) where vlanid=1 
union all select ''VLAN other devices'', concat(isNULL(COUNT(*),0),'''') AS [v] FROM NodeVlans  with (nolock) where vlanid>1 
--union all (select * from (select top 1000 concat(VlanId, '' '') as[v], concat(isNULL(COUNT(*),0),'' '') AS [B] FROM NodeVlans  with (nolock) GROUP BY VLANID order by 1) as a)
union all (select ''===  CLOUD  ==='','''' )
union all SELECT cp.Name, concat(count(*),'' total  '',sum(case when cin.Monitored=1 then 1 else 0 end),'' running'') as [running]
FROM VIM_CloudInstanceNodes  cin with (nolock) 
join clm_cloudproviders cp on cp.id=cin.providerid
group by cp.name

union all (select ''===  QoE Probes  ==='','''' )
union all (SELECT ''TOTAL Probes'', concat(isnull(count(*),0),'''') FROM DPI_Probes)
union all (SELECT ''Enabled Probes'', concat(isNULL(count(*),0),'''') FROM DPI_Probes where enabled=1)

union all (select ''===  Cisco ASA - Site-to-Site VPN Tunnels  ==='','''' )
union all (select ''TOTAL ASA Nodes'', concat(isnull(count(*),0),'''') from asa_node)
union all SELECT si.statusname, concat(count(*),'''') as [v] FROM VPN_L2LTunnel vpnt  with (nolock) join statusinfo si on si.statusid = vpnt.status group by si.statusname
'
--********************************************************************************
--  NPM - end
--********************************************************************************

--********************************************************************************
--  SAM - start
--********************************************************************************
SET @SAM =
'
union all (select '''' as [Description],'''' as [Metric] )
union all (select '''' as [Description],'''' as [Metric] )
union all (select ''****  SERVER & APPLICATION MONITOR  ****'','''' )
union all (select ''****  SERVER & APPLICATION MONITOR  ****'','''' )
union all (select ''=== Application Status ==='', '''' )
union all (select ''TOTAL''        ,concat(count(*),'''') FROM APM_CurrentStatusOfApplication a )
union all (select ''Up''           ,concat(sum(case when a.ApplicationAvailability=''Up'' then 1 else 0 end),'''') FROM APM_CurrentStatusOfApplication a  )
union all (select ''Down''         ,concat(sum(case when a.ApplicationAvailability=''Down'' then 1 else 0 end),'''') FROM APM_CurrentStatusOfApplication a )
union all (select ''Critical''     ,concat(sum(case when a.ApplicationAvailability=''Critical'' then 1 else 0 end),'''') FROM APM_CurrentStatusOfApplication a )
union all (select ''Warning''      ,concat(sum(case when a.ApplicationAvailability=''Warning'' then 1 else 0 end),'''') FROM APM_CurrentStatusOfApplication a )
union all (select ''Unknown''      ,concat(sum(case when a.ApplicationAvailability=''Unknown'' then 1 else 0 end),'''') FROM APM_CurrentStatusOfApplication a )
union all (select ''Unmanaged''    ,concat(sum(case when a.Availability=27 then 1 else 0 end),'''') FROM APM_CurrentApplicationStatus a )
union all (select 
''Not Licensed''
,case when a.c=0 then ''0''
      else concat(a.c,'' < Critical'') end
	  as [c]
from (
select concat(sum(case when a.ApplicationAvailability=''Not Licensed'' then 1 else 0 end),'''') as [c] FROM APM_CurrentStatusOfApplication a
) a )
union all (select ''=== Component Status ==='', '''' )
union all (select ''TOTAL''        ,concat(count(*),'''') FROM APM_CurrentComponentStatus a )
union all (select ''Up''           ,concat(sum(case when Availability=1 then 1 else 0 end),'''') FROM APM_CurrentComponentStatus )
union all (select ''Down''         ,concat(sum(case when Availability=2 then 1 else 0 end),'''') FROM APM_CurrentComponentStatus )
union all (select ''Critical''     ,concat(sum(case when Availability=6 then 1 else 0 end),'''') FROM APM_CurrentComponentStatus )
union all (select ''Warning''      ,concat(sum(case when Availability=3 then 1 else 0 end),'''') FROM APM_CurrentComponentStatus )
union all (select ''Unknown''      ,concat(sum(case when Availability=0 then 1 else 0 end),'''') FROM APM_CurrentComponentStatus )
union all (select ''Unmanaged''    ,concat(sum(case when Availability=27 then 1 else 0 end),'''') FROM APM_CurrentComponentStatus )

union all (select ''=== AppInsight ==='', '''' )
union all SELECT ''Active DIrectory'', concat(isnull(count(*),0),'''') FROM APM_Application a
join APM_ApplicationTemplate at on at.id=a.TemplateID
where at.name=''AppInsight for Active Directory'' and at.CustomApplicationType like ''ab%''
union all SELECT concat(''   '',csa.ApplicationAvailability), concat(isnull(count(*),0),'''') FROM APM_Application a
join APM_ApplicationTemplate at on at.id=a.TemplateID
join APM_CurrentStatusOfApplication csa on csa.ApplicationID=a.ID
where at.name=''AppInsight for Active Directory'' and at.CustomApplicationType like ''ab%''
group by csa.ApplicationAvailability

union all SELECT ''Exchange'', concat(isnull(count(*),0),'''') FROM APM_Application a
join APM_ApplicationTemplate at on at.id=a.TemplateID
where at.name=''AppInsight for Exchange'' and at.CustomApplicationType like ''ab%''
union all SELECT concat(''   '',csa.ApplicationAvailability), concat(isnull(count(*),0),'''') FROM APM_Application a
join APM_ApplicationTemplate at on at.id=a.TemplateID
join APM_CurrentStatusOfApplication csa on csa.ApplicationID=a.ID
where at.name=''AppInsight for Exchange'' and at.CustomApplicationType like ''ab%''
group by csa.ApplicationAvailability

union all SELECT ''IIS'', concat(isnull(count(*),0),'''') FROM APM_Application a
join APM_ApplicationTemplate at on at.id=a.TemplateID
where at.name=''AppInsight for IIS'' and at.CustomApplicationType like ''ab%''
union all SELECT concat(''   '',csa.ApplicationAvailability), concat(isnull(count(*),0),'''') FROM APM_Application a
join APM_ApplicationTemplate at on at.id=a.TemplateID
join APM_CurrentStatusOfApplication csa on csa.ApplicationID=a.ID
where at.name=''AppInsight for IIS'' and at.CustomApplicationType like ''ab%''
group by csa.ApplicationAvailability

union all SELECT ''SQL'', concat(isnull(count(*),0),'''') FROM APM_Application a
join APM_ApplicationTemplate at on at.id=a.TemplateID
where at.name=''AppInsight for SQL'' and at.CustomApplicationType like ''ab%''

union all SELECT concat(''   '',csa.ApplicationAvailability), concat(isnull(count(*),0),'''') FROM APM_Application a
join APM_ApplicationTemplate at on at.id=a.TemplateID
join APM_CurrentStatusOfApplication csa on csa.ApplicationID=a.ID
where at.name=''AppInsight for SQL'' and at.CustomApplicationType like ''ab%''
group by csa.ApplicationAvailability



union all (select ''=== Componets by Poller ==='', '''' )
--union all (select a.Poller, concat(''Licenses['',sum(a.LICENSES),'']  TotalComponents['', sum(a.totalComponents),'']'') as [TotalComponents]
union all (select a.Poller, concat(sum(a.totalComponents),'''') as [TotalComponents]
from (
SELECT
e.ServerName as [Poller]
,CASE WHEN t.CustomApplicationType = ''ABXA'' THEN ''50''
      WHEN t.CustomApplicationType = ''ABSA'' THEN ''50''
      WHEN t.CustomApplicationType = ''ABIA'' THEN ''30''
      WHEN t.CustomApplicationType = ''ABTA'' THEN ''5''
 ELSE COUNT(c.ID) END AS [Licenses]
,COUNT(c.ID) as [totalComponents]
FROM APM_Component c
left join APM_Application a on c.ApplicationID=a.ID-- and c.IsDisabled is null
left join APM_ApplicationTemplate t on t.ID=a.TemplateID
left join nodes n on n.nodeid=a.NodeID
left join engines e on e.EngineID=n.EngineID
WHERE a.unmanaged =0 and (c.IsDisabled is null)
group by a.name, t.CustomApplicationType, e.ServerName, n.caption, n.EngineID
) a
group by a.poller
)

union all (select ''=== SAM CREDENTIALS SUMMARY ==='' , '''' )
union all SELECT ''TOTAL'', concat(count(*),'''') as [x] FROM (
          select Name from  Credential c
          left join APM_ComponentSetting cs on cs.value=c.id and [key]=''__CredentialSetId''
          where c.CredentialOwner=''APM'' group by c.name
          ) a

union all SELECT ''Used'', concat(sum(case when a.c > 0 then 1 else 0 end),'''') as [x] FROM (
          select c.Name ,concat(sum(case when cs.value is not null then 1 else 0 end),'''') as [c] from  Credential c
          left join APM_ComponentSetting cs on cs.value=c.id and [key]=''__CredentialSetId''
          where c.CredentialOwner=''APM'' group by c.name
          ) a

--union all (select c.Name ,concat(sum(case when cs.value is not null then 1 else 0 end),'''') as [c] from  Credential c
--left join APM_ComponentSetting cs on cs.value=c.id and [key]=''__CredentialSetId''
--where c.CredentialOwner=''APM'' group by c.name )

union all (select ''=== SAM Retention ==='', '''' )
union all (select ''Detailed''          ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days  <'',defaultvalue)  end FROM APM_Config a where a.Name=''RetainDetail'')
union all (select ''Hourly''            ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days  <'',defaultvalue) end FROM APM_Config a where a.Name=''RetainHourly'')
union all (select ''Daily''             ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days  <'',defaultvalue) end FROM APM_Config a where a.Name=''DataRetention'')
union all (select ''Event Log''         ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days  <'',defaultvalue) end FROM APM_Config a where a.Name=''DataRetentionEventLog'')
union all (select ''=== SAM AppInsight for SQL ==='', '''' )
union all (select ''Detached DBs''      ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days <'',defaultvalue) end FROM APM_Config a where a.Name=''SQLBB_RetainDetachedDBDays'')
union all (select ''Detail Tables''     ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days <'',defaultvalue) end FROM APM_Config a where a.Name=''SQLBB_RetainDetailTablesDays'')
union all (select ''History''           ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days <'',defaultvalue) end FROM APM_Config a where a.Name=''SQLBB_RetainHistoryDays'')
union all (select ''=== SAM AppInsight for Exchange ==='', '''' )
union all (select ''Deleted DBs''       ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days <'',defaultvalue) end FROM APM_Config a where a.Name=''EXBB_RetainDeletedDBDays'')
union all (select ''Detial Tables''     ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days <'',defaultvalue) end FROM APM_Config a where a.Name=''EXBB_RetainDetailTablesDays'')
union all (select ''Mailbox History''   ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days <'',defaultvalue) end  FROM APM_Config a where a.Name=''EXBB_RetainMailboxHistoryDays'')
union all (select ''=== SAM AppInsight for IIS ==='' , '''' )
union all (select ''Detail Tables''     ,case when value=defaultvalue then concat(value,'' days'') else concat(value,'' days <'',defaultvalue) end FROM APM_Config a where a.Name=''IISBB_RetainDetailTablesDays'')

--union all (select ''=== SAM CREDENTIALS  ==='' , '''' )
--union all (select tmp.Name ,concat(''Nodes:'',isnull(sum([total nodes]),''''), ''  Components:'',isnull(sum([total com]),''''))
--           from (select ''SAM Appliaction Monitors'' as c,a.Name,count(a.name) as ''Total Nodes''
--		   ,(select count(id) from APM_Component c where c.ApplicationID=a.ID) as ''Total Com'' from APM_Application a group by a.name, a.id) tmp 
--            group by tmp.c, tmp.name )
'
--********************************************************************************
--  SAM - end
--********************************************************************************


--********************************************************************************
--  NCM - start
--********************************************************************************
SET @NCM = 
'
union all select '''',''''
union all select '''',''''
union all (select ''****  NCM  ****'','''' )
union all (select ''****  NCM  ****'','''' )
union all (select ''TOTAL'', concat(COUNT(*),'''') FROM NCM_Nodes )
union all (select vendor, concat(isNULL(COUNT(*),0),'''') FROM NCM_Nodes group by vendor)
union all (select ''===  CONFIG ARCHIEV FOLDER  ==='','''' )
union all SELECT concat(e.ServerName,''''), case when settingvalue like ''%solarwinds%'' then ''SW folder'' else ''non SW folder'' end FROM NCM_NCMSettings s join engines e on e.EngineID=s.EngineID where SettingName=''Config-Archive Directory''
--union all SELECT concat(e.ServerName,''''), convert(varchar(300), settingvalue) FROM NCM_NCMSettings s join engines e on e.EngineID=s.EngineID where SettingName=''Config-Archive Directory''

union all (select ''****  Connection Profile  ****'','''' )
union all (select a.profilename , concat(isNULL(count(*),0),'''') as [v] from
             (select top 100 case when ncm.ConnectionProfile = 0 then ''No Profile''
                                  when ncm.ConnectionProfile < 0 then ''Deleted Profile''
	                              when ncm.ConnectionProfile > 0 then p.name
	                         end as [profilename]
               from NCM_nodes ncm
               left join NCM_ConnectionProfiles p on p.id=ncm.ConnectionProfile order by 1) a
            group by a.profilename
          )

union all (select ''===  Startup vs running  ===='','''' )
union all (SELECT  ''No Conflict''
                  ,concat(isnull(sum (case when cr.diffflag=0 and cr.ComparisonType=1 then 1 else 0 end),0),'' ('',round((sum (case when cr.diffflag=0 and cr.ComparisonType=1 then 1 else 0 end)*100)/((SELECT count(*) as [Total Nodes] FROM NCM_NodeProperties))+0.5,0),''%)'') as [No Conflict] 
                  FROM NCM_NodeProperties cn 
                  left join NCM_LatestComparisonResults cr on cr.nodeid=cn.NodeID )
union all (SELECT ''Conflict''
                  ,concat(isnull(sum (case when cr.diffflag=1 and cr.ComparisonType=1 then 1 else 0 end),0),'' ('',round((sum (case when cr.diffflag=1 and cr.ComparisonType=1 then 1 else 0 end)*100)/((SELECT count(*) as [Total Nodes] FROM NCM_NodeProperties))+0.5,0),''%)'') as [Conflict] 
                   FROM NCM_NodeProperties cn 
                  left join NCM_LatestComparisonResults cr on cr.nodeid=cn.NodeID )
union all (SELECT ''Unknown''
                  ,concat(isnull((SELECT count(*) as [Total Nodes] FROM NCM_NodeProperties cn)-sum(case when cr.ComparisonType=1  then 1 else 0 end),0),'' ('',round((((SELECT count(*) as [Total Nodes] FROM NCM_NodeProperties cn) - sum(case when cr.ComparisonType=1  then 1 else 0 end))*100)/(SELECT count(*) as [Total Nodes] FROM NCM_NodeProperties cn),0),''%)'') as [Unknown] 
                  FROM NCM_NodeProperties cn 
                  left join NCM_LatestComparisonResults cr on cr.nodeid=cn.NodeID )
union all (select ''===  Overall Devices  ==='','''')
union all (select ''Backedup''
                   ,concat(isnull(sum (case when cr.ComparisonType=3 then 1 else 0 end),0),'' ('',round((sum (case when cr.ComparisonType=3 then 1 else 0 end)*100)/((SELECT count(*) as [Total Nodes] FROM NCM_NodeProperties))+0.5,0),''%)'') as [No Conflict] 
                   FROM NCM_NodeProperties cn 
                   left join NCM_LatestComparisonResults cr on cr.nodeid=cn.NodeID )
union all (SELECT  ''not Backedup''
                   ,concat(isnull((SELECT count(*) as [Total Nodes] FROM NCM_NodeProperties cn)-sum(case when cr.ComparisonType=3  then 1 else 0 end),0),'' ('',round((((SELECT count(*) as [Total Nodes] FROM NCM_NodeProperties cn) - sum(case when cr.ComparisonType=1  then 1 else 0 end))*100)/(SELECT count(*) as [Total Nodes] FROM NCM_NodeProperties cn),0),''%)'') as [Unknown] 
                   FROM NCM_NodeProperties cn 
                   left join NCM_LatestComparisonResults cr on cr.nodeid=cn.NodeID )
union all (select ''=== Inventoried  ==='','''' )
union all (SELECT  ''Inventoried'',concat(isnull(count(*)-isnull((SELECT count(*) as [t] FROM NCM_Nodes where datediff(dd,LastInventory ,getdate())>365),''0''),''0''),'''')  from ncm_nodes)
union all (SELECT  ''Not Inventoried'',concat(isnull((SELECT count(*) as [t] FROM NCM_Nodes where datediff(dd,LastInventory ,getdate())>365),''0''),''''))
union all (select ''===  NCM JOBS  ==='','''' )
union all (SELECT  concat(NCMJobName,''''), concat(DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), [LastDateRunUtc]),'''')  FROM NCM_NCMJobs where enabled=1  group by NCMJobName,LastDateRunUtc ) 

--convert(sql_variant, concat(''ServerType: '',e.servertype,''''))
union all (select ''****  NCM JOBS STATUS ****'','''' )

union all select 
--convert(varchar(4000),(select NCMJobname from NCM_NCMJobs where NCMJOBid=jn.JobId)) as [Job]
--,a.mxdate,jn.JobLog
convert(varchar(4000),l.NCMJobName) as [Job]
,convert(varchar(4000),substring(jn.joblog,CHARINDEX(''Devices:'',jn.joblog),99)) as [e1]
from NCM_JobLogsNodes jn
inner join 
(SELECT [JobId],max([RunDate]) as mxdate
FROM NCM_JobLogsNodes
where NodeID is null and joblog like ''%Download%''
group by jobid
) a on a.JobId=jn.JobId and a.mxdate=jn.RunDate
join NCM_NCMJobsView l on l.ncmJobID=jn.JobId
where jn.NodeID is null and jn.joblog like ''%Download%''


--union all (SELECT
--convert(varchar(4000),NCMJobName) as [Job]
--,convert(varchar(4000),concat(''LastRun: '',convert(varchar, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), LastDateRunUtc),0)
--        ,''        '',a.q) ) as [Error]
--FROM NCM_NCMJobs nj
--join (select 
--a.ncmjobid
--,jv.NCMJobType
--,case when jv.NCMJobType=11 then substring(substring(jl.JobLog,charindex(replace(convert(varchar, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), a.maxrundate) ,101),''/0'',''/'') ,jl.JobLog)+11,999999),charindex(''errors:'',substring(jl.JobLog,charindex(replace(convert(varchar, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), a.maxrundate) ,101),''/0'',''/'') ,jl.JobLog)+11,999999)),11) 
--      when jv.NCMJobType=7    then concat(''Errors: '',(DATALENGTH(substring(jl.JobLog,charindex(replace(convert(varchar, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), a.maxrundate) ,101),''/0'',''/'') ,jl.JobLog)+11,999999))-DATALENGTH(REPLACE(substring(jl.JobLog,charindex(replace(convert(varchar, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), a.maxrundate) ,101),''/0'',''/'') ,jl.JobLog)+11,999999),'' error: '','''')))/DATALENGTH('' error: '')/2) 
--	  when jv.NCMJobType=10   then ''-''
--      end as [q]
--from NCM_JobLogs jl
--join (SELECT NCMJobId,max(RunDate) as [MaxRunDate] FROM NCM_JobLogs group by ncmjobid) a on a.NCMJobId=jl.NCMJobId and a.MaxRunDate=jl.RunDate
--join NCM_NCMJobsView jv on jv.NCMJobID=jl.NCMJobId
--) a on a.NCMJobId=nj.NCMJobID
--where enabled=1
--)

union all (select ''****  Custom Device Templates ****'','''' )
union all SELECT ''Custom Device Templates'', concat(isnull(count(*),0),'''') FROM Cli_DeviceTemplates where author <> ''SolarWinds''

union all (select ''****  NCM Compliance ****'','''' )
union all select 
          report
		  ,concat(''Info['',info,'']  warn['',warn,'']  crit['',crit,'']'') as [v]
          from
          (SELECT top 100 ReportName as [report]
                  ,sum(isNULL(case when ErrorLevel=0 and IsViolation=1 then 1 end,0)) as [info]
				  ,sum(isNULL(case when ErrorLevel=1 and IsViolation=1 then 1 end,0)) as [warn]
				  ,sum(isNULL(case when ErrorLevel=2 and IsViolation=1 then 1 end,0)) as [crit]
           FROM NCM_PolicyCacheResults
           group by ReportName 
		   order by 4 desc, 3 desc, 2 desc
		   ) a

union all (select ''****  FIRMWARE VULNERABILITIES  ****'','''' )
union all (SELECT ''Number of CVEs'', concat(isNULL(count(*),0),'''') as [x] FROM NCM_VulnerabilitiesAnnouncements y )
union all select severity , concat(isnull(count(corenodeid),0),'''') as [Nodes Affected] from (
    SELECT distinct top 1000 case when score>=7 then ''High'' when score>=4 and score <7 then ''Medium'' when score>=0 and score <4 then ''low'' end as [Severity]
	,v.corenodeid FROM NCM_VulnerabilitiesAnnouncements y
    join NCM_VulnerabilitiesAnnouncementsNodes v on v.EntryId =y.EntryId 
    group by v.CoreNodeID, y.score
    order by CoreNodeID
    ) a
group by a.severity

union all SELECT ''RTCN'', case when SettingValue=''true'' then ''enabled'' else ''disabled'' end FROM NCM_NCMSettings where SettingName=''Real-Time Notifications''
union all select ''Change Approval'', case when settingvalue=''true'' then ''Enable'' else ''disabled'' end  from ncm_ncmsettings where settingname=''ConfigChangeApprovalEnabled''
'
--********************************************************************************
--  NCM - end
--********************************************************************************

--********************************************************************************
--  IPAM - Start
--********************************************************************************
SET @IPAM =
'
union all (select '''','''')
union all (select '''','''')
union all (select ''****  IPAM  ****'','''')
union all (select ''****  IPAM  ****'','''')
union all (select ''=== IPAM Servers ==='','''')
union all (select  ''IPAM: DHCP Servers'', concat(count(*),'''')  as [x] from IPAM_DhcpServerDetails dhcp join nodes n on n.nodeid=dhcp.NodeId)
union all (SELECT concat(n.caption,'' ('',n.IP_Address,'')'') as [s], concat(''Scopes: '',(select count(*) as [x] from IPAM_DhcpScopeDetails ii where ii.NodeId=d.nodeid)) 
FROM IPAM_DhcpServerDetails d join nodes n on n.nodeid=d.nodeid group by n.caption, n.IP_Address, d.NodeId)
union all (select  ''IPAM: DHCP Scopes'', concat(count(*),'''')  as [x] from IPAM_DhcpScopeDetails dhcp join nodes n on n.nodeid=dhcp.NodeId)
union all (select  ''IPAM: DNS Servers'', concat(count(*),'''')  as [x] from IPAM_DnsServerDetails dns join nodes n on n.nodeid=dns.NodeId)
union all (SELECT concat(n.caption,'' ('',n.IP_Address,'')'') as [s], concat(''Zones: '',(select count(*) as [x] from IPAM_DnsZoneDetails ii where ii.nodeid=d.nodeid)) 
FROM IPAM_DnsServerDetails d join nodes n on n.nodeid=d.nodeid group by n.caption, n.IP_Address, d.NodeId)
union all (select  ''IPAM: DNS Zones'', concat(count(*),'''')  as [x] from IPAM_DnsZoneDetails dns join nodes n on n.nodeid=dns.NodeId )
union all (select ''=== IPAM Elements ==='','''' )
union all (select a.* from (select top 100 concat(igt.GroupType,'''') as [c],concat(count(ig.GroupType),'''') as [Count] FROM IPAM_Group ig join IPAM_GroupType igt on igt.GroupTypeId=ig.GroupType where igt.GroupType not like ''DNS%'' and igt.GroupType not like ''DHCP%'' group by igt.GroupTypeId,igt.GroupType order by igt.GroupTypeId) a )
union all (select ''=== IPAM CIDR ==='','''' )
union all (select * from (SELECT top 100 concat(''CIDR: '',CIDR) as [c], concat(count(*),'''') as [x] FROM IPAM_Group group by cidr order by cidr) tmp  group by tmp.c, tmp.x)
union all (select ''=== IPAM Scan Interval ==='','''' )
union all (SELECT ''scan interval'', concat(scaninterval,'' minutes on '',count(scaninterval),'' networks'') as [count] FROM IPAM_Group where status=1 and ScanInterval>0 group by ScanInterval )
union all (select ''=== IP Address Conflicts ==='','''' )
union all (select ''IP Address Conflicts'', concat(isNULL(count(*),0),'''') as [d] from IPAM_IPConflict where datediff(day,LastSeenUTC,getutcdate())=0 group by ipnodeid )
union all (select ''=== DNS Records Mismatch ==='','''' )
union all (select ''DNS Records Mismatch'', concat(isNULL(count(*),0),'''') as [d] from IPAM_DNSMismatch )
union all (select ''=== IP Networks ==='','''' )
--union all (SELECT IPStatusText, concat(count(*),'' ('',round(count(*)*100/(select count(*) as [x] from IPAM_IPInfo),0),''%)'') as [x] FROM IPAM_IPInfo WITH (nolock) group by IPStatusText)
union all (select ''=== DNS Records Mismatch ==='','''' )
union all (select ''DNS Records Mismatch'', concat(isNULL(count(*),0),'''') as [d] from IPAM_DNSMismatch )
union all (select ''=== Discovered Subnets folder ==='','''' )
union all (
select ''Discovered Subnets'',count(*)
from IPAM_group
where ParentID = (SELECT groupid as [d] FROM IPAM_Group where friendlyname like ''dp %'' and (grouptype=1 or parentid=0))
)


union all (select ''=== Settings ==='','''' )
union all SELECT
case when name=''ScanSetting.SnmpEnableNeighborScanning'' then ''Enable Neighbor Scanning''
     when name=''ScanSetting.SimultaneousScans'' then ''Simultaneous Scans''
     when name=''SystemSetting.EnableDuplicatedSubnets'' then ''Enable Duplicated Subnets''
     end as [s]
,case when Value=''true'' then ''YES''
      when Value=''false'' then ''NO''
	  else concat(value,'''') end as [v]
  FROM IPAM_Setting
  where name in (''ScanSetting.SnmpEnableNeighborScanning'',''ScanSetting.SimultaneousScans'',''SystemSetting.EnableDuplicatedSubnets'')
'
--********************************************************************************
--  IPAM - end
--********************************************************************************

--********************************************************************************
--  UDT - start
--********************************************************************************
SET @UDT =
'
union all select '''',''''
union all (select '''','''')
union all (select ''****  UDT  ****'','''')
union all (select ''****  UDT  ****'','''')
union all (select ''=== UDT PORTS TOTAL ===='','''')
union all (SELECT e.servername, concat(isnull(count(*),0),'''') FROM udt_port u join nodes n on n.nodeid=u.nodeid join engines e on e.EngineID=n.EngineID group by e.ServerName)

union all (select ''=== UDT PORTS MONITORED ===='','''')
union all (SELECT e.servername, concat(isnull(count(*),0),'''') FROM udt_port u join nodes n on n.nodeid=u.nodeid join engines e on e.EngineID=n.EngineID where u.IsMonitored=1 group by e.ServerName)

union all (select ''=== UDT PORTS MONITORED BY VENDOR ===='','''')
union all select  n.vendor, concat(isNULL(count(*),0),'''') as [x] from UDT_Port p join nodes n on n.nodeid=p.nodeid where IsMonitored=1 and ismissing=0 group by n.vendor

union all (select ''=== ENDPOINT Vendors ===='','''')
union all (select * from (select top 100 vendor, concat(isNULL(count(*),0),'''') as [x] from udt_endpoint where vendor is not NULL group by vendor order by count(*) desc) a)

union all (select ''=== UDT DOMAIN CONTROLLERS ===='','''')
union all (
SELECT DISTINCT 
n.Caption as [DCName]
, case when j.JobLastResult=1 then ''Polling ok''
       when j.JobLastResult=2 then ''Polling failed''
	   end
	   as [DCPollingStatus]
FROM    udt_NodeCapability  nc
INNER JOIN Nodes  n ON nc.NodeID = n.NodeID
INNER JOIN NodeSettings ns ON nc.NodeID = ns.NodeID AND SettingName = ''UDTCredential''
INNER JOIN Credential c ON ns.SettingValue = c.ID
LEFT JOIN UDT_Job j ON j.NodeID = nc.NodeID AND j.JobType=5
WHERE nc.Capability=8 
--ORDER BY DCName ASC --WITH ROWS 1 To 10 RETURN XML RAW
)

union all (select ''=== UDT Whitelist ALL ===='','''')
union all (select concat(name,''''), concat(case when Enabled=1 then ''Enabled'' else ''Disabled'' end,'''') as whitelist from udt_rule u where RuleType like ''WhiteList'' group by u.name, u.enabled)

union all (select ''=== UDT Watchlist ===='','''')
union all (select concat(WatchName,''''), concat(count(*),'''') from UDT_WatchList group by watchname)

union all (select ''=== UDT Devices ===='','''')
union all (select ''Rouge'', concat(count(*),'''') as r from udt_endpoint u where u.Rogue=1)

union all (select ''=== UDT Polling Intervals ===='','''')
union all (select ''Layer 2'',  case when settingvalue=defaultvalue then concat(SettingValue,'''') else concat(SettingValue,'' < '',defaultvalue) end from UDT_Setting where SettingName=''UDT.DefaultPollingInterval.Layer2'')
union all (select ''Layer 3'',  case when settingvalue=defaultvalue then concat(SettingValue,'''') else concat(SettingValue,'' < '',defaultvalue) end   from UDT_Setting where SettingName=''UDT.DefaultPollingInterval.Layer3'')
union all (select ''Domain COntroller'',  case when settingvalue=defaultvalue then concat(SettingValue,'''') else concat(SettingValue,'' < '',defaultvalue) end   from UDT_Setting where SettingName=''UDT.DefaultPollingInterval.DomainCOntroller'')

union all (select ''=== UDT Data Rentition ===='','''')
union all (select ''Detail'', case when settingvalue=defaultvalue then concat(SettingValue,'''') else concat(SettingValue,'' < '',defaultvalue) end from UDT_Setting where SettingName=''Data-Retention-Statistics-Detail'')
union all (select ''Hourly'', case when settingvalue=defaultvalue then concat(SettingValue,'''') else concat(SettingValue,'' < '',defaultvalue) end from UDT_Setting where SettingName=''Data-Retention-Statistics-Hourly'')
union all (select ''Daily'', case when settingvalue=defaultvalue then  concat(SettingValue,'''') else concat(SettingValue,'' < '',defaultvalue) end from UDT_Setting where SettingName=''Data-Retention-Statistics-Daily'')
'
--********************************************************************************
--  UDT - end
--********************************************************************************

--********************************************************************************
--  VNQM - start
--********************************************************************************
SET @VNQM =
'
union all select '''',''''
union all select '''',''''
union all (select ''****  VNQM  ****'','''')
union all (select ''==== IPSLA Elements ===='','''')
union all (SELECT top 1 ''TOTAL nodes'', concat((select count(distinct sourcenodeid) from voipoperations),'''') FROM VoIPOperations )
union all SELECT ''TOTAL Operations'', concat(count(*),'''') FROM VoIPOperationCurrentStats
union all select ''Up'', concat(sum(case when VoipOperationStatusID=1 then 1 else 0 end),'''') FROM VoIPOperationCurrentStats
union all select ''Warning'', concat(sum(case when VoipOperationStatusID=3 then 1 else 0 end),'''') FROM VoIPOperationCurrentStats
union all select ''Critical'', concat(sum(case when VoipOperationStatusID=14 then 1 else 0 end),'''') FROM VoIPOperationCurrentStats
union all select ''Down'', concat(sum(case when VoipOperationStatusID=2 then 1 else 0 end),'''') FROM VoIPOperationCurrentStats
union all select ''Unknown'', concat(sum(case when VoipOperationStatusID=0 then 1 else 0 end),'''') FROM VoIPOperationCurrentStats
union all select ''Unmanaged'', concat(sum(case when VoipOperationStatusID=9 then 1 else 0 end),'''') FROM VoIPOperationCurrentStats
union all (select ''==== IPSLA Operations ===='','''')
union all (SELECT OperationType, concat(count(OperationType),'''') from VoIPOperations group by OperationType)
union all (select ''==== Call Manager ===='','''')
union all (SELECT ''Voice Sites'', concat(count(voipSiteID),'''') as [Sites] FROM voipSites)
union all (SELECT ''Call Manager'', concat(isnull(count(*),0),'''') as [c] FROM VoipCallManagerDetails where CallManagerType=''Cisco Call Manager'')
union all (select ''Voice Gateways'', concat(count(NodeID),'''') FROM VoipGateways)
union all (select ''==== AVAYA ===='','''')
union all (SELECT ''Voice Sites'', concat(count(voipSiteID),'''') as [Sites] FROM voipSites)
union all (SELECT ''Call Manager'', concat(isnull(count(*),0),'''') as [c] FROM VoipCallManagerDetails where CallManagerType=''Cisco Call Manager'')
union all (select ''Voice Gateways'', concat(count(NodeID),'''') FROM VoipGateways)
union all (select ''==== VoIP Polling ===='','''')
union all (SELECT  ''Voice Gateway Polling'', concat(case when value is NULL then defaultvalue else concat(value,'' <'',defaultvalue) end,'' mins'') from VoipConfig where name=''VoipGatewayPollingIntervalMinutes'' group by value, DefaultValue)
union all (SELECT  ''Call Manager Polling'', concat(case when value is NULL then defaultvalue else concat(value,'' <'',defaultvalue) end,'' mins'') from VoipConfig where name=''CCMPollingIntervalMinutes'' group by value, DefaultValue)
union all (select ''==== VNQM Retention ===='','''')
union all (SELECT  name, concat(case when value is NULL then defaultvalue else concat(value,'' <'',defaultvalue) end,'' days'') from VoipConfig where name like ''%retention%'' group by value, DefaultValue, name)
'
--********************************************************************************
--  VNQM - end
--********************************************************************************

--********************************************************************************
--  WPM - start
--********************************************************************************
SET @WPM =
'
union all select '''','''' 
union all select '''',''''  
union all (select ''****  WPM  ****'','''' )
union all (select ''****  WPM  ****'','''' )
union all (select ''=== Transactions ==='','''' )
union all (SELECT ''TOTAL'', concat((select count(*) FROM SEUM_Transactions),'''') )
union all (SELECT ''Up'', concat((select sum(case when LastStatus=1 then 1 else 0 end) FROM SEUM_Transactions),'''') )
union all (SELECT ''Warning'', concat((select sum(case when LastStatus=3 then 1 else 0 end) FROM SEUM_Transactions),'''') )
union all (SELECT ''Critical'', concat((select sum(case when LastStatus=14 then 1 else 0 end) FROM SEUM_Transactions),'''') )
union all (SELECT ''Down'', concat((select sum(case when LastStatus=2 then 1 else 0 end) FROM SEUM_Transactions),'''') )
union all (SELECT ''Unknown'', concat((select sum(case when LastStatus=0 then 1 else 0 end) FROM SEUM_Transactions),'''') )
union all (SELECT ''UnManage'', concat((select sum(case when LastStatus=9 then 1 else 0 end) FROM SEUM_Transactions),'''') )

----union all (SELECT ''Transactions'', concat(''TOTAL('',(select count(*) FROM SEUM_Transactions),
----           '') Unk('',(select sum(case when LastStatus=0 then 1 else 0 end) FROM SEUM_Transactions),
----		   '') Up('',(select sum(case when LastStatus=0 then 1 else 0 end) FROM SEUM_Transactions),
----		   '') Warn('',(select sum(case when LastStatus=3 then 1 else 0 end) FROM SEUM_Transactions),
----		   '') Critical('',(select sum(case when LastStatus=14 then 1 else 0 end) FROM SEUM_Transactions),
----		   '') Down('',(select sum(case when LastStatus=2 then 1 else 0 end) FROM SEUM_Transactions),
----		   '') Unmanage('',(select sum(case when LastStatus=9 then 1 else 0 end) FROM SEUM_Transactions),'')'')
----           )
----union all (SELECT ''Steps'', concat(''TOTAL('',(select count(*) FROM SEUM_TransactionSteps),
----           '') Unk('',(select sum(case when LastStatus=0 then 1 else 0 end) FROM SEUM_TransactionSteps),
----		   '') Up('',(select sum(case when LastStatus=0 then 1 else 0 end) FROM SEUM_TransactionSteps),
----		   '') Warn('',(select sum(case when LastStatus=3 then 1 else 0 end) FROM SEUM_TransactionSteps),
----		   '') Critical('',(select sum(case when LastStatus=14 then 1 else 0 end) FROM SEUM_TransactionSteps),
----		   '') Down('',(select sum(case when LastStatus=2 then 1 else 0 end) FROM SEUM_TransactionSteps),
----		   '') Unmanage('',(select sum(case when LastStatus=9 then 1 else 0 end) FROM SEUM_TransactionSteps),'')'')
----		   )
union all (select ''=== Steps ==='','''' )
union all (SELECT ''TOTAL'', concat((select count(*) FROM SEUM_TransactionSteps),'''') )
union all (SELECT ''Up'', concat((select sum(case when LastStatus=1 then 1 else 0 end) FROM SEUM_TransactionSteps),'''') )
union all (SELECT ''Warning'', concat((select sum(case when LastStatus=3 then 1 else 0 end) FROM SEUM_TransactionSteps),'''') )
union all (SELECT ''Critical'', concat((select sum(case when LastStatus=14 then 1 else 0 end) FROM SEUM_TransactionSteps),'''') )
union all (SELECT ''Down'', concat((select sum(case when LastStatus=2 then 1 else 0 end) FROM SEUM_TransactionSteps),'''') )
union all (SELECT ''Unknown'', concat((select sum(case when LastStatus=0 then 1 else 0 end) FROM SEUM_TransactionSteps),'''') )
union all (SELECT ''UnManage'', concat((select sum(case when LastStatus=9 then 1 else 0 end) FROM SEUM_TransactionSteps),'''') )
union all (select ''=== Transaction Monitors ==='','''')
union all (SELECT [Name],    concat(LastPlayed,'''') FROM [SEUM_TransactionsReportsView])
union all (select ''=== Recording ==='','''' )
union all (SELECT r.name,cast(t.LastStatus as varchar)  FROM SEUM_Recordings r left join SEUM_TransactionsReportsView t on t.RecordingId=r.RecordingId group by r.name, t.LastStatus )
union all (select ''=== Player Load ==='','''' )
union all (SELECT concat(name, ''('',LoadPercentage,''% load)''), cast(ConnectionStatusMessage as varchar) FROM SEUM_Agents group by name, LoadPercentage, ConnectionStatusMessage )
union all (select ''=== Alerts ==='','''' )
union all select ''Total'', concat(isNULL(count(*),0),'''') from AlertDefinitionsView where objecttype in (''transaction'',''player'',''step'')
union all select ''Enabled'', concat(isNULL(count(*),0),'''') from AlertDefinitionsView where objecttype in (''transaction'',''player'',''step'') and enabled=1

union all (select ''=== Retention ==='','''' )
union all (SELECT ''Detail'', cast(value as varchar) from SEUM_Settings where name=''RetainDetail'' group by value )
union all (SELECT ''Hourly'', cast(value as varchar) FROM SEUM_settings where name=''RetainHourly'' group by value )
union all (SELECT ''Daily'', cast(value as varchar) from SEUM_settings where name=''RetainDaily'' group by value )
union all (SELECT ''Screenshoots'', cast(value as varchar) FROM SEUM_settings where name=''RetainScreenshots'' group by value )
'
--********************************************************************************
--  WPM - end
--********************************************************************************


--********************************************************************************
--  NTA - start
--********************************************************************************
SET @NTA =
'
union all select '''',''''
union all select '''',''''
union all (select ''****  NTA  ****'','''')
union all (select ''****  NTA  ****'','''' )
union all (select ''=== NTA Sources ==='','''' )
union all (select ''Nodes'',concat((SELECT COUNT(DISTINCT isNULL(NodeID,0)) from Netflow_AllNetFlowSources with (nolock) where enabled=1),'''') )
union all (select ''Interfaces'',concat((SELECT COUNT(isnull(NetflowSourceID,0)) from Netflow_AllNetFlowSources with (nolock) where enabled=1),'''') )
--union all (select ''Stale Sources'',concat(COUNT(isNULL(NodeID,0)) ,'''') FROM Netflow_AllNetFlowSources  where dateDIFF(dd,LastTime,GETDATE())>1)
union all (select ''=== NTA Flows (last 5 mins)==='','''')
union all (SELECT concat(ServerName,''''),concat(StatisticsValue,'''') FROM NetFlowEnginesStatistics with (nolock) JOIN engines with (nolock) on NetFlowEnginesStatistics.EngineID = Engines.EngineID  where StatisticsName=''FlowsPerSecondForLast5Minutes'' group by servername, StatisticsName, StatisticsValue)
union all (select ''=== NTA IP Address Groups ==='','''')
union all (select ''IP Groups'',concat((SELECT COUNT(IPGroupID) as [Groups] FROM  NetFlowIPGroups with (nolock) ),''''))
union all SELECT ''=== NetFlow Management ==='', ''''  
union all SELECT ''Enable automatic addition of NetFlow sources'', case when value=1 then ''Checked'' else ''unchecked   <====='' end FROM [NetFlowGlobalSettings] with (nolock) where description=''Automatically add sources to NTA''
union all SELECT ''Allow monitoring of flows from unmonitored ports'', case when value=1 then ''Checked'' else ''unchecked   <====='' end FROM [NetFlowGlobalSettings] with (nolock) where description=''Retain data for traffic designated as "other".''  
union all SELECT ''Allow monitoring of flows from unmanaged interfaces'', case when value=1 then ''Checked'' else ''unchecked   <====='' end FROM [NetFlowGlobalSettings] with (nolock) where description=''Allow monitoring of flows from unmanaged interfaces''  
union all SELECT ''Allow matching nodes by another IP Address'', case when value=1 then ''Checked'' else ''unchecked   <====='' end FROM [NetFlowGlobalSettings] with (nolock) where description=''Match nodes also by IP addresses from the table NodeIPAddress, otherwise only by IP Address from Nodes table is flow matched.''  
union all SELECT ''Show notification bar for unknown traffic events'', case when value=1 then ''Checked'' else ''unchecked   <====='' end FROM [NetFlowGlobalSettings] with (nolock) where description=''Determines if NTA shows notification bar for UTN events or not. Default is true.''  
union all SELECT ''Process IPv6 flow data'', case when value=1 then ''Checked'' else ''unchecked   <====='' end FROM [NetFlowGlobalSettings] where description=''Enables of processing IPv6 Flows.''  
union all SELECT ''Process flow data from Meraki MX 15.13 and earlier.'', case when value=1 then ''Checked'' else ''unchecked   <====='' end FROM [NetFlowGlobalSettings] with (nolock) where description=''Meraki MX Interface Mapping is generated and applied. Not needed with firmware MX 15.14 and newer.''  
--SELECT * FROM [NetFlowGlobalSettings] where value=''0''

union all SELECT ''=== NetFlow Collector Port(KeepAlive) ==='', ''''  
union all SELECT 
concat(e.ServerName,'' ('',e.ServerType,'')'') AS [Server]
,concat(NetFlowPort,'' (ka:'',isNULL(datediff(mi,FlowCollectorKeepAlive,getdate()),0),'')'') as [SinceKeepalive] 
FROM (SELECT FlowCollectorKeepAlive, NetFlowPort, EngineID FROM FlowEngines with (nolock) ) AS fe
LEFT JOIN engines e with (nolock) ON e.EngineID = fe.engineid 

union all SELECT ''=== Top Talker Optimization ==='', ''''  
union all SELECT ''Capture flows based on this maximum percentage of traffic'', case when value<>''95'' then concat(value,'''') else concat(value,''   <====='') end FROM [NetFlowGlobalSettings] with (nolock) where description=''Capture the flows that represent the top [   ]% of total network traffic''    
union all SELECT ''=== CBQoS Polling ==='', ''''  
union all SELECT ''Enable NetBIOS resolution of endpoints'', case when value=1 then ''Checked'' else ''unchecked    <====='' end FROM [NetFlowGlobalSettings] with (nolock) where keyname=''DnsResolverUseNetbiosFunction''    
union all SELECT ''=== DNS and NetBIOS Resolution ==='', ''''  
union all SELECT ''Resolve IPv4 and IPv6 addresses to DNS hostnames'', case when value=1 then ''Checked'' else ''unchecked    <====='' end FROM [NetFlowGlobalSettings] with (nolock) where keyname=''DnsOnDemandEnabled''    
union all SELECT ''Resolve and store IPv4 hostnames immediately when a flow record is received'', case when value=1 then ''Checked'' else ''unchecked    <====='' end FROM [NetFlowGlobalSettings] with (nolock) where keyname=''DnsPersistEnabled''    
union all SELECT ''Default number of days to wait until next DNS lookup'', case when value=7 then concat(value,'''') else concat(value,''    <====='') end FROM [NetFlowGlobalSettings] with (nolock) where keyname=''CacheExpirationDays''    
union all SELECT ''Default number of days to wait until next DNS lookup for unresolved IP Addresses'', case when value=2 then concat(value,'''') else concat(value,''    <====='') end FROM [NetFlowGlobalSettings] with (nolock) where keyname=''CacheExpirationDaysNotResolved''    
union all SELECT ''Number of IP addresses to resolve as a batch'', case when value=50 then concat(value,'''') else concat(value,''    <====='') end FROM [NetFlowGlobalSettings] with (nolock) where keyname=''NameResolver.RowsToFetchForNameResolutionCount''    
union all SELECT ''Interval in seconds between batches'', case when value=50 then concat(value,'''') else concat(value,''    <====='') end FROM [NetFlowGlobalSettings] with (nolock) where keyname=''NameResolver.NameResolverDelay''    
union all SELECT ''Maximum time spent to process IP addresses'', case when value=60 then concat(value,'''') else concat(value,''    <====='') end FROM [NetFlowGlobalSettings] with (nolock) where keyname=''DatabaseMaintenanceMinutesBeforeBailout''    
union all SELECT ''=== Database Settings ==='', ''''  

union all (select ''=== NTA Retention ==='','''')
union all (SELECT ''Retention period'', concat(Value,'' days'') FROM NetFlowGlobalSettings with (nolock) where keyname = ''RetainCompressedDataInDays'' group by value)
'
--********************************************************************************
--  NTA - end
--********************************************************************************

--********************************************************************************
--  VMAN - start
--********************************************************************************
SET @VMAN = 
'
union all select '''','''' 
union all select '''',''''  
union all (select ''****  VMAN  ****'','''' )
union all (select ''****  VMAN  ****'','''' )
union all select ''=== VMAN OVERALL'' as [Description],'''' as [Value]
union all (SELECT ''Number of Host'', concat((select count(*) from VIM_HostNodes with (nolock) ),''''))
union all (SELECT ''TOTAL VMs'', concat(isnull(sum(isnull(vmcount,0)),0),'''') from VIM_HostNodes with (nolock))
union all SELECT ''Running VMs'', concat(isnull(sum(isnull(VmRunningCount,0)),0),'''') from VIM_HostNodes where nodestatus <>2
union all (SELECT ''Physical CPU Cores'', concat((select sum(isnull(CpuCoreCount,0)) from VIM_HostNodes where VmWareProductVersion is not NULL ),''''))
union all (SELECT ''Memory'', concat((select sum(isnull(MemorySize,0))/1024/1024/1024 from VIM_HostNodes where VmWareProductVersion is not NULL ),'' GB''))
union all (select ''=== VMware ===='','''')
union all (SELECT ''Number of DataCenters'', concat((select count(*) from VIM_DataCenters where datacenterid is not NULL ),''''))
union all (SELECT ''Virtual Center'', concat((select count(*) from VIM_VCenterNodes with (nolock) ),''''))
union all (SELECT ''Clusters'', concat((select count(*) from VIM_ClustersView with (nolock) ),''''))
union all (SELECT ''Clustered ESX Hosts'', concat((select count(*) from VIM_HostNodes with (nolock) where VMwareProductName like ''%vmware%'' and ClusterID is not NULL),''''))
union all (SELECT ''non-Clustered ESX Hosts'', concat((select count(*) from VIM_HostNodes with (nolock) where VMwareProductversion is not NULL and clusterid is NULL),''''))
union all (SELECT ''TOTAL VMs'', concat(isnull(sum(isnull(vmcount,0)),0),'''') from VIM_HostNodes with (nolock) where VMwareProductName like ''VM%'')
union all (SELECT ''Running VMs'', concat(isnull(sum(isnull(vmrunningcount,0)),0),'''') from VIM_HostNodes with (nolock) where VMwareProductVersion is not NULL)
union all (SELECT ''Total Number of Physical CPU Cores'', concat((select sum(CpuCoreCount) from VIM_HostNodes with (nolock) where VMwareProductName like ''%vmware%''),''''))
union all (SELECT ''Total Memory'', concat((select sum(MemorySize)/1024/1024/1024 from VIM_HostNodes with (nolock) where VMwareProductName like ''%vmware%''),'' GB''))
union all (select ''=== Hyper-V ===='','''')
union all (SELECT ''Number of Host'', concat((select count(*) from VIM_HostNodes with (nolock) where VMwareProductName like ''%hyper%''),''''))
union all (SELECT ''Total VMs'', concat((select sum(vmcount) from VIM_HostNodes where VMwareProductName like ''%hyper%''),''''))
union all (SELECT ''Running VMs'', concat((select sum(VmRunningCount) from VIM_HostNodes with (nolock) where ManagedStatus=1 and VMwareProductName like ''%hyper%''),''''))
union all (SELECT ''HyperV: Physical CPU Cores'', concat((select sum(CpuCoreCount) from VIM_HostNodes with (nolock) where VMwareProductName like ''%hyper%''),''''))
union all (SELECT ''HyperV: Memory'', concat((select sum(MemorySize)/1024/1024/1024 from VIM_HostNodes with (nolock) where VMwareProductName like ''%hyper%''),'' GB''))

union all (select ''=== NUTANICS ===='','''')
union all SELECT ''Cluster'', concat(isnull(count(*),0),'''') as [v] FROM VIM_Clusters c join VIM_Platform p on p.PlatformID=c.PlatformID and p.Name=''Nutanix''

union all (select ''=== VMWARE ISSUES ===='','''')
union all SELECT ''vCenter with problems'', concat(isnull(count(*),0),'''') as [v] FROM VIM_Clusters c join VIM_Platform p on p.PlatformID=c.PlatformID and p.Name=''vmware''
union all (SELECT ''Hosts with problems'', concat(isnull(count(*),0),'''') as [v] FROM VIM_Hosts h where ManagedStatusMessage is not NULL)
union all (SELECT ''Guest with problems'', concat(isnull(count(*),0),'''') as [v] FROM VIM_VirtualMachines h where TriggeredAlarmDescription is not NULL )

union all (select ''=== SPRAWL - VMs by Snapshot usage ===='','''')
union all select * from (
select top 100
concat(vm.Name,'' - '',ds.name) as [n]
,concat(round(vm.SnapshotStorageSize/1024/1024/1024,1),''GB'') as [Snapshots]
--,ds.name
from VIM_VirtualMachines vm
inner join 
(SELECT vmn.VirtualMachineID,MIN(ds.DataStoreID) AS DataStoreID 
,ds.Name
FROM [dbo].[VIM_VirtualMachineNodes] AS vmn 
LEFT JOIN VIM_VirtualMachineDatastoreMapping AS dsm ON dsm.VirtualMachineID=vmn.VirtualMachineID 
LEFT JOIN VIM_Datastores AS ds ON ds.DataStoreID=dsm.DataStoreID 
where vmn.SnapshotStorageSize>0
group by vmn.VirtualMachineID,ds.name) ds on ds.VirtualMachineID=vm.VirtualMachineID
--where ds.DataStoreID=
where round(vm.SnapshotStorageSize/1024/1024/1024,1)>0
order by vm.SnapshotStorageSize desc) a

union all select ''=== SPRAWL - VMs Powered Off for More Than 30 Days   ==='', ''''
union all SELECT ''TOTAL VMs'', concat(isNULL(count(*),0),'''') from VIM_VirtualMachines where datediff(day,lastactivitydate,getdate()) > 30 and powerstate=''poweredOff''
union all SELECT ''Total CPUs'', concat(isNULL(sum(processorcount),0),'''') from VIM_VirtualMachines where datediff(day,lastactivitydate,getdate()) > 30 and powerstate=''poweredOff''
union all SELECT ''Total Memory'', concat(isNULL(sum(MemoryConfigured)/1024/1024/1024,0),'' GB'') from VIM_VirtualMachines where datediff(day,lastactivitydate,getdate()) > 30 and powerstate=''poweredOff''

union all select ''=== SPRAWL - VMs Idle for the last week   ==='', ''''
union all select ''Nodes'', concat(isnull(count(*),0),'''') as [v]
from (
SELECT vms.VirtualMachineID, vm.Name
--,AVG(vms.AvgCPULoad) as [cpu],AVG(vms.AvgIOPSTotal) as [iops],AVG(AvgNetworkTransmitRate) as [net]
FROM VIM_VMStatistics AS VMs 
join VIM_VirtualMachines vm on vm.VirtualMachineID=vms.VirtualMachineID
WHERE (DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), DateTime)  >= dateadd(dd, -1, dateadd(wk, datediff(wk, 0, getdate()) - 1, 0))  )
AND (DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), DateTime)  <= dateadd(ss, -1, dateadd(wk, datediff(wk, 0, getdate()), 0)-1)  )
group by vms.VirtualMachineID, vm.name
Having (AVG(isnull(AvgCPULoad,-2)) >= 0 AND AVG(isnull(AvgCPULoad,-2)) <= 1)
   AND (AVG(isnull(AvgIOPSTotal,-2)) >= 0 AND AVG(isnull(AvgIOPSTotal,-2)) <= 20)
   AND (AVG(isnull(AvgNetworkTransmitRate,-2)) >= 0 AND AVG(isnull(AvgNetworkTransmitRate,-2)) <= 1)
--order by AVG(vms.AvgCPULoad)
) a





union all select ''===   Predicted Datastore Space Depletion   ==='', ''''
union all SELECT a.* from (select top 5 Name, convert(nvarchar, DepletionDate, 101) as[v] FROM VIM_DataStores where DepletionDate is not NULL order by DepletionDate asc) a

union all select ''===   Datastore IOPS TOP 5   ==='', ''''
union all SELECT a.* from (select top 5 Name, concat(round(IOPSTotal,1),'''') as[v] FROM VIM_DataStores order by IOPSTotal desc) a

union all select ''===   Datastore I/O Latency TOP 5   ==='', ''''
union all SELECT a.* from (select top 5 Name, concat(round(LatencyTotal,1),'' ms'') as[v] FROM VIM_DataStores order by LatencyTotal desc) a

union all select ''===   DataStore   ==='', ''''
union all SELECT ''TOTAL Datastores'', concat(count(*),'''') as [v] FROM VIM_DataStores
union all SELECT ''TOTAL Space'',case when sum(isnull(capacity,0))/1024/1024/1024/1024 > 1 then concat(round(sum(cast(isnull(capacity,0) as float))/1024/1024/1024/1024,1),'' TB'') else  concat(round(sum(cast(capacity as float))/1000/1000/1000/1000,1),'' GB'') end as [v] FROM VIM_DataStores
union all SELECT ''Free Space'',case when sum(isnull(FreeSpace,0))/1024/1024/1024/1024 > 1 then concat(round(sum(cast(isnull(FreeSpace,0) as float))/1024/1024/1024/1024,1),'' TB'') else  concat(round(sum(FreeSpace)/1024/1024/1024,1),'' GB'') end as [v] FROM VIM_DataStores
union all SELECT ''Provisioned Space'',case when sum(isnull(ProvisionedSpace,0))/1024/1024/1024/1024 > 1 then concat(round(sum(cast(isnull(ProvisionedSpace,0) as float))/1024/1024/1024/1024,1),'' TB'') else  concat(round(sum(cast(capacity as float))/1000/1000/1000/1000,1),'' GB'') end as [v] FROM VIM_DataStores
union all SELECT ''Storage Used'', concat(round(100-(sum(cast(isnull(freespace,0) as float))*100/sum(cast(isnull(capacity,0) as float))),1),''%'') as [v] FROM VIM_DataStores

union all (select ''=== VMAN Recommendations ===='','''')
union all SELECT ''High'', concat(isnull(count(*),0),'''') as [v] FROM RE_Recommendations where priority=1
union all SELECT ''Medium'', concat(isnull(count(*),0),'''') as [v] FROM RE_Recommendations where priority=2
union all SELECT ''Low'', concat(isnull(count(*),0),'''') as [v] FROM RE_Recommendations where priority=3

union all (select ''=== VMAN Retation ===='','''')
union all select ''Detailed'', concat(CurrentValue,'''') from settings where settingid=''VIM_Setting_Detailed_Retain''
union all select ''Hourly'', concat(CurrentValue,'''') from settings where settingid=''VIM_Setting_Hourly_Retain''
union all select ''Daily'', concat(CurrentValue,'''') from settings where settingid=''VIM_Setting_Daily_Retain''
'
--********************************************************************************
--  VMAN - end
--********************************************************************************


--********************************************************************************
--  SRM - start
--********************************************************************************
SET @SRM = 
'
union all select '''','''' 
union all select '''',''''  
union all (select ''****  SRM  ****'','''' )
union all (select ''****  SRM  ****'','''' )
union all select ''=== ARRAY VENDORS ==='',''''
union all select  sa.Manufacturer,  concat(isnull(count(*),0),'''') as [v] from SRM_StorageArrays sa where sa.enabled=1 group by sa.Manufacturer

union all select ''=== ARRAY STATUS ==='',''''
union all select  ''TOTAL'', concat(isnull(count(*),0),'''') as [v] from SRM_StorageArrays sa where sa.enabled=1
union all select ''Up'', concat(isnull(sum(case when sa.status=1 then 1 else 0 end),0),'''') as [v] from SRM_StorageArrays sa where sa.enabled=1
union all select ''Warning'', concat(isnull(sum(case when sa.status=3 then 1 else 0 end),0),'''') as [v] from SRM_StorageArrays sa where sa.enabled=1
union all select ''Critical'', concat(isnull(sum(case when sa.status=14 then 1 else 0 end),0),'''') as [v] from SRM_StorageArrays sa where sa.enabled=1
union all select ''Down'', concat(isnull(sum(case when sa.status=2 then 1 else 0 end),0),'''') as [v] from SRM_StorageArrays sa where sa.enabled=1
union all select ''Unknown'', concat(isnull(sum(case when sa.status=0 then 1 else 0 end),0),'''') as [v] from SRM_StorageArrays sa where sa.enabled=1
union all select ''Unreachable'', concat(isnull(sum(case when sa.status=12 then 1 else 0 end),0),'''') as [v] from SRM_StorageArrays sa where sa.enabled=1

union all select ''=== ARRAY OPERATIONAL STATE ==='',''''
union all select  operStatusDescription, concat(isnull(count(*),0),'''')  from SRM_StorageArrays group by operStatusDescription

union all select ''=== POOL STATUS ==='',''''
union all select  ''TOTAL'', concat(isnull(count(*),0),'''') as [v] from SRM_Pools
union all select ''Up'', concat(isnull(sum(case when status=1 then 1 else 0 end),0),'''') as [v] from SRM_Pools
union all select ''Warning'', concat(isnull(sum(case when status=3 then 1 else 0 end),0),'''') as [v] from SRM_Pools
union all select ''Critical'', concat(isnull(sum(case when status=14 then 1 else 0 end),0),'''') as [v] from SRM_Pools
union all select ''Down'', concat(isnull(sum(case when status=2 then 1 else 0 end),0),'''') as [v] from SRM_Pools
union all select ''Unknown'', concat(isnull(sum(case when status=0 then 1 else 0 end),0),'''') as [v] from SRM_Pools
union all select ''Unreachable'', concat(isnull(sum(case when status=12 then 1 else 0 end),0),'''') as [v] from SRM_Pools

union all select ''=== POOL OPERATIONAL STATE ==='',''''
union all select  operStatusDescription, concat(isnull(count(*),0),'''')  from SRM_Pools group by operStatusDescription

union all select ''=== LUN STATUS ==='',''''
union all select  ''TOTAL'', concat(isnull(count(*),0),'''') as [v] from SRM_LUNs
union all select ''Up'', concat(isnull(sum(case when status=1 then 1 else 0 end),0),'''') as [v] from SRM_LUNs
union all select ''Warning'', concat(isnull(sum(case when status=3 then 1 else 0 end),0),'''') as [v] from SRM_LUNs
union all select ''Critical'', concat(isnull(sum(case when status=14 then 1 else 0 end),0),'''') as [v] from SRM_LUNs
union all select ''Down'', concat(isnull(sum(case when status=2 then 1 else 0 end),0),'''') as [v] from SRM_LUNs
union all select ''Unknown'', concat(isnull(sum(case when status=0 then 1 else 0 end),0),'''') as [v] from SRM_LUNs
union all select ''Unreachable'', concat(isnull(sum(case when status=12 then 1 else 0 end),0),'''') as [v] from SRM_LUNs
union all select ''=== LUN OPERATIONAL STATE ==='',''''
union all select  operStatusDescription, concat(isnull(count(*),0),'''')  from SRM_LUNs group by operStatusDescription

union all select ''=== Disk STATUS ==='',''''
union all select  ''TOTAL'', concat(isnull(count(*),0),'''') as [v] from SRM_PhysicalDisks
union all select ''Up'', concat(isnull(sum(case when status=1 then 1 else 0  end),0),'''') as [v] from SRM_PhysicalDisks
union all select ''Warning'', concat(isnull(sum(case when status=3 then 1 else 0 end),0),'''') as [v] from SRM_PhysicalDisks
union all select ''Critical'', concat(isnull(sum(case when status=14 then 1 else 0 end),0),'''') as [v] from SRM_PhysicalDisks
union all select ''Down'', concat(isnull(sum(case when status=2 then 1 else 0 end),0),'''') as [v] from SRM_PhysicalDisks
union all select ''Unknown'', concat(isnull(sum(case when status=0 then 1 else 0 end),0),'''') as [v] from SRM_PhysicalDisks
union all select ''Unreachable'', concat(isnull(sum(case when status=12 then 1 else 0 end),0),'''') as [v] from SRM_PhysicalDisks
union all select ''=== DISK OPERATIONAL STATE ==='',''''
union all select  operStatusDescription, concat(isnull(count(*),0),'''')  from SRM_PhysicalDisks group by operStatusDescription

--union all select ''=== Vendor(Array) - Pool - LUN  - Status==='',''''
--union all select  
--concat(sa.Manufacturer,''('',  sa.name, '') - '',p.Name,'' - '',l.Name) as [pool]
--,concat(sia.statusname, '' - '',sip.StatusName,'' - '',sil.StatusName) as [status]
--from SRM_StorageArrays sa 
--left join SRM_Pools p on p.StorageArrayID=sa.StorageArrayID
--left join SRM_LUNs l on l.StorageArrayID=sa.StorageArrayID
--join StatusInfo sip on sip.StatusId=p.Status
--join Statusinfo sia on sia.StatusId=sa.Status
--join Statusinfo sil on sil.StatusId=sa.Status

--union all select '''',''''
--union all select ''=== Vendor(Array) - Pool - LUN Lat ==='',''''
--union all select * from (select top 100  
--concat(sa.Manufacturer,''('',  sa.name, '') - '',p.Name,'' - '',l.Name) as [pool]
--,concat(round(l.IOLatencyTotal,2),'' mS'') as [status]
--from SRM_StorageArrays sa 
--left join SRM_Pools p on p.StorageArrayID=sa.StorageArrayID
--left join SRM_LUNs l on l.StorageArrayID=sa.StorageArrayID
--join StatusInfo sip on sip.StatusId=p.Status
--join Statusinfo sia on sia.StatusId=sa.Status
--join Statusinfo sil on sil.StatusId=sa.Status
--order by l.IOLatencyTotal desc
--) a 

union all select ''=== Vendor(Array) - User Capacity Space ==='',''''
union all select * from (select top 100  
concat(sa.Manufacturer,''('',  sa.name, '') User space'') as [pool]
,concat(round(sa.CapacityUserFree/1024/1024/1024,2),'' GB free of '', sa.CapacityUserTotal/1024/1024/1024, '' GB total'') as [status]
from SRM_StorageArrays sa 
order by sa.CapacityUserFree asc
) a 

union all select ''=== top 5 LUN Latency  ==='',''''
union all select top 5 a.name, concat(round(isnull(a.latency,0),0),'' ms'') as [Latency] from (
    select top 100 ''LUN'' as [type], name, isnull(ioLatencytotal,0) [Latency] , status from srm_luns
	order by latency desc, type
) a 

union all select ''=== top 5 Volume Latency  ==='',''''
union all select top 5 a.name, concat(round(isnull(a.latency,0),0),'' ms'') as [Latency] from (
    select top 100 ''Volume'' as [type], name, isnull(ioLatencytotal,0) [Latency] , status from srm_volumes
	order by latency desc, type
) a 

union all select ''=== top 5 LUN IOPS  ==='',''''
union all select top 5 a.name, concat(round(isnull(a.iops,0),0),'''') as [iops] from (
    select top 100 ''Volume'' as [type], name, isnull(iopstotal,0) [iops] , status from srm_luns
	order by iops desc, type
) a 

'

-- SRM end




--********************************************************************************
--  LA - start
--********************************************************************************
SET @LA =
'
union all select '''',''''
union all select '''',''''
union all select ''****  LA  ****'',''''
union all (select ''****  LA  ****'','''' )
union all (select ''=== Sources ==='','''' )
union all (SELECT concat(e.servername,'' ''), concat(count(*),'''') FROM [' + @LAdb + '].[dbo].[OrionLog_LogEntryMessageSource] with (nolock) 
join engines e with (nolock) on e.EngineID=[' + @LAdb + '].[dbo].[OrionLog_LogEntryMessageSource].EngineID
group by e.servername)

union all (select ''=== Events by Day (Last 7 days ) ==='','''' )
union all (select * from (
SELECT top 100000
  CONVERT(VARCHAR(10), lev.DateTime, 111) as [Date]
  ,concat(count(*),'''') as [Source]
FROM [' + @LAdb + '].[dbo].[OrionLog_LogEntryView] lev with (nolock) 
join [' + @LAdb + '].[dbo].[OrionLog_LogEntrySource] les with (nolock)  on les.LogEntrySourceID=lev.LogEntrySourceID
where datediff(dd,lev.DateTime,getutcdate()) <=7
group by CONVERT(VARCHAR(10), lev.DateTime, 111)
order by CONVERT(VARCHAR(10), lev.DateTime, 111)
) a
 )

union all (select ''=== Events by Type (Last 7 days ) ==='','''' )
union all (
select a.date,concat(les.name,'' - '',a.c) as [c]
from 
(
SELECT top 100000 CONVERT(VARCHAR(10), DateTime, 111) as [Date]
      ,[LogEntrySourceID]
,count(*) as [c]
  FROM [' + @LAdb + '].[dbo].[OrionLog_LogEntryView]
  group by LogEntrySourceID, CONVERT(VARCHAR(10), DateTime, 111)
  order by CONVERT(VARCHAR(10), DateTime, 111), [LogEntrySourceID]
) a
join [' + @LAdb + '].[dbo].[OrionLog_LogEntrySource] les on les.LogEntrySourceID=a.LogEntrySourceID
--order by a.date, les.name
)


union all (select ''=== Events by Vendor (yesterday) ==='','''' )
union all ( select * from (
SELECT top 1000
  CONVERT(VARCHAR(10), lev.DateTime, 111) as [Date]
  ,concat(lems.Vendor,'': '',count(*)) as [Source]
FROM [' + @LAdb + '].[dbo].[OrionLog_LogEntryView] lev with (nolock) 
join [' + @LAdb + '].[dbo].[OrionLog_LogEntryMessageSource] lems with (nolock) on lems.LogEntryMessageSourceID=lev.LogEntryMessageSourceID
where datediff(dd,lev.DateTime,getutcdate()) = 1
group by CONVERT(VARCHAR(10), lev.DateTime, 111), lems.vendor
order by CONVERT(VARCHAR(10), lev.DateTime, 111), lems.vendor
) a
)

union all (select ''=== Top 5 Events by Device (yesterday) ==='','''' )
union all (select top 5 a.source, a.count from (
SELECT top 100
      concat(lems.Caption, ''('',lems.IPAddress,'')'') as [Source]
	  ,concat(count(lemv.Message),'''') as [Count]
  FROM [' + @LAdb + '].[dbo].[OrionLog_LogEntryView] lev with (nolock)
  join [' + @LAdb + '].[dbo].[OrionLog_LogEntryMessageView] lemv with (nolock) on lemv.LogEntryID=lev.LogEntryID
  join [' + @LAdb + '].[dbo].[OrionLog_LogEntryMessageSource] lems with (nolock) on lems.LogEntryMessageSourceID=lev.LogEntryMessageSourceID
where datediff(day,lev.datetime,getutcdate()) = 1
group by lems.Caption,lems.IPAddress
order by count(lemv.Message) desc
) a )

union all (select ''=== Log Alert Count ==='','''' )
union all (
SELECT 
case when childrule.SourceType='''' then ''Global'' else childrule.SourceType end as [Source]
, concat(isNULL(count(*),0),'''') as [d]--parentrule.isenabledp
from [' + @LAdb + '].[dbo].[OrionLog_RuleProcessingDefinitions] with (nolock)
CROSS APPLY
OPENJSON(RuleDefinitions,''$."$values"'')
WITH (
     ChildRules nvarchar(MAX)  ''$.ChildRules''  as JSON,
	 [isEnabledp] nvarchar(max) ''$.IsEnabled'' 
      ) parentRule CROSS APPLY OPENJSON(parentRule.ChildRules,''$'')
WITH (
      [SourceType] nvarchar(max) ''$.SourceType'')
      --[isEnabled] nvarchar(max) ''$.isenabled'')
	  childRule
group by childrule.SourceType, parentrule.isenabledp
)
union all (select ''=== Retention ==='','''' )
union all SELECT [Name], concat(RetentionPeriodInDays,'' days'') as [r] FROM [' + @LAdb + '].[dbo].[OrionLog_LogEntrySource] with (nolock) 
'

--********************************************************************************
--  SCM - start
--********************************************************************************
SET @SCM =
'
union all select '''',''''
union all select '''',''''
union all select ''****  SCM ****'',''''
union all (select ''****  SCM  ****'','''' )
union all (select ''=== Nodes ==='','''' )
union all SELECT ''TOTAL'', concat(isNULL(count(*),0),'''') FROM SCM_ActiveNodes s where s.enabled=1
union all select * from (select top 100 n.vendor, concat(isnull(count(*),0),'''') as [v] fROM SCM_ActiveNodes s join nodes n on n.nodeid=s.nodeid where s.enabled=1 group by n.vendor order by n.vendor) a

union all (select ''=== Nodes STATUS ==='','''' )
union all (select * from (select top 100 s.statusname, isnull(count(*),0) as [v] fROM SCM_ActiveNodes scm join statusinfo s on s.statusid=scm.Status where scm.enabled=1 group by s.statusname order by s.statusname desc) a)

'

--********************************************************************************
--  SCM - end
--********************************************************************************


SET @Query = @OrionServers + @OrionPolling + @OrionCore

IF (@isNPM='Installed')  BEGIN  SET @Query = @Query + @NPM   END
IF (@isSAM='Installed')  BEGIN  SET @Query = @Query + @SAM   END
IF (@isNCM='Installed')  BEGIN  SET @Query = @Query + @NCM   END
IF (@isNTA='Installed')  BEGIN  SET @Query = @Query + @NTA   END
IF (@isVNQM='Installed') BEGIN  SET @Query = @Query + @VNQM  END
IF (@isIPAM='Installed') BEGIN  SET @Query = @Query + @IPAM  END
IF (@isUDT='Installed')  BEGIN  SET @Query = @Query + @UDT   END
IF (@isWPM='Installed')  BEGIN  SET @Query = @Query + @WPM   END
IF (@isVMAN='Installed') BEGIN  SET @Query = @Query + @VMAN  END
IF (@isSRM='Installed')  BEGIN  SET @Query = @Query + @SRM   END
IF (@isSCM='Installed')  BEGIN  SET @Query = @Query + @SCM   END
--IF (@isLA='Installed')   BEGIN  SET @Query = @Query + @LA    END

EXEC (@Query)
