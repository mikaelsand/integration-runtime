Connect-AzAccount
$rawToken = Get-AzAccessToken | Select-Object -ExpandProperty Token

$authtoken = ConvertTo-SecureString $rawToken -AsPlainText -Force

$csv = @()
$subscriptionDisplayname = ''
$basePath = 'https://management.azure.com'

# Set the URI to get all subscriptions
$subscriptionsUri = '/subscriptions?api-version=2020-01-01'
$uri = $basePath + $subscriptionsUri

# Get all subscriptions
$response = Invoke-RestMethod -Uri $uri -Method Get -Authentication Bearer -Token $authtoken 
$response.value | ForEach-Object {

    # For each subscription
    $subscriptionDisplayname = $_.displayName
    Write-Output "Looking in $subscriptionDisplayname"
    
    # Set the URI to get all datafactories
    $factoriesUrl = $basePath + '/subscriptions/' + $_.subscriptionId + "/resources?`$filter=resourceType%20eq%20'Microsoft.DataFactory/factories'&api-version=2021-04-01"
    $factoriesResponse = Invoke-RestMethod -Uri $factoriesUrl -Method Get -Authentication Bearer -Token $authtoken 
    $factoriesResponse.value | ForEach-Object {
        
        # For each factory - List IR
        $currentDatafactoryName = $_.name
        Write-Output "Looking in $currentDatafactoryName"
        # Set the URI to get all Integration Runtimes for a factory
        $IRUrl = $basePath + $_.id + '/integrationRuntimes?api-version=2018-06-01'
        $IRResponse = Invoke-RestMethod -Uri $IRUrl -Method Get -Authentication Bearer -Token $authtoken

        $IRResponse.value | ForEach-Object {
            # For each IR
            $currentIRName = $_.name
            
            $IRStatusUrl = $basePath + $_.id + '/getstatus?api-version=2018-06-01'
            # Get status info.
            $IRStatusResponse = Invoke-RestMethod -Uri $IRStatusUrl -Method Post -Authentication Bearer -Token $authtoken           
           
            $IRStatusResponse.properties.typeProperties.nodes | ForEach-Object {
                # IR that is not selfhosted dies not have any nodes.
                
                Write-Host 'Found node: ' $_.nodeName
                # Based per node, add information.
                
                $row = "" | Select-Object Subscription,DataFactoryName,IRName,NodeName,MachineName,Status,AutoUpdate,VersionStatus,Registered,LastUsed
                $row.Subscription = $subscriptionDisplayname
                $row.DataFactoryName = $currentDatafactoryName
                $row.IRName = $currentIRName
                $row.NodeName = $_.nodename
                $row.MachineName = $_.machineName
                $row.Status = $_.status
                $row.AutoUpdate = $IRStatusResponse.properties.typeProperties.autoUpdate
                $row.VersionStatus = $_.versionStatus
                $row.Registered = $_.registerTime
                $row.LastUsed = $_.lastConnectTime
                $csv += $row
            }
        }
    }
}

$csv | Export-Csv -Path './Integration Runtime Nodes.csv'
