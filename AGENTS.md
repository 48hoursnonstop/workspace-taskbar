# Workspace Taskbar agent rules

This project uses a strict precedence order. Lower layers may refine the work but must not override higher layers.

1. `REBUILD_PROMPT_OMARCHY_4.0.4_RUST_POLICY.md` when present in the working tree.
2. Omarchy 4.0.4 public plugin contract and current Omarchy `shell-dev`, `visual-verification`, and `acceptance-tests` guidance.
3. Qt `qt-qml` implementation guidance.
4. Qt `qt-ui-design` interaction and layout guidance.
5. `frontend-design` for art direction only; it does not decide architecture, icon sources, persistence, IPC, or framework choice.
6. `motion-design` and `microinteractions` for state feedback and timing.
7. Current Hyprland documentation for compositor semantics and IPC.
8. Rust guidance for the one-shot backend only.
9. `qt-qml-review`, Omarchy visual verification, and acceptance testing are release gates.

## Product direction

Workspace Taskbar is a refined utilitarian desktop instrument, not a detached web-style dock. It should feel native to Omarchy while having a recognizable interaction language.

- Reuse Omarchy `Color`, `Style`, `Button`, `PopupCard`, bar geometry, and AppLibrary presentation. Do not create a parallel design system.
- Keep one real Hyprland window address equal to one taskbar button. Never combine instances.
- App names and icons come only from the Omarchy AppLibrary facade. No filesystem icon resolver or fabricated launcher identity.
- Prefer progressive disclosure. The frequent path stays short; advanced window operations live one level deeper.
- Motion personality is snappy and deliberate: roughly 90 ms direct feedback, 120–150 ms state changes, 180 ms maximum settling. Prefer `Easing.OutCubic`, no decorative looping, and no layout-geometry animation for state feedback.
- Signature visual language: a compact state rail communicates active/minimized/urgent/popped state; a small accent diamond marks a window created by the project Pop action.
- Direct manipulation feedback must be visible immediately. Busy state must remain recognizable without blocking the entire taskbar.
- Destructive actions use the existing Omarchy urgent semantic color and remain textually explicit.
- Hyprbars is optional and upstream-only through official `hyprwm/hyprland-plugins`; never fork or patch it.
- Never write to `/usr/share/omarchy`.

## Release gate

Before calling a visual release complete:

1. Run project smoke tests and `omarchy plugin validate .`.
2. Run a QML review pass; use `qmllint` when available and inspect bindings, delegates, layouts, image loading, and performance.
3. Restart the real Omarchy shell and visually inspect active, inactive, minimized, urgent, popped, busy, menu-main, menu-more, and workspace-picker states.
4. For motion changes, record a short focused clip and inspect timing/jank.
5. Keep graphical acceptance tests separate from the active development session; use the Omarchy disposable-VM acceptance workflow for release-level automation.
