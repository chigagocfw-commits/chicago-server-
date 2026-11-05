# After Install Checklist

Use this checklist after copying resources and adding items.

## Server Console

- Start the server.
- Confirm `ox_lib` starts with no errors.
- Confirm `oxmysql` connects to the database.
- Confirm `lunar_bridge` starts before `lunar_heistcontracts`.
- Confirm `lunar_heistcontracts` starts with no Lua errors.

## In Game

- Give yourself the tablet item:

```text
contracts_tablet
```

- Use the tablet item.
- Confirm the tablet UI opens.
- Confirm contracts load in the tablet.
- Try buying a contract.
- Try inviting another player.
- Try starting a contract.
- Check that required heist items exist in your inventory.
- Check that item images show correctly.

## Database

Confirm these tables exist after startup:

```text
lunar_contracts
lunar_contracts_profiles
```

## Common First Test Command

Inventory/framework command names vary, but the item you need is:

```text
contracts_tablet
```
