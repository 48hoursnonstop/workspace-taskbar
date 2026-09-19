#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)

jq -e '.schemaVersion == 1 and .version == "0.13.7" and (.kinds|index("service")) and (.kinds|index("bar-widget")) and (.kinds|index("menu")) and .entryPoints.menu == "CapabilityMenu.qml"' "$ROOT/manifest.json" >/dev/null
jq -e '.omarchy.baseline == "4.0.4" and .omarchy.tag == "v4.0.4"' "$ROOT/compat/upstream.json" >/dev/null

! grep -R --exclude-dir=.git -E '/usr/share/omarchy.*(>|tee|sed -i|cp |mv )|parent\.parent\.shell|bar\.shell\.appLibrary' "$ROOT" >/dev/null
! grep -R --exclude-dir=.git -E 'Quickshell\.iconPath|/usr/share/icons|steam.*artwork|favicon' "$ROOT/Taskbar.qml" "$ROOT/TaskbarService.qml" "$ROOT/qml" >/dev/null

for file in "$ROOT"/scripts/*.sh "$ROOT"/tests/smoke/*.sh "$ROOT"/tests/acceptance/*.sh; do
  bash -n "$file"
done

plugin_id=$(jq -r '.id' "$ROOT/manifest.json")
grep -Fq 'pub const PLUGIN_ID: &str = "'"$plugin_id"'";' "$ROOT/backend/src/protocol.rs"
grep -Fq 'readonly property string pluginId: "'"$plugin_id"'"' "$ROOT/TaskbarService.qml"
grep -Fq 'property var service: null' "$ROOT/CapabilityMenu.qml"

node "$ROOT/tests/smoke/app-matcher.test.js"
"$ROOT/tests/smoke/hyprbars-setup.test.sh"
"$ROOT/tests/smoke/hyprbars-action.test.sh"

grep -Fq 'special:becerromarchy-workspace-taskbar' "$ROOT/backend/src/protocol.rs"
grep -Fq 'fs::rename(&temporary, &path)?;' "$ROOT/backend/src/state.rs"
grep -Fq 'fs::File::open(parent)?.sync_all()?;' "$ROOT/backend/src/state.rs"
grep -Fq 'batch.starts_with(&batch_prefix)' "$ROOT/backend/src/actions.rs"
grep -Fq 'create_new(true)' "$ROOT/backend/src/state.rs"
grep -Fq 'XDG_RUNTIME_DIR' "$ROOT/backend/src/state.rs"

grep -Fq 'readonly property int expectedProtocol: 4' "$ROOT/TaskbarService.qml"
grep -Fq 'property var service: null' "$ROOT/CapabilityMenu.qml"
grep -Fq 'KeyboardPanel {' "$ROOT/Taskbar.qml"
grep -Fq 'PanelKeyCatcher {' "$ROOT/Taskbar.qml"
grep -Fq 'focusTarget: menuKeyCatcher' "$ROOT/Taskbar.qml"
grep -Fq 'anchorItem: menuAnchorProxy' "$ROOT/Taskbar.qml"
grep -Fq 'root.service.showDesktop()' "$ROOT/Taskbar.qml"
grep -Fq 'float-pin-toggle' "$ROOT/Taskbar.qml"
grep -Fq 'dispatch("hl.dsp.group.toggle()")?;' "$ROOT/backend/src/hypr.rs"
grep -Fq 'pub const PROTOCOL_VERSION: u32 = 4;' "$ROOT/backend/src/protocol.rs"
grep -Fq 'EXPECTED_PROTOCOL=4' "$ROOT/scripts/build-backend.sh"
grep -Fq 'expected 4, got $protocol' "$ROOT/scripts/doctor.sh"
! grep -Fq 'root.rebuildDebounce.restart()' "$ROOT/TaskbarService.qml"
! grep -Fq 'root.snapshotDebounce.restart()' "$ROOT/TaskbarService.qml"
! grep -Fq -- '--yes' "$ROOT/scripts/install.sh"
! grep -Fq 'windowModel.clear()' "$ROOT/TaskbarService.qml"
! grep -Fq 'required property string address' "$ROOT/Taskbar.qml"
grep -Fq 'property var appPresentationById' "$ROOT/TaskbarService.qml"
grep -Fq 'workspaceName:' "$ROOT/TaskbarService.qml"

grep -Fq 'pub fn reattach_tiled(address: &str) -> Result<()>' "$ROOT/backend/src/hypr.rs"
grep -Fq 'hypr::wait_for_workspace(&record.address, &workspace)?;' "$ROOT/backend/src/actions.rs"
grep -Fq 'hypr::reattach_tiled(&record.address)?;' "$ROOT/backend/src/actions.rs"

# Backend release pin for the current plugin protocol.
grep -Fq 'version = "0.7.0"' "$ROOT/backend/Cargo.toml"
grep -Fq 'Style.selectedFillFor' "$ROOT/qml/WindowButton.qml"
grep -Fq 'Style.hoverFillFor' "$ROOT/qml/WindowButton.qml"
grep -Fq 'delegate: Button {' "$ROOT/Taskbar.qml"
! test -e "$ROOT/WindowMenu.qml"

grep -Fq 'https://github.com/hyprwm/hyprland-plugins' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'hyprpm update' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'hyprpm add "$OFFICIAL_REPO"' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'hyprpm enable "$HYPRBARS_NAME"' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'hyprpm reload' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'hyprctl plugin list' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'hyprctl configerrors' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'REPO_ADDED_BY_PROJECT' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'PLUGIN_ENABLED_BY_PROJECT' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'grep -Fxc -- "$HYPRBARS_BEGIN"' "$ROOT/scripts/doctor.sh"
grep -Fq 'grep -Fxc -- "$HYPRBARS_END"' "$ROOT/scripts/doctor.sh"
grep -Fq 'Hyprbars action helper' "$ROOT/scripts/doctor.sh"
grep -Fq 'Hyprbars controls' "$ROOT/scripts/doctor.sh"
grep -Fq 'if not (hl and hl.plugin and hl.plugin.hyprbars) then' "$ROOT/hyprbars/workspace-taskbar-hyprbars.lua"
grep -Fq 'hl.plugin.hyprbars.add_button({' "$ROOT/hyprbars/workspace-taskbar-hyprbars.lua"
grep -Fq 'workspace-taskbar-hyprbars-action' "$ROOT/hyprbars/workspace-taskbar-hyprbars.lua"
grep -Fq 'minimize)' "$ROOT/scripts/hyprbars-action.sh"
grep -Fq 'maximize)' "$ROOT/scripts/hyprbars-action.sh"
grep -Fq 'window = \"$selector\"' "$ROOT/scripts/hyprbars-action.sh"
grep -Fq 'workspace-taskbar-hyprbar-inactive' "$ROOT/hyprbars/workspace-taskbar-hyprbars.lua"
grep -Fq 'match = { fullscreen = true }' "$ROOT/hyprbars/workspace-taskbar-hyprbars.lua"
grep -Fq 'match = { content = "^game$" }' "$ROOT/hyprbars/workspace-taskbar-hyprbars.lua"
grep -Fq 'local found_accent = false' "$ROOT/hyprbars/workspace-taskbar-hyprbars.lua"
grep -Fq 'if not found_accent and color4 then colors.accent = color4 end' "$ROOT/hyprbars/workspace-taskbar-hyprbars.lua"
grep -Fq 'for cmd in hyprctl hyprpm jq' "$ROOT/scripts/setup-hyprbars.sh"
grep -Fq 'hyprbars-overrides.lua' "$ROOT/hyprbars/workspace-taskbar-hyprbars.lua"
grep -Fq '["hyprbars:no_bar"] = true' "$ROOT/tests/fixtures/hyprbars-overrides.example.lua"
! grep -R -E 'right.?click|on_right_click|right_button' "$ROOT/hyprbars" >/dev/null

grep -Fq 'Move to workspace…' "$ROOT/Taskbar.qml"
grep -Fq 'Move here · Workspace ' "$ROOT/Taskbar.qml"
grep -Fq 'Pop out window' "$ROOT/Taskbar.qml"
grep -Fq 'Return popped window' "$ROOT/Taskbar.qml"
grep -Fq '"pop-toggle"' "$ROOT/backend/src/hypr.rs"
grep -Fq 'pub tags: Vec<String>' "$ROOT/backend/src/hypr.rs"
grep -Fq 'hl.dsp.window.center' "$ROOT/backend/src/hypr.rs"
grep -Fq 'hl.dsp.window.tag' "$ROOT/backend/src/hypr.rs"
grep -Fq 'pop-out requires a tiled, unpinned, non-fullscreen window' "$ROOT/backend/src/hypr.rs"
grep -Fq 'Hyprland.workspaces.values' "$ROOT/Taskbar.qml"
grep -Fq 'root.service.menuAction(name, String(root.menuTarget.address), argument)' "$ROOT/Taskbar.qml"
grep -Fq 'property string workspaceName' "$ROOT/qml/WindowButton.qml"



# 0.8.x skill-driven QML/UX release gate (skills are not shipped/installed).
! test -e "$ROOT/AGENTS.md"
! test -e "$ROOT/scripts/install-agent-skills.sh"
test -f "$ROOT/docs/UX_DIRECTION.md"
grep -Fq 'pragma ComponentBehavior: Bound' "$ROOT/Taskbar.qml"
grep -Fq 'More window actions…' "$ROOT/Taskbar.qml"
grep -Fq 'required property int index' "$ROOT/Taskbar.qml"
grep -Fq 'KeyboardPanel {' "$ROOT/Taskbar.qml"
grep -Fq 'PanelKeyCatcher {' "$ROOT/Taskbar.qml"
grep -Fq 'onMoveRequested: function(dx, dy)' "$ROOT/Taskbar.qml"
grep -Fq 'onActivateRequested: root.activateMenuCursor()' "$ROOT/Taskbar.qml"
grep -Fq 'onCloseRequested: root.close()' "$ROOT/Taskbar.qml"
grep -Fq 'onTabRequested: function(direction)' "$ROOT/Taskbar.qml"
grep -Fq 'hasCursor: index === root.menuFocusIndex' "$ROOT/Taskbar.qml"
grep -Fq 'Accessible.role: Accessible.MenuItem' "$ROOT/Taskbar.qml"
grep -Fq 'Accessible.onPressAction' "$ROOT/Taskbar.qml"
grep -Fq 'Accessible.role: Accessible.Button' "$ROOT/qml/WindowButton.qml"
grep -Fq 'Keys.onReturnPressed' "$ROOT/qml/WindowButton.qml"
grep -Fq 'Qt.Key_Menu' "$ROOT/qml/WindowButton.qml"
grep -Fq 'Qt.Key_F10' "$ROOT/qml/WindowButton.qml"
grep -Fq 'Style.focusFillFor' "$ROOT/qml/WindowButton.qml"
grep -Fq 'registerClickTarget(root)' "$ROOT/qml/WindowButton.qml"
grep -Fq 'unregisterClickTarget(root)' "$ROOT/qml/WindowButton.qml"
grep -Fq 'function triggerPress(button)' "$ROOT/qml/WindowButton.qml"
grep -Fq 'property bool motionEnabled' "$ROOT/qml/WindowButton.qml" || grep -Fq 'readonly property bool motionEnabled' "$ROOT/qml/WindowButton.qml"
grep -Fq 'enabled: root.motionEnabled' "$ROOT/qml/WindowButton.qml"
! grep -Fq 'Behavior on width' "$ROOT/qml/WindowButton.qml"
! grep -Fq 'Behavior on height' "$ROOT/qml/WindowButton.qml"
grep -Fq 'backend to `0.7.0` and protocol `4`' "$ROOT/CHANGELOG.md"


# 0.9.0 Omarchy-native launcher/scratchpad integration.
grep -Fq 'Open new window' "$ROOT/Taskbar.qml"
grep -Fq 'action: "launch-app"' "$ROOT/Taskbar.qml"
grep -Fq 'function launchApplication(desktopId, appName)' "$ROOT/TaskbarService.qml"
grep -Fq 'shell.appLibrary.launch(id, String(appName || id))' "$ROOT/TaskbarService.qml"
grep -Fq 'argument: "special:scratchpad"' "$ROOT/Taskbar.qml"
grep -Fq 'Scratchpad' "$ROOT/qml/WindowButton.qml"

# 0.10.0 multi-monitor integration.
grep -Fq 'Move to monitor…' "$ROOT/Taskbar.qml"
grep -Fq 'function monitorRows()' "$ROOT/Taskbar.qml"
grep -Fq 'Hyprland.monitors.values' "$ROOT/Taskbar.qml"
grep -Fq 'action: "move-monitor"' "$ROOT/Taskbar.qml"
grep -Fq 'required monitorId' "$ROOT/Taskbar.qml"
! grep -Fq 'required property int monitorId' "$ROOT/Taskbar.qml"
grep -Fq 'property int monitorId: -1' "$ROOT/qml/WindowButton.qml"
grep -Fq 'Monitor " + root.monitorName' "$ROOT/qml/WindowButton.qml"
grep -Fq '"move-monitor" => {' "$ROOT/backend/src/hypr.rs"
grep -Fq 'monitor = {}, follow = false' "$ROOT/backend/src/hypr.rs"


# 0.11.0 AppLibrary-only pinned launcher shelf.
test -f "$ROOT/qml/PinnedLauncher.qml"
grep -Fq 'readonly property string pinsPath:' "$ROOT/TaskbarService.qml"
grep -Fq 'property alias pinnedLaunchers: pinnedLauncherModel' "$ROOT/TaskbarService.qml"
grep -Fq 'atomicWrites: true' "$ROOT/TaskbarService.qml"
grep -Fq 'function pinApplication(desktopId)' "$ROOT/TaskbarService.qml"
grep -Fq 'function unpinApplication(desktopId)' "$ROOT/TaskbarService.qml"
grep -Fq 'function movePinnedApplication(desktopId, delta)' "$ROOT/TaskbarService.qml"
grep -Fq 'shell.appLibrary.launch(id, String(appName || id))' "$ROOT/TaskbarService.qml"
grep -Fq 'delegate: PinnedLauncher {' "$ROOT/Taskbar.qml"
grep -Fq 'Pin to taskbar' "$ROOT/Taskbar.qml"
grep -Fq 'Unpin from taskbar' "$ROOT/Taskbar.qml"
grep -Fq 'Move pin left' "$ROOT/Taskbar.qml"
grep -Fq 'Move pin right' "$ROOT/Taskbar.qml"
grep -Fq 'property bool taskbarPinned: false' "$ROOT/qml/WindowButton.qml"
grep -Fq 'Pinned to taskbar' "$ROOT/qml/WindowButton.qml"
grep -Fq 'Accessible.role: Accessible.Button' "$ROOT/qml/PinnedLauncher.qml"
grep -Fq 'registerClickTarget(root)' "$ROOT/qml/PinnedLauncher.qml"
! grep -R --exclude-dir=.git -E 'gtk-launch|desktop-file-validate|/usr/share/applications' "$ROOT/qml/PinnedLauncher.qml" "$ROOT/Taskbar.qml" "$ROOT/TaskbarService.qml" >/dev/null

# 0.12.2 delayed single-frame window previews + runtime regression fixes.
test -f "$ROOT/qml/WindowPreview.qml"
grep -Fq 'ScreencopyView {' "$ROOT/qml/WindowPreview.qml"
grep -Fq 'paintCursor: false' "$ROOT/qml/WindowPreview.qml"
! grep -Fq 'paintCursors: false' "$ROOT/qml/WindowPreview.qml"
grep -Fq 'captureSource: root.visible ? root.captureSource : null' "$ROOT/qml/WindowPreview.qml"
grep -Fq 'live: false' "$ROOT/qml/WindowPreview.qml"
grep -Fq 'interval: 320' "$ROOT/Taskbar.qml"
grep -Fq 'interval: 160' "$ROOT/Taskbar.qml"
grep -Fq 'readonly property QtObject previewSource:' "$ROOT/qml/WindowButton.qml"
grep -Fq 'replace(/^0x/, "")' "$ROOT/qml/WindowButton.qml"
grep -Fq 'owner: previewCoordinator' "$ROOT/Taskbar.qml"
grep -Fq 'onPreviewEntered: root.requestWindowPreview(windowButton)' "$ROOT/Taskbar.qml"
! grep -Fq 'live: true' "$ROOT/qml/WindowPreview.qml"
grep -Fq 'property Item previewAnchor: null' "$ROOT/Taskbar.qml"
grep -Fq 'property QtObject previewCaptureSource: null' "$ROOT/Taskbar.qml"
grep -Fq 'id: previewAnchorProxy' "$ROOT/Taskbar.qml"
grep -Fq 'function openPendingWindowPreview()' "$ROOT/Taskbar.qml"
grep -Fq 'function closeForPopoutSwitch() { root.cancelWindowPreview() }' "$ROOT/Taskbar.qml"
grep -Fq 'Quickshell Screencopy' "$ROOT/scripts/doctor.sh"
grep -Fq 'signal previewEntered()' "$ROOT/qml/WindowButton.qml"
[[ $(grep -Fc 'WindowPreview {' "$ROOT/Taskbar.qml") -eq 1 ]]
! grep -Fq 'WindowPreview {' "$ROOT/qml/WindowButton.qml"

# 0.13.1 intentionally keeps the 0.12.2 per-window UX; rejected 0.13.0
# multi-instance clustering/badges/instance submenu must not return.
! grep -R --exclude-dir=.git -Fq 'instanceCount' "$ROOT/Taskbar.qml" "$ROOT/TaskbarService.qml" "$ROOT/qml/WindowButton.qml"
! grep -R --exclude-dir=.git -Fq 'instanceIndex' "$ROOT/Taskbar.qml" "$ROOT/TaskbarService.qml" "$ROOT/qml/WindowButton.qml"
! grep -Fq 'App windows · ' "$ROOT/Taskbar.qml"
! grep -Fq 'instances-menu' "$ROOT/Taskbar.qml"

# 0.13.3 Show Desktop simplification + Lucide control/action iconography.
grep -Fq 'Right click: Dwindle ↔ Scrolling' "$ROOT/Taskbar.qml"
grep -Fq 'button === Qt.RightButton) root.toggleWorkspaceLayout()' "$ROOT/Taskbar.qml"
! grep -Fq 'openDesktopMenu' "$ROOT/Taskbar.qml"
! grep -Fq 'Middle click: Recovery' "$ROOT/Taskbar.qml"
! grep -Fq 'menuKind === "desktop"' "$ROOT/Taskbar.qml"
grep -Fq 'root.bar.run("omarchy-hyprland-workspace-layout-toggle")' "$ROOT/Taskbar.qml"
grep -Fq 'function toggleWorkspaceLayout()' "$ROOT/Taskbar.qml"
test -f "$ROOT/qml/LucideIcon.qml"
test -f "$ROOT/icons/lucide/LICENSE"
grep -Fq 'import QtQuick.Effects' "$ROOT/qml/LucideIcon.qml"
grep -Fq 'colorization: 1.0' "$ROOT/qml/LucideIcon.qml"
true # 0.13.7 restores native Show Desktop glyph
grep -Fq 'function menuIconFor(item)' "$ROOT/Taskbar.qml"
grep -Fq 'function menuActionHasSubmenu(item)' "$ROOT/Taskbar.qml"
grep -Fq 'name: root.menuIconFor(actionButton.modelData)' "$ROOT/Taskbar.qml"
grep -Fq 'name: "chevron-right"' "$ROOT/Taskbar.qml"
for icon in arrow-left arrow-right chevron-right square-plus pin pin-off minus maximize-2 minimize-2 picture-in-picture-2 move-right layout-grid monitor monitor-down ellipsis x square-arrow-out-up-right panels-top-left scaling group square-dashed undo-2 triangle-alert; do
  test -f "$ROOT/icons/lucide/$icon.svg"
done

printf 'static smoke ok\n'

# 0.13.4 theme-native Lucide colors + visible right-click affordance.
grep -Fq 'property color color: Color.foreground' "$ROOT/qml/LucideIcon.qml"
grep -Fq 'name: "mouse-pointer-click"' "$ROOT/Taskbar.qml"
true # superseded by 0.13.7 native Show Desktop foreground
grep -Fq 'foreground: modelData.action === "close" ? Color.urgent : Color.menu.text' "$ROOT/Taskbar.qml"
grep -Fq 'Color.menu.selectedText' "$ROOT/Taskbar.qml"
grep -Fq 'Color.menu.selectedBorder' "$ROOT/Taskbar.qml"
! grep -Fq 'property color color: "white"' "$ROOT/qml/LucideIcon.qml"

# 0.13.5 Show Desktop affordance follows the legacy WidgetButton theme contract.
true # 0.13.7 Show Desktop no longer uses an active accent
true # superseded by 0.13.7 native Show Desktop foreground
! grep -A18 -F 'name: "mouse-pointer-click"' "$ROOT/Taskbar.qml" | grep -Fq 'color: Color.accent'

# 0.13.6 Lucide tint regression: black `currentColor` SVG strokes must be
# lifted to white before MultiEffect colorization, exactly as Qt's own SVG tint
# example does. Theme role selection remains owned by the calling controls.
grep -Fq 'brightness: 1.0' "$ROOT/qml/LucideIcon.qml"
grep -Fq 'colorization: 1.0' "$ROOT/qml/LucideIcon.qml"
grep -Fq 'colorizationColor: root.color' "$ROOT/qml/LucideIcon.qml"
grep -Fq 'foreground: bar ? bar.barForeground : Color.foreground' "$ROOT/README.md" || true

# 0.13.7 Show Desktop uses Omarchy's native bar-glyph color/alignment contract.
grep -Fq 'text: "󰍹"' "$ROOT/Taskbar.qml"
grep -Fq 'useActiveColor: false' "$ROOT/Taskbar.qml"
grep -A18 -F 'name: "mouse-pointer-click"' "$ROOT/Taskbar.qml" | grep -Fq 'color: desktopButton.foreground'
! grep -A45 -F 'id: desktopButton' "$ROOT/Taskbar.qml" | grep -Fq 'Color.accent'
! grep -A45 -F 'id: desktopButton' "$ROOT/Taskbar.qml" | grep -Fq 'name: "monitor-down"'
