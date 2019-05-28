<#
    .DESCRIPTION
        Returns IQL query from Insight Plugin API. 
    .EXAMPLE
        Return Objects with Status "In Service" and empty modelName Attribute field
        -----------
        IQL = '"Status" IN ("In Service") AND "modelName" IS empty' 
    .NOTES
        This script needs the "BetterCredentials" Module
        Read More about jira insight apis's https://documentation.riada.io/display/ICV50/IQL+-+REST
#>


$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
cd $dir 

Import-Module BetterCredentials -Force
$Credential = Get-Credential -UserName JIRA_USERNAME -Store

$RESTAPIServer = 'https://JIRASERVER'

$headers = @{'Content-Type' = 'application/json'}

$credJSON = @{
    username = $Credential.UserName
    password = $Credential.GetNetworkCredential().Password
} | ConvertTo-Json

Invoke-WebRequest -Uri "$RESTAPIServer/rest/auth/1/session" -Headers $headers -Method Post -Body $credJSON -SessionVariable jiraSession

Write-host "API Access" $RESTAPIServer -ForegroundColor yellow -BackgroundColor black

# Change IQL
$IQL = 'objectSchemaId=4 AND objectType IN objectTypeAndChildren(592) AND "Status" IN ("In Service") AND "MacAddress" IS NOT empty' 
$encodedIQL = [System.Web.HttpUtility]::UrlEncode($IQL) 

$pageSize = 1
$pageNumber = 1


$insightData = while($pageNumber -le $pageSize ){


    $query = "/rest/insight/1.0/iql/objects?objectSchemaId=4&page=$pageNumber&resultPerPage=500&includeAttributes=true&iql=$encodedIQL"

    $response = Invoke-WebRequest -Uri $($RESTAPIServer+$query)  -Method Get -WebSession $jiraSession
    $response = $response.Content | ConvertFrom-Json
    Write-host "Page $pageNumber returned. totalFilterCount is $($response.totalFilterCount)" -ForegroundColor yellow -BackgroundColor black
 
    $pageNumber ++
    $pageSize = $response.pageSize

    [PSCustomObject]@{ 
        objectEntries = $response.objectEntries 
        objectTypeAttributes = $response.objectTypeAttributes 
        objectTypeId = $response.objectTypeId
        objectTypeIsInherited = $response.objectTypeIsInherited
        iql = $response.iql
    }

}


Write-host "Retrieved Data from " $RESTAPIServer "... Crunching it " -ForegroundColor yellow -BackgroundColor black



$data = $insightData | % { 

    foreach ($objectEntry in $_.objectEntries){

        # $objectTypeAttribute
        $objectAttr = [ordered]@{} 

        $objectAttr.add("objectTypeId",$objectEntry.objectType.id)
        $objectAttr.add("objectTypeName",$objectEntry.objectType.name)
        $objectAttr.add("objectId",$objectEntry.id)
        $objectAttr.add("objectName",$objectEntry.name)
        $objectAttr.add("objectKey",$objectEntry.objectKey)



        foreach ($objectEntryAttr in $objectEntry.attributes){
        
                $objectAttr.add( $( $_.objectTypeAttributes | Where id -eq $objectEntryAttr.objectTypeAttributeId | Select-Object -ExpandProperty name ),$objectEntryAttr.objectAttributeValues.displayValue)
            
            }

        $objectAttr.add("iql",$_.iql)
        
    
    [pscustomobject]$objectAttr

    }


}

$data | Export-Csv -Path Insight-iql-assetdetails.csv -NoTypeInformation 

