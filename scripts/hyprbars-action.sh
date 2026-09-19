#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID=dev.becerromarchy.workspace-taskbar
: "${XDG_DATA_HOME:=$HOME/.local/share}"
BIN="$XDG_DATA_HOME/$PLUGIN_ID/bin/workspace-taskbar-backend"

action=${1:-}

command -v hyprctl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Hyprbars focuses the exact owner window before launching a button command.
# Capture that address once and carry it through the whole action so a later
# focus change cannot redirect maximize/close to a different client.
address=$(hyprctl activewindow -j 2>/dev/null | jq -er '.address | select(type == "string" and length > 0)' 2>/dev/null || true)
[[ -n $address ]] || exit 0
selector="address:$address"

case "$action" in
  minimize)
    [[ -x $BIN ]] || exit 0
    exec "$BIN" minimize "$address"
    ;;
  maximize)
    exec hyprctl dispatch "hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\", window = \"$selector\" })"
    ;;
  close)
    exec hyprctl dispatch "hl.dsp.window.close({ window = \"$selector\" })"
    ;;
  *)
    printf 'usage: %s {minimize|maximize|close}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
