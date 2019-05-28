﻿# Description

Module to manage WMI Filters for Group Policy.

This module uses the active directory module only to manipulate WMI filters at their source: In AD.

Use this module to read, create, edit, delete or migrate WMI Filters of any kind.

# Example

> List all WMI Filters

```powershell
Get-GPWmiFilter
```

> Copy all WMI Filters from one domain to another

```powershell
Get-GPWmiFilter -Server fabrikam.com | New-GPWmiFilter -Server fabrikam.com -Credential $cred
```
