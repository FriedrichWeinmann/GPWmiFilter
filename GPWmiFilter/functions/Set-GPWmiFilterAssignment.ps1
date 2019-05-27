function Set-GPWmiFilterAssignment
{
<#
	.SYNOPSIS
		Assigns WMI Filters to GPOs.
	
	.DESCRIPTION
		Assigns WMI Filters to GPOs.
	
	.PARAMETER Policy
		The Group Policy Object to modify.
	
	.PARAMETER Filter
		The Filter to Apply.
	
	.PARAMETER Server
		The server to contact.
		Specify the DNS Name of a Domain Controller.
	
	.PARAMETER Credential
		The credentials to use to contact the targeted server.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Get-GPO -Name '01_A_OU_1' | Set-GPWmiFilterAssignment -Filter 'Windows 10'
	
		Assigns the WMI Filter "WIndows 10" to the GPO "01_A_OU_1"
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('Id', 'DisplayName')]
		$Policy,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		$Filter,
		
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
			Stop-PSFFunction -String 'Set-GPWmiFilterAssignment.FailedADAccess' -StringValues $Server -EnableException $EnableException -ErrorRecord $_
			return
		}
		#endregion Resolve Server
		
		$adParameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
		$domainName = (Get-ADDOmain @adParameters).DNSRoot
		
		#region Handle Explicit Filter input
		$filterExplicit = $false
		if (Test-PSFParameterBinding -Mode Explicit -ParameterName 'Filter')
		{
			if ($Filter.PSObject.TypeNames -eq 'GroupPolicy.WMIFilter')
			{
				$filterObject = $Filter
			}
			elseif ($Filter -as [System.Guid])
			{
				$filterObject = Get-GPWmiFilter @adParameters -Guid $Filter
			}
			else { $filterObject = Get-GPWmiFilter @adParameters -Name $Filter }
			
			if (-not $filterObject)
			{
				Stop-PSFFunction -String 'Set-GPWmiFilterAssignment.NoFilter' -StringValues $Filter -EnableException $EnableException
				return
			}
			if ($filterObject.Count -gt 1)
			{
				Stop-PSFFunction -String 'Set-GPWmiFilterAssignment.TooManyFilter' -StringValues $Filter -EnableException $EnableException
				return
			}
			$filterExplicit = $true
			$filterString = '[{0};{{{1}}};0]' -f $domainName, $filterObject.ID.ToString().ToUpper()
		}
		#endregion Handle Explicit Filter input
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		#region Piped Filter Input
		if (-not $filterExplicit)
		{
			if ($Filter.PSObject.TypeNames -eq 'GroupPolicy.WMIFilter')
			{
				$filterObject = $Filter
			}
			elseif ($Filter -as [System.Guid])
			{
				$filterObject = Get-GPWmiFilter @adParameters -Guid $Filter
			}
			else { $filterObject = Get-GPWmiFilter @adParameters -Name $Filter }
			
			if (-not $filterObject)
			{
				Stop-PSFFunction -String 'Set-GPWmiFilterAssignment.NoFilter' -StringValues $Filter -EnableException $EnableException
				return
			}
			if ($filterObject.Count -gt 1)
			{
				Stop-PSFFunction -String 'Set-GPWmiFilterAssignment.TooManyFilter' -StringValues $Filter -EnableException $EnableException
				return
			}
			$filterString = '[{0};{{{1}}};0]' -f $domainName, $filterObject.ID.ToString().ToUpper()
		}
		#endregion Piped Filter Input
		
		foreach ($policyItem in ($Policy | Resolve-PolicyName))
		{
			$gpoObject = Get-ADObject @adParameters -LDAPFilter "(&(objectClass=groupPolicyContainer)(|(cn=$($policyItem))(cn={$($policyItem)})(displayName=$($policyItem))))"
			
			if (-not $gpoObject)
			{
				Write-PSFMessage -Level Warning -String 'Set-GPWmiFilterAssignment.GPONotFound' -StringValues $policyItem
				continue
			}
			
			Invoke-PSFProtectedCommand -ActionString 'Set-GPWmiFilterAssignment.UpdatingGPO' -ActionStringValues $filterObject.Name, $policyItem, $gpoObject -Target $policyItem -ScriptBlock {
				$gpoObject | Set-ADObject @adParameters -Replace @{ gPCWQLFilter = $filterString }
			} -Continue -PSCmdlet $PSCmdlet -EnableException $EnableException.ToBool()
		}
	}
}