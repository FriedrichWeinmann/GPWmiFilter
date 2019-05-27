@{
	'Clear-GPWmiFilterAssignment.FailedADAccess' = 'Failed to establish contact with {0}'
	'Clear-GPWmiFilterAssignment.GPONotFound'    = 'No GPO with name {0} found!'
	'Clear-GPWmiFilterAssignment.UpdatingGPO'    = 'Clearing WMI Filter from gpo {0} | {1}'
	
	'Get-DomainController.DCFound'			     = 'Resolved {0} and connected to {1}'
	
	'Get-GPWmiFilter.FailedADAccess'			 = 'Failed to establish contact with {0}'
	'Get-GPWmiFilter.SearchGuid'				 = 'Searching for AD GPO WMI Filter Object based on Guid: {0}'
	'Get-GPWmiFilter.SearchName'				 = 'Searching for AD GPO WMI Filter Object based on Name: {0}'
	
	'New-GPWmiFilter.FailedADAccess'			 = 'Failed to establish contact with {0}'
	'New-GPWmiFilter.NoFilter'				     = 'At least one Expression Method is required to create a WMI Filter.'
	'New-GPWmiFilter.CreatingFilter'			 = 'Creating GPO WMI Filter: {0}'
	
	'Remove-GPWmiFilter.Delete'				     = 'Removing WMI Filter: {0}'
	
	'Rename-GPWmiFilter.FailedADAccess'		     = 'Failed to establish contact with {0}'
	'Rename-GPWmiFilter.RenamingFilter'		     = 'Renaming WMI Filter {0} to {1} : {2}'
	'Rename-GPWmiFilter.NoChangeNeeded'		     = 'The specified name {1} is equal to the current name {0}, no update needed. : {2}'
	'Rename-GPWmiFilter.PerformingRename'	     = 'Executing the rename of the WMI Filter {0} to {1} : {2}'
	
	'Set-GPWmiFilter.FailedADAccess'			 = 'Failed to establish contact with {0}'
	'Set-GPWmiFilter.NoChangeParameters'		 = 'No change was requested. Specify either -{0} or -{1} as parameter to affect change!'
	'Set-GPWmiFilter.UpdatingFilter'			 = 'Updating the WMI Filter {0} : {1}'
	'Set-GPWmiFilter.NoChangeNeeded'			 = 'The specified settings are equal to the previous settings, no update will be performed on {0} : {1}'
	'Set-GPWmiFilter.PerformingUpdate'		     = 'Executing update to the WMI Filter {0} : {1}'
	
	'Set-GPWmiFilterAssignment.FailedADAccess'   = 'Failed to establish contact with {0}'
	'Set-GPWmiFilterAssignment.NoFilter'		 = 'Could not find a WMI Filter object for {0}! Try searching for WMI Filter object using Get-GPWmiFilter.'
	'Set-GPWmiFilterAssignment.TooManyFilter'    = 'Found more than one WMI Filter object for {0}! Be more specific or use Get-GPWmiFilter to provide a specific object to assign.'
	'Set-GPWmiFilterAssignment.GPONotFound'	     = 'No GPO with name {0} found!'
	'Set-GPWmiFilterAssignment.UpdatingGPO'	     = 'Setting WMI Filter {0} for gpo {1} | {2}'
}