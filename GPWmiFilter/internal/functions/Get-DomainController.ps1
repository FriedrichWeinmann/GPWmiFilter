function Get-DomainController
{
<#
	.SYNOPSIS
		Returns a specific domain controller.
	
	.DESCRIPTION
		Helper function that resolves the server parameter into a specific domain controller to operate against.
		If the server parameter is given an actual domain controller, it will try to contact it and return its name.
		If given a domain name, it will contact an arbitrary domain controller and return its name.
	
	.PARAMETER Server
		The server to contact.
		Specify the DNS Name of a Domain Controller or domain.
	
	.PARAMETER Credential
		The credentials to use to contact the targeted server.
	
	.EXAMPLE
		PS C:\> Get-DomainController -Server 'contoso.com'
	
		Returns a domain controller of the domain 'contoso.com'
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Server,
		
		[AllowNull()]
		[System.Management.Automation.PSCredential]
		$Credential
	)
	
	$adParameters = @{
		Server	    = $Server
		ErrorAction = 'Stop'
	}
	if ($Credential -and ($Credential -ne [System.Management.Automation.PSCredential]::Empty))
	{
		$adParameters['Credential'] = $Credential
	}
	
	try { $controller = (Get-ADDomainController @adParameters).HostName }
	catch { throw }
	Write-PSFMessage -Level Debug -String 'Get-DomainController.DCFound' -StringValues $Server, $controller
	$controller
}