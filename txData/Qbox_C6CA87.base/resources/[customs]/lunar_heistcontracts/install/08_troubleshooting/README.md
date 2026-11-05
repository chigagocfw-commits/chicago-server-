# Troubleshooting

## Tablet Does Not Open

Check:

- `contracts_tablet` exists in your inventory item list.
- You actually have the item.
- `Config.tabletItem` is still `contracts_tablet`.
- `lunar_bridge` started before `lunar_heistcontracts`.
- `ox_lib` is started.

## NUI Tablet Is Blank

Check:

- `lunar_heistcontracts/web/build/index.html` exists.
- `lunar_heistcontracts/web/build/assets/` exists.
- The resource folder was not renamed.
- Browser/NUI cache may need clearing after replacing files.

## Native Crash / SIGSEGV On Start

If FiveM prints native crash reporting instead of a Lua error, first update your FiveM artifact/client and confirm all required dependencies start cleanly.

This cleaned build lazy-loads the Lunar prompt DUI texture so `lunar_bridge` does not create a CEF/browser texture during resource startup.

If the crash only happens when using 3D prompts:

- Set `Config.Target = true` in `lunar_bridge/config/config.lua` and use your target resource.
- Or set `Config.Prompts.Enabled = false` in `lunar_bridge/config/config.lua` to disable built-in prompts temporarily.
- Try switching `Config.Prompts.Dict` from `prompt` to `prompt_old`.
- Clear FiveM cache after replacing the resource.

## MySQL Errors

Check:

- `oxmysql` starts before `lunar_heistcontracts`.
- Your database connection string is correct.
- Import `install/03_database/lunar_heistcontracts.sql` manually if automatic table creation fails.

## Missing Item Errors

Check:

- Add items from `install/items/`.
- Add weapon definitions from `install/weapons/`.
- Copy images from `install/images/`.
- Restart your inventory resource after adding items/images.

## Dispatch Errors

Check:

```lua
Config.Dispatch.Type
```

in:

```text
lunar_bridge/config/config.lua
```

If you use `cd_dispatch`, `qs-dispatch`, or `ps-dispatch`, that dispatch resource must be installed and started.

If you do not use an external dispatch, keep:

```lua
Type = 'normal'
```

## Admin Button Does Not Work

For QBCore, add:

```cfg
add_ace group.admin contracts_admin allow
```

For ESX, edit:

```lua
Config.adminGroups
```

in:

```text
lunar_heistcontracts/config/config.lua
```

## mka-lasers Error

The resource manifest requires:

```text
@mka-lasers/client/client.lua
```

Install and start `mka-lasers` before `lunar_heistcontracts`.
