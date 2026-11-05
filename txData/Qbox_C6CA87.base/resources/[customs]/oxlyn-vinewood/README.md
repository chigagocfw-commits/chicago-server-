# OXLYN · Advanced Vinewood Editor

Replace the Vinewood hills sign with your own. Stand anywhere, type `/vinewood`,
and a freecam editor opens over the hills: build the sign from **real 3D
letters** with depth and lighting, **flat text** in 23 typefaces and **images**
you import straight from your PC, animate them with ten motion effects, and
press **Publish** — every player on the server sees the new sign at once. While
you work, everything is a private preview; nobody sees a half-finished sign.

* **Frameworks** — ESX · QBCore · Qbox · standalone (detected automatically)
* **Dependencies** — none. No database, no ox_lib, no oxmysql
* **Languages** — 14 included, each player picks their own
* **Version** — 2.6.1

---

## Table of contents

1. [Features](#features)
2. [Editions](#editions)
3. [Requirements](#requirements)
4. [Installation](#installation)
5. [Updating](#updating)
6. [Permissions & frameworks](#permissions--frameworks)
7. [Using the editor](#using-the-editor)
8. [Keyboard shortcuts](#keyboard-shortcuts)
9. [3D letters](#3d-letters)
10. [Flat text](#flat-text)
11. [Images & uploads](#images--uploads)
12. [Motion effects](#motion-effects)
13. [Camera tools](#camera-tools)
14. [Scene tools](#scene-tools)
15. [Showcase](#showcase)
16. [Languages](#languages)
17. [Configuration overview](#configuration-overview)
18. [Original sign](#original-sign)
19. [Storage & backups](#storage--backups)
20. [Performance](#performance)
21. [Diagnostics & export](#diagnostics--export)
22. [Building the interface](#building-the-interface) *(Open Source edition)*
23. [Troubleshooting](#troubleshooting)
24. [Credits & licences](#credits--licences)

---

## Features

* **Up to 8 layers** per scene — any mix of 3D letters, flat text and images.
* **Physical 3D letters** — real models with depth, shading and lighting.
  17 typefaces, solid / gradient / rainbow colour per layer, natural, night-time
  or always-on illumination, optional support posts. Every letter can be moved,
  rotated and scaled on its own.
* **Flat text** — 23 typefaces, weight, colour / gradient / rainbow, outline,
  glow, brightness, letter spacing, alignment, line height and multiple lines.
* **Images** — PNG / JPG / WebP from your PC (file picker, drag and drop or
  paste), local files shipped with the resource, or direct HTTPS links. Tint,
  brightness, contrast, saturation, glow, flip, fit modes, double-sided.
* **10 motion effects** for images, synchronised for every player by network
  time — no per-frame network traffic.
* **Private preview, then Publish.** One admin edits at a time, with 60 steps
  of undo / redo.
* **Hide the original sign** with one switch; the distant low-detail letters
  are removed for you (see [Original sign](#original-sign)).
* **Map-editor style interface** — full-width dock with six tabs, layer list,
  gizmo, freecam, seven camera views, orbit / pan / zoom, bookmarks and a
  time-of-day preview.
* **Style presets, scene templates, JSON import / export** and an appearance
  clipboard.
* **Self-driving showcase** (`/vinewood showcase`) for store videos and
  screenshots.
* **Safe storage** — every save is written, read back and verified, with the
  previous version kept as a backup.

---

## Editions

The resource ships in two editions. Both install and behave exactly the same in
game.

| | Escrow | Open Source |
|---|---|---|
| Folder in the zip | `oxlyn-vinewood` | `oxlyn-vinewood-OPENSOURCE` |
| `config.lua` | readable | readable |
| `locales/*.lua` | readable | readable |
| `data/` (storage + READMEs) | readable | readable |
| `licenses/`, `README.md`, `CHANGELOG.md` | readable | readable |
| `client/`, `server/`, `shared/` Lua | protected | **readable** |
| `web/dist` (built interface) | included (minified) | included |
| `web/src`, `web/build.mjs`, `web/package.json` | not included | **included** |
| `stream/` (letter models, map files) | protected | protected |

`stream/` stays protected in both editions; it is the only reason the Open
Source edition goes through escrow at all.

> **Rename the Open Source folder.** The Open Source zip contains a folder
> called `oxlyn-vinewood-OPENSOURCE`. Rename it to **`oxlyn-vinewood`** before
> you start it. The resource name is part of the interface URLs
> (`https://cfx-nui-oxlyn-vinewood/...`) and of `exports['oxlyn-vinewood']`;
> under any other name the interface and the export will not work.

### Folder layout

```
oxlyn-vinewood/
├─ fxmanifest.lua
├─ config.lua              -- everything you can configure
├─ locales/                -- loader.lua + 14 languages
├─ client/                 -- editor, freecam, 3D letters, atlas rendering
├─ server/                 -- permissions.lua, main.lua (publish/storage), assets.lua (uploads)
├─ shared/                 -- scene schema/validation, glyph catalogue, layout, effects
├─ web/
│  ├─ src/                 -- interface source            (Open Source only)
│  ├─ dist/                -- built interface the game loads (both editions)
│  └─ build.mjs, package.json                            (Open Source only)
├─ data/                   -- scene.json, scene.backup.json, upload-index*.json, uploads/
├─ stream/                 -- 3D letter models, map files (protected)
└─ licenses/               -- font licences
```

---

## Requirements

* A FiveM server. That is all.

No framework is required: ESX, QBCore and Qbox are supported when present and
detected automatically, and the resource works standalone with a single ACE
line. No database, no oxmysql, no ox_lib — the scene is stored as JSON files in
`data/`.

---

## Installation

**1.** Put the folder in your `resources` directory as **`oxlyn-vinewood`**
(Open Source edition: rename `oxlyn-vinewood-OPENSOURCE`).

**2.** Add it to `server.cfg`, together with the permission for your admins:

```cfg
ensure oxlyn-vinewood

# who may open the editor (works on every framework and standalone)
add_ace group.admin oxlyn.vinewood allow
```

On ESX, QBCore and Qbox the `admin` / `superadmin` / `god` groups are also
accepted without the ACE line — see [Permissions & frameworks](#permissions--frameworks).

**3.** Make sure FXServer can **write** to `oxlyn-vinewood/data/` (and
`data/uploads/`). The published scene and imported images are saved there.

**4. Restart the whole server** — not only the resource. The 3D letter models
and map files are streamed assets, and a resource restart does not pick them up
the first time.

**5.** Every player (you included) **closes FiveM completely and opens it
again** once after the first install, and again after any update that changes
`stream/`.

**6.** In game, on foot and outside any vehicle, type `/vinewood`.

The server console confirms the permissions setup on start:

```
[oxlyn-vinewood] Permissions: framework qbox, ACE oxlyn.vinewood
```

---

## Updating

1. Stop the resource (or the server).
2. **Back up and keep your `data/` folder**: `scene.json`, `scene.backup.json`,
   `upload-index.json`, `upload-index.backup.json` and `uploads/`. This is your
   published sign and your image library.
3. Replace everything else with the new version (including all of `stream/`).
4. Compare your `config.lua` with the new one and carry your settings across.
   Configs from older versions keep working — missing keys fall back to safe
   defaults — but new options only appear in the new file.
5. Full server restart, and players close and reopen FiveM once.

Scenes saved by older versions open without changes.

---

## Permissions & frameworks

`Config.Framework = 'auto'` detects the framework once, on first use:

| Started resource | Detected as |
|---|---|
| `qbx_core` | Qbox (checked first, because Qbox also starts a qb-core bridge) |
| `qb-core` | QBCore |
| `es_extended` | ESX |
| none of the above | standalone |

To force one, set `Config.Framework` to `'esx'`, `'qbcore'`, `'qbox'` or
`'standalone'`.

### Order of checks

The first check that says "yes" wins:

1. **`Config.Permissions.Custom(source)`** — your own function, if you set one.
   If it errors, the error is printed to the server console and the other
   checks still run.
2. **ACE `Config.Permissions.Ace`** (default `oxlyn.vinewood`) — checked on
   every framework, and the only check when standalone.
3. **Framework groups** from `Config.Permissions.Groups`.

| Framework | Default groups | How the group is checked |
|---|---|---|
| ESX | `admin`, `superadmin` | `xPlayer.getGroup()` |
| QBCore | `admin`, `god` | `QBCore.Functions.HasPermission(source, group)` |
| Qbox | `admin`, `god` | ACE `group.<name>`, and qbx_core `HasPermission` when available |

```lua
Config.Permissions = {
    Ace = 'oxlyn.vinewood',
    Groups = {
        esx    = { admin = true, superadmin = true },
        qbcore = { admin = true, god = true },
        qbox   = { admin = true, god = true },
    },
    Custom = nil,
}
```

Group lists may also be written as `{ 'admin', 'god' }`.

### ACE examples

```cfg
# a whole group
add_ace group.admin oxlyn.vinewood allow

# one player by licence
add_principal identifier.license:xxxxxxxxxxxxxxxx group.vinewood
add_ace group.vinewood oxlyn.vinewood allow
```

### Your own check

```lua
Config.Permissions.Custom = function(source)
    return exports['my_staff']:IsStaff(source)
end
```

Return `true` to allow. Anything else falls through to the ACE and framework
checks.

Configs from versions before 2.6.0 that still use `Config.Ace` /
`Config.ESXGroups` keep working.

Permission is checked by the server when the editor opens, on every heartbeat
while it is open and again on every publish. If an admin loses permission
mid-session, the session ends.

---

## Using the editor

Type `/vinewood` (on foot, alive, outside a vehicle). The editor opens with a
full-width **dock** at the bottom, a **layer list** on its left, **status chips**
top-left (published / unpublished changes, layer count, version) and a
**keybind bar** above the dock showing the keys for the current mode.

* **Tab** slides the dock away (the keybind bar glides to the bottom edge and a
  *Show editor* button appears); press it again to bring it back.
* **H** hides the whole interface for screenshots.
* **Q** switches to freecam; the dock hides and comes back when you leave.
* Drag the top edge of the dock to change its height.

### Layers

Add a text or image layer, move it up / down, duplicate, delete (click twice),
show / hide, lock, and rename with a double-click. Badges show **3D**, **Flat**
or **Image**. Locked layers ignore clicks in the world and the gizmo.

### Tabs

| Tab | What is in it |
|---|---|
| **Appearance** | Layer card (name, opacity, double-sided, lock); typography (3D letters / flat text, searchable grouped font picker, text, weight, alignment, line height); colour & fill with 9 one-click style presets — Classic, Hollywood, Neon, Gold, Sunset, Ocean, Rainbow, Midnight, Chrome; shape & light; finish. Image layers get image cards instead. |
| **Motion** | The 10 motion effects and their settings, pause preview, reset. |
| **Transform** | Gizmo (Move / Rotate / Scale, active axis X / Y / Z, snap), letter selector, exact position / rotation / width / height, nudge pad with step, −90° / +90° / Turn 180°, reset rotation, face the camera, mirror across the sign, center at sign anchor, align X / align height. |
| **Camera** | Views, field of view, freecam speed, look sensitivity, invert vertical look, smooth transitions, 3 bookmarks, time-of-day preview, navigation help. |
| **Scene** | Hide original sign, statistics, templates, JSON export / import, discard, appearance clipboard. |
| **Settings** | Per player, saved on their computer: language, interface scale (automatic or 100–200 %), editor height (300–560 px), keybind hints, grain & soft shadows (off = lighter look), accent colour (7 presets + custom), default snap, shortcut list, reset all settings, about. |

### Preview and publish

Everything you change is a **private preview** — only you see it. **Publish**
(`Ctrl+S`) sends the scene to the server, which validates it, saves it to
`data/scene.json` and shows it to every player. Leaving with `Esc` asks what to
do with unpublished changes: *Publish and exit*, *Discard* or *Keep editing*.

**One admin edits at a time.** The session is kept alive by a heartbeat; a
second admin who runs `/vinewood` is told someone else is editing. If the
editing admin disconnects, the session is released.

**Undo / redo** keeps the last 60 steps (`Ctrl+Z` / `Ctrl+Shift+Z`).

---

## Keyboard shortcuts

### Cursor mode

| Key | Action |
|---|---|
| `Q` | Switch to freecam |
| Left click | Select a layer or letter / drag the gizmo axis |
| Right-drag | Orbit around the selection |
| Middle-drag | Pan |
| Mouse wheel | Zoom |
| `←` / `→` | Nudge on X |
| `↑` / `↓` | Nudge on Y |
| `Page Up` / `Page Down` | Nudge on Z |
| `Shift` / `Alt` + nudge | ×10 / ÷10 |
| `Ctrl` + `←` / `→` | Rotate by `Config.Keys.rotateStep` (5°) |
| `F` | Frame the selection |
| `Tab` | Hide / show the editor |
| `H` | Hide the whole interface |
| `Delete` | Delete the layer (press twice) |
| `Ctrl+S` | Publish |
| `Ctrl+Z` / `Ctrl+Shift+Z` | Undo / redo |
| `Esc` | Close open lists and dialogs first, then ask to leave |

### Freecam

| Key | Action |
|---|---|
| `W` `A` `S` `D` | Move |
| `E` / `Ctrl` | Up / down |
| `Shift` | Faster |
| `Alt` | Slower |
| Mouse | Look |
| Mouse wheel | Field of view |
| `Q` | Back to cursor mode |
| `Esc` / `Backspace` | Exit |

While the editor is open the game never receives the keyboard — the interface
keeps focus in both modes — so other resources' keybinds (inventory on Tab,
phone, hotbar…) cannot fire inside the editor.

`Config.Keys` changes the freecam, toggle-editor, hide-interface and frame keys
(browser key codes such as `'KeyQ'`, `'Tab'`, `'F2'`) and the nudge steps.

---

## 3D letters

Choose **3D letters** in the typography card of a text layer.

* Real models with depth, shading and lighting, in **17 typefaces**.
* Limits: up to **4** 3D layers, **48** characters per layer and **96**
  letters in the whole scene (`Config.Limits`).
* Uppercase letters, numbers, Latin accents and the symbols in the catalogue.
  Text is converted to uppercase when you switch a layer to 3D.
* Colour per layer: **solid**, **gradient** (vertical or horizontal) or static
  **rainbow**. The custom colour picker has hue, saturation, brightness and HEX.
* Lighting: **Natural**, **At night** (from `Config.Solid.NightStart` 19:00 to
  `NightEnd` 07:00) or **Always on**, with light intensity.
* Optional **support posts** with adjustable length.
* Select a single letter with the letter selector (or by clicking it) to move,
  rotate and scale it on its own.

Each typeface has one physical weight in 3D; the weight slider applies to flat
text. Custom outline and glow are flat-text features.

---

## Flat text

Choose **Flat text** in the typography card. Flat text is drawn on a texture in
the world and supports:

* 23 typefaces and selectable weight
* colour, gradient or rainbow fill
* outline, glow and brightness
* letter spacing, alignment (left / centre / right), line height
* multiple lines, up to `Config.Limits.MaxTextLength` (96) characters

### Typefaces

Modern (Inter), Vinewood (Bungee), Serif (Roboto Slab), Mono (Roboto Mono),
Marker (Permanent Marker), Anton, Orbitron, Bebas Neue, Oswald, Montserrat,
Poppins, Playfair Display, Cinzel, Pacifico, Lobster, Righteous, Bangers,
Monoton, Audiowide, Russo One, Teko, Abril Fatface, Black Ops One. All are
available both as flat text and as 3D letters.

---

## Images & uploads

An image layer can take its picture from three places.

### 1. Imported from your PC

Use the file picker, drag and drop the file onto the editor, or paste it.

| | Limit |
|---|---|
| Formats | PNG, JPG, WebP |
| Input file | up to 8 MB and 16 million pixels |
| Stored as | PNG, at most 768 KiB and 2048 px on the longest side (`Config.Uploads`) |
| Library | up to 128 files in `data/uploads` |

The server gives each file its own name, verifies the PNG and its saved bytes,
and registers it in `data/upload-index.json`. Uploads are streamed at
`Config.Uploads.BytesPerSecond` so the connection stays smooth. Files are never
deleted automatically.

### 2. Local files shipped with the resource

Put PNG / JPG / WebP files in `web/dist/images/` (both editions) — or in
`web/src/images/` and rebuild (Open Source) — then **restart the resource** and
reference them in the editor as:

```
images/my-logo.png
```

File names may use letters, numbers, `_`, `-` and `.`. `oxlyn.png` and
`oxlyn-logotipo.png` are examples you can replace.

### 3. Remote HTTPS links

Allowed while `Config.AllowRemoteImages = true`:

* must start with `https://` and point at a public host (no `localhost`,
  private or local addresses, explicit ports or credentials);
* the path must end in `.png`, `.jpg`, `.jpeg` or `.webp`;
* at most `Config.Limits.MaxUrlLength` (512) characters;
* optionally restricted to the hosts in `Config.ImageHosts`:

```lua
Config.ImageHosts = { ['cdn.example.com'] = true, ['i.imgur.com'] = true }
```

Every player's game downloads a remote image directly from that host. **Avoid
expiring CDN links** (for example Discord attachment links with signed query
strings): they work while you edit and stop working hours later, and the image
disappears for everyone. For anything permanent, import the image instead —
it is then stored on your server.

### Image appearance

Tint, brightness, contrast, saturation, glow with colour, flip horizontal /
vertical, fit **contain / cover / stretch**, keep proportions and
double-sided.

---

## Motion effects

Image layers can move. Ten effects, in the **Motion** tab:

**Still · Float · Spin · Float + spin · Pulse · Sway · Orbit · Rock · Flip ·
Breathe**

Each has its own settings — speed, amount, radius, angle and phase — plus pause
preview and reset. Motion is calculated on every player's game from the
network clock, so everyone sees the same movement in sync without any
per-frame network traffic.

---

## Camera tools

* **Views** — Home, Front, Back, Left, Right, Top, Isometric and **Frame
  selection** (`F`). With something selected the views frame it; otherwise they
  frame the sign area.
* **Smooth transitions** between views and bookmarks
  (`Config.Camera.Interpolation`, in milliseconds; the *Smooth transitions*
  switch turns them off).
* **Orbit** (right-drag), **pan** (middle-drag) and **zoom** (wheel) in cursor
  mode.
* **Field of view, freecam speed, look sensitivity, invert vertical look.**
* **3 camera bookmarks**, remembered on that computer.
* **Time-of-day preview** — Live / Day / Sunset / Night. Only the editing admin
  sees it; the clock returns to server time when the editor closes. Times are
  set in `Config.Camera.TimePreview`.
* **Navigation help** listing the controls.

The camera cannot leave `Config.Freecam.MaxDistance` (800 m) around the anchor.

---

## Scene tools

In the **Scene** tab:

* **Templates** — Classic, Hollywood, Neon, Gold, Sunset, Rainbow and Server
  name. A template replaces the scene (undoable).
* **Style presets** (Appearance tab) — Classic, Hollywood, Neon, Gold, Sunset,
  Ocean, Rainbow, Midnight, Chrome; each applies colour, fill, lighting and
  finish in one click, respecting what the layer type supports.
* **Export scene** — copies the current scene as JSON.
* **Import scene** — pastes a JSON scene; it is validated with the same rules
  as the server and replaces the scene (undoable).
* **Discard** — returns to the published version.
* **Appearance clipboard** — copy a style from one layer and paste it onto
  another compatible layer.
* **Hide original sign** and scene **statistics**.

---

## Showcase

```
/vinewood showcase
```

Same permission as the editor. It opens the editor and lets a ghost cursor
build a demo by itself: it types the 3D text **"OXLYN SCRIPTS"** letter by
letter, tours the font list and picks Anton, applies the Gold preset, switches
to a gradient, sets lighting to Always on, adds an image layer "OXLYN Logo"
(`web/dist/images/oxlyn-logotipo.png`), places it 15 m above the text through
the Transform fields, gives it the Float effect, and finally tours the camera
views (Frame, Front, Right, Top, Isometric).

* No messages are shown — made for store videos and screenshots.
* Moving your mouse does not interfere; a real click or key press hands control
  back silently.
* The result stays a private preview until you publish or discard it.
* Needs two free layer slots.

Replace `oxlyn-logotipo.png` with your own logo to make the showcase yours.

---

## Languages

Included: **en**, **pt** (Portugal), **br** (Brazil), **es**, **fr**, **de**,
**it**, **nl**, **pl**, **tr**, **ru**, **cs**, **sv**, **ro** — one file each
in `locales/`. Any missing key falls back to English.

`Config.Locale` is the server default and the language of server replies. Each
player can pick another in **Settings → Language**; the choice is remembered on
their computer.

### Adding a language

1. Copy `locales/en.lua` to `locales/xx.lua`.
2. Change the code and name at the top:
   ```lua
   RegisterLocale('xx', {
       _name = 'My Language',
       -- ...
   })
   ```
3. Translate the values. Keep every `{placeholder}` exactly as written.
4. Restart the resource. The language appears in the list automatically (the
   manifest loads every file in `locales/`).

---

## Configuration overview

Everything is in `config.lua`, split into ten commented sections. After
editing, `restart oxlyn-vinewood`. See the file for every value.

| # | Section | What it controls |
|---|---|---|
| 1 | Framework & permissions | `Config.Framework`, `Config.Permissions` (`Ace`, `Groups`, `Custom`). |
| 2 | Command & language | `Config.Command` (`'vinewood'`) and `Config.Locale` (`'en'`). |
| 3 | Keyboard shortcuts | `Config.Keys`: `freecam` `'KeyQ'`, `toggleEditor` `'Tab'`, `hideUi` `'KeyH'`, `focus` `'KeyF'`, `nudgeStep` 0.1, `nudgeFast` 1.0, `nudgeSlow` 0.01, `rotateStep` 5. |
| 4 | Interface defaults | `Config.UI` (`Scale` `'auto'`, `Hints`, `DockHeight` 440, `Grain`) and `Config.Theme` (`accent`, `surface`). Players can override these in Settings. |
| 5 | Scene limits & area | `Config.Anchor` (centre of the editable area) and `Config.Limits`: 8 layers, 4 3D layers, 48 characters per 3D layer, 96 letters, 96 flat-text characters, 512-character URLs, 24000-byte scene, 450 m area radius, size 0.2–240 m. |
| 6 | Freecam & camera | `Config.Freecam` (start position / rotation, FOV 55, speed 18, fast / slow multipliers, max distance 800) and `Config.Camera` (interpolation 650 ms, sensitivities, smooth, invert Y, time-of-day preview times). |
| 7 | Rendering & streaming | Flat text / images: `DrawDistance` 2000, `FadeDistance` 150, `StreamInterval`, `DuiReleaseDelay`. 3D letters: `Config.Solid` (stream interval, release delay, load timeout, spawn budget, `NightStart` / `NightEnd`, matrix check). Leave `TextureDictionary` as it is. |
| 8 | Images & uploads | `Config.AllowRemoteImages`, `Config.ImageHosts`, `Config.Uploads` (`MaxBytes` 768 KiB, `MaxDimension` 2048, `MaxStored` 128, `BytesPerSecond`). |
| 9 | Original sign | `Config.OriginalSign`: centre, 200 m radius and the 56 models *Hide original sign* hides. Never add `ch2_lod3_*` models — they contain terrain. |
| 10 | Default scene | `Config.DefaultScene`, used until the first publish. Empty by default: open the editor, press *Replace VINEWOOD* or add layers, then Publish. |

---

## Original sign

**Hide original sign** (Scene tab) hides the **56 nearby models** of the
original sign — letters, structure, framing, joins and ladders — within 200 m
of `Config.OriginalSign.Center`. It is part of the scene, so it is published
with it.

The original letters also exist as low-detail **LOD / SLOD** versions that the
game draws from far away. Those are removed by **7 bundled map assets** in
`stream/`, in which only the letter triangles are collapsed; terrain, supports
and every other mesh stay intact:

* `ch2_03_sign_slod_children.ydd`
* `ch2_lod3_s2b_children.ydd`
* `ch2_03_emis_sign_slod_children.ydd`
* `ch2_03_emis_sign_slod.ydr`
* `ch2_lod3_slod3.ydr`
* `ch2_lod3_slod3_children.ydd`
* `ch2_lod3_emissive_slod3.ydr`

This is active whenever the resource runs, day and night. To get the original
map back, stop the resource and rejoin.

**Conflicts.** Do not run another resource that replaces the same Vinewood map
files (`ch2_03_*sign*slod*`, `ch2_lod3_*`). Whichever loads last wins, and the
original letters may reappear in the distance.

---

## Storage & backups

Everything the server saves lives in `data/`:

| File | Contents |
|---|---|
| `scene.json` | The published scene |
| `scene.backup.json` | The previously published scene |
| `upload-index.json` | The register of imported images |
| `upload-index.backup.json` | The previous register |
| `uploads/` | Imported images (`<32 hex characters>.png`) |

**How saving works.** On publish the server first writes the current scene to
`scene.backup.json`, reads it back and checks it byte for byte, and only then
writes and verifies the new `scene.json`. Only scenes that passed validation
are ever written. Imported images and their index are handled the same way.

**Storage block.** If the files are changed, damaged or unreadable outside the
editor, the server **stops saving** rather than overwrite them. Publishing then
answers *"Storage is protected"* and the server console explains which file and
why. If `scene.json` is unreadable but the backup is valid, the backup is loaded
and shown to players meanwhile.

**Recovering:**

1. Read the server console message — it names the file and the problem.
2. Stop the resource.
3. Repair the damaged file, or move it out of `data/` (for example, replace a
   broken `scene.json` with a copy of `scene.backup.json`, or with your own
   backup).
4. `ensure` / restart `oxlyn-vinewood`.

Rules of thumb:

* Keep `data/` writable by FXServer.
* **Never edit these files while the resource is running.**
* Back up the whole `data/` folder before editing anything by hand, and before
  every update.

---

## Performance

What 2.6.0 does to stay light (measured as work counts in scripted tests, not
as in-game FPS or resmon figures):

* 3D font / colour banks are requested **on demand** through YMAP / YTYP
  dependencies — at most 24 at a time — and released after their letters are
  removed.
* Flat text and images share **one 2048×2048 texture** (8 tiles of 1024×512)
  that repaints **only when content changes**; moving, rotating or animating
  never repaints it. Only the fonts in use are loaded.
* Images off screen skip animation maths; double-sided images draw only the
  visible face.
* Letters are created in small batches (`Config.Solid.SpawnBudget`).
* No per-frame network or interface traffic.
* Near-zero cost away from the sign: content beyond the draw distance is
  released after `Config.DuiReleaseDelay` / `Config.Solid.ReleaseDelay`.

---

## Diagnostics & export

### Colour check

If 3D letters stay white or show the wrong colour, open the F8 console:

```
oxvw_colorcheck
```

For 60 seconds it shows, side by side, the colour you chose, the generated
texture and the texture actually on the model. Run it again to close it early.

```
oxvw_colorcheck rebind
```

binds the colour textures to the letters again.

### Server export

```lua
-- server side
local scene, revision = exports['oxlyn-vinewood']:GetScene()

print(('Vinewood sign: revision %d, %d layer(s), original hidden: %s')
    :format(revision, #scene.layers, tostring(scene.hideOriginal)))

for _, layer in ipairs(scene.layers) do
    -- layer.type is 'text' or 'image'
    print(layer.name, layer.type, layer.text or layer.url)
end
```

`GetScene` returns a copy of the published scene and its revision number
(0 until the first publish).

---

## Building the interface

*Open Source edition only. The Escrow edition ships the built interface.*

The game loads `web/dist`. The source is in `web/src`. After editing the
source:

```bash
cd web
bun run build      # or: node build.mjs
```

* No `npm install` is needed — the build has no dependencies.
* With Bun installed the scripts are minified; with plain Node they are copied
  as they are (still valid, just larger).
* Fonts and images from `web/src` are copied to `web/dist`. **The build never
  deletes files** in `web/dist/images` or `web/dist/fonts`, so images you added
  there directly are kept.

Then `restart oxlyn-vinewood` and reopen the editor.

---

## Troubleshooting

**`/vinewood` does nothing or says I have no permission.**
Check the ACE line (`add_ace group.admin oxlyn.vinewood allow`) or your
framework group in `Config.Permissions.Groups`. The console line printed at
start shows the detected framework and ACE. You must also be on foot, alive and
outside a vehicle.

**"Another administrator is editing."**
Only one admin edits at a time. Wait for them to close the editor; if they
crashed, the session is released when they disconnect, or about a minute after
their heartbeat stops.

**The interface does not open or is blank (Open Source).**
The folder must be named `oxlyn-vinewood`, not `oxlyn-vinewood-OPENSOURCE`.

**Letters are invisible or missing after install or update.**
Full server restart (not a resource restart), then close and reopen FiveM.
Also make sure all of `stream/` was replaced.

**3D letters stay white.**
Pick a strong solid colour and run `oxvw_colorcheck` in F8; try
`oxvw_colorcheck rebind`.

**The original letters reappear in the distance.**
Another map resource replaces the same Vinewood files. See
[Original sign](#original-sign).

**Publish says "Storage is protected".**
`data/scene.json` or `data/scene.backup.json` was edited or damaged outside the
editor, or cannot be written. Read the console, fix or remove the damaged file
and restart the resource — see [Storage & backups](#storage--backups).

**A remote image does not load.**
It must be a direct `https://` link whose path ends in `.png`, `.jpg`,
`.jpeg` or `.webp`, on a host allowed by `Config.ImageHosts` (if set), with
`Config.AllowRemoteImages = true`. Expiring CDN / Discord links break later —
import the image instead.

**A local image (`images/...`) does not show.**
The file must be in `web/dist/images`, the name must match exactly, and the
resource must be restarted after adding it.

**"The server image library is full."**
`data/uploads` holds up to `Config.Uploads.MaxStored` (128) images and never
deletes them by itself. Reuse images already in the library, or use local files
in `web/dist/images`. If you want to clear the library by hand, stop the
resource and back up `data/` first; an image removed by hand must not be used by
the published scene, and both upload index files must stay consistent with the
folder, otherwise the storage block described above protects the data.

**The interface is too small or too large.**
Settings → Interface scale.

---

## Credits & licences

Made by **OXLYN Software**.

The bundled typefaces are open-source fonts (mostly SIL Open Font License).
Their licence texts are in `licenses/` and alongside the fonts in
`web/dist/fonts/`.

**2.6.1 Cfx upload limit:** this edition stays below 10,000 files. All 23 fonts remain available in flat text; Playfair, Pacifico, Lobster, Monoton, Teko and Abril are flat-only. The other 17 retain full 3D colours, gradients, depth and lighting. Older saved 3D layers using a removed face load with Modern (Inter), so scenes remain editable. When updating an existing installation, replace the entire old `stream/` folder; merging folders would leave the removed models behind. Keep your `data/` folder.
