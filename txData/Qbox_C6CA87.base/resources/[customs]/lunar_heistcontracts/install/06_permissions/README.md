# Admin Permissions

## QBCore

QBCore admin actions use ACE permission:

```cfg
add_ace group.admin contracts_admin allow
```

Ready-to-copy file:

```text
install/06_permissions/qbcore_ace_permissions.cfg
```

## ESX

ESX admin actions use:

```lua
Config.adminGroups
```

in:

```text
lunar_heistcontracts/config/config.lua
```

Default:

```lua
Config.adminGroups = {
    ['god'] = true
}
```
