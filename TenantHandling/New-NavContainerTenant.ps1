﻿<# 
 .Synopsis
  Creates a new Tenant in a multitenant NAV/BC Container
 .Description
  Creates a tenant database in the Container and mounts it as a new tenant
 .Parameter containerName
  Name of the container in which you want create a tenant
 .Parameter tenantId
  Name of tenant you want to create in the container
 .Parameter sqlCredential
  Credentials for the SQL server of the tenant database (if using an external SQL Server)
 .Parameter sourceDatabase
  Specify a source database which will be the template for the new tenant (default is tenant)
 .Example
  New-NavContainerTenant -containerName test2 -tenantId mytenant
#>
function New-NavContainerTenant {
    Param
    (
        [Parameter(Mandatory=$false)]
        [string]$containerName = "navserver",
        [Parameter(Mandatory=$true)]
        [string]$tenantId,
        [PSCredential]$sqlCredential = $null,
        [string]$sourceDatabase = "tenant"
    )

    Write-Host "Creating Tenant $tenantId on $containerName"

    if ($tenantId -eq "tenant") {
        throw "You cannot add a tenant called tenant"
    }

    Invoke-ScriptInNavContainer -containerName $containerName -ScriptBlock { Param($tenantId, [System.Management.Automation.PSCredential]$sqlCredential)

        $customConfigFile = Join-Path (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName "CustomSettings.config"
        [xml]$customConfig = [System.IO.File]::ReadAllText($customConfigFile)
        if ($customConfig.SelectSingleNode("//appSettings/add[@key='Multitenant']").Value -ne "true") {
            throw "The Container is not setup for multitenancy"
        }
        $databaseServer = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseServer']").Value
        $databaseInstance = $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseInstance']").Value

        # Setup tenant
        Copy-NavDatabase -SourceDatabaseName $sourceDatabase -DestinationDatabaseName $TenantId -DatabaseServer $databaseServer -DatabaseInstance $databaseInstance -DatabaseCredentials $sqlCredential
        Mount-NavDatabase -ServerInstance $ServerInstance -TenantId $TenantId -DatabaseName $TenantId -DatabaseServer $databaseServer -DatabaseInstance $databaseInstance -DatabaseCredentials $sqlCredential

    } -ArgumentList $tenantId, $sqlCredential
    Write-Host -ForegroundColor Green "Tenant successfully created"
}
Set-Alias -Name New-BCContainerTenant -Value New-NavContainerTenant
Export-ModuleMember -Function New-NavContainerTenant -Alias New-BCContainerTenant
