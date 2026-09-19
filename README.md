# Workspace Taskbar

A per-window taskbar plugin for Omarchy 4.0.4. It keeps the built-in `omarchy.bar`, uses Omarchy's scoped AppLibrary for application presentation, and delegates only window-state transactions to a one-shot Rust helper.

## Design

- `TaskbarService.qml` owns the live window model, AppLibrary matching, runtime compatibility probe, and backend queue.
- `Taskbar.qml` renders one button for every real Hyprland window. There is no default application grouping.
- `Taskbar.qml` owns the bar-native right-click `KeyboardPanel` and its `PanelKeyCatcher` cursor model.
- `CapabilityMenu.qml` is intentionally non-visual; the `menu` manifest kind is retained only because Omarchy 4.0.4 uses it to grant the scoped AppLibrary capability.
- `qml/AppMatcher.js` selects an existing Omarchy DesktopEntry. It never resolves icons itself.
- `backend/` contains a one-shot Rust CLI for minimize/restore, group-safe state, Show Desktop, recovery, and exact-address window actions.
- `scripts/doctor.sh` checks the supported public interfaces without modifying Omarchy files.
- Optional titlebar polish uses only the official `hyprwm/hyprland-plugins` Hyprbars plugin through `hyprpm`.

The plugin does not replace the bar, modify `/usr/share/omarchy`, start another Quickshell instance, fork Hyprland/Hyprbars, or run a resident backend daemon.

## Current milestone: 0.13.5

Core behavior:

- one actual Hyprland window = one taskbar button;
- exact-address focus, minimize, restore, close, floating/fullscreen/maximized/pseudo/group actions;
- stable right-click popups anchored to the clicked instance;
- a bar-native Show Desktop button: left click toggles Show Desktop and right click uses Omarchy's own per-workspace Dwindle/Scrolling toggle;
- stable first-seen button ordering and incremental model updates;
- original workspace name/special-workspace metadata;
- AppLibrary-only application name/icon presentation;
- matching by startup class, DesktopEntry id, executable, Steam app id, web-app host, and XDG user overrides;
- persisted minimize/restore state with atomic replacement and recovery;
- tiled reattachment on restore for Hyprland 0.56.x;
- active/minimized/urgent/pressed taskbar states themed through Omarchy shared UI tokens.
- taskbar control/action glyphs use a small bundled Lucide SVG subset, normalized to white luminance before Qt MultiEffect tinting so menu/control pixels follow Omarchy semantic colors; Show Desktop itself stays on Omarchy’s native bar-glyph path for exact built-in alignment/color, and application identity icons still come exclusively from AppLibrary;
- context-menu workspace picker using the same 1-5 plus live 6-10 workspace policy as Omarchy's built-in workspace widget;
- exact-address move-to-workspace without following/focusing the moved window;
- one-click Move here for windows on another workspace;
- exact-address Omarchy-style Pop out / Return popped window, tracked with Hyprland's static `pop` tag;
- taskbar tooltips include the window's current workspace and live compositor state;
- window buttons expose Qt accessibility semantics and keyboard activation/context-menu access;
- context menus use Omarchy's keyboard-focus-owning panel path and support Up/Down/Left/Right, Tab/Shift+Tab, Enter/Space, and Escape with visible Omarchy cursor treatment;
- matched AppLibrary applications expose **Open new window** without bypassing Omarchy's launcher path;
- **Move to workspace…** includes Omarchy's native Scratchpad (`special:scratchpad`) alongside the numeric workspaces;
- multi-monitor sessions expose **Move to monitor…** using Quickshell's native `Hyprland.monitors` model and an exact-address Hyprland 0.56 Lua dispatcher;
- multi-monitor tooltips identify the window's current output without adding monitor chrome in single-monitor sessions;
- matched applications can be **pinned to the taskbar** using only their Omarchy AppLibrary DesktopEntry id;
- pinned launchers appear only while that application has no matched live window, preserving the invariant that every real window keeps its own independent taskbar button;
- pinned launcher order persists in `$XDG_CONFIG_HOME/dev.becerromarchy.workspace-taskbar/pins.json` and can be adjusted from the launcher's keyboard-accessible context menu;
- hovering a live window button briefly opens a compositor-native single-frame preview using Quickshell `ScreencopyView`; the capture source exists only while the preview surface is visible, never runs as a live feed, and yields to context menus/popouts through Omarchy's bar coordinator;

Bundled Lucide assets are licensed under the upstream ISC/MIT terms in `icons/lucide/LICENSE`.

Optional Hyprbars integration:

- official `https://github.com/hyprwm/hyprland-plugins` only;
- installed, enabled and reloaded only through `hyprpm`;
- ABI matching remains Hyprpm's responsibility;
- one managed config: `~/.config/hypr/workspace-taskbar-hyprbars.lua`;
- one marker-delimited hook in user-owned `~/.config/hypr/hyprland.lua`;
- guarded Lua config, so a missing Hyprbars plugin does not create Hyprland config errors;
- theme-derived titlebar colors from Omarchy's current `colors.toml`;
- titlebar buttons: minimize, maximize/restore, and close;
- double-click titlebar: toggle maximized;
- exact-address titlebar actions, so focus changes cannot redirect maximize/close;
- inactive title text follows the Omarchy muted color;
- real fullscreen and windows advertising Wayland content type `game` automatically suppress Hyprbars;
- titlebar colors are reread on Hyprland reload using the same semantic-role precedence as Omarchy 4.0.4, so normal theme switches retheme Hyprbars automatically;
- no titlebar right-click workaround or fork-dependent `...` button;
- ownership state records whether this project added the official repository or enabled Hyprbars, so uninstall does not blindly remove a pre-existing dependency.

The taskbar remains fully functional without Hyprbars.

## XDG paths

```text
source:   ~/.config/omarchy/plugins/dev.becerromarchy.workspace-taskbar/
config:   $XDG_CONFIG_HOME/dev.becerromarchy.workspace-taskbar/
          ├── overrides.json   (optional AppLibrary match overrides)
          └── pins.json        (taskbar-pinned AppLibrary DesktopEntry ids)
backend:  $XDG_DATA_HOME/dev.becerromarchy.workspace-taskbar/bin/workspace-taskbar-backend
state:    $XDG_STATE_HOME/dev.becerromarchy.workspace-taskbar/restore-v1.json
cache:    $XDG_CACHE_HOME/dev.becerromarchy.workspace-taskbar/
runtime:  $XDG_RUNTIME_DIR/dev.becerromarchy.workspace-taskbar/
```

Optional Hyprbars files:

```text
~/.config/hypr/workspace-taskbar-hyprbars.lua
$XDG_DATA_HOME/dev.becerromarchy.workspace-taskbar/bin/workspace-taskbar-hyprbars-action
$XDG_STATE_HOME/dev.becerromarchy.workspace-taskbar/hyprbars-ownership.env
```

Application matching overrides are optional:

```json
{
  "matches": {
    "window-class": "desktop-entry-id"
  }
}
```

Save that as `$XDG_CONFIG_HOME/dev.becerromarchy.workspace-taskbar/overrides.json`. The value identifies an entry already exposed by Omarchy AppLibrary; it does not provide a custom icon or display name.

## Validation

Source-only checks:

```bash
tests/smoke/static.sh
omarchy plugin validate .
```

The backend build is a separate runtime step. `scripts/build-backend.sh` uses no `sudo`; Cargo output stays under XDG cache and the installed executable goes under XDG data instead of the watched plugin source tree.

0.12.2 adds delayed, single-frame window previews entirely in QML using Quickshell's Hyprland toplevel mapping and `ScreencopyView`. Capture is created only while the hover card is open and `live` remains disabled, so there is no resident preview stream. The one-shot backend stays at `0.7.0` / protocol `4`; updating from 0.11.0 requires no Rust rebuild or Hyprbars setup rerun. Agent/design skills remain development methodology only and are not installed or shipped by the plugin.

## Optional Hyprbars setup

Run only after the core taskbar is healthy:

```bash
./scripts/setup-hyprbars.sh
```

Status:

```bash
./scripts/setup-hyprbars.sh --status
```

Remove only this project's Hyprbars integration:

```bash
./scripts/setup-hyprbars.sh --remove
```

The setup script never installs Arch packages or uses `sudo`. It checks for Hyprpm's build dependencies and stops if they are missing.

## Runtime IPC

```bash
omarchy-shell workspace-taskbar status
omarchy-shell workspace-taskbar model
omarchy-shell workspace-taskbar refreshApps
omarchy-shell workspace-taskbar showDesktop
omarchy-shell workspace-taskbar restoreLast
omarchy-shell workspace-taskbar restoreAll
omarchy-shell workspace-taskbar recover
```

## Compatibility baseline

The reviewed baseline is Omarchy `v4.0.4`, Hyprland `0.56.2` and the official Hyprbars Lua API exposed through Hyprpm. Exact Omarchy compatibility notes are recorded in `compat/upstream.json`. `scripts/doctor.sh` reports version drift rather than patching upstream automatically.

### Preview runtime note

Version 0.12.2 fixes the initial preview implementation by using Quickshell 0.3.1's `paintCursor` property and by normalizing Hyprland window addresses before resolving the associated Wayland toplevel.


## 0.13.1 compatibility reset

Version 0.13.1 deliberately returns the taskbar UI/model behavior to the validated 0.12.2 baseline. The rejected 0.13.0 multi-instance clustering, number badges, `Window N of M` metadata, and `App windows` submenu are not part of the plugin.

`./scripts/doctor.sh` also checks the runtime taskbar model against Hyprland's live clients plus the backend's minimized records so a stale/ghost taskbar row is reported explicitly.


### Theme color contract for taskbar-owned icons

Bar controls follow Omarchy `WidgetButton`: `foreground: bar ? bar.barForeground : Color.foreground`. Show Desktop deliberately does not opt into an accent/active color; its main glyph and right-click cue both use that native bar foreground. Menu action glyphs follow `Color.menu.text`, `Color.menu.selectedText`, and semantic `Color.urgent` for Close. Lucide SVGs are rendered as monochrome masks: the raw `currentColor` source resolves black in Qt Image, so `LucideIcon.qml` applies `brightness: 1.0` before `colorization: 1.0`; the target color still comes entirely from the Omarchy theme role supplied by the caller.
