# Workspace Taskbar

An Omarchy plugin with one button per window, launcher-matched app icons, minimize/restore, Show Desktop, pinned launchers, window previews and a keyboard-accessible context menu. It uses the built-in Omarchy bar and a small one-shot Rust helper.

**0.14.0-rc.1** is a release candidate. See [verification](docs/verification/RESULTS.md) for executed checks and remaining graphical acceptance gates. Repository: [48hoursnonstop/workspace-taskbar](https://github.com/48hoursnonstop/workspace-taskbar).

## Requirements

- Omarchy **4.0.4**, its built-in `omarchy.bar`, Hyprland **0.56.x** (tested on 0.56.2), Quickshell **0.3.1**.
- Rust **1.89+** with Cargo, `jq`, Bash and Git for installation/building.
- A running user desktop with working `omarchy-shell` and `hyprctl` IPC.
- Hyprbars is optional. The plugin works without it.

The backend refuses window mutations outside the reviewed Hyprland dispatcher family. Doctor warns about Omarchy version drift. Updates need a compatibility review; version numbers alone do not guarantee compatibility.

## Install

Review the source first. Omarchy adds plugins disabled; build the helper before enabling this one.

```bash
omarchy plugin add https://github.com/48hoursnonstop/workspace-taskbar.git
cd ~/.config/omarchy/plugins/dev.becerromarchy.workspace-taskbar
./scripts/install.sh
```

The installer validates the manifest, builds from committed `Cargo.lock`, checks the environment, enables the widget and runs doctor. It does not install system packages or require root. Missing dependencies are reported explicitly.

For a source archive, extract its `dev.becerromarchy.workspace-taskbar/` directory under `~/.config/omarchy/plugins/`, then run the same installer. Keep an existing checkout backed up before replacing it. Archive installations do not have Git update history; use a Git checkout for Omarchy-managed updates.

Place the widget as desired:

```bash
omarchy bar move dev.becerromarchy.workspace-taskbar --section left --after omarchy.workspaces
```

## Use

- Click the active window to minimize it; click an inactive window to focus it; click a minimized window to restore it.
- Right-click an icon for window actions. Arrow keys navigate; Enter/Space activates; Escape closes.
- Show Desktop hides the current workspace as a reversible batch. Its right-click action uses Omarchy's workspace layout toggle.
- Pin an application from its context menu. Its launcher appears when no matching live window is present; live windows always retain separate buttons.
- Hover a live window for a delayed, single-frame compositor preview.
- Minimized group members restore together where Hyprland treats their group as one unit. Exact tiled left/right positions are intentionally not reconstructed.

Names and app icons come only from Omarchy AppLibrary. An unmatched app or a failed AppLibrary capability probe degrades explicitly; there is no competing icon resolver.

## Update

```bash
cd ~/.config/omarchy/plugins/dev.becerromarchy.workspace-taskbar
./scripts/update.sh
```

For noninteractive source-update confirmation, pass `--yes`. The wrapper records current versions, delegates Git updates to `omarchy plugin update`, validates source, rebuilds the backend, rescans and runs doctor. Calling Omarchy's updater directly requires running `./scripts/build-backend.sh` afterward.

Every QML/Hyprbars backend call carries the expected protocol. The invoked executable checks that protocol before state changes, even if the binary was replaced after a health probe. Protocol **5**, backend **0.8.0**, state schema **1**. Legacy schema-1 records remain readable. Finish recovery before downgrading to an older backend, which cannot understand pending transactions.

## Diagnose and recover

```bash
./scripts/doctor.sh
./scripts/doctor.sh --pre-enable
omarchy-shell workspace-taskbar status
omarchy-shell workspace-taskbar refreshApps
omarchy-shell workspace-taskbar restoreLast
omarchy-shell workspace-taskbar restoreAll
omarchy-shell workspace-taskbar recover
```

The shell recovery commands enqueue work; inspect `status` afterward for completion/errors. For synchronous recovery when the shell is unavailable:

```bash
~/.local/share/dev.becerromarchy.workspace-taskbar/bin/workspace-taskbar-backend --protocol 5 recover
```

Transactions persist their original state before dispatch. Interrupted operations keep a pending record so recovery can finish. Closed/reused clients and manually moved completed records are reconciled. Orphaned windows on the private hidden workspace are rescued onto the active normal workspace; without their original record, their original workspace/geometry cannot be reconstructed. Corrupt or incompatible state is retained and reported; it is never silently discarded. Back up that file before repairing it.

An `UPSTREAM_APP_LIBRARY_CAPABILITY_BROKEN` diagnostic requires reviewing the upstream capability contract. `WindowMenu.qml` uses the host's own-service injection and does not request a second shell facade; this avoids the Omarchy 4.0.4 model-delivered menu capability bug while keeping application metadata exclusively in the service.

## Optional Hyprbars

```bash
./scripts/setup-hyprbars.sh
./scripts/setup-hyprbars.sh --status
./scripts/setup-hyprbars.sh --remove
```

Only official `hyprwm/hyprland-plugins`, managed by `hyprpm`, is supported. Setup checks prerequisites and ownership, guards configuration when Hyprbars is absent, verifies config errors and rolls back its changes on failure. Buttons provide minimize, maximize and close. There is no empty-titlebar right-click patch or `...` workaround.

## Uninstall

```bash
cd ~/.config/omarchy/plugins/dev.becerromarchy.workspace-taskbar
./scripts/uninstall.sh
```

This disables the UI, recovers windows, verifies none remain hidden, removes owned Hyprbars integration and runtime files, then delegates Git checkout removal to Omarchy. Pass `--yes` for Omarchy's removal confirmation. A manual source directory is moved to a timestamped backup under `~/.local/share/omarchy-plugin-backups/`.

Missing backend, failed disable, unresolved records or failed compositor queries stop cleanup with state retained. Fix the error and rerun. Pins and match overrides are preserved as user preferences. Do not run `omarchy plugin remove` alone while the plugin has minimized windows: Omarchy does not run uninstall hooks.

## Files

| Purpose | Location (XDG defaults) |
|---|---|
| Source | `~/.config/omarchy/plugins/dev.becerromarchy.workspace-taskbar/` |
| Helper | `~/.local/share/dev.becerromarchy.workspace-taskbar/bin/` |
| Restore journal | `~/.local/state/dev.becerromarchy.workspace-taskbar/restore-v1.json` |
| Cargo output | `~/.cache/dev.becerromarchy.workspace-taskbar/cargo-target/` |
| Session lock | `$XDG_RUNTIME_DIR/dev.becerromarchy.workspace-taskbar/transaction.lock` |
| Pins / overrides | `~/.config/dev.becerromarchy.workspace-taskbar/` |

Runtime, cache and preferences honor their corresponding XDG variables. Generated files do not enter the recursively watched plugin tree. Matching overrides select an existing DesktopEntry, for example `{"matches":{"window-class":"desktop-entry-id"}}` in `overrides.json`.

## Development

```bash
export CARGO_TARGET_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dev.becerromarchy.workspace-taskbar/cargo-target"
cargo fmt --manifest-path backend/Cargo.toml -- --check
cargo clippy --manifest-path backend/Cargo.toml --locked -- -D warnings
cargo test --manifest-path backend/Cargo.toml --locked
cargo build --manifest-path backend/Cargo.toml --locked --release
shellcheck scripts/*.sh tests/smoke/*.sh tests/acceptance/*.sh
tests/smoke/static.sh
python3 tests/smoke/lifecycle.test.py
TASKBAR_TEST_BINARY="$CARGO_TARGET_DIR/release/workspace-taskbar-backend" python3 tests/backend/test_transactions.py
omarchy plugin validate .
./scripts/check-qml.sh
```

CI executes these source/backend checks; the scheduled upstream job flags contract changes for review. Graphical acceptance belongs in a disposable Omarchy VM: see [acceptance procedure](tests/acceptance/README.md). A green hosted CI run alone is not graphical release certification.

From a clean, committed checkout, `./scripts/package.sh /path/to/output` creates a source tar and SHA-256 file from Git. No compiled executable is downloaded by the installer.

MIT licensed. Bundled Lucide control glyphs retain their upstream license in `icons/lucide/LICENSE`.
