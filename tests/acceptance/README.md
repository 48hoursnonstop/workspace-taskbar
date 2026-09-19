# Desktop acceptance

`live-smoke.sh` only checks the running service/model and refreshes AppLibrary. It does not open, close or move windows.

`desktop.py` creates three Foot windows, verifies individual model rows, minimizes/restores, exercises Show Desktop and focus restoration, restarts the shell with saved state, opens the real menu, sends keyboard input and checks protocol rejection. It captures screenshots and closes only processes it created. It refuses to run without both a VM and `TASKBAR_DISPOSABLE_VM=1`.

Use the official [Omarchy disposable-VM procedure](https://github.com/omacom/omarchy/blob/v4.0.4/agents/skills/acceptance-tests.md). Prepare an Omarchy 4.0.4 guest using the sibling `omarchy-iso` harness; install this checkout and build its backend inside that guest. Run as its logged-in desktop user:

```bash
./scripts/doctor.sh
tests/acceptance/live-smoke.sh
TASKBAR_DISPOSABLE_VM=1 python3 tests/acceptance/desktop.py
```

A fresh VM must begin with no plugin-minimized windows. Keep the guest's screenshots/logs with its Omarchy, Hyprland, Quickshell and plugin versions. Do not substitute the active development desktop for a disposable VM.

Complete these additional manual checks before promoting the candidate to stable. Automated backend tests simulate their state transitions but do not establish real compositor behavior:

| Area | Required evidence |
|---|---|
| State | Floating geometry, pin, pseudo, internal/client fullscreen and maximized state survive minimize/restore. |
| Groups | Minimize either member, restore either member, close a member while hidden; no sibling stranded. |
| Lifecycle | Disable/re-enable; shell restart; guest reboot clears stale addresses without affecting newly launched clients. |
| Identity | Normal app, Omarchy web app and installed Steam game match their launcher icon; live tooltip titles update. |
| Menu | Main, more, workspace and monitor pages; Enter/Space/Escape; exact-address actions; monitor unplug/replug. |
| Visual states | Active, inactive, minimized, urgent, popped and busy; no clipping or stale focus. |
| Optional Hyprbars | Present, missing, failed load, config reload and reboot; no configerrors. |
| Updates | Git fast-forward source update, stale backend refusal, explicit rebuild, clean checkout afterward. |
| Removal | Recover hidden windows, remove owned configuration only, preserve pre-existing Hyprbars; missing backend blocks destructive cleanup. |
| Performance | Record representative focus/minimize/restore and event-to-model timings against the kit's <100 ms targets. |

To test installation/removal, use a disposable guest snapshot so the test runner is not executing from the directory it removes. Hosted GitHub CI intentionally runs mocks/source checks; it does not certify the graphical matrix.
