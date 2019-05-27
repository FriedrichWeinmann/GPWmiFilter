Import-PSFLocalizedString -Path "$($script:ModuleRoot)\en-us\strings.psd1" -Module 'GPWmiFilter' -Language 'en-US'

$script:strings = Get-PSFLocalizedString -Module 'GPWmiFilter'