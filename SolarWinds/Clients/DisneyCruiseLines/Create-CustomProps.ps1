# PropertyName - the name of the property.
$PropertyName = ""

# Description - a description of the property to be shown in editing UI.
$Description = ""

# ValueType - the data type for the custom property. The following types are allowed: string, integer, datetime, single, double, boolean.
$ValueType = ""

# Size - for string types, this is the maximum length of the values, in characters. Ignored for other types.
$Size = "4000"

# ValidRange - unused, pass null.
$ValidRange = $null

# Parser - unused, pass null.
$Parser = $null

# Header - unused, pass null.
$Header = $null

# Alignment - unused, pass null.
$Alignment = $null

# Format - unused, pass null.
$Format = $null

# Units - unused, pass null.
$Units = $null

# Usages - optional. You can pass null for this.
$Usages = $null

# Mandatory - optional. Defaults to false. If set to true, the Add Node wizard in the Orion web console will require that a value for this custom property be specified at node creation time.
$Mandatory = $null

# Default - optional. You can pass null for this. If you provide a value, this will be the default value for new nodes.
$Default = $null

$swis = Connect-Swis -Hostname localhost -Username admin -Password ""
Invoke-SwisVerb $swis Orion.NodesCustomProperties CreateCustomProperty @("Test1", "this is my description", "string", 4000, $null, $null, $null, $null, $null, $null)



$swis = Connect-Swis -Hostname localhost -Username admin -Password ""
$values = New-Object string[] 3
$values[0] = "value1"
$values[1] = "value2"
$values[2] = "value3"
Invoke-SwisVerb $swis Orion.NodesCustomProperties CreateCustomPropertyWithValues @($PropertyName, $Description, $ValueType, $Size, $ValidRange, $ValidRange, $Parser, $Header, $Alignment, $Format, $Units, $Usages, $Mandatory, $Default)