function Clear-GPWmiFilterAssignment
{
<#
	.SYNOPSIS
		Clears a GPO of its assigned WMI Filter.
	
	.DESCRIPTION
		Clears a GPO of its assigned WMI Filter.
	
	.PARAMETER Policy
		The name of the GPO to clear of its assigned WMI Filter.
	
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
		PS C:\> Get-GPO -All | Clear-GPWmiFilterAssignment
	
		Clear all WMI Filters from all GPOs.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
		[Alias('Id', 'DisplayName')]
		$Policy,
		
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
			Stop-PSFFunction -String 'Clear-GPWmiFilterAssignment.FailedADAccess' -StringValues $Server -EnableException $EnableException -ErrorRecord $_
			return
		}
		#endregion Resolve Server
		
		$adParameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
	}
	process
	{
		foreach ($policyItem in ($Policy | Resolve-PolicyName))
		{
			$gpoObject = Get-ADObject @adParameters -LDAPFilter "(&(objectClass=groupPolicyContainer)(|(cn=$($policyItem))(cn={$($policyItem)})(displayName=$($policyItem))))"
			
			if (-not $gpoObject)
			{
				Write-PSFMessage -Level Warning -String 'Clear-GPWmiFilterAssignment.GPONotFound' -StringValues $policyItem
				continue
			}
			
			Invoke-PSFProtectedCommand -ActionString 'Clear-GPWmiFilterAssignment.UpdatingGPO' -ActionStringValues $policyItem, $gpoObject -Target $policyItem -ScriptBlock {
				$gpoObject | Set-ADObject @adParameters -Clear 'gPCWQLFilter'
			} -Continue -PSCmdlet $PSCmdlet -EnableException $EnableException.ToBool()
		}
	}
}