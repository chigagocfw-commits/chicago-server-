# Database Install

The script automatically creates its tables on startup from:

```text
lunar_heistcontracts/config/sv_edit.lua
```

If your server console shows MySQL/table errors, import this SQL manually:

```text
install/03_database/lunar_heistcontracts.sql
```

## Tables Created

- `lunar_contracts`
  - Stores generated/purchased contract data.

- `lunar_contracts_profiles`
  - Stores tablet usernames, profile pictures, crypto, XP, and leaderboard data.

## oxmysql Required

Make sure `oxmysql` starts before `lunar_heistcontracts`.
