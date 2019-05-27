function Get-GPWmiFilter
{
<#
	.SYNOPSIS
		Get a WMI filter in current domain
	
	.DESCRIPTION
		The Get-GPWmiFilter function query WMI filter(s) in current domain with specific name or GUID.
	
	.PARAMETER Name
		The name of WMI filter you want to query out.
		Default Value: '*'
	
	.PARAMETER Guid
		The guid of WMI filter you want to query out.
	
	.PARAMETER Server
		The server to contact.
		Specify the DNS Name of a Domain Controller.
	
	.PARAMETER Credential
		The credentials to use to contact the targeted server.
	
	.EXAMPLE
		PS C:\> Get-GPWmiFilter -Name 'Virtual Machines'
		
		Get WMI filter(s) with the name 'Virtual Machines'
	
	.EXAMPLE
		PS C:\> Get-GPWmiFilter
		
		Get all WMI filters in current domain
#>
	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	param
	(
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = "ByName")]
		[ValidateNotNull()]
		[string[]]
		$Name = "*",
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "ByGUID")]
		[ValidateNotNull()]
		[Guid[]]
		$Guid,
		
		[string]
		$Server = $env:USERDNSDOMAIN,
		
		[System.Management.Automation.PSCredential]
		$Credential
	)
	
	begin
	{
		$parameters = @{
			Properties = "msWMI-Name", "msWMI-Parm1", "msWMI-Parm2", "msWMI-Author", "msWMI-ID", "Modified", 'nTSecurityDescriptor'
		}
		if (Test-PSFParameterBinding -ParameterName Domain) { $parameters['Server'] = $Server }
		if (Test-PSFParameterBinding -ParameterName Credential) { $parameters['Credential'] = $Credential }
		
		$selectProperties = @(
			'"msWMI-Name" as Name'
			'"msWMI-Author" as Author'
			'"msWMI-Parm1" as Description'
			'"msWMI-ID".Trim("{}") to GUID as ID'
			'Modified'
			'"msWMI-Parm2" as Filter'
			'DistinguishedName'
			'nTSecurityDescriptor.Owner as SecOwner'
			'nTSecurityDescriptor.Access as SecAccess'
			'nTSecurityDescriptor as SecACL'
		)
		[System.Collections.ArrayList]$foundPolicies = @()
	}
	process
	{
		if ($Guid)
		{
			foreach ($guidItem in $Guid)
			{
				Write-PSFMessage -String 'Get-GPWmiFilter.SearchGuid' -StringValues $guidItem -Level Debug
				$ldapFilter = "(&(objectClass=msWMI-Som)(Name={$guidItem}))"
				Get-ADObject @parameters -LDAPFilter $ldapFilter | Select-PSFObject -Property $selectProperties -TypeName 'GroupPolicy.WMIFilter' | Where-Object {
					if ($foundPolicies -notcontains $_.ID)
					{
						$null = $foundPolicies.Add($_.ID)
						return $true
					}
				}
			}
		}
		elseif ($Name)
		{
			foreach ($nameItem in $Name)
			{
				Write-PSFMessage -String 'Get-GPWmiFilter.SearchName' -StringValues $nameItem -Level Debug
				$ldapFilter = "(&(objectClass=msWMI-Som)(msWMI-Name=$nameItem))"
				Get-ADObject @parameters -LDAPFilter $ldapFilter | Select-PSFObject -Property $selectProperties -TypeName 'GroupPolicy.WMIFilter' | Where-Object {
					if ($foundPolicies -notcontains $_.ID)
					{
						$null = $foundPolicies.Add($_.ID)
						return $true
					}
				}
			}
		}
	}
}
