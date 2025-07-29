# Open a connection to SWIS
# $OrionServer = Read-Host "Enter the Orion Server hostname or IP"
# $OrionUserName = Read-Host "Enter the UserName"
# $OrionPassword = Read-Host "Enter the Password"

$OrionServer = "enghco.loop1.com"
$OrionUserName = "L1SENG\RWoolsey"
$OrionPassword = "W@shingt0n22!"

$swis = Connect-Swis -Hostname $OrionServer -Username $OrionUserName -Password $OrionPassword

# Gather and Display a list of all the Interface Custom Properties
$CpQueryinterface = @'
SELECT Field, DataType, MaxLength, Description, TargetEntity, URI
FROM Orion.CustomProperty
where TargetEntity = 'Orion.NPM.InterfacesCustomProperties'
'@

$swisQueryInterfaceCP = Get-SwisData -SwisConnection $swis -Query $CpQueryinterface


do{
    $swisQueryInterfaceCP | Select-Object Field, Description | Format-Table

    # Select which custom property to filter off of
    $filterCpInterface = read-host "Which Field would you like to filter interfaces off of?"

    if ($filterCpInterface -notin $swisQueryInterfaceCP.Field) {
        
        Write-Host "`nEnter a valid field." -ForegroundColor Yellow
    }

    
    
}until($filterCpInterface -in $swisQueryInterfaceCP.Field) {

    Write-Host "Filtering Interface Custom Properties off of $filterCpInterface"

    # Get all the possible values for the custom property

    $swisQueryFilteredCpValues = @"
SELECT $filterCpInterface
FROM Orion.NPM.InterfacesCustomProperties
group by $filterCpInterface
"@

do {
    Write-Host "Possible filter options for $filterCpInterface"
    $swisQueryFilteredCpValues

    $FilteredCpValues = read-host "Which Value would you like to filter?"

    if ($FilteredCpValues -notin $swisQueryFilteredCpValues) {
        
        Write-Host "`nEnter a valid field." -ForegroundColor Yellow
    }
    } until (
        $FilteredCpValues -in $swisQueryFilteredCpValues
    ){
        $swisQueryFilteredInterfaces = @"
SELECT 
icp.Interface.Node.Caption as [Node],
icp.Interface.Caption as [Interface Caption],
icp.$filterCpInterface,
icp.Interface.URI

FROM Orion.NPM.InterfacesCustomProperties as icp

WHERE icp.$filterCpInterface = '$FilteredCpValues'

Order By icp.$filterCpInterface, icp.Interface.Node.Caption, icp.Interface.Caption
"@

$swisQueryFilteredInterfaces | Select-Object Node, 'Interface Caption', $filterCpInterface
    }
}


# Get a list of Uris for the interfaces you want to change
#$uris = Get-SwisData $swis "SELECT Uri FROM Orion.NPM.Interfaces WHERE my-filter-expression"