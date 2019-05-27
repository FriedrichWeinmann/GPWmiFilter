function New-GPWmiFilter
{
<#
	.SYNOPSIS
		Create a new WMI filter for Group Policy with given name, WQL query and description.
	
	.DESCRIPTION
		The New-GPWmiFilter function create an AD object for WMI filter with specific name, WQL query expressions and description.
		With -PassThru switch, it output the WMIFilter instance which can be assigned to GPO.WMIFilter property.
	
	.PARAMETER Name
		The name of new WMI filter.
	
	.PARAMETER Filter
		The wmi filter query to use as condition for the filter.
	
	.PARAMETER Expression
		The expression(s) of WQL query in new WMI filter. Pass an array to this parameter if multiple WQL queries applied.
	
	.PARAMETER Description
		The description text of the WMI filter (optional).
	
	.PARAMETER Server
		The server to contact.
		Specify the DNS Name of a Domain Controller.
	
	.PARAMETER Credential
		The credentials to use to contact the targeted server.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		New-GPWmiFilter -Name 'Virtual Machines' -Filter 'SELECT * FROM Win32_ComputerSystem WHERE Model = "Virtual Machine"' -Description 'Only apply on virtual machines'
		
		Create a WMI filter to apply GPO only on virtual machines
	
	.EXAMPLE
		Get-GPWmiFilter -Server contoso.com | New-GPWmiFilter -Server fabrikam.com
	
		Copies all WMI Filters from the domain contoso.com to the domain fabrikam.com
	
	.EXAMPLE
		$filter = New-GPWmiFilter -Name 'Workstation 32-bit' -Expression 'SELECT * FROM WIN32_OperatingSystem WHERE ProductType=1', 'SELECT * FROM Win32_Processor WHERE AddressWidth = "32"' -PassThru
		$gpo = New-GPO -Name "Test GPO"
		$gpo.WmiFilter = $filter
		
		Create a WMI filter for 32-bit work station and link it to a new GPO named "Test GPO".
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
		[ValidateNotNull()]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
		[ValidateNotNull()]
		[Alias('Expression')]
		[string[]]
		$Filter,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,
		
		[string]
		$Server = $env:USERDNSDOMAIN,
		
		[System.Management.Automation.PSCredential]
		$Credential,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		$adParameters = @{
			Server	    = $Server
			ErrorAction = 'Stop'
		}
		if (Test-PSFParameterBinding -ParameterName Credential) { $adParameters['Credential'] = $Credential }
		
		try
		{
			$namingContext = (Get-ADRootDSE @adParameters).DefaultNamingContext
			# Resolve to dedicated server to ensure repeated calls are executed against same machine
			$adParameters.Server = (Get-ADDomainController @adParameters).HostName
		}
		catch
		{
			Stop-PSFFunction -String 'New-GPWmiFilter.FailedADAccess' -StringValues $Server -EnableException $EnableException -ErrorRecord $_
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		if ($Filter.Count -lt 1)
		{
			Stop-PSFFunction -String 'New-GPWmiFilter.NoFilter' -EnableException $EnableException
			return
		}
		
		$wmiGuid = "{$([System.Guid]::NewGuid())}"
		$creationDate = (Get-Date).ToUniversalTime().ToString("yyyyMMddhhmmss.ffffff-000")
		$filterString = "{0};" -f $Filter.Count.ToString()
		$Filter | ForEach-Object {
			$filterString += "3;10;{0};WQL;root\CIMv2;{1};" -f $_.Length, $_
		}
		$attributes = @{
			"showInAdvancedViewOnly" = "TRUE"
			"msWMI-Name"			 = $Name
			"msWMI-Parm1"		     = $Description
			"msWMI-Parm2"		     = $filterString
			"msWMI-Author"		     = (Get-PSFConfigValue -FullName 'GPWmiFilter.Author' -Fallback "$($env:USERNAME)@$($env:USERDNSDOMAIN)")
			"msWMI-ID"			     = $wmiGuid
			"instanceType"		     = 4
			"distinguishedname"	     = "CN=$wmiGuid,CN=SOM,CN=WMIPolicy,CN=System,$namingContext"
			"msWMI-ChangeDate"	     = $creationDate
			"msWMI-CreationDate"	 = $creationDate
		}
		
		$paramNewADObject = @{
			OtherAttributes = $attributes
			Name		    = $wmiGuid
			Type		    = "msWMI-Som"
			Path		    = "CN=SOM,CN=WMIPolicy,CN=System,$namingContext"
		}
		$paramNewADObject += $adParameters
		Invoke-PSFProtectedCommand -ActionString 'New-GPWmiFilter.CreatingFilter' -ActionStringValues $Name -ScriptBlock {
			New-ADObject @paramNewADObject
			Get-GPWmiFilter -Guid $wmiGuid @adParameters
		} -Target $Name -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet
	}
}
