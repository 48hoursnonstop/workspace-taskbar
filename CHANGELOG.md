# 0.14.0-rc.2

- Use `workspace-taskbar` as the plugin ID and source/runtime directory name.
- Add `install.sh --with-hyprbars` for complete installation in one step.
- Isolate doctor test fixtures from the host Omarchy installation.
- For the old plugin ID, uninstall the previous release before adding this one.

# 0.14.0-rc.1

- Preserve pending minimize/restore transactions across dispatcher failures; recover orphaned hidden windows and reject unsafe cleanup.
- Add executable-side protocol guards, kernel-managed locking and strict doctor error propagation.
- Move the context menu to a real menu entry point using documented own-service injection; keep monitor-host ownership valid after removal.
- Commit Cargo.lock, fix Rust/ShellCheck gates, add backend and lifecycle regressions, and monitor upstream contracts in CI.
- Document source installation, explicit backend rebuilding, recovery and symmetrical removal.

# Changelog

## 0.13.7

- Restore Show Desktop's main control to Omarchy's native glyph rendering path (`BarIconButton`/`OpticalGlyph`) so its optical center matches the built-in bar icons instead of inheriting Lucide SVG geometry.
- Stop treating any minimized window as an accent-worthy Show Desktop state. The control now uses the same `bar.barForeground -> Color.bar.text` color as ordinary built-in bar icons at all times.
- Keep the small right-click discoverability cue, but tint it with the same bar foreground and reduce it to a subtle corner overlay; it no longer uses `Color.accent` or shifts the main glyph.

## 0.13.6

- Fix Lucide controls rendering black despite correct Omarchy color bindings. Lucide SVG `currentColor` resolves to black when loaded by Qt `Image`; Qt `MultiEffect` colorization preserves source luminance, so black cannot become the requested theme color by colorization alone.
- Match Qt's own SVG-tint pattern by applying `brightness: 1.0` before `colorization: 1.0`. This turns the monochrome source into a white mask while preserving alpha, then paints it with the caller's Omarchy semantic color.
- Keep the actual theme contract unchanged: bar controls use the same `bar.barForeground`/active-color behavior as Omarchy `WidgetButton`; menu actions use `Color.menu.text` / `Color.menu.selectedText`; Close remains `Color.urgent`. No hard-coded visual color is introduced.
- Add a static regression gate for the required brightness + colorization pipeline.

## 0.13.5 - 2026-09-19

- Make the Show Desktop right-click affordance use the exact same theme-state color contract as the pre-Lucide control: `bar.barForeground`/widget foreground at rest and `Color.accent` only while Show Desktop is active.
- Remove the permanently accented right-click cue introduced in 0.13.4; the cue remains visible but no longer competes with active/selected semantic color.
- Keep backend `0.7.0`, protocol `4`, menu iconography, previews, pins, multi-monitor behavior, scratchpad support, and Hyprbars unchanged. No Rust rebuild is required.

## 0.13.4 - 2026-09-19

- Make the bundled Lucide renderer theme-native by default: `LucideIcon` now inherits Omarchy `Color.foreground` instead of falling back to hard-coded white.
- Use Omarchy's dedicated `Color.menu.*` roles for context-menu text/icons and selected-row icon/text feedback; Close remains on the semantic `Color.urgent` role.
- Add a small theme-accented Lucide `mouse-pointer-click` cue to the Show Desktop control so the Dwindle/Scrolling right-click action is discoverable without adding another permanent bar button.
- Keep the 0.13.3 menu icons; this pass changes their palette integration rather than expanding iconography further.
- Keep backend `0.7.0`, protocol `4`, Hyprbars, previews, pins, scratchpad, and multi-monitor behavior unchanged. No Rust rebuild is required.

## 0.13.3 - 2026-09-19

- Remove the Show Desktop middle-click recovery menu; the control now has only two everyday actions: left click Show Desktop, right click Omarchy's per-workspace Dwindle/Scrolling toggle. Backend recovery commands remain available for diagnostics/maintenance but no longer occupy a hidden pointer gesture.
- Replace the Show Desktop Nerd Font glyph and degraded-state exclamation mark with theme-tinted Lucide SVG controls rendered through Omarchy/Qt Quick primitives.
- Add Lucide icons to context-menu actions while preserving text labels, keyboard cursor semantics, accessible names, semantic urgent coloring for Close, and the existing progressive-disclosure structure.
- Keep application identity icons strictly AppLibrary-only; the bundled Lucide subset is used only for taskbar-owned controls/actions and carries its upstream ISC/MIT license in `icons/lucide/LICENSE`.
- Keep backend `0.7.0`, protocol `4`, previews, pins, multi-monitor behavior, scratchpad support, and Hyprbars unchanged; no Rust rebuild or Hyprbars setup rerun is required.

## 0.13.2 - 2026-09-19

- Repurpose the Show Desktop button's everyday pointer actions: left click remains Show Desktop, while right click now toggles the current workspace between Dwindle and Scrolling.
- Delegate the layout switch to Omarchy 4.0.4's own `omarchy-hyprland-workspace-layout-toggle`, preserving Omarchy's per-workspace layout persistence and notification behavior instead of duplicating Hyprland state logic in the plugin.
- Keep the existing restore-last, restore-all, and recovery menu available on middle click so maintenance actions remain reachable without occupying the primary right-click gesture.
- Update the Show Desktop tooltip to document all three pointer actions.
- Keep backend `0.7.0`, protocol `4`, previews, pins, multi-monitor behavior, and Hyprbars unchanged; no Rust rebuild or Hyprbars setup rerun is required.

## 0.13.1 - 2026-09-19

- Revert the rejected 0.13.0 multi-instance UX completely: no same-app clustering, number badges, `Window N of M` metadata, `App windows` submenu, or instance-focus action.
- Restore the validated 0.12.2 one-window/one-button ordering and interaction model unchanged.
- Add a doctor-only runtime model integrity check that compares taskbar row addresses with Hyprland live clients and backend minimized records. This makes stale/ghost rows visible in diagnostics without adding polling or another runtime state source to QML.
- Keep backend `0.7.0`, protocol `4`, previews, pins, multi-monitor support, scratchpad support, AppLibrary-only presentation, and Hyprbars unchanged. No Rust rebuild or Hyprbars setup rerun is required.


## 0.12.2

- Fix the preview widget regression introduced in 0.12.1: Quickshell 0.3.1 exposes the QML property as `paintCursor` (singular). The C++ getter/setter are named `paintCursors`/`setPaintCursors`, but the `Q_PROPERTY` name used by QML is singular.
- Keep the 0x-insensitive Hyprland address matching added in 0.12.1.
- Doctor now verifies that the installed Quickshell package exposes the Screencopy QML module before preview testing.
- No Rust/backend or Hyprbars changes.

## 0.12.1

- Fixed window previews not appearing at runtime.
- 0.12.1 attempted a preview property correction that was reverted in 0.12.2; the working QML property is `paintCursor` (singular).
- Normalized Hyprland addresses before associating a taskbar window with its Wayland toplevel (`0xabc...` vs `abc...`).
- Added static regression checks for both failures.

## 0.12.0 - 2026-09-19

- Add delayed hover previews for live taskbar windows using Quickshell 0.3.1 `ScreencopyView` with the Hyprland toplevel's native Wayland capture source; no screenshot helper, external process, or custom compositor IPC is introduced.
- Capture a single frame only: `live` stays disabled and the capture source is bound only while the preview surface is visible, avoiding a background video stream for every taskbar button.
- Keep the ordinary tooltip for quick pointer passes, then replace it with the richer preview after a 320 ms dwell; use a 160 ms exit grace so the pointer can cross the bar-to-popup gap without the card flickering closed.
- Reuse one Omarchy `PopupCard` in hover mode for the entire taskbar instead of creating a popup/capture surface per delegate, and participate in the bar popout coordinator so context menus or other bar popups close the preview cleanly.
- Show the captured frame plus title and compact workspace/monitor metadata; if capture content is not ready, fall back to the existing AppLibrary icon or unmatched marker rather than inventing another presentation source.
- Disable previews while the taskbar context menu owns interaction, while an exact-window backend action is busy, and for reconstructed minimized records that no longer have a live Hyprland/Wayland toplevel.
- Keep backend `0.7.0`, protocol `4`, AppLibrary-only names/icons, pinned launchers, and Hyprbars unchanged; updating from 0.11.0 requires no Rust rebuild or Hyprbars setup rerun.

## 0.11.0 - 2026-09-19

- Add AppLibrary-backed **Pin to taskbar / Unpin from taskbar** actions for matched applications without introducing a second launcher database or custom icon resolver.
- Persist pins as ordered DesktopEntry ids in `$XDG_CONFIG_HOME/dev.becerromarchy.workspace-taskbar/pins.json` using Quickshell `FileView` atomic writes; missing parent directories are created by FileView and malformed external edits keep the last valid in-memory state while surfacing an error.
- Add a compact pinned-launcher shelf for applications that are not currently running. As soon as a matched live window appears, that app's launcher disappears so one real window still equals one independent taskbar button and no instances are combined.
- Launch pinned apps through the scoped Omarchy AppLibrary `launch(desktopId, name)` capability only. Names/icons are still taken exclusively from AppLibrary.
- Give pinned launchers the same pointer, keyboard, accessibility, bar-click forwarding, motion gate, and Omarchy focus treatment as window buttons.
- Add a keyboard-accessible pinned-launcher menu with Open, Move pin left/right, and Unpin actions; disabled reorder edges are skipped by the existing `PanelKeyCatcher` cursor model.
- Mark matched live windows as taskbar-pinned in their tooltip while keeping Hyprland's separate always-on-top `pinned` state semantically distinct.
- Keep backend `0.7.0`, protocol `4`, and Hyprbars unchanged; updating from 0.10.0 does not require a Rust rebuild or Hyprbars setup rerun.

## 0.10.0 - 2026-09-19

- Add a keyboard-navigable **Move to monitor…** page when more than one Hyprland output is present; single-monitor sessions keep the ordinary menu unchanged.
- Discover outputs through Quickshell 0.3.1's native `Hyprland.monitors` model instead of shelling out or maintaining a second monitor cache.
- Carry each live window's Hyprland monitor id through the taskbar model so the current output is disabled in the picker and multi-monitor tooltips can identify the current monitor.
- Move windows with the reviewed Hyprland 0.56 Lua dispatcher `hl.dsp.window.move({ window = ..., monitor = ..., follow = false })`, always using the exact captured address.
- Keep minimized windows out of monitor movement because their backend restore record owns their original workspace transaction; moving the hidden implementation client would corrupt restore semantics.
- Bump the one-shot backend to `0.7.0` and protocol `4` so older backends cannot silently accept the new QML while lacking the `move-monitor` action.
- Keep AppLibrary-only presentation, keyboard-panel interaction, Hyprbars integration, and the no-daemon architecture unchanged.

## 0.9.0 - 2026-09-18

- Add **Open new window** to matched application menus using only Omarchy's scoped AppLibrary `launch(desktopId, name)` capability; no custom `.desktop` execution or launcher resolver is introduced.
- Integrate Omarchy's native `special:scratchpad` into **Move to workspace…** so a taskbar window can be sent to the scratchpad without leaving the taskbar workflow.
- Present `special:scratchpad` as **Scratchpad** in menu context and tooltips instead of exposing Hyprland's raw special-workspace identifier to the user.
- Keep ordinary special workspaces readable as `Special workspace · <name>` while preserving their exact raw names internally.
- Keep progressive disclosure intact: scratchpad lives with workspace movement rather than adding another permanent top-level window action.
- Keep backend `0.6.0`, protocol `3`, Hyprbars, exact-window semantics, and AppLibrary-only presentation unchanged; no Rust rebuild or Hyprbars setup rerun is required.

## 0.8.1 - 2026-09-18

- Fix context-menu keyboard navigation instead of merely styling focused rows: replace the bar-owned `PopupCard` with Omarchy 4.0.4's official `KeyboardPanel`, whose layer-shell focus prime is specifically designed for keyboard-driven bar panels.
- Route Up/Down/Left/Right, Tab/Shift+Tab, Enter/Space, and Escape through Omarchy's `PanelKeyCatcher` so one stable focus owner drives the menu cursor instead of trying to force focus into an xdg-popup delegate.
- Keep the visible menu treatment unchanged: the selected action still uses the shared Omarchy `Button.hasCursor` state and semantic Close coloring.
- Synchronize pointer hover with the keyboard cursor so mouse and keyboard can be mixed without stale selection.
- Register custom taskbar window buttons with the bar click-target API, matching Omarchy's `WidgetButton` contract, so the full-screen keyboard panel can forward bar clicks while it is open instead of requiring a second click.
- Keep backend `0.6.0`, protocol `3`, and Hyprbars unchanged; no Rust rebuild or Hyprbars setup rerun is required.

## 0.8.0 - 2026-09-18

- Remove the project-local agent-skill installer and `AGENTS.md`; design/review skills are development methodology, not plugin runtime or repository setup.
- Add keyboard operation to each window button: Enter/Space performs the normal left-click action and Menu/Shift+F10 opens the exact-window context menu.
- Add an explicit Omarchy-token focus treatment and expose window buttons through Qt `Accessible` button semantics.
- Make the context popup keyboard navigable: first enabled action receives focus, Up/Down move across enabled rows, Right enters submenus, Left returns/closes, and Escape dismisses.
- Expose popup rows as accessible menu items with press actions matching pointer activation.
- Gate taskbar micro-motion through the host bar's animation-enabled state and keep all new feedback on opacity/scale rather than taskbar layout geometry.
- Add `pragma ComponentBehavior: Bound`, required delegate `index`, qualified delegate role access, and `let`/`const` in the touched QML to reduce delegate/binding ambiguity.
- Fix the advanced-menu pseudo-state label by carrying the live `pseudo` role into the captured exact-window menu target.
- Keep the 0.7 visual language: compact selected surface, state rail, Pop diamond, busy marker, semantic urgent Close row, and progressive-disclosure menus.
- Keep backend `0.6.0`, protocol `3`, and the existing Hyprbars integration unchanged; this release does not require a Rust rebuild or Hyprbars setup rerun.

## 0.7.0 - 2026-09-18

- Apply a project-local UX hierarchy based on the Omarchy plugin contract first, Qt/QML implementation rules second, and art-direction/motion guidance only below those architectural constraints.
- Add `AGENTS.md` and `docs/UX_DIRECTION.md` so future agent work preserves the same precedence, native Omarchy design system, AppLibrary-only presentation, and upstream-only Hyprbars policy.
- Add an opt-in `scripts/install-agent-skills.sh` bootstrap for the project-local Codex skill stack without coupling plugin installation/runtime to Node or external agent tooling.
- Reduce the ordinary right-click menu with progressive disclosure: frequent actions stay on the main page while float/fullscreen/pseudo/group/pin operations move under **More window actions…**.
- Make destructive Close rows use Omarchy's semantic urgent color and make popup rows keyboard-focusable through the existing Omarchy `Button` component.
- Replace state-rail width/height animation with transform-based scaling so state feedback no longer animates taskbar geometry.
- Add snappy hover/press feedback, one-shot urgent attention feedback, a Pop-specific accent diamond, and a compact busy activity marker without adding decorative looping motion.
- Expand tooltips with live floating/pinned/popped/fullscreen/maximized/pseudo/group state while retaining workspace and AppLibrary identity.
- Keep backend `0.6.0` and protocol `3`; this is a QML/UX-only release and does not require a Rust rebuild.

## 0.6.0 - 2026-09-18

- Add an exact-address **Pop out window** action modeled on Omarchy 4.0.4's `omarchy-hyprland-window-pop`: float, resize to 1300×900, center, pin, raise, and tag an ordinary tiled target window.
- Add a reversible **Return popped window** action keyed by Hyprland's static `pop` tag instead of guessing from generic pinned/floating state; pre-existing floating, pinned, maximized, or fullscreen windows are not offered Pop out.
- Keep the Pop transaction address-scoped end to end; it never depends on whichever client is active when the menu action runs.
- Add a one-click **Move here · Workspace N** action when the selected window lives on a different positive workspace, while retaining the full workspace picker.
- Expose the live `pop` tag as a taskbar model role so menu wording tracks compositor state.
- Bump the backend to 0.6.0 and protocol 3 because Pop introduces a new backend action contract.

## 0.5.0

- Add a two-page right-click workflow for moving an exact window to another workspace without bloating the main context menu.
- Mirror Omarchy 4.0.4's workspace picker policy: workspaces 1-5 are always present and live positive workspaces 6-10 are added dynamically.
- Use the existing exact-address `move-workspace` backend action with `follow = false`; no Rust/protocol change is required.
- Mark the current workspace as disabled in the picker and provide an in-popup Back action.
- Include workspace information in per-window taskbar tooltips.

## 0.4.4 - 2026-09-18

- Preserve the approved Hyprbars geometry and titlebar controls from 0.4.3.
- Match Omarchy 4.0.4 theme-color precedence exactly: explicit `background`, `foreground`, `accent`, and `muted` roles win, while `color0`, `color7`, `color4`, and `color8` are fallback values only.
- Let healthy Hyprbars refreshes run without requiring Meson/CMake/GCC after the official plugin is already installed, enabled, and loaded; build dependencies are still checked when Hyprpm must install/rebuild it.
- Extend `doctor.sh` to verify the installed Hyprbars action helper and all three managed titlebar controls instead of only checking that the config file exists.
- Extend smoke coverage so a second setup succeeds after the test build tool disappears, proving the runtime-only refresh path is independent of the compiler toolchain.
- No Rust or taskbar-QML changes; backend `0.3.1` and protocol `2` remain compatible.

## 0.4.3 - 2026-09-18

- Keep the approved 0.4.2 Hyprbars geometry and visual proportions unchanged.
- Make all titlebar actions capture the Hyprbars-focused window address once and use that exact address for minimize, maximize/restore, and close.
- Dim inactive title text through Hyprland 0.56 dynamic `focus` window rules while keeping active title text on the Omarchy foreground color.
- Suppress Hyprbars automatically for true fullscreen windows without affecting Hyprland's separate maximized mode.
- Suppress Hyprbars for clients that explicitly advertise Wayland content type `game`; unadvertised games remain configurable through the user override file.
- Document that Omarchy theme switches already trigger `hyprctl reload`, causing the managed Hyprbars Lua to reread the current theme colors.
- Fix the stale setup summary so it reports all three titlebar buttons.
- Add a smoke test proving titlebar actions target the captured window address.
- No Rust or taskbar-QML changes; backend `0.3.1` and protocol `2` remain compatible.

## 0.4.2 - 2026-09-18

- Add a dedicated Hyprbars maximize/restore button between minimize and close, using the reviewed Hyprland 0.56 Lua dispatcher.
- Keep minimize delegated to the state-safe Workspace Taskbar backend while titlebar close/maximize operate on the exact window focused by Hyprbars before running a button action.
- Load optional user titlebar overrides from `~/.config/dev.becerromarchy.workspace-taskbar/hyprbars-overrides.lua` after the managed defaults, so exclusions and local styling survive plugin updates.
- Add a disabled example override showing the supported dynamic `hyprbars:no_bar` window-rule effect.
- Make repeated `setup-hyprbars.sh` refreshes skip the expensive Hyprpm update when the official repo is already present, Hyprbars is enabled, and it is currently loaded.
- No Rust or taskbar-QML changes; backend `0.3.1` and protocol `2` remain compatible.

## 0.4.1 - 2026-09-18

- Fix a false-negative Hyprbars hook diagnostic in `doctor.sh`: the managed marker begins with `--`, so `grep` must use the explicit option terminator before the pattern.
- Validate both begin and end hook markers and distinguish a missing hook from a malformed marker pair.
- No QML, Hyprbars behavior, protocol, or Rust backend changes; backend `0.3.1` remains compatible.

## 0.4.0 - 2026-09-18

- Implement optional upstream-only Hyprbars integration through official `hyprpm` and `hyprwm/hyprland-plugins`.
- Add a guarded user-owned Lua config with theme-derived titlebar colors, minimize/close buttons, and double-click maximize.
- Add an exact-active-window titlebar action helper; minimize delegates to the existing state-safe Rust backend.
- Add idempotent marker-delimited `~/.config/hypr/hyprland.lua` integration without touching Omarchy-owned files.
- Track whether this project added the official plugin repository or enabled Hyprbars so removal preserves pre-existing dependencies.
- Add rollback on setup failure, config-error verification, loaded-plugin verification, and conservative uninstall behavior.
- Extend `doctor.sh` and smoke tests with Hyprpm/Hyprbars status and setup/remove lifecycle checks.
- Keep backend `0.3.1` and protocol `2`; this release does not require a Rust rebuild.

## 0.3.2

- Polish taskbar window states using Omarchy 4.0.4 shared hover/selected/pressed style tokens.
- Make active, minimized, urgent and pressed states visually distinct without changing window semantics.
- Theme the right-click popup rows through the shared Omarchy `Button` component.
- Add a separator and minimized-state cue for the Show Desktop control.
- Replace the obsolete standalone window menu with a non-visual menu capability entry point; the live context menu remains the bar-owned `PopupCard`.
- Allow UI-only plugin versions to advance without rebuilding an unchanged protocol-compatible Rust backend.

## 0.3.1 - 2026-09-18

- Fix first-restore tiled windows overlapping at 1:1 geometry after individual minimize/restore and Show Desktop.
- Restore in two phases: settle every workspace move first, then restore per-window state.
- Force a real floating-to-tiled reattachment for originally tiled clients so Hyprland 0.56.x rebuilds the destination layout target immediately.
- Keep the protocol at 2; this is a backend behavior fix with no QML command-contract change.

## 0.3.0 - 2026-09-18

- Fix the bar-widget service facade lookup to use the scoped `bar.shell` API injected by Omarchy.
- Fix QML delegate role shadowing that made matched windows render as `!`.
- Replace the taskbar's right-click summon path with an in-bar `PopupCard`, avoiding the Omarchy 4.0.4 menu-loader/AppLibrary facade failure observed during live testing.
- Keep the manifest's legitimate `menu` kind and writable menu `service` injection contract for capability compatibility and external menu lifecycle.
- Anchor the context popup to a stable captured bar geometry so model refreshes and hover changes cannot move it.
- Cache AppLibrary-resolved names/icons during a healthy probe so transient facade changes cannot erase already resolved icons.
- Update the window model incrementally by Hyprland address instead of clearing/recreating every delegate on each event.
- Preserve first-seen per-window button order across focus/minimize/restore updates; multiple instances remain separate buttons.
- Add original `workspaceName`/special-workspace metadata and prevent plugin-hidden windows from exposing the private minimize workspace as user state.
- Add live floating, pinned, pseudo, fullscreen, client-fullscreen, and group-count state to menu payloads.
- Add a taskbar Show Desktop control plus a recovery menu for restore-last, restore-all, and recover.
- Make Float + pin reversible as Unpin + tile.
- Align group toggle with Omarchy 4.0.4's active-window dispatcher by focusing the exact address before toggling the group.
- Restore Show Desktop batches in reverse minimize order while still leaving tiled placement to Hyprland.
- Bump the backend protocol to 2 so stale 0.2.x backends cannot silently run the new action semantics.
- Remove the unsupported `--yes` flag from the Omarchy 4.0.4 install path.

## 0.2.0 - 2026-09-18

- Merge backend restore records into the QML model so minimized windows keep independent taskbar buttons.
- Add the mandatory scoped AppLibrary runtime probe and explicit degraded state.
- Re-query AppLibrary once for each newly observed unmatched window and expose manual refresh IPC for diagnostics.
- Improve DesktopEntry matching for startup class, desktop id, executable identity, Steam app id, Omarchy web-app identity, and XDG user overrides.
- Ensure matched application names and icons are presented only through Omarchy AppLibrary.
- Replace aggressive backend polling with Hyprland-event reconciliation plus a 10-second safety pass.
- Avoid rewriting restore state when reconciliation made no changes.
- Fsync both the restore-state file and its parent directory after atomic replacement.
- Add a one-shot XDG runtime lock to prevent concurrent state mutations without introducing a daemon.
- Preserve identity, floating geometry, pinned, pseudo, fullscreen/client-fullscreen, group, sequence, and Show Desktop batch metadata.
- Restore focus to the exact clicked member after an atomic group restore.
- Keep state-changing context-menu actions unavailable while a window is plugin-minimized.
- Add exact-address context-menu actions using the reviewed Hyprland Lua dispatcher family.
- Add Omarchy 4.0.4 compatibility fingerprints and stronger doctor checks.
- Add JavaScript matcher tests, Rust unit-test coverage, expanded static smoke checks, and CI.
