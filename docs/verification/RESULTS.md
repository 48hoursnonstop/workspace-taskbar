# Verification — 0.14.0-rc.1

Date: 2026-09-19. Baseline: Omarchy package 4.0.4-1, Hyprland 0.56.2-2, Quickshell 0.3.1-1, Rust/Cargo 1.98.1, ShellCheck 0.11.0.

## Executed

| Check | Result |
|---|---|
| Omarchy manifest validation | Passed on source and installed candidate. |
| Committed Cargo.lock + locked release build | Passed; build and installation output remain outside source. |
| Rustfmt | Passed. |
| Clippy with warnings denied | Passed. |
| Rust unit tests | 3 passed. |
| CLI transaction integration | 14 passed using an isolated compositor test double. |
| Install/uninstall/doctor lifecycle | 8 passed using isolated XDG directories and IPC doubles. |
| App matcher, Hyprbars setup/action smoke tests | Passed. |
| ShellCheck, all distributed shell scripts | Passed. |
| QML lint gate | Passed with real shell import mapping; dynamic-facade member and incomplete Quickshell enum metadata diagnostics remain informational. |
| Independent QML review | Six focused read-only passes. One monitor-removal ownership issue found and fixed; follow-up accepted the fix. |
| Upstream contract hashes | Match the reviewed v4.0.4 baseline. |
| Running desktop doctor / read-only live smoke | Passed with healthy backend, protocol and AppLibrary, one shell process and no Hyprland config errors. |
| Real menu lifecycle | Summon, main/more/workspace surfaces, keyboard navigation, Escape and hide verified; AppLibrary remains healthy afterward. |
| Shell restart | Candidate reloaded successfully; no plugin QML load errors in the shell log. |

Regression tests cover partial minimize/restore failures, persisted pending work, geometry/fullscreen/pin preservation, grouped windows, Show Desktop batch isolation and focus, restore-last/all, external moves, moved minimized clients, orphan recovery, closed/reused addresses, protocol refusal, unsupported Hyprland, corrupt-state preservation, lock contention, failed disable, missing backend and failed doctor queries.

## Runtime discoveries resolved

1. Omarchy 4.0.4 can revoke the service's AppLibrary facade when a model-delivered menu requests another shell facade. The menu now uses the host's explicit own-service injection, with AppLibrary owned only by TaskbarService. No upstream file is patched.
2. Doctor previously competed for the UI transaction lock. It now reads the atomically replaced journal without taking that lock, and the service treats a busy backend as a transient action result rather than a broken backend.

## Release status

The owner reports that the plugin works in their desktop session and approved publishing this candidate on 2026-09-19. This is manual user validation; it does not represent an automated VM run.

**Candidate, not stable graphical certification.** The full disposable-VM/reboot matrix has not been executed. No prepared VM or ISO was present; the official harness requires a separately installed guest. The active desktop was used for scoped visual inspection and read-only smoke checks, not destructive graphical automation.

`tests/acceptance/desktop.py` is supplied with VM/opt-in guards; its refusal on the development desktop was verified. Complete [the remaining acceptance matrix](../../tests/acceptance/README.md) in a disposable Omarchy guest before tagging a stable release. The <100 ms performance targets, physical multi-monitor removal, Steam/webapp identity samples, reboot, real groups, and full clean install/update/removal matrix are not claimed as passed.

The hosted GitHub workflow is prepared and its corresponding local checks passed. No hosted Actions run is claimed before the repository is published.
