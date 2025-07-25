-- Description: Grab the Global SRM Settings and list out the threshold settings
-- The list of settings to grab (Entity Type)
-- Global Array thresholds (Orion.SRM.StorageArrays)
-- IOPS(Total)
-- IOPS(Read)
-- IOPS(Write)
-- IOPS(Other)
-- Throughput(Total)
-- Throughput(Read)
-- Throughput(Write)
-- IO Size(Total)
-- IO Size(Read)
-- IO Size(Write)
-- TODO Cache Hit Ratio
-- TODO File System Used Capacity
-- TODO Provisioned Capacity

-- Global Storage Pool thresholds (Orion.SRM.Pools)
-- IOPS(Total)
-- IOPS(Read)
-- IOPS(Write)
-- IOPS(Other)
-- Throughput(Total)
-- Throughput(Read)
-- Throughput(Write)
-- IO Size(Total)
-- IO Size(Read)
-- IO Size(Write)
-- TODO Cache Hit Ratio
-- TODO Provisioned Capacity

-- Global LUN thresholds (Orion.SRM.LUNs)
-- IOPS(Total)
-- IOPS(Read)
-- IOPS(Write)
-- IOPS(Other)
-- Latency(Total)
-- Latency(Read)
-- Latency(Write)
-- Latency(Other)
-- Throughput(Total)
-- Throughput(Read)
-- Throughput(Write)
-- IO Size(Total)
-- IO Size(Read)
-- IO Size(Write)
-- TODO QUEUE LENGTH (Total)
-- TODO QUEUE LENGTH (Read)
-- TODO QUEUE LENGTH (Write)
-- TODO R/W IOPS Ratio
-- TODO DISK % BUSY
-- TODO Cache Hit Ratio

-- Global NAS Volume thresholds (Orion.SRM.Volumes)
-- IOPS(Total)
-- IOPS(Read)
-- IOPS(Write)
-- IOPS(Other)
-- Latency(Total)
-- Latency(Read)
-- Latency(Write)
-- Latency(Other)
-- Throughput(Total)
-- Throughput(Read)
-- Throughput(Write)
-- IO Size(Total)
-- IO Size(Read)
-- IO Size(Write)
-- TODO R/W IOPS Ratio
-- TODO Cache Hit Ratio
-- TODO File System Used Capacity
-- TODO Provisioned Capacity
-- TODO Global File Share thresholds
-- TODO FILE SYSTEM USED CAPACITY

-- Global Vserver thresholds (Orion.SRM.Vservers)
-- IOPS(Total)
-- IOPS(Read)
-- IOPS(Write)
-- IOPS(Other)
-- Throughput(Total)
-- Throughput(Read)
-- Throughput(Write)
-- IO Size(Total)
-- IO Size(Read)
-- IO Size(Write)

-- Global Storage Controller thresholds (Orion.SRM.StorageControllers)
-- IOPS(Total)
-- IOPS(Read)
-- IOPS(Write)
-- TODO IOPS(Other)
-- Throughput(Total)
-- Throughput(Read)
-- Throughput(Write)
-- IO Size(Total)
-- IO Size(Read)
-- IO Size(Write)
-- Latency(Total)
-- Latency(Read)
-- Latency(Write)
-- TODO Latency(Other)
-- IOPS Distribution
-- Throughput Distribution
-- Utilization

-- Global Storage Controller Port thresholds (Orion.SRM.StorageControllerPorts)
-- IOPS(Total)
-- Throughput(Total)
-- IOPS Distribution
-- Throughput Distribution

-- Column Layout
-- Column 1: [Threshold Category]
-- Column 2: [Threshold Name]
-- Column 3: [Warning Threshold Global Value]
-- Column 4: [Critical Threshold Global Value]
-- Column 5: [Unit of Measurement]

SELECT 
  DISTINCT tn.id, 
  -- Find character index wheres '.srm.' starts. Take that index starting position and add 5. (The length of '.srm.'). Then take difference between the start and the end to get the remaining character count as the [Category].
  SubString(
    at.EntityType, 
    CharIndex('.srm.', at.EntityType) + 5, 
    (
      length(at.EntityType) - CharIndex('.srm.', at.EntityType) + 4
    )
  ) as [Category], 
  tn.DisplayName, 
  at.GlobalWarningValue, 
  at.GlobalCriticalValue AS [Global Critical], 
  tn.Unit 
FROM 
  Orion.SRM.ApplicationThresholds AS at 
  JOIN Orion.ThresholdsNames tn on tn.Name = at.Name 
ORDER BY 
  tn.Id ASC
