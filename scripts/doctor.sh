#!/usr/bin/env bash
set -uo pipefail

PLUGIN_ID=dev.becerromarchy.workspace-taskbar
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
BIN="$XDG_DATA_HOME/$PLUGIN_ID/bin/workspace-taskbar-backend"
OMARCHY_PATH=${OMARCHY_PATH:-/usr/share/omarchy}
HYPRBARS_CONFIG="$HOME/.config/hypr/workspace-taskbar-hyprbars.lua"
HYPRBARS_HELPER="$XDG_DATA_HOME/$PLUGIN_ID/bin/workspace-taskbar-hyprbars-action"
HYPRBARS_STATE="$XDG_STATE_HOME/$PLUGIN_ID/hyprbars-ownership.env"
HYPRBARS_BEGIN='-- >>> dev.becerromarchy.workspace-taskbar:hyprbars >>>'
HYPRBARS_END='-- <<< dev.becerromarchy.workspace-taskbar:hyprbars <<<'

ok=1
warn=0

check() { printf '%-34s %s\n' "$1" "$2"; }
pass() { check "$1" "ok"; }
fail() { check "$1" "FAIL: $2"; ok=0; }
warning() { check "$1" "WARN: $2"; warn=1; }

check "plugin" "$PLUGIN_ID"
check "plugin directory" "$ROOT"

omarchy_version=$(pacman -Q omarchy 2>/dev/null | awk '{print $2}' || true)
[[ -n $omarchy_version ]] || omarchy_version=$(omarchy version 2>/dev/null || true)
check "Omarchy" "${omarchy_version:-unavailable}"
if [[ -n $omarchy_version && $omarchy_version != 4.0.4* ]]; then
  warning "Omarchy compatibility" "reviewed baseline is 4.0.4; installed is $omarchy_version"
else
  pass "Omarchy compatibility"
fi

hyprland_version=$(hyprctl version 2>/dev/null | head -1 || true)
check "Hyprland" "${hyprland_version:-unavailable}"
quickshell_version=$(qs --version 2>/dev/null || quickshell --version 2>/dev/null || true)
check "Quickshell" "${quickshell_version:-unavailable}"
check "kernel" "$(uname -r)"

qml_root=$(qtpaths6 --query QT_INSTALL_QML 2>/dev/null || true)
[[ -n $qml_root ]] || qml_root=/usr/lib/qt6/qml
screencopy_qmldir="$qml_root/Quickshell/Wayland/_Screencopy/qmldir"
if [[ -f $screencopy_qmldir ]]; then
  pass "Quickshell Screencopy"
else
  fail "Quickshell Screencopy" "Quickshell.Wayland Screencopy module not installed"
fi

if omarchy-shell shell ping >/dev/null 2>&1; then pass "omarchy-shell ping"; else fail "omarchy-shell ping" "shell IPC unavailable"; fi

if omarchy plugin validate "$ROOT" >/dev/null 2>&1; then pass "plugin validate"; else fail "plugin validate" "manifest/source rejected"; fi

if [[ -f $OMARCHY_PATH/shell/services/PluginShellApi.qml ]] && grep -Fq 'function serviceFor(id)' "$OMARCHY_PATH/shell/services/PluginShellApi.qml"; then
  pass "upstream serviceFor"
else
  fail "upstream serviceFor" "public own-service API not found"
fi

if [[ -f $OMARCHY_PATH/shell/services/PluginAppLibraryApi.qml ]] \
  && grep -Fq 'function sortedEntries(query)' "$OMARCHY_PATH/shell/services/PluginAppLibraryApi.qml" \
  && grep -Fq 'function iconSource(icon)' "$OMARCHY_PATH/shell/services/PluginAppLibraryApi.qml"; then
  pass "upstream AppLibrary facade"
else
  fail "upstream AppLibrary facade" "required public facade methods not found"
fi

if [[ -f $OMARCHY_PATH/shell/Ui/PluginBarApi.qml ]] \
  && grep -Fq 'function requestPopout(owner)' "$OMARCHY_PATH/shell/Ui/PluginBarApi.qml" \
  && grep -Fq 'function releasePopout(owner)' "$OMARCHY_PATH/shell/Ui/PluginBarApi.qml"; then
  pass "upstream PopupCard bar API"
else
  fail "upstream PopupCard bar API" "requestPopout/releasePopout facade not found"
fi

if [[ -f $OMARCHY_PATH/default/hypr/bindings/tiling.lua ]] \
  && grep -Fq 'hl.dsp.window.fullscreen' "$OMARCHY_PATH/default/hypr/bindings/tiling.lua" \
  && grep -Fq 'hl.dsp.window.move' "$OMARCHY_PATH/default/hypr/bindings/tiling.lua" \
  && grep -Fq 'hl.dsp.group.toggle()' "$OMARCHY_PATH/default/hypr/bindings/tiling.lua"; then
  pass "upstream Lua dispatchers"
else
  fail "upstream Lua dispatchers" "reviewed Lua dispatcher family not found"
fi

if [[ -x $BIN ]]; then
  check "backend" "$BIN"
  version_json=$($BIN version-json 2>/dev/null || true)
  doctor_json=$($BIN doctor-json 2>/dev/null || true)
  check "backend version" "${version_json:-FAIL}"
  check "backend doctor" "${doctor_json:-FAIL}"

  if command -v jq >/dev/null 2>&1 && [[ -n $version_json ]]; then
    protocol=$(jq -r '.protocolVersion // -1' <<<"$version_json" 2>/dev/null || echo -1)
    [[ $protocol == 4 ]] && pass "backend protocol" || fail "backend protocol" "expected 4, got $protocol"
  fi

  command -v sha256sum >/dev/null 2>&1 && check "backend sha256" "$(sha256sum "$BIN" | awk '{print $1}')"
else
  fail "backend" "missing; build is required before runtime testing"
fi

config_errors=$(hyprctl configerrors 2>/dev/null || true)
if [[ -z $config_errors ]]; then pass "Hyprland config errors"; else fail "Hyprland config errors" "$config_errors"; fi

if command -v hyprpm >/dev/null 2>&1; then
  pass "hyprpm"
  hyprpm_clean=$(hyprpm list 2>/dev/null | sed -E $'s/\x1B\\[[0-9;]*[mK]//g' || true)
  if grep -Fq 'Repository hyprland-plugins ' <<<"$hyprpm_clean"; then
    pass "official hyprland-plugins"
  else
    check "official hyprland-plugins" "optional/not installed"
  fi
else
  check "hyprpm" "optional/not installed"
  hyprpm_clean=""
fi

hyprbars_loaded=false
if hyprctl plugin list 2>/dev/null | grep -qi 'hyprbars'; then
  hyprbars_loaded=true
  pass "Hyprbars loaded"
else
  check "Hyprbars loaded" "optional/no"
fi

hyprbars_managed=false
if [[ -f $HYPRBARS_CONFIG || -f $HYPRBARS_STATE ]] || grep -Fq "$HYPRBARS_BEGIN" "$HOME/.config/hypr/hyprland.lua" 2>/dev/null; then
  hyprbars_managed=true
fi

if [[ $hyprbars_managed == true ]]; then
  [[ -f $HYPRBARS_CONFIG ]] && grep -Fq 'dev.becerromarchy.workspace-taskbar managed Hyprbars config v1' "$HYPRBARS_CONFIG" \
    && pass "Hyprbars managed config" \
    || fail "Hyprbars managed config" "missing or not recognized"
  hyprbars_begin_count=$(grep -Fxc -- "$HYPRBARS_BEGIN" "$HOME/.config/hypr/hyprland.lua" 2>/dev/null || true)
  hyprbars_end_count=$(grep -Fxc -- "$HYPRBARS_END" "$HOME/.config/hypr/hyprland.lua" 2>/dev/null || true)
  if [[ $hyprbars_begin_count == 1 && $hyprbars_end_count == 1 ]]; then
    pass "Hyprbars config hook"
  elif [[ $hyprbars_begin_count == 0 && $hyprbars_end_count == 0 ]]; then
    fail "Hyprbars config hook" "missing from user hyprland.lua"
  else
    fail "Hyprbars config hook" "managed marker pair is malformed in user hyprland.lua"
  fi
  [[ $hyprbars_loaded == true ]] \
    && pass "Hyprbars integration" \
    || fail "Hyprbars integration" "managed integration exists but plugin is not loaded"
  [[ -x $HYPRBARS_HELPER ]] \
    && pass "Hyprbars action helper" \
    || fail "Hyprbars action helper" "missing or not executable"
  hyprbars_button_count=$(grep -Fc 'hl.plugin.hyprbars.add_button({' "$HYPRBARS_CONFIG" 2>/dev/null || true)
  if [[ $hyprbars_button_count == 3 ]] \
    && grep -Fq 'workspace-taskbar-hyprbars-action' "$HYPRBARS_CONFIG" 2>/dev/null \
    && grep -Fq '" minimize"' "$HYPRBARS_CONFIG" 2>/dev/null \
    && grep -Fq '" maximize"' "$HYPRBARS_CONFIG" 2>/dev/null \
    && grep -Fq '" close"' "$HYPRBARS_CONFIG" 2>/dev/null; then
    pass "Hyprbars controls"
  else
    fail "Hyprbars controls" "expected managed minimize/maximize/close controls"
  fi
  [[ -f $HYPRBARS_STATE ]] \
    && pass "Hyprbars ownership state" \
    || fail "Hyprbars ownership state" "missing; uninstall cannot prove dependency ownership"
else
  check "Hyprbars integration" "optional/not configured"
fi

if omarchy-shell workspace-taskbar status >/dev/null 2>&1; then
  refresh_apps=$(omarchy-shell workspace-taskbar refreshApps 2>/dev/null || true)
  check "AppLibrary refresh" "${refresh_apps:-unavailable}"
fi

service_status=$(omarchy-shell workspace-taskbar status 2>/dev/null || true)
if [[ -n $service_status ]]; then
  check "taskbar service" "$service_status"
  if command -v jq >/dev/null 2>&1; then
    app_ok=$(jq -r '.appLibraryHealthy // false' <<<"$service_status" 2>/dev/null || echo false)
    proto_ok=$(jq -r '.protocolCompatible // false' <<<"$service_status" 2>/dev/null || echo false)
    [[ $app_ok == true ]] && pass "AppLibrary runtime probe" || fail "AppLibrary runtime probe" "$(jq -r '.appLibraryDiagnostic // "failed"' <<<"$service_status" 2>/dev/null)"
    [[ $proto_ok == true ]] && pass "service/backend protocol" || fail "service/backend protocol" "mismatch or backend unavailable"

    model_json=$(omarchy-shell workspace-taskbar model 2>/dev/null || true)
    clients_json=$(hyprctl -j clients 2>/dev/null || true)
    snapshot_json=$($BIN snapshot 2>/dev/null || true)
    if [[ -n $model_json && -n $clients_json && -n $snapshot_json ]]; then
      stale_rows=$(jq -n \
        --argjson model "$model_json" \
        --argjson clients "$clients_json" \
        --argjson snapshot "$snapshot_json" '
          def norm: ascii_downcase | if startswith("0x") then . else "0x" + . end;
          ([ $clients[]?.address | tostring | norm ] + [ $snapshot.minimized[]?.address | tostring | norm ]) as $valid
          | [ $model[]? | select(((.address | tostring | norm) as $a | ($valid | index($a))) == null)
              | {address, appName, title, minimized} ]
        ' 2>/dev/null || echo '[]')
      stale_count=$(jq 'length' <<<"$stale_rows" 2>/dev/null || echo 0)
      if [[ $stale_count == 0 ]]; then
        pass "taskbar model reconciliation"
      else
        warning "taskbar model reconciliation" "stale/ghost row(s): $(jq -c . <<<"$stale_rows" 2>/dev/null || echo "$stale_rows")"
      fi
    else
      warning "taskbar model reconciliation" "could not compare taskbar model with Hyprland/backend state"
    fi
  fi
else
  warning "taskbar service" "not enabled or IPC target not loaded yet"
fi

(( warn == 0 )) || echo "Doctor completed with compatibility warning(s)." >&2
exit $((ok ? 0 : 1))
