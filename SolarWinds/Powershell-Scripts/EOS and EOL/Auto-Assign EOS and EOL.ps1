# ===================================================================
# End of Support (EOS) Assignment Script
# ===================================================================
# This script processes EOS match queue entries and assigns them to nodes
# Supports dry run mode to preview changes before execution
# ===================================================================

param(
    [string]$OrionServer = "",
    [string]$Username = "", 
    [string]$Password = "",
    [switch]$DryRun = $true,
    [switch]$Verbose = $true
)

# ===================================================================
# CONFIGURATION & INITIALIZATION
# ===================================================================

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "EOS Assignment Script Starting" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Server: $OrionServer" -ForegroundColor White
Write-Host "Username: $Username" -ForegroundColor White
Write-Host "Dry Run Mode: $($DryRun.ToString())" -ForegroundColor $(if($DryRun) {"Yellow"} else {"Green"})
Write-Host "Verbose Mode: $($Verbose.ToString())" -ForegroundColor White
Write-Host ""

# Initialize counters for reporting
$processedCount = 0
$successCount = 0
$errorCount = 0
$startTime = Get-Date

# ===================================================================
# SWIS CONNECTION SETUP
# ===================================================================

Write-Host "Establishing SWIS connection..." -ForegroundColor Yellow

try {
    # Create secure credential object
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($Username, $securePassword)
    
    # Establish SWIS connection
    $swis = Connect-Swis -Hostname $OrionServer -Credential $credential
    
    Write-Host "✓ SWIS connection established successfully" -ForegroundColor Green
    
    # Test connection with a simple query
    $testQuery = "SELECT TOP 1 NodeID FROM Orion.Nodes"
    $testResult = Get-SwisData -SwisConnection $swis -Query $testQuery
    Write-Host "✓ Connection test successful" -ForegroundColor Green
}
catch {
    Write-Error "Failed to establish SWIS connection: $($_.Exception.Message)"
    exit 1
}

# ===================================================================
# RETRIEVE EOS MATCH QUEUE ENTRIES
# ===================================================================

Write-Host "`nRetrieving EOS match queue entries..." -ForegroundColor Yellow

try {
    # Query to get all URIs from the EOS match queue
    $uriQuery = "SELECT Uri FROM Cirrus.NCM_EosMatchQueue ORDER BY Uri"
    $uriResults = Get-SwisData -SwisConnection $swis -Query $uriQuery
    
    Write-Host "✓ Found $($uriResults.Count) entries in EOS match queue" -ForegroundColor Green
    
    if ($uriResults.Count -eq 0) {
        Write-Host "No entries found in queue. Exiting." -ForegroundColor Yellow
        exit 0
    }
}
catch {
    Write-Error "Failed to retrieve EOS match queue entries: $($_.Exception.Message)"
    exit 1
}

# ===================================================================
# PROCESS EACH EOS MATCH QUEUE ENTRY
# ===================================================================

Write-Host "`nProcessing EOS match queue entries..." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan

foreach ($uriEntry in $uriResults) {
    $processedCount++
    $currentUri = $uriEntry
    
    Write-Host "`n[$processedCount/$($uriResults.Count)] Processing URI: $currentUri" -ForegroundColor White
    
    try {
        # ===================================================================
        # RETRIEVE EOS OBJECT DATA
        # ===================================================================
        
        if ($Verbose) {
            Write-Host "  → Retrieving EOS object data..." -ForegroundColor Gray
        }
        
        # Get the complete EOS object using the URI
        $eosObject = Get-SwisObject -SwisConnection $swis -Uri $currentUri
        
        if ($null -eq $eosObject) {
            Write-Warning "  ⚠ EOS object not found for URI: $currentUri"
            $errorCount++
            continue
        }
        
        # ===================================================================
        # VALIDATE AND PREPARE DATA
        # ===================================================================
        
        if ($Verbose) {
            Write-Host "  → Validating and preparing EOS data..." -ForegroundColor Gray
        }
        
        # Validate required fields
        if ([string]::IsNullOrEmpty($eosObject.nodeId)) {
            Write-Warning "  ⚠ Missing nodeId for URI: $currentUri"
            $errorCount++
            continue
        }
        
        if ([string]::IsNullOrEmpty($eosObject.eosentryId)) {
            Write-Warning "  ⚠ Missing eosentryId for URI: $currentUri"
            $errorCount++
            continue
        }
        
        # Convert empty date values to proper $null for nullable DateTime parameters
        $endOfSupport = if ([string]::IsNullOrEmpty($eosObject.endOfSupport)) { 
            $null 
        } else { 
            try { [DateTime]$eosObject.endOfSupport } catch { $null }
        }
        
        $endOfSales = if ([string]::IsNullOrEmpty($eosObject.endOfSales)) { 
            $null 
        } else { 
            try { [DateTime]$eosObject.endOfSales } catch { $null }
        }
        
        $endOfSoftware = if ([string]::IsNullOrEmpty($eosObject.endOfSoftware)) { 
            $null 
        } else { 
            try { [DateTime]$eosObject.endOfSoftware } catch { $null }
        }
        
        # ===================================================================
        # DISPLAY EOS OBJECT DETAILS
        # ===================================================================
        
        Write-Host "  📋 EOS Object Details:" -ForegroundColor Cyan
        Write-Host "     Node ID: $($eosObject.nodeId)" -ForegroundColor White
        Write-Host "     EOS Entry ID: $($eosObject.eosentryId)" -ForegroundColor White
        Write-Host "     End of Support: $(if($endOfSupport) {$endOfSupport.ToString('yyyy-MM-dd')} else {'Not specified'})" -ForegroundColor White
        Write-Host "     End of Sales: $(if($endOfSales) {$endOfSales.ToString('yyyy-MM-dd')} else {'Not specified'})" -ForegroundColor White
        Write-Host "     End of Software: $(if($endOfSoftware) {$endOfSoftware.ToString('yyyy-MM-dd')} else {'Not specified'})" -ForegroundColor White
        Write-Host "     Version: $($eosObject.eosversion)" -ForegroundColor White
        Write-Host "     Link: $($eosObject.eoslink)" -ForegroundColor White
        Write-Host "     Comments: $($eosObject.comments)" -ForegroundColor White
        Write-Host "     Replacement Part: $($eosObject.replacementPartNumber)" -ForegroundColor White
        
        # ===================================================================
        # PREPARE SWIS VERB ARGUMENTS
        # ===================================================================
        
        # Prepare arguments array for the AssignEOSEntry verb
        $arguments = @(
            [array]$eosObject.nodeId,                    # Node ID array
            $endOfSupport,                               # End of Support date
            $endOfSales,                                 # End of Sales date  
            $endOfSoftware,                              # End of Software date
            [guid]$eosObject.eosentryId,                 # EOS Entry ID as GUID
            "Manual",                                    # Assignment method
            $eosObject.eosversion,                       # EOS version
            $eosObject.eoslink,                          # EOS link
            $eosObject.comments,                         # Comments
            $eosObject.replacementPartNumber             # Replacement part number
        )
        
        # ===================================================================
        # EXECUTE OR SIMULATE EOS ASSIGNMENT
        # ===================================================================
        
        if ($DryRun) {
            # DRY RUN: Show what would be executed without making changes
            Write-Host "  🔍 DRY RUN - Would execute AssignEOSEntry with:" -ForegroundColor Yellow
            Write-Host "     Entity: Cirrus.Nodes" -ForegroundColor Gray
            Write-Host "     Verb: AssignEOSEntry" -ForegroundColor Gray
            Write-Host "     Arguments: [Array with $($arguments.Length) parameters]" -ForegroundColor Gray
            Write-Host "  ✓ DRY RUN - Would assign EOS entry to node $($eosObject.nodeId)" -ForegroundColor Yellow
        }
        else {
            # LIVE RUN: Execute the actual assignment
            Write-Host "  🔄 Executing EOS assignment..." -ForegroundColor Yellow
            
            $result = Invoke-SwisVerb -SwisConnection $swis -EntityName "Cirrus.Nodes" -Verb "AssignEOSEntry" -Arguments $arguments
            
            Write-Host "  ✓ Successfully assigned EOS entry to node $($eosObject.nodeId)" -ForegroundColor Green
            
            if ($Verbose -and $result) {
                Write-Host "     Result: $result" -ForegroundColor Gray
            }
        }
        
        $successCount++
        
    }
    catch {
        # ===================================================================
        # ERROR HANDLING
        # ===================================================================
        
        Write-Host "  ❌ Error processing URI: $currentUri" -ForegroundColor Red
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($Verbose) {
            Write-Host "     Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
        }
        
        $errorCount++
    }
}

# ===================================================================
# FINAL SUMMARY REPORT
# ===================================================================

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "EOS Assignment Script Complete" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Execution Summary:" -ForegroundColor White
Write-Host "  Total Entries Processed: $processedCount" -ForegroundColor White
Write-Host "  Successful Assignments: $successCount" -ForegroundColor Green
Write-Host "  Errors Encountered: $errorCount" -ForegroundColor $(if($errorCount -gt 0) {"Red"} else {"Green"})
Write-Host "  Success Rate: $(if($processedCount -gt 0) {[math]::Round(($successCount/$processedCount)*100,2)} else {0})%" -ForegroundColor White
Write-Host "  Execution Time: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
Write-Host "  Mode: $(if($DryRun) {"DRY RUN (No changes made)"} else {"LIVE RUN (Changes applied)"})" -ForegroundColor $(if($DryRun) {"Yellow"} else {"Green"})

if ($errorCount -gt 0) {
    Write-Host "`n⚠ Review errors above and consider running with -Verbose for more details" -ForegroundColor Yellow
}

Write-Host "`nScript execution completed." -ForegroundColor Cyan