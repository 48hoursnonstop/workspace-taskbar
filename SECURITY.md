# Security

Workspace Taskbar runs as an ordinary user inside Omarchy's existing Quickshell process and invokes a one-shot user-level Rust helper. It does not require root, a system service, a daemon, or a network listener.

The plugin intentionally uses only the scoped Omarchy plugin facade for application metadata and its own service lifecycle. It does not traverse private shell objects or modify Omarchy-owned files.

Window addresses are normalized as hexadecimal values before they enter Hyprland selectors. Backend subprocess arguments are passed as argument arrays from QML. The Rust helper escapes values embedded in Hyprland Lua expressions and never interpolates window titles into commands.

Runtime restore state is stored under `XDG_STATE_HOME` and is written with a temporary file, `fsync`, atomic rename, and parent-directory `fsync`.

The optional Hyprbars path uses Hyprland's official C++ plugin repository only and delegates ABI/version selection to `hyprpm`. The project does not ship, copy, patch, or manually build a Hyprbars `.so`. Because any Hyprland C++ plugin runs inside the compositor process, Hyprbars remains opt-in and the taskbar core has no dependency on it.

Hyprbars setup writes only a project-owned Lua config plus a marker-delimited hook in the user's own `~/.config/hypr/hyprland.lua`. Setup checks `hyprctl plugin list` and `hyprctl configerrors`, and rolls back only changes made by the current run if validation fails.
