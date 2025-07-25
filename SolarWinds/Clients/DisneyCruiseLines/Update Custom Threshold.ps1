# connect to solarwinds
$OrionServer = "localhost"
$Username = "Loop1"
$Password = "30DayPassword!"
$swis = Connect-Swis -Hostname $OrionServer -UserName $Username -Password $Password

# what hardware sensor to filter for 
$hardwaresensor = "Transceiver Receive Power"

# build swql Query
$swqlquery = "
SELECT
    hh.NodeID,
    hh.ID,
    hh.HardwareInfoID,
    hh.HardwareCategoryStatusID,
    hh.node.caption,
    hh.Name,
    hh.OriginalStatus,
    hh.IsDeleted,
    hh.HardwareCategoryID,
    hh.IsDisabled,
    hh.StatusDescription,
    hh.STATUS,
    hh.Uri,
    hh.hardwareitemthreshold.warning,
    hh.hardwareitemthreshold.critical
FROM
    Orion.HardwareHealth.HardwareItem AS hh
WHERE
    hh.name LIKE '%$hardwaresensor%'"
    
# Query solarwinds db for all matching hardware sensors
$querydata = Get-SwisData -SwisConnection $swis -Query $swqlquery

# Custom warning threshold
$newWarningthreshold = '<Expr xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Reporting.Models.Selection" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Child><Expr><Child><Expr><Child i:nil="true"/><NodeType>Field</NodeType><Value>Value</Value></Expr><Expr><Child i:nil="true"/><NodeType>Constant</NodeType><Value>-40</Value></Expr></Child><NodeType>Operator</NodeType><Value>!=</Value></Expr><Expr><Child><Expr><Child i:nil="true"/><NodeType>Field</NodeType><Value>Value</Value></Expr><Expr><Child i:nil="true"/><NodeType>Constant</NodeType><Value>-13.9</Value></Expr></Child><NodeType>Operator</NodeType><Value>&lt;=</Value></Expr></Child><NodeType>Operator</NodeType><Value>AND</Value></Expr>'

# Custom critical threshold
$newcriticalthreshold = '<Expr xmlns="http://schemas.datacontract.org/2004/07/SolarWinds.Reporting.Models.Selection" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Child><Expr><Child><Expr><Child i:nil="true"/><NodeType>Field</NodeType><Value>Value</Value></Expr><Expr><Child i:nil="true"/><NodeType>Constant</NodeType><Value>-40</Value></Expr></Child><NodeType>Operator</NodeType><Value>!=</Value></Expr><Expr><Child><Expr><Child i:nil="true"/><NodeType>Field</NodeType><Value>Value</Value></Expr><Expr><Child i:nil="true"/><NodeType>Constant</NodeType><Value>2</Value></Expr></Child><NodeType>Operator</NodeType><Value>&gt;=</Value></Expr></Child><NodeType>Operator</NodeType><Value>AND</Value></Expr>'

# Loop through each hardware sensor and update thresholds
foreach ($q in $querydata) {
    Write-Host "Updating Threshold $($q.name) on $($q.caption)"
    
    # Uncomment to apply
    # Invoke-SwisVerb -SwisConnection $swis -EntityName 'Orion.HardwareHealth.HardwareItemThreshold' -Verb 'SetThreshold' -Arguments $q.ID, $newWarningthreshold, $newcriticalthreshold
}