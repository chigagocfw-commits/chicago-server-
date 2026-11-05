# OXLYN Advanced Garage System

**Version 1.2.1** · Escrow edition · ESX Legacy / QBCore / Qbox · OneSync · oxmysql

A complete garage system for FiveM. Admins build every garage **in game**, with no coordinates to copy. Players get a **modern interface** with real vehicle renders. Parking **brings every vehicle back exactly as it was left**. It also includes **job and gang fleets**, **impound lots**, a **park mode** and **vehicle sale contracts** signed on paper inside the car. It works on **ESX, QBCore and Qbox** and detects them automatically, along with the most common inventories, key systems, fuel scripts, target resources and notification resources.

---

## Contents

1. [Features](#1-features)
2. [Editions: Escrow and Open Source](#2-editions-escrow-and-open-source)
3. [Requirements](#3-requirements)
4. [Quick start (5 minutes)](#4-quick-start-5-minutes)
5. [Installation in detail](#5-installation-in-detail)
6. [Framework notes: ESX, QBCore, Qbox](#6-framework-notes-esx-qbcore-qbox)
7. [Configuration guide](#7-configuration-guide)
8. [Permissions](#8-permissions)
9. [Commands](#9-commands)
10. [Using a garage (players)](#10-using-a-garage-players)
11. [The garage editor (admins)](#11-the-garage-editor-admins)
12. [Job and gang garages: fleets](#12-job-and-gang-garages-fleets)
13. [Impound](#13-impound)
14. [Park mode](#14-park-mode)
15. [Sale contracts](#15-sale-contracts)
16. [Notifications](#16-notifications)
17. [Compatibility](#17-compatibility)
18. [Languages](#18-languages)
19. [Exports and events](#19-exports-and-events)
20. [Garage schema](#20-garage-schema)
21. [Database](#21-database)
22. [The interface (web)](#22-the-interface-web)
23. [Updating](#23-updating)
24. [Troubleshooting and FAQ](#24-troubleshooting-and-faq)

---

## 1. Features

**For admins — `/garageeditor`**
- Create **garages** and **impound lots** anywhere, for cars and motorcycles, boats, aircraft or everything.
- Set the interaction point **from where you stand**, **from the vehicle you sit in** or **by aiming at the ground**.
- Place the **parking spots** and draw the **parking zone** from a **free camera** over the garage, with the mouse.
- **Access** per garage: everyone, jobs (with a minimum grade), gangs or specific players.
- **Fleet** per garage: the garage's own vehicles for a job or gang, with a minimum grade and a limit on how many can be out at once.
- Per garage: **attendant ped** (18 presets or any model), **blip**, **vehicle collision** inside the parking area, and an own accent colour or menu layout.
- **Theme editor** with a live preview: 9 colour presets or custom colours, corners, 4 menu layouts, world icon and prompt styles, and how a garage opens (E key, ox_target / qb-target, or both).
- **Park mode** rules, edited in game.

**For players**
- A garage menu with a **real render** of every vehicle (738 vanilla models included; add-on vehicles get a coloured silhouette). It shows engine, body and fuel gauges, where each vehicle is, and when and by whom it was parked.
- **Cinematic preview**: choosing a vehicle puts it on a free spot with you at the wheel and a camera orbiting it. **Spawn** takes it out right there.
- **Realistic parking**: damage, fuel, dirt, mods, colours, extras, broken windows and doors and tyres are saved. The vehicle comes back in the same state.
- Every other vehicle is handled from the same menu:
  - **Locate** any vehicle: its live position or where it was last seen, with a waypoint.
  - **Rescue** a vehicle left out in the world, for a fee.
  - **Bring here** a vehicle parked in another garage, for a valet fee.
  - Give any vehicle a **nickname**.
- Fully usable from the keyboard: ↑ / ↓, Enter, Esc, L.

**Around the garages**
- **Impound lots** with their own interface:
  - a printed *Notice of impoundment*;
  - `/impound` for police and mechanics, with a tool that lists the vehicles around you;
  - a release desk where owners pay the fee.
- **Park mode (`/park`)**: leave your vehicle where it stands. It survives restarts, only you can get in, and it is towed after a configurable number of hours.
- **Sale contracts**: sell a vehicle to a passenger on a realistic agreement paper. They sign and pay with cash or card, and ownership, keys and money move on the spot.

**Under the hood**
- **Server-authoritative.** The server:
  - reads the plate from the real entity;
  - checks the driver seat and the distance;
  - takes ownership from the database;
  - charges every fee.
  The client is never trusted.
- **No duplicate or ghost vehicles**: a vehicle only exists once, and the server deletes it when it is parked.
- Everything on screen is the resource's **own interface**. No game markers and no default GTA text, with an optional bridge to your notification resource.

---

## 2. Editions: Escrow and Open Source

The system ships in two editions. The features are identical; only what you can read and edit is different.

| | **Escrow** (`oxlyn-garage.zip`) | **Open Source** (`oxlyn-garage-OPENSOURCE.zip`) |
|---|---|---|
| `config/config.lua` | ✅ readable and editable | ✅ readable and editable |
| `locales/*.lua` (all texts) | ✅ readable and editable | ✅ readable and editable |
| `install/`, `sql/`, `images/`, `README.md`, `CHANGELOG.md` | ✅ readable | ✅ readable |
| `client/`, `server/`, `shared/` (Lua) | 🔒 protected by the Cfx asset escrow | ✅ readable and editable |
| Interface | built interface only (`web/dist`) | built interface **and its full source** (`web/src`, React + Vite + TypeScript) |

Both zips contain a folder called **`oxlyn-garage`**. Keep that name: other scripts and the item call `exports['oxlyn-garage']`.

> **You have the Escrow edition.** `config/`, `locales/`, `install/`, `sql/`, `images/` and the built interface (`web/dist`) are open. The Lua in `client/`, `server/` and `shared/` is protected by the Cfx asset escrow. Everything is adjustable from `config/config.lua`, the in-game editor and the hooks in the config: `Config.Admin.check`, `Config.Notify.custom` / `event`, and `Config.VehicleKeys.extraClientEvents` / `extraServerEvents`. The Open Source edition includes all of the code if you need to change it.

---

## 3. Requirements

| | |
|---|---|
| **Server** | FiveM server artifact with **OneSync** enabled (the server inspects and deletes vehicles) |
| **Database** | [`oxmysql`](https://github.com/overextended/oxmysql) |
| **Framework** | ESX Legacy, QBCore or Qbox, detected automatically. Standalone also runs, but then no vehicle belongs to anyone. |
| **Optional** | ox_target or qb-target; a vehicle keys resource; a fuel resource; a notification resource. All are detected automatically (see [Compatibility](#17-compatibility)). |

---

## 4. Quick start (5 minutes)

1. Extract the zip into your resources folder. You get `resources/oxlyn-garage/`.
2. In `server.cfg`, after your framework, inventory and `oxmysql`:
   ```cfg
   ensure oxmysql
   ensure es_extended        # or qb-core / qbx_core
   ensure ox_inventory       # your inventory
   ensure oxlyn-garage

   add_ace group.admin oxlyn.garage.admin allow
   ```
3. Add the `vehicle_contract` item to your inventory (see [5.3](#53-the-contract-item)). You can skip this if you do not want sale contracts.
4. Start the server. The console prints:
   ```
   [oxlyn-garage] v1.2.1 ready · framework esx · db esx · inventory ox_inventory · keys none
   ```
   The database tables are created and 9 starter garages are added: Legion Square, Vinewood, Sandy Shores, Paleto Bay, a boat dock, an LSIA hangar, a Mission Row police garage with a fleet, and 2 impound lots.
5. In game, type **`/garageeditor`** and adjust the starter garages to your map, or delete them and build your own.

That is it. Players walk up to a garage point and press **E**.

---

## 5. Installation in detail

### 5.1 Resource order

`oxlyn-garage` must start **after** `oxmysql`, your framework and your inventory. Target, keys, fuel and notification resources can start in any order: they are detected when they are used, and target zones are rebuilt when the target resource restarts.

Do **not** run a second garage script at the same time (esx_garage, qb-garages, jg-advancedgarages, cd_garage, …). Both would spawn and delete the same vehicles. Vehicles that another garage script already stored keep working: they appear in every garage of the right type until they are parked in one.

### 5.2 Admin permission

The editor and the admin commands are protected by `Config.Admin`. The simplest setup is the ace line from the quick start:

```cfg
add_ace group.admin oxlyn.garage.admin allow
add_principal identifier.license:YOUR_LICENSE group.admin
```

An `add_ace` written in `server.cfg` only applies after a **full server restart**. To apply it right away, paste the same lines in the live server console. See [Permissions](#8-permissions) for groups, jobs and identifiers, and use `/garageaccess <id>` whenever someone "is admin but it says no".

### 5.3 The contract item

The sale contract is an item called `vehicle_contract`. Two images are in `images/`: `vehicle_contract.png` and `vehicle_contract_signed.png`.

**ox_inventory.** Paste this into `ox_inventory/data/items.lua` (it is also in `install/ox_inventory_item.lua`) and copy both images into `ox_inventory/web/images/`:

```lua
['vehicle_contract'] = {
    label = 'Vehicle Sale Contract',
    weight = 50,
    stack = false,
    close = true,
    consume = 0,
    description = 'A vehicle sale agreement. Sit in your vehicle with the buyer and use it to sell the vehicle on the spot.',
    server = { export = 'oxlyn-garage.vehicle_contract' },
},
```

The `server.export` line is required. Without it, nothing happens when the item is used.

**QBCore / Qbox with qb-inventory, ps-inventory, lj-inventory, qs-inventory and similar.** Paste `install/qb-core_item.lua` into `qb-core/shared/items.lua`, and copy the images into your inventory's image folder. The garage registers the item as usable by itself.

**ESX with the default inventory, or any inventory that reads the `items` table:**

```sql
INSERT INTO items (name, label, weight) VALUES ('vehicle_contract', 'Vehicle Sale Contract', 1);
```

Give the item to players through a shop, crafting or `/giveitem`. The deal is live, so no item metadata is needed and any inventory works.

### 5.4 Database

Nothing to import. On first start the resource creates its tables with `CREATE TABLE IF NOT EXISTS`. If your database user cannot create tables, import `sql/install.sql` by hand. On ESX it also adds the `parking` and `pound` columns to `owned_vehicles` when they are missing. See [Database](#21-database).

### 5.5 Starter garages

`Config.DefaultGarages` is written to the database **once**, the first time the resource starts with an empty `oxlyn_garages` table. After that, the editor owns the garages and changing `Config.DefaultGarages` does nothing. To re-seed, delete every row of `oxlyn_garages` and restart.

---

## 6. Framework notes: ESX, QBCore, Qbox

Detection order is **Qbox → QBCore → ESX**. Qbox ships a qb-core shim, so it has to be checked first. You can force one with `Config.Framework = 'esx' | 'qbcore' | 'qbox'`.

| | ESX Legacy | QBCore | Qbox |
|---|---|---|---|
| Vehicle table | `owned_vehicles` (`owner`, `plate`, `vehicle` JSON, `stored`, `parking`, `pound`, `type`) | `player_vehicles` (`citizenid`, `plate`, `mods`, `garage`, `state`, `fuel`, `engine`, `body`, `depotprice`) | `player_vehicles` (same as QBCore) |
| Player identifier | `xPlayer.identifier` (with multicharacter, the character identifier) | `citizenid` | `citizenid` |
| Jobs and grades | ✅ `job.name` / `job.grade` | ✅ `job.name` / `job.grade.level` | ✅ |
| On duty (optional) | — | ✅ `job.onduty` | ✅ |
| Gangs | ✗ ESX has no gangs, so use job garages | ✅ `gang.name` / `gang.grade.level` | ✅ |
| Admin groups | `xPlayer.getGroup()`, e.g. `admin` | QBCore permissions + `qbcore.<group>` aces | `qbx.<group>` aces |
| Money | `money` (cash) and `bank` accounts | `cash` and `bank` | `cash` and `bank` |
| Vehicle type | `owned_vehicles.type`: `car` / `boat` / `aircraft` (written for vehicles added by the garage; the model decides when missing) | read from the model | read from the model |

Vehicle properties use the usual ESX / ox_lib / QBCore keys (`color1`, `modEngine`, `engineHealth`, `fuelLevel`, …). Rows written by vehicle shops, mechanic scripts and your previous garage load unchanged.

---

## 7. Configuration guide

Everything is in **`config/config.lua`**, and every option is commented there. Some settings live in the **database** instead: each garage, the interface theme and the park mode rules. The config only holds their **defaults**, and whatever an admin saves in game wins. Restart the resource after editing the config.

| Section | What it controls | Most-asked options |
|---|---|---|
| **1. General** | language, framework, currency format | `Config.Locale = 'en'`, `Config.Framework = 'auto'`, `Config.Currency` |
| **2. Admin permissions** | who may open the editor and use the admin commands | `methods`, `aces`, `groups`, `jobs`, `identifiers`, `check` (your own function) |
| **3. Commands** | every command name (`false` disables a command) | `garage`, `park`, `impound`, `admincar`, `contract` |
| **4. Interaction** | E prompt or ox_target / qb-target, the key, world icons | `mode = 'prompt' \| 'target' \| 'both'`, `key = 38` |
| **5. Garage rules** | fees, global garages, restart behaviour, fleets, cinematic preview | `global`, `transferFee`, `retrieveFee`, `lostVehicles`, `restoreOnRestart`, `fleetPerPlayer`, `fleetRecall`, `preview.enabled` |
| **6. Impound** | who can impound, fees, default lot, quick reasons | `jobs = { police = 0, mechanic = 0 }`, `defaultFee`, `maxFee`, `defaultLot = 'nearest'` |
| **6b. Park mode** | the defaults of `/park`, edited in game afterwards | `maxPerPlayer`, `maxHours`, `towFee`, `collision` |
| **7. Sale contracts** | the `vehicle_contract` item and the deal rules | `item`, `tax`, `offerMinutes`, `accounts`, `sellerReceives` |
| **8. Keys / notifications / fuel** | bridges to other resources | `Config.VehicleKeys.system`, `Config.Notify.system`, `Config.Fuel.system` (all `'auto'` except `Notify`, which is `'builtin'`) |
| **9. Blips & peds** | blip defaults per garage type, attendant ped defaults, hiding blips of garages the player cannot use | `showOnlyAccessible`, `Config.Peds.spawnDistance` |
| **10. Interface** | defaults of the theme editor | `theme.preset`, `style`, `hideHudWhileOpen` |
| **11. Default garages** | the starter garages, used once | see [Garage schema](#20-garage-schema) |

**Common recipes**
- *Take stored vehicles out of other garages:* set `Config.Garage.global = true`. Garages with **Only vehicles in this garage** enabled remain local.
- *Free valet and rescue:* set `transferFee = 0` and `retrieveFee = 0`.
- *Garages open with ox_target only:* set `Config.Interaction.mode = 'target'`, or choose it in game under `/garageeditor → Theme → Opening a garage`.
- *Vehicles left out stay "out" after a restart:* set `Config.Garage.restoreOnRestart = false`. In garage recovery mode, they can then be rescued for the fee.
- *Sale tax as a money sink:* `Config.Contract.tax = 5` means the buyer pays the price and the seller gets 95 %.
- *Use your server's notifications:* set `Config.Notify.system = 'auto'` (see [Notifications](#16-notifications)).

---

## 8. Permissions

`Config.Admin` decides who is an admin. It is checked on the server, and a player is an admin as soon as **any** enabled method says yes:

| Method | What it checks |
|---|---|
| `ace` | `IsPlayerAceAllowed` for one of `Config.Admin.aces` (default `oxlyn.garage.admin`) |
| `group` | the framework group is in `Config.Admin.groups` (`admin`, `superadmin`, `god`). The `group.<name>`, `qbcore.<name>`, `qbx.<name>` and `esx.<name>` aces also count, which is what makes **txAdmin** admins work. |
| `job` | the player's job is in `Config.Admin.jobs = { mapper = 0 }` with at least that grade (optionally only on duty) |
| `identifier` | the player's license, discord, steam or fivem id is in `Config.Admin.identifiers` |
| `check` | your own function: `check = function(src) return exports.myperms:isStaff(src) end`. Return `true` or `false` to decide, or `nil` to let the other methods decide. |

The server console always passes. `Config.Admin.everyone = true` opens the editor to every player, which is meant for test servers only.

**"I'm admin and it says no."** Run `/garageaccess <id>` in the console or in game. It prints every method with its verdict. When access is denied, it also prints the exact `add_ace` / `add_principal` lines with that player's real license.

---

## 9. Commands

| Command | Who | What it does |
|---|---|---|
| `/garageeditor` | admins | opens the editor (garages, theme, park mode) |
| `/garageaccess <id>` | console, admins | permission report for a player |
| `/garage` | everyone | opens the garage you are standing at |
| `/garage <player ID>` | admins (`Config.Admin`) | manages the connected player’s owned vehicles by category and garage |
| `/park` | everyone (when park mode is enabled) | leaves the vehicle next to you in park mode (see [Park mode](#14-park-mode)) |
| `/impound` | `Config.Impound.jobs` | opens the **impound tool**: the vehicles around you, with a fee, a reason and a target lot |
| `/impound [fee] [reason]` | `Config.Impound.jobs` | quick impound of the vehicle you are in, or the closest one |
| `/admincar` | admins | the vehicle you are sitting in becomes **yours**. It is written to your vehicles with its current mods and damage, you get the keys, and it appears in your garage menu. An empty plate, or one that already belongs to someone, is replaced by a new unique plate. Every use is logged in the console. |
| `/contract` | admins | **showcase for videos**: an NPC buyer sits in your passenger seat and signs and "pays" the sale contract on paper only. Nothing real changes. |

Every name can be changed in `Config.Commands`, and `false` disables a command.

**Player vehicle administration.** Use **/garage 12** to manage connected player ID 12. The same **Config.Admin** checks as the editor apply, including the configured **oxlyn.garage.admin** ACE. Choose cars/motorcycles, boats or aircraft, select a garage, then inspect vehicles or add one by model name/hash. Leave the plate empty to generate a unique plate. New vehicles are saved in that garage with factory-default condition and are not spawned into the world. Only garages that accept the vehicle and allow the target's personal vehicles can receive additions.

**Remove vehicle** asks for confirmation naming the player and plate, then permanently deletes that player's ownership record. Return active or parked vehicles and finish pending sales/deliveries first; busy vehicles are protected. Existing impounded vehicles and vehicles assigned to missing garages are visible for management. Sessions are tied to the target character; requests are rejected and the panel closes if that player has disconnected or the administrator has lost permission. Add/remove operations are logged in the server console.

---

## 10. Using a garage (players)

**Opening.** Walk to the garage point, where the attendant stands and a floating icon is shown, and press **E**. Depending on the server setting, the garage may open through the ox_target / qb-target option instead, or both. `/garage` does the same.

**The menu** lists your vehicles for this garage:

| State | Meaning | Action |
|---|---|---|
| **Ready** | parked here | **Spawn** on the first free spot |
| **Parked at X** | parked in another garage | **Bring here** (valet fee). Only shown with `global = false`. |
| **Out** | taken out and not parked again | **Locate** (free); recovery follows `Config.Garage.lostVehicles` |
| **Impounded** | at an impound lot | shows the lot, the fee and the reason. Pay at the lot. |
| **Park mode** | left with `/park` | **Locate**, and the time left before it is towed |
| **Fleet** | the garage's own vehicle | **Spawn** (see [Fleets](#12-job-and-gang-garages-fleets)) |

**Impound presentation.** Open **/garageeditor → select an impound → Identity → Presentation**, choose **Document** or **Cinematic camera**, then save. Existing lots use Document. Cinematic mode uses the same local vehicle camera (drag to orbit, scroll to zoom) while keeping the fine, reason, payment account and paid release. It requires `Config.Garage.preview.enabled`; if a preview cannot load or no bay is available, the document remains available. The choice is saved per lot in its existing JSON document (`impound.presentation`), without a SQL migration.

**Cinematic preview.** Choosing a vehicle puts a local copy on a free spot with you at the wheel and a camera orbiting it. Drag to look around and scroll to zoom. Choose another vehicle to swap, or press **Spawn** to take it out right where it stands. Other players never see the preview copy. You can turn it off with `Config.Garage.preview.enabled`.

**Parking.** Drive into the garage's parking area, which is the drawn zone or the radius around the point and spots, and press **E**:
- A car or motorcycle driver steps out beside the vehicle.
- A boat or aircraft pilot is put back in front of the attendant (`Config.Garage.returnToAttendant`).
- Only the **driver** can park, and only a vehicle **registered to them**. `allowStoreOthers` relaxes the owner check.
- The prompt says so when a garage does not accept that vehicle type.

**Keys and engine.** The server approves one grant per spawn. QS, QB and Qbox also confirm that the client can see its keys before handing over the driver seat. Garage takeout starts the engine after that handoff, including when an old config still contains `spawnEngineOn = false`. Saved engine damage and fuel still apply; this never repairs or refuels the vehicle. CodeM/LB valet leave the engine running after NPC exit. Ordinary storage respects `removeOnStore`; sale, impound and fleet recall revoke the former holder regardless of that option. Failed key integration leaves a valid vehicle out with its engine off and an error notification, but no permanent auto-start lock; it does not spawn another copy. Replace the phone client adapters from `install/` too when upgrading to 1.0.6. Keys already granted by a dealership or another resource are recognised instead of duplicated or refused, and revoking a key nobody holds succeeds silently. See [Vehicle-key integration](EXPORTS.MD#vehiclekeys-v120) for APIs, limitations and removal hooks.

**Locate.** Press the button or **L**. The menu shows the street, the district, the distance and whether someone is driving. The game sets a waypoint and a flashing blip.

**Keyboard.** ↑ / ↓ choose a vehicle, **Enter** runs the main action, **L** locates, **Esc** goes back or closes.

---

### Lost vehicles: garage recovery or automatic impound

Edit **config/config.lua → Config.Garage.lostVehicles**:

```lua
lostVehicles = {
    mode = 'impound',          -- 'garage' (default), 'impound', or 'disabled'
    autoImpound = true,
    graceSeconds = 120,
    checkInterval = 60,
    impound = {
        lot = nil,            -- choose an existing lot; or its exact editor ID
        fee = 500,
        reason = 'Abandoned / lost vehicle',
    },
},
```

- **garage:** retains Rescue, `retrieveFee`, and the existing `restoreOnRestart` setting.
- **impound:** out vehicles that no longer exist in the **server** world go automatically to the configured lot after the grace period. The owner pays the fixed fine when releasing the vehicle at an impound lot. `autoImpound = false` instead requires the player to use **Send to impound** after the same grace period.
- **disabled:** removes garage recovery and automatic impound; Locate and normal driving/storage still work.

The shipped mode is `garage` to preserve existing behavior. Change it to `impound` to enable the automatic policy. Checks are periodic; with 120 seconds of grace and a 60-second interval, processing occurs on a check after the grace expires, not at an exact timer deadline. A resource restart starts a fresh observation window. `restoreOnRestart` only applies in garage mode and cannot bypass the other modes.

Client streaming distance never counts as disappearance. Live vehicles, `/park`, pending spawns and vehicle sale contracts are excluded. The scan reads only out-vehicle identifiers until a missing candidate is eligible, and does not run every frame. A bad/missing impound destination leaves the vehicle out so the configuration can be corrected. The fine is capped by `Config.Impound.maxFee`; the fixed reason is stored with the impound record.

Loss preserves the **last saved** tuning/damage snapshot. Changes made after the last save cannot be read from an entity that has already disappeared. The local-garage option still limits manual recovery, while automatic lost-vehicle impound can send a local vehicle to its impound lot.

## 11. The garage editor (admins)

`/garageeditor` opens a two-column studio:
- **Left:** every garage as a compact row, grouped by who can use it (public, job, gang, private, impound lots). Groups fold and unfold, and **Theme** and **Park mode** sit at the top.
- **Right:** the selected garage, in six pages.

| Page | What you set |
|---|---|
| **Identity** | name, id (letters, digits and underscores), kind (garage or impound lot), what it accepts (cars & motorcycles, motorcycles, boats, aircraft or everything), **Only vehicles in this garage** for personal garages, and the release fee plus **Document / Cinematic camera** presentation for impound lots |
| **Location** | the interaction point (X / Y / Z / heading) with **Use my position**, **Pick in world** and **Teleport there**; the **attendant** (on/off, 18 presets or any ped model, and a scenario); the on-foot radius; the **parking area** (a radius, or a zone drawn in the world); and **vehicle collision** on/off inside the parking area |
| **Parking** | the numbered spots: **Place in freecam**, **Add from my vehicle** (the exact position and heading of the car you are in), **Add at my position** or **Pick in world**. Every value stays editable, and each spot can be teleported to or deleted. |
| **Fleet** | garages only: personal vehicles on/off, the plate prefix, the per-player limit, bring back empty vehicles, and the garage's own vehicles (see [Fleets](#12-job-and-gang-garages-fleets)) |
| **Display** | blip (on/off, sprite, colour, scale, label) and this garage's own accent colour or menu layout |
| **Access** | everyone, jobs (`police 0`, one per line, as `name minGrade`), gangs, or specific identifiers |

**Save** validates everything on the server: ids are slugged, radii clamped and headings wrapped. It then writes the database and updates every connected player at once. **Delete** asks for a second click. **Duplicate** copies the garage under a new id. While the editor is open, nearby garages are drawn in the world with their radii and numbered spots.

**Pick in world.** The window hides and a card shows the coordinates. **E** places, the **wheel** rotates, **R** turns a quarter and **Backspace** cancels. When you are in a vehicle, its position and heading are used.

### Only vehicles in this garage

Open **/garageeditor → select a garage → Identity → Only vehicles in this garage**, enable the switch and save. It uses the same toggle style as the rest of the editor. The switch appears for ordinary garages with personal vehicles enabled (Fleet page).

When enabled, stored/out personal vehicles are listed only at their assigned garage. Other garages cannot take, transfer or rescue those vehicles remotely, even with `Config.Garage.global = true`; the local garage cannot import vehicles assigned elsewhere either. Collection/rescue of its assigned cars requires the player near its interaction point or a configured parking spot, including cinematic preview. Players can still drive a vehicle and store it at another garage to change its home.

Phone Garage apps can still list and locate these vehicles, but `canValet` is false and valet requests are rejected. Impound information and collection at the impound lot are unchanged, as are fleet vehicles. Newly imported vehicles without a valid ordinary garage remain recoverable until parked at a registered garage.

The setting defaults to off, retaining the existing global/Bring here rules. It is stored as `localVehiclesOnly = true` in the existing garage JSON, with no SQL migration. Changing a garage label keeps vehicle associations; changing its ID uses the existing delete/recreate behavior, so keep IDs stable after parking vehicles there. Trusted administrative exports can still reassign a vehicle deliberately.

### Drawing a parking zone

Go to **Location → Parking area → Draw zone**. A free camera flies over the garage.

| Input | Action |
|---|---|
| Left click on the ground | add a corner |
| Drag a corner / **+** on an edge | move it / insert a corner there |
| Right-drag · wheel | look around · fly forward and back |
| W A S D · Q / E · Shift / Ctrl | move · down / up · faster / slower |
| Del · Ctrl Z · H | remove the selected corner · undo · back over the garage |
| Enter · Esc | save · cancel |

The top bar shows the number of corners, the area, and whether the outline is valid (at least 3 corners, no crossing edges). A vehicle counts as inside when it is within the outline seen from above and between 3 m below the lowest corner and 6 m above the highest. That way a multi-storey car park only catches its own floor. **Use the circle** removes the zone. Save the garage afterwards.

### Placing parking spots in freecam

Go to **Parking → Place in freecam**. Each spot is drawn as the footprint of the vehicle it is for, with an arrow and its number.

| Input | Action |
|---|---|
| Left click on the ground | drop a spot (a ghost shows it first) |
| Drag a spot · drag its handle · wheel over it · R | move · turn · 15° per notch · a quarter turn |
| C · Shift+C | duplicate the selected spot beside it · on the other side |
| Del · Ctrl Z · Enter · Esc | remove · undo · save · cancel |

A garage can have up to 60 spots. Overlapping spots turn red.

### Theme

Choose **Theme** at the top of the list:
- a colour preset (Midnight, Graphite, Onyx, Slate, Steel, Mint, Amber, Crimson, Violet) or Custom;
- corners;
- the **garage menu layout** (Showroom, Ledger, Gallery, Compact);
- the world icon and the key prompt;
- vehicle renders and animations on/off;
- **how a garage opens**: E key, ox_target / qb-target, or both.

The live preview is the real menu with sample vehicles. **Save for everyone** re-skins every connected player at once.

### Park mode page

This page sets the rules of `/park` for the whole server: enabled, collision, map blip, vehicles per player, command range, maximum time and tow fee.

---

## 12. Job and gang garages: fleets

A garage can be restricted to a **job** or a **gang** in **Access**. It can also keep a **fleet**: vehicles that belong to the garage itself, such as police cruisers at the station, a gang's cars or a company's vans. Nobody owns them, and whoever may use the garage takes one out.

Everything below is set per vehicle or per garage in **`/garageeditor → Fleet`**:

| Setting | Meaning |
|---|---|
| **Model** / **Name** | spawn name (`police3`) and the name shown in the menu. **Add the vehicle I'm in** copies the model/name, livery and enabled extras from your current vehicle. |
| **Min. grade** | the lowest job or gang grade that may take it. Lower grades see it with a lock and the grade it needs. |
| **Max out** | how many of this vehicle can be out at the same time (`0` = no limit), shown as *2 of 3 in use* |
| **Livery** · **Tuned** | livery index (`-1` = the model's own) · engine, brakes, gearbox, suspension, armour and turbo at maximum |
| **Extras** | leave **Configure extras** off for model defaults. Turn it on and enter the extra IDs to enable for that vehicle; unselected supported extras are disabled. An empty custom selection disables them all. |
| **Plate prefix** | fleet plates are the prefix plus digits, e.g. `LSPD 042` |
| **Per player** | how many fleet vehicles one player may have out from this garage (`0` = no limit). If it is not set, `Config.Garage.fleetPerPlayer` applies. |
| **Bring back empty vehicles** | on: a fleet vehicle left empty returns by itself when its driver takes another one over the limit, or when its driver has left the server. A colleague's empty car stays theirs while they are online. Off: vehicles stay out until they are parked back or destroyed. |
| **Personal vehicles** | off (the default for job and gang garages): the garage lists only its fleet, and players' own vehicles cannot be parked or brought there. On: both. |

**Liveries and extras.** A livery selects the vehicle design/skin. Extras are optional physical accessories supplied by that model, such as lightbars or equipment. In **Fleet**, configure each row independently: for example, set a livery index and enable extras **1, 3, 6, 12**. Those numbers are examples, not a preset. The editor supports integer extra IDs **0–20**, matching the vehicle-property capture range; IDs that do not exist on the model are ignored. The same selection is applied in cinematic previews and when taking the vehicle out. The saved definition uses `extras = { 1, 3, 6, 12 }`; omit `extras` to keep model defaults, or use `extras = {}` to disable them all. Existing fleets are unchanged until configured.

**Subcategories.** In **/garageeditor → select the job/gang garage → Fleet**, enter a subcategory on each vehicle, such as **SWAT Vehicles** or **Patrol**. Reuse the suggestions to group vehicles under the same name; leave it empty for uncategorized vehicles. The garage and cinematic menus show a matching filter when any groups exist. Personal vehicles retain their normal filters. Subcategories only organize the fleet: the existing minimum-grade and access settings still decide who can take each vehicle. They are saved in the existing garage JSON, with no SQL migration.

Fleet vehicles come out with a full tank, no damage, the keys and a fleet plate. Parking one in **any garage that keeps a fleet** returns it, and nothing is written to anyone's vehicles. They are never "lost": after a restart the whole fleet is back, and a fleet vehicle the server lost track of is still recognised by its plate and model when parked.

---

## 13. Impound

- **`/impound`** (jobs in `Config.Impound.jobs`) opens the impound tool. It lists every vehicle within `toolRadius` with its distance, plate and whether it is occupied. Choose one, then set the fee (up to `maxFee`), the reason (free text or one of `Config.Impound.reasons`) and the lot (the nearest by default).
- **`/impound [fee] [reason]`** is the quick version: the vehicle you are in, or the closest one within `radius`.
- The record keeps the fee, the reason, who impounded it and when. The owner is notified. A vehicle nobody owns is simply removed (`deleteUnknownPlates`).
- At the **impound lot**, the owner sees a printed *Notice of impoundment*, pays the fee in cash or by bank, and the vehicle comes out on a spot of the lot.
- With `anyLot = true`, every lot shows all of a player's impounded vehicles.
- Admins can impound only when `adminCanImpound = true`.
- From any script: `exports['oxlyn-garage']:ImpoundVehicle(plate, { fee = 500, reason = 'Abandoned', lot = 'impound_davis', by = src })`.

---

## 14. Park mode

**Optional keybinding.** In `Config.Park.keybind`, set `enabled = true` and choose `key = 'F7'` (or another FiveM key name) with `mapper = 'keyboard'`. It calls the same parking flow as `/park`: stand beside the vehicle after getting out. The shortcut is disabled by default and is configured only in this file, independently of the editor's park settings. `Config.Commands.park = false` disables the chat command while an enabled shortcut continues to work. Turning park mode itself off disables both ways of parking.

Players can change the mapping under **Settings → Key Bindings → FiveM → OXLYN: park nearby vehicle**. The config key sets the initial mapping; it does not overwrite an existing player binding. See the [official FiveM key mapping API](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/RegisterKeyMapping.md). The shortcut ignores input while the game pause menu or a NUI interface is focused, and it performs one action per press without a frame polling loop.

Use `/park` on foot, next to a vehicle you own that nobody is sitting in. The vehicle stays exactly where it stands:
- It is re-created **by the server**, so it survives restarts, crashes and everyone leaving. Mods, colours, damage and fuel come back with it.
- It is frozen and invincible, and **locked for everyone but the owner**. Its collision follows the editor setting (off by default, so it never blocks a road). The owner sees a map blip.
- A **hologram** over the car shows that park mode is on, how long the car may stay and the tow fee (`Config.Park.hologramSeconds`).
- **Getting in ends park mode.** With collision off, the owner's game turns it back on up close, and **F** works within 3.5 m. Parking the vehicle in a garage or impounding it also ends park mode.
- **Time limit**: after the *maximum time* (default 4 h, 0 = none), the vehicle is towed to the nearest impound lot with the *tow fee*. The owner is told when parking, warned 15 minutes before and notified of the tow. A park that expired while the server was off is towed at boot.

---

## 15. Sale contracts

The deal happens **inside the vehicle**, on a realistic agreement paper:

1. The **owner** sits in their vehicle with the buyer as a passenger and uses the `vehicle_contract` item. The paper opens with the vehicle already filled in (make and model, plate, class, condition).
2. The owner **writes the price** on the price line; the amount in words follows. The passenger's name appears on the buyer line, and with several passengers the owner chooses one. **Signing the seller's box** hands the paper over, and the vehicle is locked while the deal is open.
3. The **buyer** sees the same paper. They **tick Cash or Card** and **sign their box** to pay. Esc declines.
4. The server re-checks everything, then:
   - charges the buyer and pays the seller (minus `tax` %);
   - moves the registration and hands over the keys;
   - uses up the sheet (`consumeItem`).

   Both papers get a **PAID** stamp.
5. Declining, cancelling, leaving the vehicle, disconnecting or the timer (`offerMinutes`) voids the deal. The sheet stays with the owner.

Every deal is written to `oxlyn_garage_contracts` for audit. The deal is live, so the item works with **any inventory**, including the plain ESX one.

---

## 16. Notifications

Every message of the garage goes to one place, set by `Config.Notify.system`. This covers messages from the server and from the client, such as "Vehicle stored" or "Not enough money".

| Value | Where messages go |
|---|---|
| `'builtin'` (default) | the garage's own notifications, top right, matching the theme |
| `'auto'` | the first of these resources that is running: okokNotify, brutal_notify, wasabi_notify, lation_ui, t-notify, mythic_notify, pNotify, oxlyn-notify, corescripts-notify, esx_notify, ox_lib, qbx_core, qb-core, es_extended |
| a name | `'okokNotify'`, `'brutal_notify'`, `'wasabi_notify'`, `'lation_ui'`, `'t-notify'`, `'mythic_notify'`, `'pNotify'`, `'oxlyn-notify'`, `'corescripts-notify'`, `'esx_notify'`, `'ox_lib'`, `'qbox'`, `'qbcore'`, `'esx'` |
| `'event'` | `TriggerEvent(Config.Notify.event, message, type, title, durationMs)` on the client, for any other resource |
| `'custom'` | your own function `Config.Notify.custom(message, type, title, durationMs)` |

`type` is `'success'`, `'error'`, `'warning'` or `'info'`, and each resource gets its own equivalent (for example `info` becomes `inform` for ox_lib). If the chosen resource is not running or its export fails, the built-in notification is shown instead and the console explains why, once, so a message is never lost.

---

## 17. Compatibility

Everything below is detected automatically. The config line only forces a choice.

| | Supported |
|---|---|
| **Framework** | Qbox, QBCore, ESX Legacy (`Config.Framework`) |
| **Vehicle table** | `owned_vehicles` (ESX) or `player_vehicles` (QBCore / Qbox) |
| **Inventories** (contract item) | ox_inventory, qb-inventory, ps-inventory, lj-inventory, qs-inventory, ak47_inventory, tgiann-inventory, codem-inventory, origen_inventory, core_inventory, or the framework's own |
| **Vehicle keys** | qbx_vehiclekeys, qb-vehiclekeys, MrNewbVehicleKeys, wasabi_carlock, Renewed-Vehiclekeys, qs-vehiclekeys, ti_vehicleKeys, jaksam vehicles_keys, ak47_vehiclekeys, tgiann-hotwire, brutal_keys, mono_carkeys, mk_vehiclekeys, t1ger_keys, F_RealCarKeysSystem, xd_locksystem, esx_vehiclelock, cd_garage, okokGarage, plus your own events (`Config.VehicleKeys`) |
| **Fuel** | ox_fuel, LegacyFuel, cdn-fuel, ps-fuel, lc_fuel, okokGasStation, x-fuel, ti_fuel, nd_fuel, rcore_fuel, or native (`Config.Fuel`). The `fuel` state bag is always written too. |
| **Target** | ox_target, qb-target (`Config.Interaction.mode`, or in game under Theme → Opening a garage). Without one, the E prompt keeps working. |
| **Notifications** | see [Notifications](#16-notifications) |
| **Money** | ESX accounts, QBCore / Qbox `cash` and `bank`. Payouts to offline players are written straight to the database. |

---

**Interface name.** Set `Config.UI.brandName = 'My Server Garage'` in `config/config.lua` to change the interface footer and window title, then restart the resource. This config-only setting is not overridden by the theme editor; older configs default to **OXLYN Garage**. Blank or invalid values also use the default.

## 18. Languages

Every text players see is in `locales/<code>.lua`. The resource ships with **7 languages**: English (`en`), Portuguese (`pt`), Spanish (`es`), French (`fr`), German (`de`), Polish (`pl`) and Lithuanian (`lt`). All seven shipped languages contain the same **755 translation keys**, including vehicle classes and the latest garage, parking and impound features. The contract paper also writes the amount in words in the chosen language. Set the language with `Config.Locale`.

To add a language, copy `locales/en.lua` to `locales/xx.lua`, change `Locales['en']` to `Locales['xx']` at the top, translate the values and add the file to `fxmanifest.lua` next to the others. At runtime, any key you leave out falls back to English, so a text never shows up as a raw key. The release builder requires complete locale files and rejects missing, duplicate or empty translations and mismatched `%s` / `%d` placeholders before packaging. When updating locale files, merge any custom wording into the new files so new translations are retained. The interface texts (menus, editor, paper) are in the same file, under the `ui_` keys.

---

## 19. Exports and events

**Server exports**

```lua
exports['oxlyn-garage']:ImpoundVehicle(plate, { fee = 500, reason = 'Abandoned', lot = 'impound_davis', by = src })  -- ok, code
exports['oxlyn-garage']:GetVehicle(plate)                  -- normalised vehicle row + garage data, or nil
exports['oxlyn-garage']:GetOwnedVehicles(identifier)       -- list of a player's vehicles
exports['oxlyn-garage']:SetVehicleGarage(plate, garageId)  -- mark it parked there (nil = any garage)
exports['oxlyn-garage']:IsVehicleOut(plate)
exports['oxlyn-garage']:IsVehicleParked(plate)             -- park mode
exports['oxlyn-garage']:GetParkedVehicles()
exports['oxlyn-garage']:GetGarages()                       -- every garage document
exports['oxlyn-garage']:GetGarage(id)
exports['oxlyn-garage']:CanAccessGarage(src, id)
exports['oxlyn-garage']:IsAdmin(src)
exports['oxlyn-garage']:SaveGarage(doc, byName)            -- create / update a garage from code
exports['oxlyn-garage']:DeleteGarage(id)
exports['oxlyn-garage']:GetSettings() / SaveSettings(doc, byName)
```

**Client exports**

```lua
exports['oxlyn-garage']:OpenGarage(id)
exports['oxlyn-garage']:OpenNearestGarage()
exports['oxlyn-garage']:OpenEditor()
exports['oxlyn-garage']:IsOpen()
exports['oxlyn-garage']:GetGarages()
exports['oxlyn-garage']:GetNearestGarage()
```

**Server events** (listen with `AddEventHandler`)

| Event | Arguments |
|---|---|
| `oxlyn-garage:server:vehicleStored` | `src, plateKey, garageId` |
| `oxlyn-garage:server:vehicleOut` | `src, plateKey, netId, garageId` |
| `oxlyn-garage:server:vehicleImpounded` | `plateKey, lotId, fee, reason, by` |
| `oxlyn-garage:server:vehicleTransferred` | `plateKey, newIdentifier, newSrc` |
| `oxlyn-garage:server:vehicleParked` / `vehicleUnparked` | `plateKey, src` |
| `oxlyn-garage:server:fleetOut` | `src, plateKey, netId, garageId, index` |
| `oxlyn-garage:server:fleetReturned` | `src, plateKey, garageId` |
| `oxlyn-garage:server:contractCreated` | `id, sellerSrc, buyerIdentifier, plateKey, price` |
| `oxlyn-garage:server:contractAccepted` | `id, sellerIdentifier, buyerIdentifier, plateKey, price` |
| `oxlyn-garage:server:contractClosed` | `id, status` |
| `oxlyn-garage:server:garageSaved` / `garageDeleted` | `garage` / `id` |
| `oxlyn-garage:server:settingsSaved` | `settings` |
| `oxlyn-garage:server:adminVehicleAdded` | `src, plateKey, identifier` |

**Client events**: `oxlyn-garage:client:vehicleOut (plateKey, vehicle)` and `oxlyn-garage:client:vehicleStored (plateKey, garageId)`.

A vehicle spawned by the garage carries the state bag `oxlynGarage`: `{ plate, owner }`, or `{ plate, fleet = garageId }` for fleet vehicles.

`plateKey` is the plate in upper case without spaces.

---

## 20. Garage schema

This is what the editor saves, and what `Config.DefaultGarages` and `SaveGarage` accept. Everything is validated on the server.

```lua
{
  id = 'legion_square', label = 'Legion Square Parking',
  kind = 'garage',                     -- 'garage' | 'impound'
  type = 'car',                        -- 'car' (cars AND motorcycles) | 'motorcycle' | 'boat' | 'air' | 'all'
  point = { x = 0.0, y = 0.0, z = 0.0, w = 0.0 },   -- interaction point + heading
  radius = 2.5,                        -- on-foot interaction radius
  storeRadius = 22.0,                  -- parking radius (when there is no zone)
  zone = { points = { { x, y, z }, ... } },         -- optional drawn parking area (3–64 corners)
  spots = { { x, y, z, w }, ... },     -- numbered parking spots (max 60)
  vehicleCollision = true,             -- false = vehicles pass through each other inside the parking area
  blip = { enabled = true, sprite = 357, color = 3, scale = 0.75, label = nil },
  ped = { enabled = true, model = 's_m_y_valet_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
  access = {
    mode = 'public',                   -- 'public' | 'job' | 'gang' | 'private'
    jobs = { police = 0 },             -- job = minimum grade
    gangs = { 'ballas' },
    identifiers = { 'license:…' },
  },
  impound = { fee = 300 },             -- impound lots: release fee
  personal = true,                     -- players' own vehicles (default: false for job / gang garages)
  localVehiclesOnly = false,           -- true = collect here; no remote garage transfer or phone valet
  fleetPlate = 'LSPD',                 -- fleet plate prefix (1–4 letters/digits)
  fleetPerPlayer = 1,                  -- fleet vehicles out per player (0 = no limit; nil = config default)
  fleetRecall = true,                  -- empty fleet vehicles come back by themselves (nil = config default)
  fleet = {                            -- the garage's own vehicles (max 30)
    { model = 'police3', label = 'Police Interceptor', minGrade = 2, count = 2, livery = -1, tuned = true, extras = { 1, 3, 6, 12 } }, -- optional extras; {} = all off, omitted = model defaults
  },
  theme = { accent = '#4d7cff', style = 'showroom' },   -- optional look of this garage only
}
```

---

## 21. Database

| Table | Content |
|---|---|
| `oxlyn_garages` | the garage documents saved by the editor |
| `oxlyn_garage_vehicles` | per plate: nickname, when, where and by whom it was parked, impound record, contract lock |
| `oxlyn_garage_settings` | the interface theme and the park mode rules |
| `oxlyn_garage_parked` | vehicles in park mode |
| `oxlyn_garage_contracts` | audit log of every sale contract |

**Ownership** and the stored / out / impounded state stay in your framework's own table (`owned_vehicles` or `player_vehicles`). Other scripts that read those tables keep working, and so do vehicle shops, mechanic scripts and phone apps.

---

## 22. The interface (web)

The interface is a single-page app already built into `web/dist` and loaded by `ui_page`. There is nothing to install or build.

- **Look**: change it in game (`/garageeditor → Theme`), per garage (Display page), or its defaults in `Config.UI`.
- **Texts**: every label of the menus, editor, impound notice and contract paper is in `locales/<code>.lua`, under the `ui_` keys.
- **Vehicle pictures**: `images/vehicles/<model>.webp` (400×225). To add a picture for an add-on vehicle, drop a WebP named after its spawn name in lower case (e.g. `mycar.webp`) there and add that name to `images/vehicles/index.json`.

The interface source (React + Vite + TypeScript) is part of the Open Source edition.

---

## 23. Updating

1. Back up your `config/config.lua` and any locale you changed.
2. Replace the whole `oxlyn-garage` folder with the new one.
3. Compare your backup with the new `config/config.lua`, which may have new options, and copy your values back.
4. Restart the server, or run `ensure oxlyn-garage`.

Your garages, theme and park mode rules live in the database, so an update never touches them. `CHANGELOG.md` lists what changed in each version.

---

## 24. Troubleshooting and FAQ

| Symptom | Cause and fix |
|---|---|
| "You do not have permission" on `/garageeditor` | Run `/garageaccess <id>`. Usually the `add_ace` was added to `server.cfg` without a full restart; paste it in the live console. |
| The console says `oxmysql is not started` | `ensure oxmysql` must come before `ensure oxlyn-garage`. |
| `No framework detected — running standalone` | No framework was running 20 s after the garage started. Check that `ensure oxlyn-garage` comes after your framework and that its folder has its usual name (`es_extended`, `qb-core`, `qbx_core`), or set `Config.Framework`. |
| Nothing happens when using the contract item (ox_inventory) | The item is missing `server = { export = 'oxlyn-garage.vehicle_contract' }`. |
| "This vehicle is not registered to you" | The plate is not in `owned_vehicles` / `player_vehicles` for this character. Use `/admincar` to register a vehicle for testing. |
| "Sit in your vehicle together with the buyer" | The contract only works while you sit in your own registered vehicle with the buyer as a passenger. |
| The vehicle spawns but the engine will not start | Check `Config.VehicleKeys.system`, resource startup and the server/client `vehicle keys` diagnostics. QS model-name conversion runs on the client and the bridge probes every plate/model spelling another resource may have stored the key under; Qbox and mk_vehiclekeys need a live entity. Follow [EXPORTS.MD](EXPORTS.MD#vehiclekeys-v120) for custom removal hooks and version compatibility. |
| Fuel is full or reset after taking a vehicle out | Your fuel script is not in the auto list. Set `Config.Fuel.system`. |
| Only silhouettes, no vehicle pictures | Renders ship for the 738 vanilla models; add-on vehicles show a silhouette unless you add a picture (see [The interface](#22-the-interface-web)). For vanilla vehicles, check that *Vehicle renders* is on in the Theme. |
| The garage does not open with ox_target | Choose *Target* or *Both* in `/garageeditor → Theme → Opening a garage`. The card shows which target resource is running. |
| A job garage lists nothing | Job and gang garages start with **personal vehicles off**. Add a fleet, or turn personal vehicles on, in `/garageeditor → Fleet`. |
| "This garage only keeps its own fleet" | Your personal vehicle cannot be parked in a job or gang garage with personal vehicles off. Park it in a public garage. |
| A player cannot see a job garage's blip | That is intended: `Config.Blips.showOnlyAccessible = true` hides garages the player cannot use. |
| Changed `Config.DefaultGarages` but nothing changed | Starter garages are seeded only once. Edit the garages in `/garageeditor`, or empty `oxlyn_garages` to re-seed. |
| A message appears in ox_lib, the framework's notifications or the chat instead of the garage's own | Only possible in the first seconds after joining, before the interface has loaded. After that, messages follow `Config.Notify`. |

**Can players see other players' vehicles in the menu?** No. The menu lists only the vehicles registered to the player, plus the garage's fleet.

**Does it work with my vehicle shop?** Yes. Any shop that writes to `owned_vehicles` or `player_vehicles` works. Vehicles with no garage yet can be taken out at any garage of the right type.

**Is there a performance cost?** The client does almost nothing when you are away from garages. World icons and prompts only run within `Config.Interaction.drawDistance`, and attendant peds exist only within `Config.Peds.spawnDistance`.

---

**OXLYN Software®** · Support: open a ticket on our Discord with your framework, inventory and the console output of the start-up line.


## v1.0.1 — Phone integrations and persistence

See [EXPORTS.MD](EXPORTS.MD) for the client/server API, CodeM mPhone 2.5 and LB-Phone installation adapters. Use one edition only. Phone adapters live in `install/` and must be installed in the phone, not loaded by this garage.

Vehicle modifications and condition are captured when storing or using `/park`; they are restored on takeout and through the phone property export. There is no continuous autosave of vehicles left out. Body dents are sampled and approximate; native health, broken parts and mods are preserved in the snapshot. Verify the resource in a FiveM development server with your actual mechanic/key/fuel/phone resources.
