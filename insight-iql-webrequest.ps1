<#
    .DESCRIPTION
        Returns IQL query from Insight Plugin API. 
    .EXAMPLE
        Return Objects with Status "In Service" and empty modelName Attribute field
        -----------
        IQL = '"Status" IN ("In Service") AND "modelName" IS empty' 
    .NOTES
        This script needs the "BetterCredentials" 
        Read More about jira insight apis's https://documentation.riada.io/display/ICV50/IQL+-+REST
#>
