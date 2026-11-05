# Changelog

## 2.6.1 — 2026-09-26

- Correct the Cfx 10,000-file asset limit: 17 physical 3D fonts and all 23 flat-text fonts.
- Playfair, Pacifico, Lobster, Monoton, Teko and Abril remain available as flat text. Older 3D layers using these faces fall back to Modern (Inter).
- Retain all four independent 3D colour slots, gradients, lighting and the existing model geometry.
- Remove the six unused physical font banks and their map dependencies; keep the previous lossless compression.
- Replace the entire old `stream/` folder when updating, preserve `data/`, then restart the server and FiveM.

## 2.6.0 — 2026-09-26

**Update notes:** replace all of `stream/`, keep your `data/` folder, do a full
server restart and close and reopen FiveM before testing. Your 2.5.0
`config.lua` keeps working.

### Typefaces
- All 23 typefaces are now available as physical 3D letters as well as flat
  text, including the 16 added in 2.5.0. They keep per-layer colours and
  gradients, depth, lighting and individual letter selection.

### Performance
- 3D font / colour banks are requested per font and per layer through YMAP /
  YTYP dependencies, with a cap of 24 requests at a time (banks still loading
  count towards it), and released after their letters are removed.
- The flat-text / image atlas loads only the fonts in use and reuses text
  measurements during colour changes.
- Imported images are no longer resent to the interface on every change; large
  images are kept in memory at a limited resolution, preserving transparency.
- Images outside the camera's view skip animation maths; double-sided images
  draw only the visible face.
- Letters that finished loading no longer rebuild the creation queue; the
  per-frame matrix correction only runs when needed.

### Frameworks & permissions
- Framework bridge: ESX, QBCore, Qbox and standalone, detected automatically or
  forced with `Config.Framework`.
- New `Config.Permissions` block (ACE, framework groups, optional `Custom`
  function). Older configs using `Config.Ace` / `Config.ESXGroups` keep
  working.
- The server console prints the detected framework and ACE at start.

### Editor
- `/vinewood showcase`: a self-driving, silent demonstration for videos and
  screenshots.
- Freecam keeps interface focus, so other resources' keybinds cannot fire
  inside the editor.
- Custom dropdown menus.
- Full-width inspector: every card fits without scrolling at 1080p (default
  editor height 440).

### Open Source edition
- Interface source in `web/src`, built into `web/dist` with
  `cd web && bun run build` (or `node build.mjs`). The build never deletes
  files you added to `web/dist/images`.

### Unchanged
- Existing geometry, colour materials, the seven original-sign map fixes,
  languages, tools and 2.5.0 scenes.

## 2.5.0 — 2026-09-25

### Interface
- Redesigned editor: bottom dock with six tabs (Appearance, Motion, Transform,
  Camera, Scene, Settings), layer column, card rails, status chips top-left
  (publish state, layer count, version).
- Hide / show the editor like the Map Editor: `Tab` slides the dock down and
  the keybind bar glides to the bottom edge with a "Show editor" button.
  Freecam (`Q`) hides the dock and restores it on exit.
- `H` hides the whole interface for screenshots.
- Context-aware keybind bar (cursor, freecam, selected letter, hidden
  interface), can be turned off.
- Editor height by dragging the top edge or a slider (300–560 px); interface
  scale automatic or fixed (100–200 %); accent colour presets and custom
  colour; lighter look without grain and heavy shadows.
- Popovers and dialogs position correctly at any scale.

### Typefaces
- 16 new flat-text typefaces: Bebas Neue, Oswald, Montserrat, Poppins,
  Playfair Display, Cinzel, Pacifico, Lobster, Righteous, Bangers, Monoton,
  Audiowide, Russo One, Teko, Abril Fatface, Black Ops One (all bundled, OFL).
- Grouped, searchable font picker with a "3D" badge.
- Flat text alignment (left, centre, right) and line height.

### Tools
- One-click style presets: Classic, Hollywood, Neon, Gold, Sunset, Ocean,
  Rainbow, Midnight, Chrome.
- Scene templates: Classic, Hollywood, Neon, Gold, Sunset, Rainbow, Server
  name.
- JSON export / import, discard to the published version (undoable),
  appearance clipboard.
- Lock layers, rename by double-click, 3D / Flat / Image badges.
- Arrow-key nudge (X / Y), Page Up / Down (Z), Shift ×10, Alt ÷10,
  Ctrl + arrows rotate; nudge pad with configurable step.
- Face the camera, turn 180°, mirror, align to the sign anchor.

### Camera
- Smooth, configurable transitions between views.
- Seven views (Home, Front, Back, Left, Right, Top, Isometric) and Frame
  selection.
- Orbit (right button), pan (middle button) and zoom (wheel) in cursor mode.
- Three camera bookmarks.
- Adjustable field of view, speed, sensitivity and vertical inversion.
- Time-of-day preview (Live, Day, Sunset, Night) for the editing admin only.

### Languages & configuration
- 14 languages (en, pt, br, es, fr, de, it, nl, pl, tr, ru, cs, sv, ro);
  `Config.Locale` sets the server default, each player can choose another.
- New options: `Config.Locale`, `Config.Keys`, `Config.UI`, `Config.Camera`.
- Scenes from 2.4.x load unchanged (`locked`, `align` and `lineHeight` are
  optional).

## 2.4.2

- The distant LOD / SLOD letters of the original sign are removed by bundled
  map assets.
- Wide bottom editor bar with sections, layers and publishing at hand.

## 2.4.0

- Bottom editor bar.
- Camera views.
- 10 motion effects for images.
- Image appearance tools (tint, brightness, contrast, saturation, glow, flip,
  fit).

## 2.3.x

- Colour texture recovery for 3D letters.
- `oxvw_colorcheck` diagnostic command.

## Earlier

- Gradient and rainbow fills.
- Four independent 3D colour layers.
- Font picker.
