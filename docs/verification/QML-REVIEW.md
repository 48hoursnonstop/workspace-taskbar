# QML review

Scope: the v0.13.7 → v0.14.0-rc.1 changes, plus surrounding QML and the installed Omarchy public UI/loader implementations.

The Qt review procedure's deterministic scanner and qmllint ran before six read-only review passes: bindings/properties, layout/anchoring, component lifecycle, delegates/model roles, state transitions and performance.

The scanner reports existing project conventions such as dynamic `var` facades, imperative anchor snapshots and declaration ordering. Anchor snapshots are intentional: the popup should remain stable if its window delegate disappears. These style diagnostics were inspected and do not constitute compilation failures. No source was automatically rewritten by the scanner.

The independent lifecycle/state passes identified that removing the screen owning `menuHost` left surviving taskbars unable to receive a shell summon. Surviving widgets now observe host changes and take ownership, while a destruction guard prevents the departing widget from reclaiming it. Follow-up static review found the issue resolved. Physical monitor removal remains in the VM/hardware acceptance matrix.

The subsequent real-shell check exposed the upstream menu-side facade revocation described in the rebuild kit. WindowMenu intentionally declares only `service`, not `shell`; the host injects the plugin's own singleton before delivering its queued `open()` payload. The service retains its working scoped AppLibrary. Main, more and workspace menus were rendered and inspected, keyboard/Escape tested, and health checked again after hide.

`check-qml.sh` reconstructs Quickshell's qs import mapping in a temporary directory and fails all warnings except two documented informational categories: dynamic members of host QtObject/var facades, and the missing QProcess::ExitStatus enum metadata in the installed Quickshell qmltypes. Syntax, import and unresolved-type failures are not suppressed.
