#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID=dev.becerromarchy.workspace-taskbar
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
SHELL_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json

for command in jq omarchy omarchy-shell hyprctl pgrep; do
  command -v "$command" >/dev/null || { echo "missing required command: $command" >&2; exit 2; }
done

pass() { printf '%-36s ok\n' "$1"; }
fail() { printf '%-36s FAIL: %s\n' "$1" "$2" >&2; exit 1; }

omarchy plugin validate "$ROOT" >/dev/null && pass "plugin validation"
omarchy-shell shell ping >/dev/null && pass "omarchy-shell IPC"

config_errors=$(hyprctl configerrors 2>/dev/null || true)
[[ -z $config_errors ]] && pass "Hyprland config" || fail "Hyprland config" "$config_errors"

if [[ -f $SHELL_CONFIG ]]; then
  bar_id=$(jq -r '.bar.id // "omarchy.bar"' "$SHELL_CONFIG")
else
  bar_id=omarchy.bar
fi
[[ $bar_id == omarchy.bar ]] && pass "built-in bar remains active" || fail "built-in bar remains active" "bar.id=$bar_id"

shell_processes=$(pgrep -af 'quickshell .* -n .* -p .*/shell|quickshell -n -p .*/shell' || true)
shell_count=$(grep -c . <<<"$shell_processes" || true)
[[ $shell_count -eq 1 ]] && pass "single Omarchy Quickshell" || fail "single Omarchy Quickshell" "found $shell_count candidate processes"

status=$(omarchy-shell workspace-taskbar status)
echo "$status" | jq -e '.backendHealthy == true and .protocolCompatible == true and .appLibraryHealthy == true' >/dev/null \
  && pass "service health" \
  || fail "service health" "$status"

model=$(omarchy-shell workspace-taskbar model)
echo "$model" | jq -e 'type == "array"' >/dev/null || fail "taskbar model" "IPC did not return an array"
echo "$model" | jq -e 'all(.[]; (.address | test("^0x[0-9a-f]+$")))' >/dev/null \
  && pass "exact address identities" \
  || fail "exact address identities" "invalid address in model"
echo "$model" | jq -e '([.[].address] | length) == ([.[].address] | unique | length)' >/dev/null \
  && pass "one row per window address" \
  || fail "one row per window address" "duplicate address in model"
echo "$model" | jq -e 'all(.[]; if .matched then (.iconSource | length) > 0 and .appName != "Unmatched application" else .iconSource == "" end)' >/dev/null \
  && pass "AppLibrary presentation rule" \
  || fail "AppLibrary presentation rule" "matched/unmatched presentation invariant failed"
echo "$model" | jq -e 'all(.[]; (.workspaceName | type == "string") and (.specialWorkspace | type == "boolean"))' >/dev/null \
  && pass "workspace metadata" \
  || fail "workspace metadata" "workspaceName/specialWorkspace missing"
echo "$model" | jq -e 'all(.[]; (.floating | type == "boolean") and (.pinned | type == "boolean") and (.pseudo | type == "boolean") and (.taskbarPinned | type == "boolean"))' >/dev/null \
  && pass "window state metadata" \
  || fail "window state metadata" "floating/pinned/pseudo/taskbarPinned roles missing"

echo "$status" | jq -e '(.pinnedApplications | type == "number") and (.pinsPath | type == "string")' >/dev/null \
  && pass "taskbar pin state" \
  || fail "taskbar pin state" "pin status metadata missing"

omarchy-shell workspace-taskbar refreshApps >/dev/null && pass "manual AppLibrary refresh"

printf '\nCurrent model: %s window(s), %s minimized by the plugin.\n' \
  "$(jq 'length' <<<"$model")" \
  "$(jq '[.[] | select(.minimized)] | length' <<<"$model")"
