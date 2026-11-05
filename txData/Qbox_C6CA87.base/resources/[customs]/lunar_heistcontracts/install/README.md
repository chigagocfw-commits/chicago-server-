# Lunar Heist Contracts Install Guide

This folder contains the local install files needed to make the cleaned `lunar_heistcontracts` resource work.

## Install Order

1. Copy both resource folders into your FiveM resources folder:
   - `lunar_bridge`
   - `lunar_heistcontracts`

2. Install required dependencies:
   - See `01_dependencies/required_resources.md`

3. Add the resources to `server.cfg` in the correct order:
   - See `02_server_cfg/server.cfg.example`

4. Add database tables:
   - The script creates its own tables on startup through `config/sv_edit.lua`.
   - A manual SQL fallback is included in `03_database/lunar_heistcontracts.sql`.

5. Add inventory items:
   - Use the files inside `items/`.
   - Use the file that matches your inventory/framework.

6. Add item images:
   - Copy files from `images/` into your inventory image folder.

7. Add weapon definitions if needed:
   - Use the files inside `weapons/`.

8. Add QBCore admin permission if using QBCore:
   - See `06_permissions/qbcore_ace_permissions.cfg`.

9. Restart the server and test:
   - See `07_after_install/checklist.md`.

## Important Folders

- `items/` contains item definitions for `ox_inventory`, `qb-core`, and `es_extended`.
- `images/` contains item image PNG files.
- `weapons/` contains weapon definitions for the signal booster/digiscanner item.
- `01_dependencies/` explains required resources.
- `02_server_cfg/` contains startup order examples.
- `03_database/` contains manual SQL.
- `04_inventory/` explains where to put item definitions.
- `05_images/` explains where to put item images.
- `06_permissions/` contains admin permission examples.
- `07_after_install/` contains a restart/test checklist.
- `08_troubleshooting/` contains fixes for common errors.

## Resource Start Names

The resource folder names must stay exactly:

```cfg
lunar_bridge
lunar_heistcontracts
```

Do not rename either folder unless you also update every reference in the manifests and scripts.
