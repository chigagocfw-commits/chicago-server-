# Changelog

## 1.2.1 — 2026-09-29

- The server console now prints `vehicle keys bridge 1.2.1` at startup, and the ready line shows it next to the detected key system. The line is printed by the protected code itself, so it proves which build is actually executing — the fxmanifest version alone cannot: after a partial update the console may claim a new version while old code still runs.
- If that line is missing after an update, the resource files were not fully replaced: delete the whole `oxlyn-garage` folder, extract the fresh ZIP and restart the server.
- No other changes; no configuration, locale or SQL migration.

## 1.2.0 — 2026-09-29

- Fixed qs-vehiclekeys integration failures reported as `give/remove failed: provider returned false` and `key_not_found`: keys written by another resource (dealership, auction) under a different plate or model spelling — raw 8-character plate with trailing spaces, trimmed or space-stripped; display name, lowercase or spawn name — are now found by probing `GetKey` and operated on under the spelling that actually exists. This applies to giving keys (the existing key is recognised instead of refused as a duplicate), to removing keys on store, impound and sale, and to the engine-start key wait.
- Removing a vehicle key the player does not hold is now a silent success on key systems with a read API (qs-vehiclekeys, ak47_vehiclekeys, mk_vehiclekeys): the no-key end state is already true, and the key system's console no longer logs `key_not_found` errors during park, store or impound.
- Added nine vehicle key systems: ak47_vehiclekeys, tgiann-hotwire, brutal_keys, mono_carkeys, mk_vehiclekeys, t1ger_keys, F_RealCarKeysSystem, xd_locksystem and esx_vehiclelock — each on its documented API and side, with duplicate-safe grants and key-wait checks where the system offers a read API. tgiann-hotwire has no removal API by design; see EXPORTS.MD for details and for hooking up systems without a public API.
- Selling a vehicle whose entity no longer exists now revokes and grants plate-based keys with the plate exactly as stored in the database instead of the space-stripped internal key.
- Update the resource files and, if customised, merge the new `Config.VehicleKeys.system` comment block. No locale, configuration or SQL migration is required.

## 1.1.1 — 2026-09-27

- Added per-vehicle fleet extras in the garage editor. Keep model defaults or enter the exact extra IDs to enable, independently of the existing livery setting. Each vehicle can use a different combination; an empty custom selection disables all supported extras.
- Add the vehicle I am in now copies its active extras as well as its model and livery. Fleet previews and actual takeout use the same server-saved selection; nonexistent extras are ignored.
- Extras are applied after livery/mods, with disabled extras processed before enabled extras. Saved vehicle condition is restored afterwards, preserving damage and modifications.
- Added the new editor text to all seven languages. Replace the updated locale files with the resource; existing garage definitions retain model defaults. No configuration or SQL migration is required.

## 1.1.0 — 2026-09-27

- Added `/garage <player ID>` for administrators: browse a connected player's garages by cars/motorcycles, boats or aircraft, inspect owned vehicles, add a model with an optional plate and permanently remove a vehicle after confirmation. The existing `/garage` command still opens the nearby garage.
- Every administrative request checks Config.Admin permissions and the target character. Ownership changes use owner-scoped SQL and shared vehicle reservations. Active, parked and pending-sale/delivery vehicles must be returned or resolved before removal; additions create stored vehicles without spawning a live copy. Operations are logged on the server.
- Fleet vehicles now support named subcategories such as SWAT Vehicles. Assign them in the editor's Fleet page and filter them in all four garage layouts or cinematic mode. Existing grade, stock and per-player limits still apply.
- Fixed large cash/bank balances being clipped or overflowing the garage and payment controls; full amounts remain available in compact layouts, impound and sale screens.
- Added `Config.UI.brandName` (default: OXLYN Garage) for the interface footer and window title, independent of saved theme settings.
- All seven languages include the new text (745 keys each). Update the resource and locale files; add the optional branding setting to a customised config if desired. No new SQL migration is required.

## 1.0.9 — 2026-09-26

- Completed the missing Spanish, French, German, Polish and Lithuanian translations for vehicle keys, local garages, lost vehicle recovery, parking keybinds and cinematic impounds. All seven languages now contain the same 700 keys.
- Moved all 23 vehicle class names and the generic vehicle label into the locale files, covering garage lists, cinematic previews, impounds and sale documents.
- Parking duration labels now use the selected language in both the interface and server notifications. Refined remaining untranslated interface labels in French, German, Polish and Lithuanian.
- Release generation now rejects missing, duplicate or empty translations and incompatible format placeholders before preparing ZIPs.
- Replace the updated locale files along with the resource files. Merge custom wording into the new translations if needed. No configuration or SQL migration is required.

## 1.0.8 — 2026-09-25

- Added a per-impound presentation choice in the garage editor: Document (existing notice) or Cinematic camera, using the existing editor and cinematic styles.
- Cinematic impounds show a local vehicle preview with orbit/zoom controls, vehicle condition, fine/reason, account selection and paid release on the previewed bay.
- The existing server release flow still validates ownership, lot/access, funds and the spawn reservation. Previewing never releases a vehicle or charges a fine.
- Closing or cancelling also invalidates pending preview loads; stale local copies are cleaned up. Failed releases restore the player/camera and retain impound/payment protections.
- Existing impounds default to Document. The choice persists in garage JSON without a new SQL migration; unavailable previews fall back to the document view.

## 1.0.7 — 2026-09-24

- Fixed /park failing to find nearby vehicles excluded by the GTA closest-vehicle flags. It now selects the nearest streamed, networked vehicle within the configured 3D radius, including emergency vehicles, boats and aircraft.
- Local preview copies and entities without a valid network ID are ignored. Lookup runs once per command/keybind request and does not rely on a pre-restart vehicle cache.
- Ownership, distance, occupancy, impound and contract checks remain server-authoritative; full saved vehicle properties are preserved.
- Includes the 1.0.6 engine-start, key-readiness and phone-adapter fixes.

## 1.0.6 — 2026-09-24

- Warns when auto detection finds multiple running key systems, naming its selection. Choose the active provider explicitly (for qs-vehiclekeys: system = 'qs').
- Fixed an engine-start lock left behind after a failed or delayed key acknowledgement. Garage takeout and phone handoffs no longer disable normal engine starting.
- QS, QB and Qbox now verify the client's keys after the approved grant, allowing inventory/state replication to finish before seating the driver or starting valet. No duplicate keys are granted.
- Garage and impound takeout start the engine after the seat handoff; the legacy spawnEngineOn=false option no longer leaves deliveries switched off.
- CodeM and LB valet leave the engine running after delivery and NPC exit, without overriding a player who has taken the driver seat.
- Persistent parking releases its temporary auto-start lock when the vehicle is unparked.
- Saved fuel, engine damage and tuning remain unchanged. Failed key grants still show a warning and do not bypass the key provider or duplicate/refund an already confirmed vehicle.
- Update the phone client adapters as well as the garage resource. Automated engine, key-readiness, valet and persistence regressions cover these changes; live FiveM verification remains required.

## 1.0.5 — 2026-09-24

- Fixed custom theme palettes ignoring the first click: pointer interactions now resolve the mounted control.
- Colour markers track clicks and drags with CSS scaling and scrolling, including drags outside the control.
- Active drags use the latest HSV values and callbacks; releasing, cancelling, losing focus/capture or closing the editor cleans up tracking.
- Preserved the editor design, HEX input and preset behaviour; rebuilt both editions and archives.

## 1.0.4 — 2026-09-24

- Added Config.Garage.lostVehicles: garage recovery, fixed-fee impound or recovery disabled.
- Added an optional Config.Park.keybind shortcut (default key F7, disabled by default), using the same /park flow and player-editable FiveM bindings.
- Optional automatic impound detects server-world disappearance after a configurable grace period; live vehicles, persistent parking, spawn reservations and sale contracts are protected.
- Fixed impound fine/reason and optional lot ID are controlled by config. The fine is paid at release, never when the vehicle is sent to the lot.
- Impound release reserves the spawn before charging; failed spawns refund the payment and restore the original lot/fine while retaining its reason.
- Garage menus and keyboard/preview actions reflect the recovery policy. Restart restoration applies only in garage recovery mode.
- Preserves the last saved vehicle snapshot and both normal/open-source release layouts.

## 1.0.3 — 2026-09-24

- Added “Only vehicles in this garage” to the editor Identity page using the existing toggle style, with English and Portuguese text.
- Persisted the opt-in setting in garage documents; existing garages retain their previous behavior without a SQL migration.
- Filtered local personal-vehicle lists and enforced origin/destination rules before takeout, remote transfers and rescue. Local collection also requires the player to be at the garage.
- Phone lists still locate local vehicles, but valet cannot deliver them remotely. Physically driving and storing a vehicle elsewhere remains supported.
- Added schema, editor and server regression coverage; rebuilt the interface and both release archives.

## 1.0.2 — 2026-09-24

- Fixed QS vehicle-keys integration: model display names are resolved only on the client; server never calls a client-native-dependent QS export. Guarded missing/invalid display-name natives.
- Replaced speculative QB/Qbox/Jaksam/TebIT/okok calls with documented APIs/events; Qbox receives live entities, QB updates authoritative server keys, and QS receives trimmed plates plus display-name strings.
- Removed duplicate client/server key grants. Spawn confirmation and key acknowledgement now precede the engine, including phone valet integrations. Explicit false/errors remain failures.
- Forced key revocation on sales, impound and fleet recall; fixed former fleet drivers and stored vehicles returned by other drivers, source reuse, stale entities and late spawn acknowledgement.
- Added custom client/server removal hooks. Key and fuel bridges recover after late startup, restart and configuration changes; invalid fuel numbers cannot contaminate saved state.
- Provider, lifecycle, phone and fuel regression tests added; both editions and ZIPs regenerated with matching runtime files.

## 1.0.1 — 2026-09-24

- Reduced client work for parked vehicles, world collision lists, ped streaming and editor geometry; preserved immediate controls and state cleanup.
- Isolated high-frequency NUI overlays; memoized sorting, vehicle cards and image fallback logic.
- Added owner-filtered single-vehicle SQL reads, bounded plate-spelling lookup cache, batched metadata reads, cached garage ordering and contract indexes. Ownership/state always come from fresh SQL.
- Preserved full tuning and damage snapshots on storage/restore; disabled tyre smoke restores correctly, conditions apply after mods/extras, and late network control restores parked vehicles correctly.
- Added bounded approximate body-deformation sampling; old rows remain compatible.
- Added phone list/locate/valet/property exports, spawn reservations and cancellation protection, CodeM mPhone 2.5 and LB-Phone installation adapters, and EXPORTS.MD. Phone integrations require installation in the phone and an in-game test.
- Lua regressions, NUI DOM regressions, TypeScript/build and release integrity checks passed. No live FiveM performance percentage is claimed; dents depend on GTA physics.

## 1.0.0 — 2026-09-24

First public release of the **OXLYN Advanced Garage System**.

- **Garage editor (`/garageeditor`)**: garages and impound lots for cars, motorcycles, boats and aircraft.
  - Interaction point from your position, your vehicle or by aiming.
  - Parking spots and parking zones placed from a free camera.
  - Access by job, gang or player.
  - Attendant ped with 18 presets, blips, and vehicle collision inside the parking area.
  - Per-garage accent colour and menu layout.
- **Theme editor** with a live preview:
  - 9 presets or custom colours;
  - 4 garage menu layouts;
  - world icon and prompt styles;
  - E key, ox_target / qb-target or both to open a garage.
- **Player menu**:
  - real renders of 738 vanilla vehicles;
  - condition gauges, and where, when and by whom each vehicle was parked;
  - cinematic preview with Spawn in place;
  - Locate, Rescue, Bring here and nicknames;
  - full keyboard control.
- **Realistic parking**: damage, fuel, dirt, mods, colours, extras, windows, doors and tyres are saved. The server deletes the vehicle when it is parked, so there are no duplicates.
- **Fleets for job and gang garages**:
  - minimum grade per vehicle;
  - how many can be out at once, and how many per player;
  - plate prefix, livery and tuning;
  - empty fleet vehicles come back by themselves (optional).
  - Personal vehicles can be switched off per garage.
- **Impound lots**:
  - `/impound` quick command and impound tool for configured jobs;
  - printed notice of impoundment;
  - release desk with payment;
  - export for other scripts.
- **Park mode (`/park`)**: the vehicle stays where it is left, survives restarts and is locked for everyone but the owner. A hologram shows the time limit, and the vehicle is towed after the configured hours.
- **Sale contracts**: the `vehicle_contract` item opens an agreement paper inside the vehicle. The seller writes the price and signs; the buyer ticks cash or card and signs to pay. Ownership, keys and money move on the spot, and every deal is audited.
- **Admin tools**: `/admincar` (register the vehicle you sit in), `/garageaccess` (permission report) and `/contract` (showcase for videos).
- **Compatibility**:
  - frameworks: ESX Legacy, QBCore, Qbox;
  - 11 inventories;
  - 10 vehicle key systems;
  - 10 fuel scripts;
  - ox_target / qb-target;
  - 14 notification resources, plus your own event or function.
- **Languages**: English, Portuguese, Spanish, French, German, Polish and Lithuanian, including the amount in words on the contract paper.
