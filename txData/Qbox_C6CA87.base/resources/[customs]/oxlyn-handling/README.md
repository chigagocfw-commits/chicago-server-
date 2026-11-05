# ⌞OXLYN⌝ Handling Studio

**The real-time vehicle handling editor for FiveM** — tune any vehicle live from an
Apple-style liquid-glass UI, persist tunes per model or per vehicle class, and even
write the results straight back into the car's `handling.meta`.

Multi-framework: **ESX / QBCore / Qbox** (auto-detected, zero configuration).
Languages: **English / Portuguese / French / Spanish / Polish**.

---

## ✨ Features

### Live editing
- `/handlingeditor` (or `/handling`) while seated in **any** vehicle — default,
  addon, custom — opens the studio pre-loaded with that vehicle's current handling.
- **46 CHandlingData parameters** across 7 categories (Transmission, Mass & Aero,
  Brakes, Traction, Suspension, Damage, Misc), each with a slider, precise numeric
  input, description, stock reference, live **Δ delta chip** and min–max range.
- Every change applies **instantly** — suspension visually settles in place,
  no driving off or respawning needed.
- **Double-click any slider** to reset that parameter to stock.
- **Copy / paste between vehicles**: copy the full tune in one vehicle, open the
  editor in another and paste it — only parameters that exist on the target are
  applied, and the clipboard survives closing the editor and relogging.
- **Advanced toggle** reveals expert parameters hidden from the everyday view.
- **Drive Mode**: the panel folds into a live telemetry HUD (circular RPM gauge,
  speed, gear) so you can test drive — press the refocus key (default **F2**)
  to jump back into the editor.

### Persistence — per model, for everyone
- **Save** stores the tune server-side (KVP, no SQL needed). Every spawn of that
  model, for every player, from then on, carries the tune automatically.
- Handling is applied on two levels: the model's **shared handling data** (so new
  spawns are born with the tune — including creation-cached values like drive
  force and gear count) plus a per-vehicle pass for cars already on the road.
- **Stock snapshots** captured on first save make *Reset* restore the true
  factory handling — even on vehicles already driving around with the tune.
- After saving, your car is seamlessly **recreated in place** (same look, mods,
  plate, fuel, seat) so cached values apply immediately (`Config.RespawnOnSave`).

### Vehicle classes
- Create named classes (e.g. *Class A*), browse the **full list of every vehicle
  model on the server** (default + addons, searchable, virtualized for speed),
  and assign vehicles by clicking them.
- Give a class one handling tune — every member uses it. Direct per-model tunes
  always take priority over class tunes. Classes can be renamed and deleted.

### Presets
- **12 built-in presets**: Racing, Drift, Off-road, Drag, Grip, Heavy/Armored,
  Realistic, Street Tuner, Rally, Time Attack, Lowrider, Muscle — applied
  deterministically on top of stock values.
- Admins can snapshot their own **server presets** in-game (stored server-side,
  visible to every admin, deletable).

### handling.meta export
- **Export** builds a ready-to-paste `<Item type="CHandlingData">` block with
  your current values, in real handling.meta units.
- **Auto-edit handling.meta files** (toggle in the Export dialog): on every Save
  the server locates the model's `handling.meta` inside its resource, edits the
  managed fields in place and keeps a one-time `.oxlyn.bak` backup. The file is
  loaded on the next server restart — until then the live tune (identical
  values) is what players feel.

### UI
- Liquid-glass Apple-style design — no `backdrop-filter` (CEF-safe), layered
  gradients, spring animations, Web-Audio interface sounds.
- **Settings panel**: 8 color themes (Ocean, Crimson, Emerald, Sunset, Violet,
  Rose, Teal, Gold) and interface scaling with **automatic 1440p / 4K sizing**.
- Compact right-side panel or **expanded centered window** (two-column layout).
- Centered toast notifications — no native GTA feed above the minimap.
- Heavily optimised: virtualized vehicle list, content-visibility cards,
  rAF-batched NUI messages, smooth inertial scrolling.

---

## 📦 Installation

1. Drop `oxlyn-handling` into your server's `resources` folder.
2. Add to `server.cfg` (after your framework):
   ```cfg
   ensure oxlyn-handling
   ```
3. Grant access — these two lines are all most servers need:
   ```cfg
   add_ace group.admin oxlyn.handling.admin allow
   add_principal identifier.license:PUT_YOUR_LICENSE_HERE group.admin
   ```
4. Restart the server. Done — no database, no dependencies.

> The framework (es_extended / qb-core / qbx_core) is auto-detected at runtime.
> Nothing to configure; the resource also loads standalone.

### Permissions

Access is a **union of independent sources** — any one saying yes is enough,
and it is re-validated server-side on **every** action. The client is never
trusted.

| Source | Where | Notes |
|---|---|---|
| **ace** | `Config.Admin.aces` | `oxlyn.handling.admin` (`oxlyn.handling` still accepted for older installs) |
| **bridge aces** | automatic | `group.<g>`, `qbcore.<g>`, `qbx.<g>`, `esx.<g>` for every group below — this is why **txAdmin and a plain `add_principal` just work**, with or without the `add_ace` line |
| **group** | `Config.Admin.groups` | ESX `getGroup()`, QBCore / Qbox `HasPermission()` |
| **job** | `Config.Admin.jobs` | `{ mechanic = 4 }` — job name → minimum grade. Optional `jobOnDuty` |
| **identifier** | `Config.Admin.identifiers` | `license:` / `steam:` / `discord:` / `fivem:` — the emergency path that depends on nothing |
| **hook** | `Config.Admin.check(src)` | Return `true`/`false` to decide, `nil` to fall through. The right place for a custom integration — never patch the core |
| **console** | `Config.Admin.allowConsole` | The server console is always staff |

> ⚠️ An `add_ace` written in `server.cfg` only takes effect on a full **server
> start** — restarting the resource is not enough. To apply it immediately,
> paste the line straight into the server console. This is by far the most
> common cause of "I'm an admin and it says I have no access".
>
> ⚠️ The `license:` prefix is written **once**.
> `identifier.license:license:c14af5…` matches nobody.

**`/handlingaccess <serverId>`** — run it in the server console (or in chat as
an admin) and it prints the detected framework, every source it consulted with
its verdict and reason, the final ALLOWED/DENIED, and the exact `add_ace` /
`add_principal` lines carrying that player's real license. If a customer sends
a screenshot of that output, the answer is already in it.

---

## ⚙️ Configuration (`config.lua`)

| Setting | Default | Description |
|---|---|---|
| `Config.Locale` | `'en'` | UI language: `en`, `pt`, `fr`, `es`, `pl` |
| `Config.Framework` | `'auto'` | Force `esx` / `qbcore` / `qbox`, or auto-detect |
| `Config.Command` | `'handlingeditor'` | Main command |
| `Config.CommandAlias` | `'handling'` | Second command (`false` to disable) |
| `Config.ResetCommand` | `'resetsettings'` | Restores the **interface** settings (theme, size, layout, auto-edit) to the script defaults — the escape hatch when a chosen interface size is too big to reach Settings. Works in chat or the F8 console, needs no permission (`false` to disable) |
| `Config.RefocusKey` | `'F2'` | Return-to-editor key while in Drive Mode (rebindable per player in GTA Settings → Key Bindings → FiveM) |
| `Config.Admin.everyone` | `false` | `true` opens the editor to everyone (testing only!) |
| `Config.Admin.methods` | all four | Which sources are consulted: `ace`, `group`, `job`, `identifier` |
| `Config.Admin.aces` | `oxlyn.handling.admin`, `oxlyn.handling` | Ace permissions that grant access |
| `Config.Admin.groupAces` | `true` | Also test `group.<g>` / `qbcore.<g>` / `qbx.<g>` / `esx.<g>` — makes txAdmin and `add_principal` work anywhere |
| `Config.Admin.groups` | `admin`, `superadmin`, `god` | ESX groups / QB permission levels |
| `Config.Admin.jobs` | `{}` | `{ mechanic = 4 }` — job name → minimum grade |
| `Config.Admin.jobOnDuty` | `false` | `true` = the job only counts while on duty (QB/Qbox) |
| `Config.Admin.identifiers` | `{}` | `license:` / `steam:` / `discord:` allow-list — depends on nothing |
| `Config.Admin.allowConsole` | `true` | The server console may always run the commands |
| `Config.Admin.check` | `nil` | `function(src)` override hook — `true`/`false` decides, `nil` falls through |
| `Config.Admin.debug` | `false` | Log every allow/deny decision to the server console |
| `Config.AccessCommand` | `'handlingaccess'` | Permission diagnostic command (`false` to disable) |
| `Config.ScanInterval` | `1500` | ms between vehicle scans that auto-apply saved tunes |
| `Config.Telemetry` | `true` | Live speed / RPM / gear strip in the editor |
| `Config.SpeedUnit` | `'kmh'` | `kmh` or `mph` |
| `Config.RespawnOnSave` | `true` | Seamlessly recreate the edited vehicle after Save so creation-cached fields apply instantly |
| `Config.Presets` | 12 presets | Built-in presets — add your own (see below) |

### Adding your own built-in preset
```lua
{
    id = 'mypreset', icon = 'gauge',           -- icons: flag, drift, mountain, bolt,
    label = 'My Preset',                       --   grip, shield, gauge, wrench,
    desc  = 'What it does.',                   --   stopwatch, cardown, engine
    fields = {
        --  mode 'mul' = stock × v   •  'set' = v   •  'add' = stock + v
        --  values are handling.meta units (fSteeringLock in degrees, etc.)
        fInitialDriveForce = { mode = 'mul', v = 1.25 },
        fSteeringLock      = { mode = 'set', v = 45.0 },
    },
},
```

---

## 🗄️ How persistence works

Everything is stored in the server's **KVP** (no SQL):

| Key | Contents |
|---|---|
| `oxlyn-handling:data` | Per-model tunes, stock snapshots, vehicle classes, revision counter |
| `oxlyn-handling:presets` | Admin-created presets |

The server publishes the state through `GlobalState`; a lightweight scan on every
client applies tunes to any matching vehicle it can see (marked with a decor so
work happens exactly once per revision). Model-level shared-handling application
guarantees future spawns are created with the tune already baked in.

**Priority:** direct model tune → vehicle-class tune → stock.

---

## 🧠 Technical notes

- **Units**: the UI, storage and sync all use plain **handling.meta units**
  (degrees, km/h, kg…). The CFX natives convert to/from engine scales on both
  read and write — verified against the CitizenFX source (`HandlingLoader.cpp`).
- **Verified writes**: every native write is read back and checked; a field that
  does not round-trip on your game build is restored and disabled for the
  session — a quirky native can never corrupt a vehicle.
- `nInitialDriveGears` is capped at 7 by the game engine itself.
- Sub-handling classes (CCarHandlingData) are not exposed — the natives do not
  support them reliably.
- Suspension edits physically re-settle the vehicle in place so ride height,
  limits and springs preview live while parked.

---

## 🔧 Troubleshooting

| Symptom | Fix |
|---|---|
| "You do not have permission" | Run **`/handlingaccess <serverId>`** in the server console — it prints exactly which sources were consulted, why each said no, and the `add_ace` / `add_principal` lines to paste. Remember an `add_ace` in `server.cfg` only applies on a full server start; paste it in the console to apply it now |
| Tune not visible on a parked car after joining | The sync applies within ~1.5 s (`Config.ScanInterval`) |
| Auto-edit says *handling.meta not found* | The model has no editable file (GTA default cars) or its resource hides the file behind wildcards — use manual Export instead |
| The interface is too large / unusable after changing the size | Type `/resetsettings` (chat or F8 console) — theme, interface size, layout and auto-edit go back to the script defaults instantly. It only touches your own local interface preferences, never handling data |
| `/handlingdiag` | In-vehicle diagnostic dump to the F8 console (revision, saved tune vs live values, per-field write status) |
| `/handlingaccess <id>` | Full permission report for a player (server console or admin chat) |

---

⌞OXLYN⌝ Software® — Handling Studio v1.3.0

## 1.3.1 — Startup and access recovery

- Framework detection retries after slow server starts and recovers when the core restarts. The detection worker stops once connected.
- A missing or invalid opening response now has a separate message from a permission refusal. Access still requires server approval.
- Run only one edition/copy. Start the framework before this resource where possible.
- If access fails, run `handlingaccess <current server ID>` in the server console while the failure is happening. Set `Config.Debug = true` temporarily for access logs.
- Persist ACE/principal commands in server.cfg or an exec-loaded permissions file; console-only changes do not survive a server restart.
