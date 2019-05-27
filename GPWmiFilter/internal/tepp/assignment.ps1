Register-PSFTeppArgumentCompleter -Command Get-GPWmiFilter -Parameter Name -Name 'GPWmiFilter.Filter'
Register-PSFTeppArgumentCompleter -Command Remove-GPWmiFilter -Parameter Name -Name 'GPWmiFilter.Filter'
Register-PSFTeppArgumentCompleter -Command Rename-GPWmiFilter -Parameter Name -Name 'GPWmiFilter.Filter'
Register-PSFTeppArgumentCompleter -Command Set-GPWmiFilter -Parameter Name -Name 'GPWmiFilter.Filter'

Register-PSFTeppArgumentCompleter -Command Set-GPWmiFilterAssignment -Parameter Filter -Name 'GPWmiFilter.Filter'