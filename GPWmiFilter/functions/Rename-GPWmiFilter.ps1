function Rename-GPWmiFilter
{
<#
	.SYNOPSIS
		Get a WMI filter in current domain and rename it
	
	.DESCRIPTION
		The Rename-GPWmiFilter function query WMI filter in current domain with specific name or GUID and then change it to a new name.
	
	.PARAMETER Name
		The name of WMI filter you want to query out.
	
	.PARAMETER Guid
		The guid of WMI filter you want to query out.
	
	.PARAMETER NewName
		The new name of WMI filter.
	
	.PARAMETER PassThru
		Output the renamed WMI filter instance with this switch.
	
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
		Rename-GPWmiFilter -Name 'Workstations' -NewName 'Client Machines'
		
		Rename WMI filter "Workstations" to "Client Machines"
#>
	[CmdletBinding(DefaultParameterSetName = 'ByName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = "ByName")]
		[ValidateNotNull()]
		[string[]]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "ByGUID")]
		[ValidateNotNull()]
		[Guid[]]
		$Guid,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
		[ValidateNotNull()]
		[string]
		$NewName,
		
		[switch]
		$PassThru,
		
		[string]
		$Server = $env:USERDNSDOMAIN,
		
		[System.Management.Automation.PSCredential]
		$Credential,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		#region Resolve Server
		try { $PSBoundParameters.Server = Get-DomainController -Server $Server -Credential $Credential }
		catch
		{
			Stop-PSFFunction -String 'Rename-GPWmiFilter.FailedADAccess' -StringValues $Server -EnableException $EnableException -ErrorRecord $_
			return
		}
		#endregion Resolve Server
	}
	process
	{
		#region Validation and Prepare
		if (Test-PSFFunctionInterrupt) { return }
		
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Name, Guid, Credential, Server
		#endregion Validation and Prepare
		
		foreach ($wmiFilter in (Get-GPWmiFilter @parameters))
		{
			Write-PSFMessage -String 'Rename-GPWmiFilter.RenamingFilter' -StringValues $wmiFilter.Name, $NewName, $wmiFilter.DistinguishedName -Target $wmiFilter.ID
			
			#region Validate Necessity
			if ($wmiFilter.Name -eq $NewName)
			{
				Write-PSFMessage -String 'Rename-GPWmiFilter.NoChangeNeeded' -StringValues $wmiFilter.Name, $NewName, $wmiFilter.DistinguishedName
				if ($PassThru) { $wmiFilter }
				continue
			}
			#endregion Validate Necessity
			
			#region Calculate AD Attribute Updates
			$adAttributes = @{
				"msWMI-Author" = (Get-PSFConfigValue -FullName 'GPWmiFilter.Author' -Fallback "$($env:USERNAME)@$($env:USERDNSDOMAIN)")
				"msWMI-ChangeDate" = (Get-Date).ToUniversalTime().ToString("yyyyMMddhhmmss.ffffff-000")
				"msWMI-Name"   = $NewName
			}
			#endregion Calculate AD Attribute Updates
			
			#region Perform Change
			$adParameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
			Invoke-PSFProtectedCommand -ActionString 'Rename-GPWmiFilter.PerformingRename' -ActionStringValues $wmiFilter.Name, $NewName, $wmiFilter.DistinguishedName -ScriptBlock {
				Set-ADObject @adParameters -Identity $wmiFilter.DistinguishedName -Replace $adAttributes -ErrorAction Stop
			} -Target $wmiFilter.ID -EnableException $EnableException.ToBool() -PSCmdlet $PSCmdlet -Continue
			
			if ($PassThru)
			{
				$getParameters = $adParameters.Clone()
				$getParameters['Guid'] = $wmiFilter.ID
				Get-GPWmiFilter @getParameters
			}
			#endregion Perform Change
		}
	}
}
