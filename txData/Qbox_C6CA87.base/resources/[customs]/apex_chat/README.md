# Apex Chat

A fully-custom, category-based chat for FiveM with a premium NUI, live themes,
permissioned channels, player tags, in-game photos, GIFs and 3D head bubbles.
Drop-in replacement for the default `chat` resource — keeps the full `chat:*`
API and legacy `okokChat` events, so the rest of your server keeps working.

**Works out of the box on ESX, QBCore and Qbox** (auto-detected).

---

## ✨ Features

- **Category channels** — unlimited, per-channel command, colour, icon, identity,
  permission rule (open / job / grade / staff / role), area radius & visibility.
  Managed live in-game (admin) — no restarts.
- **Themes** — colour themes *and* layout themes (23 designs: Glass, Neon, Bubble,
  Cards, Minimal, Terminal, iMessage, Vaporwave…). The colour theme recolours the
  whole settings panel too.
- **Player tags** — fully customizable badges (text/icon/colour/style/priority),
  assignable to online or offline players.
- **Rich messages** — @mentions (highlight + chime), replies, reactions, edit/delete
  (admin), typing indicator, slow-mode / anti-spam, GIF picker, emoji picker.
- **In-game photos** — free camera framing, sent inline (needs `screenshot-basic`).
- **3D head bubbles** — `/me` `/do` `/try` speech bubbles above the speaker.
- **Per-player settings** — size, position, free-hand drag, visibility mode,
  fonts, density, sound, blocked users/chats — all auto-saved.
- **Localised** — server messages in EN / PT / ES / FR (`Shared.locale`), plus a
  NUI i18n hook (`data-i18n`). UI ships in English.

## 📦 Dependencies

- A recent **FXServer** (artifact ≥ 5104).
- **screenshot-basic** — *optional*, only for the in-game photo tool. Without it,
  everything else works and the photo button degrades gracefully.
- No framework dependency in the manifest — the bridge detects qb-core / qbx_core /
  es_extended at runtime.

## 🚀 Installation

1. Drop the `apex_chat` folder into your resources.
2. In **`server.cfg`**:
   ```cfg
   # Stop the built-in chat so it can't open a second chat window:
   set resources_useSystemChat false
   # Do NOT `ensure chat` — apex_chat already provides 'chat'.

   ensure apex_chat
   ```
   Ensure it **after** your framework (es_extended / qb-core / qbx_core).
3. (Optional) `ensure screenshot-basic` for in-game photos.
4. Restart the server.

## ⚙️ Configuration — `shared/config.lua`

Open source & fully editable (escrow-ignored). Key options:

| Setting | Purpose |
|---|---|
| `Shared.framework` | `'auto'` (default) \| `'qb'` \| `'qbx'` \| `'esx'` |
| `Shared.locale` | `'en'` \| `'pt'` \| `'es'` \| `'fr'` |
| `Shared.debug` | `false` for production. `true` enables dev helpers (a `/me`-bubble test keybind). |
| `Config.StaffGroups` | ACE/framework groups treated as staff/admin. |
| `Config.Categories` | Seed channels (also editable live in-game). |
| `Config.Gif` | GIF provider (Tenor by default; Giphy needs your own key). |
| `Config.SlowMode` / `Config.Mentions` / `Config.Typing` | Toggle & tune. |
| `Config.WebhookURL`, `Config.ServerName`, `Config.IconURL` | Discord logging (leave blank to disable). |
| `Config.ScreenPhoto` | In-game photo (framing mode, quality…). |

Themes live in `Config.Themes`; the default is **Apex** (brand blue `#1F5EFF`).

## 🔐 Permissions

Staff/admin checks work across frameworks: the framework-native permission is
checked first, then an ACE fallback — so `add_principal identifier.X group.admin`
in `server.cfg` always works. Set which groups count as staff in
`Config.StaffGroups`.

On **Qbox** the groups are plain ACEs, the Qbox default
(`add_ace group.admin admin allow`). The chat talks to `qbx_core` natively, so
the `qb-core` bridge does not need to be enabled.

## 🗨️ Commands (defaults)

`/global`, `/local`, `/me`, `/do`, `/try`, `/ooc`, `/pm`, `/twitter`(→X),
`/twitch`, `/youtube`, `/ad`, `/anon`, `/clear`, `/hide`, plus every category
command you create. Open **Settings** from the chat gear or the bound key.

## 🎨 Customization

- Colours & layout: `Config.Themes` in `shared/config.lua` (editable in **both**
  builds). Raw stylesheets (`build/html/css/ui.css` & `chat.css`) are only
  editable in the open-source build — they are part of the encrypted build in
  the escrowed one.
- All UI strings are English; add `data-i18n="key"` to any element + the key to
  `shared/locales.lua` to translate the panel.

## 🌐 Offline by design

Fonts (Inter, Titillium Web) and icons (Font Awesome 6 Free) ship **inside** the
resource — the NUI never calls out to Google Fonts or a CDN. That keeps the chat
identical for players behind a firewall or on a bad route, and keeps joins fast:
a remote stylesheet in a NUI page is render-blocking and is fetched while the
player is still on the loading screen.

## 🆘 Support

For issues or feature requests, contact the seller. Include your framework,
artifact version and any console errors.

— *Apex Scriptz*
