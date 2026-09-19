#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
SHELL_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json

for command in jq omarchy omarchy-shell hyprctl pgrep; do
  command -v "$command" >/dev/null || { echo "missing required command: $command" >&2; exit 2; }
done

pass() { printf '%-36s ok\n' "$1"; }
fail() { printf '%-36s FAIL: %s\n' "$1" "$2" >&2; exit 1; }

omarchy plugin validate "$ROOT" >/dev/null && pass "plugin validation"
omarchy-shell shell ping >/dev/null && pass "omarchy-shell IPC"

config_errors=$(hyprctl configerrors)
if [[ -z $config_errors ]]; then pass "Hyprland config"; else fail "Hyprland config" "$config_errors"; fi

if [[ -f $SHELL_CONFIG ]]; then
  bar_id=$(jq -r '.bar.id // "omarchy.bar"' "$SHELL_CONFIG")
else
  bar_id=omarchy.bar
fi
if [[ $bar_id == omarchy.bar ]]; then pass "built-in bar remains active"; else fail "built-in bar remains active" "bar.id=$bar_id"; fi

shell_processes=$(pgrep -af 'quickshell .* -n .* -p .*/shell|quickshell -n -p .*/shell' || true)
shell_count=$(grep -c . <<<"$shell_processes" || true)
if [[ $shell_count -eq 1 ]]; then pass "single Omarchy Quickshell"; else fail "single Omarchy Quickshell" "found $shell_count candidate processes"; fi

status=$(omarchy-shell workspace-taskbar status)
if echo "$status" | jq -e '.backendHealthy == true and .protocolCompatible == true and .appLibraryHealthy == true' >/dev/null  ; then pass "service health"  ; else fail "service health" "$status"; fi

model=$(omarchy-shell workspace-taskbar model)
echo "$model" | jq -e 'type == "array"' >/dev/null || fail "taskbar model" "IPC did not return an array"
if echo "$model" | jq -e 'all(.[]; (.address | test("^0x[0-9a-f]+$")))' >/dev/null  ; then pass "exact address identities"  ; else fail "exact address identities" "invalid address in model"; fi
if echo "$model" | jq -e '([.[].address] | length) == ([.[].address] | unique | length)' >/dev/null  ; then pass "one row per window address"  ; else fail "one row per window address" "duplicate address in model"; fi
if echo "$model" | jq -e 'all(.[]; if .matched then (.iconSource | length) > 0 and .appName != "Unmatched application" else .iconSource == "" end)' >/dev/null  ; then pass "AppLibrary presentation rule"  ; else fail "AppLibrary presentation rule" "matched/unmatched presentation invariant failed"; fi
if echo "$model" | jq -e 'all(.[]; (.workspaceName | type == "string") and (.specialWorkspace | type == "boolean"))' >/dev/null  ; then pass "workspace metadata"  ; else fail "workspace metadata" "workspaceName/specialWorkspace missing"; fi
if echo "$model" | jq -e 'all(.[]; (.floating | type == "boolean") and (.pinned | type == "boolean") and (.pseudo | type == "boolean") and (.taskbarPinned | type == "boolean"))' >/dev/null  ; then pass "window state metadata"  ; else fail "window state metadata" "floating/pinned/pseudo/taskbarPinned roles missing"; fi

if echo "$status" | jq -e '(.pinnedApplications | type == "number") and (.pinsPath | type == "string")' >/dev/null  ; then pass "taskbar pin state"  ; else fail "taskbar pin state" "pin status metadata missing"; fi

omarchy-shell workspace-taskbar refreshApps >/dev/null && pass "manual AppLibrary refresh"

printf '\nCurrent model: %s window(s), %s minimized by the plugin.\n'   "$(jq 'length' <<<"$model")"   "$(jq '[.[] | select(.minimized)] | length' <<<"$model")"
