function Resolve-PolicyName
{
<#
	.SYNOPSIS
		Simple helper tool for parsing GPO object/name input.
	
	.DESCRIPTION
		Simple helper tool for parsing GPO object/name input.
		Returns name or id.
		ONLY use in pipeline.
	
	.PARAMETER InputObject
		The object to parse.
	
	.EXAMPLE
		PS C:\> $Policy | Resolve-PolicyName
	
		Returns IDs or Names of all policy items in $Policy
#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)
	
	process
	{
		if ($null -eq $InputObject) { return }
		if ($InputObject.GetType().FullName -eq 'Microsoft.GroupPolicy.Gpo') { return $InputObject.Id -as [string] }
		if ($InputObject.Id) { return $InputObject.Id -as [string] }
		if ($InputObject.DisplayName) { return $InputObject.DisplayName -as [string] }
		$InputObject -as [string]
	}
}