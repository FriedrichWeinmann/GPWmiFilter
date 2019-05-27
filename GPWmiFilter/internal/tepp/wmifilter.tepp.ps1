Register-PSFTeppScriptblock -Name 'GPWmiFilter.Filter' -ScriptBlock {
	$adParameters = @{ }
	if ($fakeBoundParameter.Server) { $adParameters['Server'] = $fakeBoundParameter.Server }
	if ($fakeBoundParameter.Credential) { $adParameters['Credential'] = $fakeBoundParameter.Credential }
	
	(Get-GPWmiFilter @adParameters).Name
}
