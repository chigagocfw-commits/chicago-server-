# Required Resources

Install and start these before `lunar_heistcontracts`.

## Required

- `ox_lib`
  - Required by both resources through `@ox_lib/init.lua`.

- `oxmysql`
  - Required by `lunar_heistcontracts` for profiles, contracts, and saved contract data.

- `lunar_bridge`
  - Included in this package.
  - Must start before `lunar_heistcontracts`.

- `mka-lasers`
  - Required by `lunar_heistcontracts/fxmanifest.lua`.
  - The manifest loads `@mka-lasers/client/client.lua`.

- A framework:
  - `qb-core`, or
  - `es_extended`

## Inventory

The included bridge framework files use `ox_inventory` item exports by default.

Recommended:

- `ox_inventory`

If your server does not use `ox_inventory`, you must edit the item functions in:

```text
lunar_bridge/framework/qb/server.lua
lunar_bridge/framework/qb/client.lua
lunar_bridge/framework/esx/server.lua
lunar_bridge/framework/esx/client.lua
```

## Optional Dispatch Resources

Only install these if you set `Config.Dispatch.Type` to that dispatch in `lunar_bridge/config/config.lua`.

- `cd_dispatch`
- `qs-dispatch`
- `ps-dispatch`

Default dispatch type is:

```lua
Config.Dispatch.Type = 'normal'
```

## Recommended Start Order

Use the example in:

```text
install/02_server_cfg/server.cfg.example
```
