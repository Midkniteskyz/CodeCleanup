SELECT 
    CP.Table, 
    CP.Field, 
    CP.DataType, 
    CP.MaxLength, 
    CP.StorageMethod, 
    CP.Description, 
    CP.TargetEntity, 
    CP.Mandatory, 
    CP.Default, 
    CP.DisplayName AS CPDisplayName,
    CPU.IsForAlerting, 
    CPU.IsForFiltering, 
    CPU.IsForGrouping, 
    CPU.IsForReporting, 
    CPU.IsForEntityDetail, 
    CPU.IsForAssetInventory,
    CPV.Value, 
    CPV.DisplayName AS CPVDisplayName, 
    CPV.Description AS CPVDescription
FROM 
    Orion.CustomProperty AS CP
LEFT JOIN 
    Orion.CustomPropertyUsage AS CPU
    ON CP.Table = CPU.Table 
    AND CP.Field = CPU.Field
LEFT JOIN 
    Orion.CustomPropertyValues AS CPV
    ON CP.Table = CPV.Table 
    AND CP.Field = CPV.Field

