function Set-GPWmiFilter
{
<#
	.SYNOPSIS
		Update the settings of a WMI filter.
	
	.DESCRIPTION
		Update the settings of a WMI filter.
	
	.PARAMETER Name
		The name of WMI filter you want to query out.
	
	.PARAMETER Guid
		The guid of WMI filter you want to query out.
	
	.PARAMETER Filter
		The expression(s) of WQL query in new WMI filter. Pass an array to this parameter if multiple WQL queries applied.

	.PARAMETER Namespace
		The namespace of the wmi filter query.
		Defaults to: 'root\CIMv2'
		Note: This parameter is ignored for individual filter conditions that include their own namespace (<namespace>;<filter>).
	
	.PARAMETER Description
		The description text of the WMI filter.
	
	.PARAMETER PassThru
		Output the updated WMI filter instance with this switch.
	
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
		Set-GPWmiFilter -Name 'Workstations' -Filter 'SELECT * FROM Win32_OperatingSystem WHERE ProductType = "1"'
		
		Set WMI filter named with "Workstations" to specific WQL query
	
	.EXAMPLE
		Get-GPWmiFilter -Server contoso.com | Set-GPWmiFilter -Server fabrikam.com
	
		Updates changes made to the wmi filters in the domain contoso.com to the wmi filters in the domain fabrikam.com.
#>
	[CmdletBinding(DefaultParameterSetName = 'ByName', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0, ParameterSetName = "ByName")]
		[string[]]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "ByGUID")]
		[Guid[]]
		$Guid,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[Alias('Expression')]
		[string[]]
		$Filter,

		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Namespace = 'root\CIMv2',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$Description,
		
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
			Stop-PSFFunction -String 'Set-GPWmiFilter.FailedADAccess' -StringValues $Server -EnableException $EnableException -ErrorRecord $_
			return
		}
		#endregion Resolve Server
	}
	process
	{
		#region Validation and Prepare
		if (Test-PSFFunctionInterrupt) { return }
		
		if (Test-PSFParameterBinding -ParameterName Filter, Description -Not)
		{
			Stop-PSFFunction -String 'Set-GPWmiFilter.NoChangeParameters' -StringValues 'Filter', 'Description' -EnableException $EnableException -Cmdlet $PSCmdlet -Category InvalidArgument
			return
		}
		
		$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Name, Guid, Credential, Server
		#endregion Validation and Prepare
		
		foreach ($wmiFilter in (Get-GPWmiFilter @parameters))
		{
			Write-PSFMessage -String 'Set-GPWmiFilter.UpdatingFilter' -StringValues $wmiFilter.Name, $wmiFilter.DistinguishedName -Target $wmiFilter.ID
			#region Calculate AD Attribute Updates
			$adAttributes = @{
				"msWMI-Author"	   = (Get-PSFConfigValue -FullName 'GPWmiFilter.Author' -Fallback "$($env:USERNAME)@$($env:USERDNSDOMAIN)")
				"msWMI-ChangeDate" = (Get-Date).ToUniversalTime().ToString("yyyyMMddhhmmss.ffffff-000")
			}
			$changeHappened = $false
			
			#region Calculating Filter
			if ($Filter)
			{
				# If receiving a fully valid filter string (e.g.: When updating from one Forest to another)
				if ($Filter -match '3;10;\d+;WQL')
				{
					$adAttributes['msWMI-Parm2'] = $Filter
				}
				else
				{
					$filterString = '{0};' -f $Filter.Count
					foreach ($filterItem in $Filter)
					{
						if ($filterItem -match '^root\\.+?;|^root;') { $filterString += "3;10;{0};WQL;{1};" -f ($filterItem -split ";",2)[1].Length, $filterItem }
						else { $filterString += "3;10;{0};WQL;$Namespace;{1};" -f $filterItem.Length, $filterItem }
					}
					$adAttributes['msWMI-Parm2'] = $filterString
				}
				if ($adAttributes['msWMI-Parm2'] -ne $wmiFilter.Filter) { $changeHappened = $true }
			}
			#endregion Calculating Filter
			#region Adding Description
			if ($Description)
			{
				$adAttributes['msWMI-Parm1'] = $Description
				if ($Description -ne $wmiFilter.Description) { $changeHappened = $true }
			}
			#endregion Adding Description
			#endregion Calculate AD Attribute Updates
			
			#region Validate Necessity
			if (-not $changeHappened)
			{
				Write-PSFMessage -String 'Set-GPWmiFilter.NoChangeNeeded' -StringValues $wmiFilter.Name, $wmiFilter.DistinguishedName
				if ($PassThru) { $wmiFilter }
				continue
			}
			#endregion Validate Necessity
			
			#region Perform Change
			$adParameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Server, Credential
			Invoke-PSFProtectedCommand -ActionString 'Set-GPWmiFilter.PerformingUpdate' -ActionStringValues $wmiFilter.Name, $wmiFilter.DistinguishedName -ScriptBlock {
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
