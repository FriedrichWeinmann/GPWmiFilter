function Remove-GPWmiFilter
{
<#
	.SYNOPSIS
		Remove a WMI filter from current domain
	
	.DESCRIPTION
		The Remove-GPWmiFilter function remove WMI filter(s) in current domain with specific name or GUID.
	
	.PARAMETER Guid
		The guid of WMI filter you want to remove.
	
	.PARAMETER Name
		The name of WMI filter you want to remove.
	
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
		Remove-GPWmiFilter -Name 'Virtual Machines'
		
		Remove the WMI filter with name 'Virtual Machines'
#>
	[CmdletBinding(DefaultParametersetName = "ByName", SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = "ByGUID")]
		[ValidateNotNull()]
		[Guid[]]
		$Guid,
		
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = "ByName")]
		[ValidateNotNull()]
		[string[]]
		$Name,
		
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
			Stop-PSFFunction -String 'Remove-GPWmiFilter.FailedADAccess' -StringValues $Server -EnableException $EnableException -ErrorRecord $_
			return
		}
		#endregion Resolve Server
		
		$adParameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		$getParameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Guid, Name, Server, Credential
		foreach ($wmiFilter in (Get-GPWmiFilter @getParameters))
		{
			Invoke-PSFProtectedCommand -ActionString Remove-GPWmiFilter.Delete -ActionStringValues $wmiFilter.Name -Target $wmiFilter.ID -ScriptBlock {
				Remove-ADObject -Identity $wmiFilter.DistinguishedName @adParameters -Confirm:$false -ErrorAction Stop
			} -EnableException $EnableException.ToBool() -Continue -PSCmdlet $PSCmdlet
		}
	}
}
