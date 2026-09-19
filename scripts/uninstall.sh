#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID=dev.becerromarchy.workspace-taskbar
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_RUNTIME_DIR:=/run/user/$UID}"
BIN="$XDG_DATA_HOME/$PLUGIN_ID/bin/workspace-taskbar-backend"

if [[ -x $BIN ]]; then
  echo "Restoring plugin-managed windows..."
  "$BIN" recover >/dev/null

  if command -v jq >/dev/null; then
    doctor_json=$($BIN doctor-json)
    if [[ $(jq -r '.ok // false' <<<"$doctor_json") != true ]]; then
      echo "Refusing cleanup because project-hidden windows still require recovery:" >&2
      jq -r '.strandedError // "unknown recovery error"' <<<"$doctor_json" >&2
      exit 3
    fi
  else
    echo "jq is required to verify that no project-hidden windows remain." >&2
    exit 2
  fi
fi

if [[ -x "$ROOT/scripts/setup-hyprbars.sh" ]]; then
  "$ROOT/scripts/setup-hyprbars.sh" --remove
fi

omarchy plugin disable "$PLUGIN_ID" 2>/dev/null || true
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true

rm -rf -- \
  "$XDG_DATA_HOME/$PLUGIN_ID" \
  "$XDG_STATE_HOME/$PLUGIN_ID" \
  "$XDG_CACHE_HOME/$PLUGIN_ID" \
  "$XDG_RUNTIME_DIR/$PLUGIN_ID"

config_errors=$(hyprctl configerrors 2>/dev/null || true)
if [[ -n $config_errors ]]; then
  echo "Hyprland reports configuration errors after runtime cleanup:" >&2
  printf '%s\n' "$config_errors" >&2
  exit 4
fi

if ! omarchy-shell shell ping >/dev/null 2>&1; then
  echo "Omarchy shell health check failed after runtime cleanup." >&2
  exit 5
fi

cat <<MSG
Runtime integration for $PLUGIN_ID was removed safely.
The source checkout was left untouched at:
  $ROOT
Use Omarchy's official plugin removal command if you also want to remove that checkout:
  omarchy plugin remove $PLUGIN_ID
MSG
