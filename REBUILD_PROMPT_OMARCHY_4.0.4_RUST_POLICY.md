# Workspace Taskbar — clean rewrite specification for Omarchy 4.0.4

Research date: 2026-09-18.
Current stable Omarchy release used as the reference baseline: **4.0.4**.

This is a clean rewrite. The old km.workspace-taskbar code is a feature reference only. Do not reuse its architecture blindly.

The project exists because a previous implementation became fragile across Omarchy/Hyprland updates. The new implementation must treat Omarchy's public plugin contract as the boundary, use upstream components without forks, keep application metadata in Omarchy's own AppLibrary, and move only the window-state operations that truly benefit from native code into a small Rust backend.

---

## 0. Non-negotiable principles

1. **No forks.**
   - Do not fork Omarchy.
   - Do not fork Hyprland.
   - Do not fork `hyprland-plugins` / Hyprbars.
   - Do not patch packaged QML or Lua under `/usr/share/omarchy`.
   - Do not vendor/copy Omarchy's `AppLibrary.qml` or `AppSearch.js` as a compatibility fork.
   - Do not use Git submodules that pin private copies of Omarchy, Hyprland or Hyprbars.

2. **Use only supported upstream installation/update mechanisms.**
   - Omarchy plugin source lives under `~/.config/omarchy/plugins/<plugin-id>/`.
   - Git-managed source updates delegate to `omarchy plugin update <plugin-id>`.
   - Hyprbars, if enabled, is installed/updated only through official `hyprpm` + official `hyprland-plugins`.
   - Never build an arbitrary Hyprbars `main` checkout manually against the current Hyprland ABI.

3. **Never modify Omarchy-owned files.**
   - No writes to `/usr/share/omarchy`.
   - No editing first-party manifests or QML.
   - No replacing Omarchy's bar.
   - No second Quickshell instance.

4. **The built-in `omarchy.bar` remains the active bar.**
   This project supplies a normal third-party `bar-widget`, `service`, and `menu` plugin.

5. **Rust is a helper, not a second desktop service.**
   The backend is one-shot and stateless between commands except for a small plugin-owned restore-state file. No resident daemon, no socket server, no systemd service, no root component.

6. **The plugin must fail safely on incompatibility.**
   If a required public capability changed, disable the affected feature and report it through `doctor.sh`; never silently reach into private host objects or patch upstream source.

---

## 1. Exact upstream contract to follow

Before implementation and before declaring support for a new Omarchy release, inspect the exact installed version/tag of:

- `agents/skills/shell-dev.md`
- `docs/omarchy-shell.md`
- `manual/32-shell-plugins.md`
- `shell/shell.qml`
- `shell/services/PluginShellApi.qml`
- `shell/services/PluginAppLibraryApi.qml`
- `shell/services/PluginRegistry.qml`
- `shell/services/AppLibrary.qml` (read-only reference only)
- current first-party launcher/menu
- current first-party Workspaces widget
- current `default/hypr/bindings/tiling.lua`
- current Hyprland IPC documentation
- current official `hyprland-plugins/hyprbars/README.md`

Do not assume an older Omarchy/Hyprland command still exists.

Current Omarchy policy essentials:

- third-party plugins live in `~/.config/omarchy/plugins/<id>/`;
- `manifest.json` uses `schemaVersion: 1`;
- one manifest may declare multiple kinds;
- the host is one long-running `omarchy-shell` Quickshell process;
- third-party plugins receive capability-scoped `shell` facades;
- `shell.serviceFor(id)` is the supported own-service lookup;
- `shell.summon(id, payloadJson)` is the supported menu/panel lifecycle route;
- menu-kind plugins are eligible for the scoped `shell.appLibrary` facade;
- official plugin updates are Git fast-forward updates with validation.

---

## 2. Recommended architecture

Use **one GitHub repository / one Omarchy plugin id** with three Omarchy kinds:

```json
{
  "schemaVersion": 1,
  "id": "io.github.OWNER.workspace-taskbar",
  "name": "Workspace Taskbar",
  "version": "X.Y.Z",
  "kinds": ["service", "bar-widget", "menu"],
  "entryPoints": {
    "service": "TaskbarService.qml",
    "barWidget": "Taskbar.qml",
    "menu": "WindowMenu.qml"
  },
  "barWidget": {
    "displayName": "Workspace Taskbar",
    "category": "Desktop",
    "defaultSection": "left",
    "allowMultiple": false
  }
}
```

The exact manifest spelling must be validated against the installed Omarchy schema before release.

### Responsibility split

`TaskbarService.qml` owns:

- AppLibrary access through the public scoped facade;
- application-entry index and window→application matching;
- current taskbar window model;
- minimized-window model merged with live Hyprland clients;
- orchestration of one-shot Rust backend commands;
- backend protocol/version check;
- lightweight health state exposed to Taskbar.qml.

`Taskbar.qml` owns only UI:

- one button per real Hyprland window;
- icons supplied by `TaskbarService` from Omarchy AppLibrary;
- tooltip using live window title;
- left-click semantics;
- right-click context-menu summon;
- theme/geometry through the normal bar facade.

`WindowMenu.qml` owns:

- normal Omarchy `menu` lifecycle (`open(payloadJson)`, `close()`);
- actions against the exact target address from the payload;
- no private access to host services.

Rust backend owns only low-level/stateful window operations that are awkward or unsafe to express entirely in QML:

- exact Hyprland client/active-window snapshot when needed;
- atomic minimize transaction;
- atomic restore transaction;
- restore-last / restore-all;
- Show Desktop batch state;
- fullscreen/maximized/floating/pinned/pseudo preservation;
- group-safe minimize/restore bookkeeping;
- atomic state persistence and reconciliation;
- compatibility/health JSON for the QML service.

Rust MUST NOT own:

- application discovery;
- `.desktop` scanning;
- Steam metadata scanning;
- web-app favicon resolution;
- icon-theme lookup;
- application display names;
- context-menu UI;
- bar placement.

---

## 3. Why `service + bar-widget + menu`

This structure deliberately uses Omarchy's public capability model instead of walking QML parent objects.

The plugin genuinely implements a context menu, so declaring `menu` is legitimate. Because the manifest has `menu`, its scoped plugin shell is eligible for `shell.appLibrary` under the current public API.

`TaskbarService.qml` should obtain application data from:

```qml
shell.appLibrary
```

and Taskbar.qml should obtain the plugin's own service via the supported own-service facade:

```qml
shell.serviceFor("io.github.OWNER.workspace-taskbar")
```

Use the exact API spelling from the installed Omarchy version.

Do not use constructs such as:

```qml
bar.shell.appLibrary
parent.parent.shell
someHostObject.appLibrary
```

Even if same-process QML makes such traversal technically possible, it violates the intended capability boundary and is likely to break.

---

## 4. App names and icons: Omarchy is the ONLY source of truth

This requirement is absolute.

The taskbar must display the same application identity/icon Omarchy's launcher resolves.

Use only the scoped `PluginAppLibraryApi` operations provided by the installed Omarchy version, currently including equivalents of:

- `sortedEntries(query)`
- `entryName(entry)`
- `entrySubtext(entry)`
- `iconSource(icon)`
- `refreshIcons()`

The final image source for a matched application must come from AppLibrary's `iconSource()`.

### Never do these again

- no Rust icon resolver;
- no manual `/usr/share/icons` scan;
- no custom Steam artwork path;
- no custom favicon downloader;
- no `Quickshell.iconPath()` as an independent competing source when AppLibrary already resolved an entry;
- no generic `X` icon except whatever fallback AppLibrary itself returns.

### Window→DesktopEntry matching

The plugin still has to determine WHICH AppLibrary entry belongs to a Hyprland window. That matcher may use stable public properties, with descending confidence:

1. `StartupWMClass` / startup class vs Hyprland `class` / `initialClass`;
2. DesktopEntry id/stem vs normalized app-id/class;
3. executable identity where unambiguous;
4. Omarchy web-app DesktopEntry command/URL host vs the browser app window class/title;
5. Steam app-id/process/class only to select the existing launcher/DesktopEntry;
6. user override table for exceptional applications.

Once a match is found, discard any locally invented icon/name and use AppLibrary for presentation.

Tooltip priority:

1. live Hyprland window `title`;
2. live `initialTitle` when useful;
3. `shell.appLibrary.entryName(entry)`.

Therefore a WhatsApp web app should show the page/window title on hover, while its icon remains exactly the launcher icon.

---

## 5. Current AppLibrary compatibility problem and safe handling

Omarchy 4.0.3 introduced capability scoping and there are current upstream reports where model-delivered third-party/cloned menu manifests can receive `shell.appLibrary = null` because the `menu`-kind test sees a QVariantList rather than a native JS array.

Do NOT work around this by forking/copying AppLibrary or traversing to the private real shell.

Instead, use this architecture to minimize exposure to the broken path:

- `TaskbarService.qml` is loaded as the plugin's own **service**, not through the menu Instantiator path;
- the service receives the scoped shell created from the registry manifest;
- because the same manifest also declares `menu`, the current host code should grant the service the AppLibrary facade;
- perform a runtime probe anyway.

### Mandatory runtime AppLibrary probe

On service initialization:

1. verify `shell != null`;
2. verify `shell.appLibrary != null`;
3. call `sortedEntries("")`;
4. verify at least one known installed DesktopEntry can resolve through `entryName()` and `iconSource()`;
5. expose `appLibraryHealthy` and a diagnostic string.

If this probe fails:

- keep window operations safe;
- show a clear degraded/error state in the taskbar rather than fake icons;
- `doctor.sh` must report `UPSTREAM_APP_LIBRARY_CAPABILITY_BROKEN`;
- do not switch to a custom icon resolver;
- support that Omarchy build only after upstream fixes or a new public API exists.

This is preferable to silently diverging from the launcher again.

### `appsChanged` caveat

The current scoped API declares `appsChanged`, but upstream reports indicate signal forwarding has been incomplete in some 4.0.x builds. Do not depend exclusively on that signal.

Re-query AppLibrary when:

- the service starts;
- an unmatched new window appears;
- a manual Refresh/doctor action is invoked;
- `appsChanged` fires when it is functional.

Do not rescan icon directories yourself.

---

## 6. Rust backend: one-shot CLI, no daemon

The backend is intentionally small and local.

Suggested binary name:

```text
workspace-taskbar-backend
```

It MUST be a one-shot CLI. No background daemon and no custom Unix socket server.

Suggested subcommands:

```text
workspace-taskbar-backend version-json
workspace-taskbar-backend capabilities
workspace-taskbar-backend snapshot
workspace-taskbar-backend minimize <address>
workspace-taskbar-backend restore <address>
workspace-taskbar-backend restore-last
workspace-taskbar-backend restore-all
workspace-taskbar-backend show-desktop-toggle [workspace]
workspace-taskbar-backend reconcile
workspace-taskbar-backend recover
workspace-taskbar-backend doctor-json
```

Every machine-readable command prints one JSON object to stdout and uses exit status properly.

Example version response:

```json
{
  "backendVersion": "1.0.0",
  "protocolVersion": 1,
  "stateSchemaVersion": 1,
  "hyprlandIpc": true
}
```

QML has a compile-time expected protocol integer. If protocol differs, destructive actions are disabled and the UI says the backend needs rebuilding/updating.

### Performance

The backend must not scan applications or icons. Typical click command target: <100 ms.

Use current documented Hyprland IPC and/or invoke `hyprctl` as an argument vector where that is the stable compatibility boundary. Never build shell strings from untrusted titles/classes.

---

## 7. Rust source placement vs runtime placement

The **Rust source code belongs inside the plugin Git repository**, e.g.:

```text
~/.config/omarchy/plugins/io.github.OWNER.workspace-taskbar/
  backend/
    Cargo.toml
    Cargo.lock
    src/
```

However, **Cargo build output, mutable runtime state, caches and sockets must NOT live inside the watched plugin tree**.

Reason: Omarchy watches third-party plugin directories recursively and reloads plugins when files change. Runtime/build churn inside that tree can create reload storms/races. This is an upstream-observed failure mode.

Use XDG paths:

```text
$XDG_CACHE_HOME/io.github.OWNER.workspace-taskbar/cargo-target/
$XDG_DATA_HOME/io.github.OWNER.workspace-taskbar/bin/workspace-taskbar-backend
$XDG_STATE_HOME/io.github.OWNER.workspace-taskbar/restore-v1.json
$XDG_RUNTIME_DIR/io.github.OWNER.workspace-taskbar/           # only ephemeral locks if needed
```

Default expansions:

```text
~/.cache/io.github.OWNER.workspace-taskbar/
~/.local/share/io.github.OWNER.workspace-taskbar/
~/.local/state/io.github.OWNER.workspace-taskbar/
/run/user/$UID/io.github.OWNER.workspace-taskbar/
```

This is still a self-contained user plugin: all source is under Omarchy Plugins, while mutable/generated files follow the XDG locations intended for them.

No files under `/usr/local`, `/usr`, `/opt`, `/etc`, or root-owned directories.

No symlink inside the plugin tree (Omarchy validation rejects symlinks).

---

## 8. Backend build script

Repository includes:

```text
scripts/build-backend.sh
```

Requirements:

- no sudo;
- no package installation automatically;
- check for `cargo`/`rustc` and fail with a precise instruction when missing;
- use `Cargo.lock` and `cargo build --locked --release`;
- set `CARGO_TARGET_DIR` to the plugin's XDG cache directory;
- build to a temporary location;
- run `backend version-json` smoke test;
- verify expected protocol;
- atomically install the final binary to `$XDG_DATA_HOME/.../bin/`;
- never write Cargo target churn into `~/.config/omarchy/plugins/`.

Optional release CI may publish reproducible checksums, but the default manual install builds from the reviewed source. Do not auto-download and execute arbitrary latest binaries.

---

## 9. Clean manual installation flow

Manual installation is supported and is the recommended path while the plugin contains a compiled backend.

### Option A — use Omarchy Git management for the source

```bash
omarchy plugin add https://github.com/OWNER/workspace-taskbar.git
cd ~/.config/omarchy/plugins/io.github.OWNER.workspace-taskbar
./scripts/build-backend.sh
./scripts/doctor.sh --pre-enable
omarchy plugin validate .
omarchy plugin enable io.github.OWNER.workspace-taskbar
omarchy bar move io.github.OWNER.workspace-taskbar --section left
./scripts/doctor.sh
```

Do **not** use `--enable` on the initial `plugin add` until the backend has been built successfully.

### Option B — fully manual checkout, still respecting Omarchy's documented manual path

```bash
git clone https://github.com/OWNER/workspace-taskbar.git \
  ~/.config/omarchy/plugins/io.github.OWNER.workspace-taskbar
cd ~/.config/omarchy/plugins/io.github.OWNER.workspace-taskbar
./scripts/install.sh
```

`install.sh` may only:

- validate environment;
- build the Rust backend into XDG data/cache paths;
- run `omarchy plugin validate`;
- run `omarchy-shell shell rescanPlugins` if appropriate for the installed version;
- enable/place the plugin with official Omarchy CLI/IPC;
- optionally offer a separate Hyprbars setup step.

It must not use sudo or patch Omarchy.

---

## 10. Update strategy

Official source update remains:

```bash
omarchy plugin update io.github.OWNER.workspace-taskbar
```

Because Omarchy deliberately does not run post-update hooks, a Rust-backed plugin needs an explicit backend rebuild afterward.

Provide:

```text
scripts/update.sh
```

that delegates source update to Omarchy rather than implementing its own Git updater:

```text
1. record current plugin/backend/protocol versions
2. omarchy plugin update <id> --yes (or interactive unless --yes was passed through)
3. omarchy plugin validate <plugin-dir>
4. scripts/build-backend.sh
5. backend version/protocol handshake
6. doctor.sh
```

The plugin UI MUST tolerate the transient state where QML source is newer than the backend:

- compare protocol versions before every state-changing backend call (or cache a validated handshake until the binary mtime changes);
- if mismatched, do not minimize/move windows;
- show `Backend update required` and the exact rebuild command.

Never continue with an incompatible backend protocol.

### No upstream submodules

Do not track Omarchy/Hyprland/Hyprbars as Git submodules.

Instead maintain a small machine-readable compatibility file such as:

```text
compat/upstream.json
```

containing tested version ranges, public capability expectations and source hashes/URLs for monitoring only. CI checks upstream changes and opens/flags a compatibility review; it does not vendor their code.

---

## 11. Plugin service lifecycle and backend invocation

Use `TaskbarService.qml` as the single orchestrator.

It should expose properties/models such as:

```text
windows
activeAddress
backendHealthy
backendVersion
protocolCompatible
appLibraryHealthy
lastError
```

Taskbar.qml uses only that service and its own bar facade.

Backend invocation uses Quickshell `Process` / the current official process API with an **argument array**, never a shell-concatenated command containing window titles or IDs.

For each target address:

- keep a short per-window `busy` state to reject duplicate clicks while an action is in flight;
- no sleeps to wait for animation;
- process exit + Hyprland events trigger reconciliation.

Do not run backend actions through a resident service socket.

---

## 12. Window model: one actual window = one button

This is non-negotiable default behavior.

```text
Foot A -> Foot icon A
Foot B -> Foot icon B
Foot C -> Foot icon C
```

No default `Foot (3)` grouping.

Stable identity key: Hyprland window address for the lifetime of the client.

Live clients and plugin-minimized restore records are merged into one model so a minimized window keeps its taskbar button.

Optional future grouping may be added as an explicit setting, but it must not be the default and must not change minimize semantics unless separately designed/tested.

---

## 13. Click semantics

Left click on one taskbar button:

- target visible + currently active => backend `minimize <address>`;
- target visible + inactive => focus exact address;
- target minimized by this plugin => backend `restore <address>` then focus.

Right click:

```qml
shell.summon("io.github.OWNER.workspace-taskbar", JSON.stringify(payload))
```

(or exact supported call for the installed shell) to open `WindowMenu.qml` for that exact address.

Payload contains only required scalar state:

```json
{
  "address": "0x...",
  "title": "...",
  "desktopId": "...",
  "appName": "...",
  "workspace": 1
}
```

Do not use a Hyprbars `...` button for the context menu.

---

## 14. Minimize/restore semantics

Minimize is emulated through plugin-private special workspaces because Hyprland does not provide a traditional minimize primitive.

Persist BEFORE moving the window.

State may include:

- address / identity metadata needed for recovery;
- original workspace id/name;
- tiled vs floating;
- floating position and size;
- pinned;
- pseudo if supported;
- internal fullscreen state;
- client fullscreen/maximized state;
- group membership sufficient to avoid stranding siblings;
- minimize sequence;
- Show Desktop batch id;
- original active address for batch focus restoration.

### Explicitly excluded forever unless public Hyprland support changes

DO NOT restore exact tiled left/right position.

DO NOT store or reconstruct:

- tiled rank;
- previous/next neighbor;
- Dwindle split tree;
- exact tiled node;
- repeated swap loops.

For tiled restore, return to the original workspace and let Hyprland insert the window naturally.

Floating geometry may be restored because it is deterministic and public.

### Groups

Do not destructively break/rebuild Hyprland groups just to fake individual minimize.

If current Hyprland moves a group as a unit, detect it before the transaction and treat the group as an atomic minimize/restore set. Keep individual taskbar buttons, but clearly define that restoring any hidden member restores the group when the compositor's group semantics require it.

Acceptance tests must prove siblings cannot become stranded in a special workspace.

---

## 15. Show Desktop

Show Desktop is a real reversible batch:

First activation:

- snapshot eligible windows on current workspace;
- assign one batch id;
- remember active address;
- atomically persist all restore records;
- hide the batch.

Second activation:

- restore only that batch;
- restore previous focus when still valid;
- remove batch metadata.

Also expose restore-last, restore-all, and recover.

Backend reconciles state if a window was externally moved/closed while marked minimized.

---

## 16. Context-menu actions

Menu behavior must be aligned with the exact installed Omarchy/Hyprland Lua APIs.

Do not hard-code legacy commands like:

```text
hyprctl dispatch fullscreen 2
```

During compatibility review inspect current `default/hypr/bindings/tiling.lua` and current Hyprland dispatcher/API documentation.

Menu actions may include:

- close;
- fullscreen;
- maximized/full-width;
- float/tile toggle;
- pseudo;
- pop;
- group operations;
- move to workspace;
- minimize / restore.

Always target/focus the intended address before an action whose upstream semantic is active-window-based.

Keep the compatibility adapter small and version-gated. If upstream semantics changed, disable the affected menu action until reviewed instead of guessing.

---

## 17. Hyprbars: upstream only, optional, no fork

Hyprbars is optional polish. The taskbar remains fully functional without it.

Rules:

- official `https://github.com/hyprwm/hyprland-plugins` only;
- managed only by `hyprpm`;
- no fork;
- no copied C++ plugin;
- no manual build against an arbitrary branch;
- verify it is actually loaded with `hyprctl plugin list` before applying `plugin.hyprbars.*` configuration;
- config must be guarded so missing Hyprbars never creates boot-time `configerrors`.

Supported titlebar buttons should be limited to what official Hyprbars exposes reliably, e.g. close and minimize.

### Right-click titlebar

Current official Hyprbars documents `on_double_click` for the bar and one `action` per button, but no right-click callback for the empty titlebar.

Therefore, with the strict no-fork rule:

- **do not implement right-click-on-empty-Hyprbars-titlebar**;
- do not patch its C++ event handler;
- do not recreate the old `...` button workaround;
- right-click on the Omarchy taskbar icon opens our context menu.

If official Hyprbars later adds a documented right-click callback, add it only after `doctor.sh`/compatibility checks detect the supported API.

---

## 18. Hyprbars configuration ownership

Never broadly regex-rewrite `~/.config/hypr/looknfeel.lua`.

Prefer one plugin-owned user config file, for example:

```text
~/.config/hypr/workspace-taskbar-hyprbars.lua
```

and one marker-delimited idempotent import/hook in a user-owned Omarchy Lua entrypoint if the current configuration model requires it.

The optional setup script must:

1. detect current Omarchy/Hyprland/hyprpm;
2. use official hyprpm repository/plugin operations;
3. verify Hyprbars is loaded;
4. add only this project's buttons/config;
5. `hyprctl reload`;
6. require clean `hyprctl configerrors`;
7. rollback only its own changes on failure.

Record whether this project enabled/added Hyprbars so uninstall does not remove a pre-existing user dependency.

---

## 19. Repository layout

Recommended:

```text
workspace-taskbar/
├── manifest.json
├── Taskbar.qml
├── TaskbarService.qml
├── WindowMenu.qml
├── qml/
│   ├── WindowButton.qml
│   ├── AppMatcher.js
│   └── Util.js
├── backend/
│   ├── Cargo.toml
│   ├── Cargo.lock
│   └── src/
│       ├── main.rs
│       ├── hypr.rs
│       ├── state.rs
│       ├── actions.rs
│       └── protocol.rs
├── scripts/
│   ├── install.sh
│   ├── build-backend.sh
│   ├── update.sh
│   ├── uninstall.sh
│   ├── doctor.sh
│   └── setup-hyprbars.sh
├── compat/
│   └── upstream.json
├── tests/
│   ├── smoke/
│   └── fixtures/
├── .github/workflows/
├── .gitignore
├── README.md
├── CHANGELOG.md
├── LICENSE
└── SECURITY.md
```

`.gitignore` should ignore developer-local Cargo/editor artifacts but runtime target output is already redirected outside the repo.

---

## 20. Clean install script requirements

`scripts/install.sh` must be idempotent and user-only.

It may:

- identify the plugin directory;
- read exact Omarchy version;
- run compatibility probes;
- run `scripts/build-backend.sh`;
- run `omarchy plugin validate`;
- rescan plugins using the current documented flow for manual installs;
- enable the plugin;
- place it using `omarchy bar put/move` rather than editing `shell.json` directly;
- run doctor;
- optionally ask whether to configure Hyprbars through the separate official-hyprpm script.

It must not:

- use sudo;
- install Arch packages automatically;
- modify `/usr/share/omarchy`;
- overwrite user Hyprland files;
- launch another Quickshell;
- add forks/remotes/submodules;
- download executable code from an unpinned URL;
- mutate unrelated shell settings.

---

## 21. Uninstall

`scripts/uninstall.sh` must be symmetrical.

Before removal:

1. invoke backend `recover` / restore-all;
2. verify no project-hidden windows remain;
3. disable/remove taskbar placement through official Omarchy commands;
4. remove only this project's Hyprbars buttons/config/hook;
5. only disable/remove Hyprbars itself if ownership state proves this project installed it and no other configuration needs it;
6. remove XDG state/cache/data runtime files owned by this project;
7. remove plugin through `omarchy plugin remove` when Git-managed, or move the manual directory to a timestamped backup if following Omarchy's manual policy;
8. verify `hyprctl configerrors` and Omarchy shell health.

No broad deletion of `~/.config/hypr` or `~/.config/omarchy`.

---

## 22. Doctor / compatibility report

`doctor.sh` is first-class functionality.

Report at minimum:

- Omarchy version/package and current release compatibility;
- Hyprland version/build;
- Quickshell version;
- kernel package and `uname -r` (diagnostic only; do not couple logic to linux-omarchy);
- `omarchy-shell shell ping`;
- `omarchy plugin validate`;
- plugin enabled/placement state;
- `TaskbarService` AppLibrary probe status;
- backend path, version, protocol and state schema;
- backend executable/hash;
- `hyprctl configerrors`;
- `hyprctl plugin list`;
- hyprpm/Hyprbars status;
- restore-state sanity;
- hidden special workspaces created by the plugin;
- any version mismatch that requires rebuild.

`doctor.sh` must be safe after every `omarchy update`.

---

## 23. GitHub/update policy

The repository is directly installable from its canonical GitHub URL. Users should not need a fork.

Source update uses Omarchy's manager and should remain fast-forward clean. Generated backend files/state must never dirty the checkout.

CI should:

- `cargo fmt --check`;
- `cargo clippy -- -D warnings`;
- `cargo test --locked`;
- build release backend;
- validate JSON/manifest syntax;
- run shellcheck on scripts;
- optionally run `omarchy plugin validate` in an Omarchy-compatible CI/container when practical;
- monitor upstream public contract files;
- flag changes requiring compatibility review.

Track upstream by release/tag/commit metadata in `compat/upstream.json`, not by submodule or copied source.

---

## 24. Required acceptance tests

### Core plugin

- plugin validates on current supported Omarchy;
- single `omarchy-shell` process only;
- no QML load errors;
- built-in `omarchy.bar` remains active;
- one Foot = one button;
- three Foot = three independent buttons;
- click active window minimizes immediately;
- click inactive window focuses exact instance;
- click minimized instance restores it;
- no `(2)` grouping by default;
- no daemon startup latency.

### Application identity

- regular app icon equals current Omarchy launcher icon;
- Steam game icon equals current Omarchy launcher icon;
- Omarchy webapp icon equals current Omarchy launcher icon;
- tooltip is live human window/page title;
- unmatched app degrades explicitly rather than inventing a competing icon resolver;
- AppLibrary probe failure is reported safely.

### State

- fullscreen survives minimize/restore;
- maximized/client fullscreen survives;
- floating + geometry survives;
- pinned survives safely;
- pseudo survives where supported;
- group operation cannot strand siblings;
- restore-last works;
- restore-all works;
- Show Desktop is reversible and restores focus;
- shell restart with minimized state can recover;
- reboot recovery works;
- external/manual window move reconciles stale restore state;
- no exact tiled left/right restoration or swap loop exists.

### Context menu

- right-click exact taskbar button opens menu for exact address;
- menu actions use current reviewed Omarchy/Hyprland semantics;
- no Hyprbars `...` button;
- no fork-dependent titlebar right-click.

### Hyprbars optional integration

- install through official hyprpm only;
- works when loaded;
- reboot produces no config error banner;
- if Hyprbars fails to load, core taskbar still works and Hyprland config remains clean;
- uninstall removes only project-owned integration.

### Updates

- `omarchy plugin update` leaves Git checkout clean;
- stale backend protocol is detected before any state-changing action;
- rebuild restores compatibility;
- future Omarchy version outside tested range yields an explicit doctor warning rather than silent breakage.

---

## 25. Performance targets

Typical local targets:

- focus/minimize/restore dispatch: <100 ms;
- event→taskbar state refresh: <100 ms;
- no metadata filesystem scan on click;
- no daemon readiness wait;
- no network access during runtime icon lookup;
- no repeated layout swaps.

---

## 26. Final design rule

**Omarchy AppLibrary knows applications and icons.**

**Quickshell/Omarchy service knows UI and app matching.**

**Rust knows safe window-state transactions.**

**Hyprland knows layout.**

**Hyprbars only decorates titlebars.**

Do not let any layer duplicate the responsibility of another.
