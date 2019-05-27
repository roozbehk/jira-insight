#requires -modules AtlassianPS/JiraPS , Jaykul/BetterCredentials
#ReadMore https://documentation.riada.io/display/ICV50/IQL+-+REST

# Change to current directory 
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
cd $dir 

# User Script requires a valid session. Use 'New-JiraSession' or edit script.
if (-not (Get-JiraSession)) {     
Import-Module $dir\Initialize-Environment.ps1
Initialize-Environment -Server "JIRASERVERNAME" -UserName api_insight
 }
 
 Write-host "API Access" $(Get-JiraConfigServer) -ForegroundColor yellow -BackgroundColor black


$pageSize = 1
$pageNumber = 1

$IQL = 'objectType IN objectTypeAndChildren(592) AND "Status" IN ("In Service") AND "MacAddress" IS NOT empty' 
$encodedIQL = [System.Web.HttpUtility]::UrlEncode($IQL) 

$insightData = while($pageNumber -le $pageSize ){


    $query = "/rest/insight/1.0/iql/objects?objectSchemaId=4&page=$pageNumber&resultPerPage=25&includeAttributes=true&iql=$encodedIQL"

    $params = @{
        URI = "$(Get-JiraConfigServer)$query"
        Method = "Get"
    }

    $response = Invoke-JiraMethod @params

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


Write-host "Retrieved Data from " $(Get-JiraConfigServer) "... Crunching it " -ForegroundColor yellow -BackgroundColor black



$data = $insightData | % { 

    foreach ($objectEntry in $_.objectEntries){

        # $objectTypeAttribute
        $objectAttr = [ordered]@{} 

        $objectAttr.add("objectTypeId",$objectEntry.objectType.id)
        $objectAttr.add("objectTypeName",$objectEntry.objectType.name)
        $objectAttr.add("id",$objectEntry.id)



        foreach ($objectEntryAttr in $objectEntry.attributes){
        
                $objectAttr.add( $( $_.objectTypeAttributes | Where id -eq $objectEntryAttr.objectTypeAttributeId | Select-Object -ExpandProperty name ),$objectEntryAttr.objectAttributeValues.displayValue)
            
            }

        $objectAttr.add("iql",$_.iql)
        
    
    [pscustomobject]$objectAttr

    }


}

$data | Export-Csv -Path my.csv -NoTypeInformation 


 
