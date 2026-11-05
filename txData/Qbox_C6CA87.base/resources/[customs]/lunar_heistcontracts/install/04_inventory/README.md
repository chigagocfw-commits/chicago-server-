# Inventory Item Install

Add the item definitions from the matching file in `install/items/`.

## ox_inventory

Use:

```text
install/items/ox_inventory.txt
```

Usually paste these into:

```text
ox_inventory/data/items.lua
```

Then copy item images from:

```text
install/images/
```

into:

```text
ox_inventory/web/images/
```

## QBCore

Use:

```text
install/items/qb-core.txt
```

Usually paste these into:

```text
qb-core/shared/items.lua
```

Then copy images into your inventory image folder, commonly:

```text
qb-inventory/html/images/
```

or your custom inventory image path.

## ESX

Use:

```text
install/items/es_extended.txt
```

These are SQL item rows. Import them into your ESX items table if your ESX inventory still uses database items.

## Required Tablet Item

The tablet item must exist:

```text
contracts_tablet
```

This must match:

```lua
Config.tabletItem = 'contracts_tablet'
```

in:

```text
lunar_heistcontracts/config/config.lua
```

## Dealer Items

The dealer shop uses items configured in:

```text
lunar_heistcontracts/config/config.lua
```

If an item is missing from your inventory, buying/selling that item can fail.
