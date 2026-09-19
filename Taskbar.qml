pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "qml"

BarWidget {
  id: root

  moduleName: "dev.becerromarchy.workspace-taskbar"

  property var manifest: null
  property string menuKind: ""
  property string menuPage: "main"
  property var menuTarget: ({})
  property bool menuOpen: false
  property int menuFocusIndex: -1
  property bool previewOpen: false
  property Item previewAnchor: null
  property QtObject previewCaptureSource: null
  property string previewTitle: ""
  property string previewAppName: ""
  property string previewIconSource: ""
  property string previewMetadata: ""
  property bool previewMatched: false

  readonly property var pluginShell: root.bar && root.bar.shell ? root.bar.shell : null
  readonly property var service: root.pluginShell ? root.pluginShell.serviceFor(root.moduleName) : null
  readonly property bool degraded: !root.service || !root.service.appLibraryHealthy || !root.service.backendHealthy || !root.service.protocolCompatible
  readonly property bool menuTargetMinimized: root.service && root.menuTarget.address
    ? root.service.isMinimized(root.menuTarget.address)
    : !!root.menuTarget.minimized

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  onMenuOpenChanged: {
    root.menuFocusIndex = -1
    if (root.menuOpen) {
      root.cancelWindowPreview()
      root.scheduleMenuFocus()
    }
  }

  onMenuPageChanged: {
    root.menuFocusIndex = -1
    if (root.menuOpen) root.scheduleMenuFocus()
  }

  Item {
    id: menuAnchorProxy

    width: 1
    height: 1
  }

  Item {
    id: previewAnchorProxy

    width: 1
    height: 1
  }

  QtObject {
    id: previewCoordinator

    function close() { root.cancelWindowPreview() }
    function closeForPopoutSwitch() { root.cancelWindowPreview() }
  }

  RowLayout {
    id: row

    anchors.fill: parent
    spacing: 0

    BarIconButton {
      id: degradedButton

      visible: root.degraded
      bar: root.bar
      active: true
      activeColor: root.bar ? root.bar.urgent : Color.urgent
      slotSize: Math.max(14, Math.round((root.bar ? root.bar.barSize : Style.bar.sizeHorizontal) * 0.62))
      opticalSize: Math.max(13, Math.round(slotSize * 0.66))
      iconComponent: Component {
        LucideIcon {
          name: "triangle-alert"
          iconSize: Math.min(width, height)
          color: degradedButton.activeColor
        }
      }
      tooltipText: {
        if (!root.service) return "Workspace Taskbar service unavailable"
        const lines = []
        if (!root.service.appLibraryHealthy) lines.push(root.service.appLibraryDiagnostic)
        if (!root.service.backendHealthy) lines.push("Workspace Taskbar backend unavailable")
        if (!root.service.protocolCompatible) lines.push("Workspace Taskbar backend protocol mismatch")
        if (root.service.lastError) lines.push(root.service.lastError)
        return lines.join("\n")
      }
      onPressed: function() {}
    }

    Repeater {
      model: root.degraded || !root.service ? null : root.service.pinnedLaunchers

      delegate: PinnedLauncher {
        id: pinnedLauncher

        required desktopId
        required appName
        required iconSource
        required pinIndex

        bar: root.bar
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight

        onClicked: function(button) {
          if (!root.service) return
          if (button === Qt.RightButton) {
            root.openLauncherMenu(pinnedLauncher, {
              desktopId: pinnedLauncher.desktopId,
              appName: pinnedLauncher.appName,
              pinIndex: pinnedLauncher.pinIndex
            })
          } else if (button === Qt.LeftButton || button === Qt.MiddleButton) {
            root.service.launchApplication(pinnedLauncher.desktopId, pinnedLauncher.appName)
          }
        }
      }
    }

    Rectangle {
      visible: !root.degraded && !!root.service
        && root.service.pinnedLaunchers.count > 0 && root.service.windows.count > 0
      Layout.preferredWidth: root.bar && root.bar.vertical ? Math.max(8, root.bar.barSize * 0.28) : Style.spacing.hairline
      Layout.preferredHeight: root.bar && root.bar.vertical ? Style.spacing.hairline : Math.max(8, root.bar.barSize * 0.28)
      Layout.alignment: Qt.AlignCenter
      radius: Style.spacing.hairline
      color: Util.alpha(root.bar ? root.bar.barForeground : Color.foreground, 0.18)
    }

    Repeater {
      model: root.degraded || !root.service ? null : root.service.windows

      delegate: WindowButton {
        id: windowButton

        required address
        required title
        required appName
        required iconSource
        required active
        required urgent
        required minimized
        required busy
        required matched
        required property int workspace
        required workspaceName
        required specialWorkspace
        required monitorId
        required property string desktopId
        required floating
        required pinned
        required pseudo
        required fullscreen
        required fullscreenClient
        required groupedCount
        required popped
        required taskbarPinned

        bar: root.bar
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight

        onPreviewEntered: root.requestWindowPreview(windowButton)
        onPreviewExited: root.releaseWindowPreview(windowButton)

        onClicked: function(button) {
          if (!root.service) return

          if (button === Qt.RightButton) {
            root.openWindowMenu(windowButton, {
              address: windowButton.address,
              title: windowButton.title,
              desktopId: windowButton.desktopId,
              appName: windowButton.appName,
              workspace: windowButton.workspace,
              workspaceName: windowButton.workspaceName,
              specialWorkspace: windowButton.specialWorkspace,
              monitorId: windowButton.monitorId,
              minimized: windowButton.minimized,
              floating: windowButton.floating,
              pinned: windowButton.pinned,
              pseudo: windowButton.pseudo,
              fullscreen: windowButton.fullscreen,
              fullscreenClient: windowButton.fullscreenClient,
              groupedCount: windowButton.groupedCount,
              popped: windowButton.popped,
              taskbarPinned: windowButton.taskbarPinned
            })
          } else if (button === Qt.MiddleButton) {
            root.service.closeWindow(windowButton.address)
          } else if (button === Qt.LeftButton) {
            root.service.activateWindow(windowButton.address)
          }
        }
      }
    }

    Rectangle {
      visible: !root.degraded && !!root.service
        && (root.service.windows.count > 0 || root.service.pinnedLaunchers.count > 0)
      Layout.preferredWidth: root.bar && root.bar.vertical ? Math.max(8, root.bar.barSize * 0.38) : Style.spacing.hairline
      Layout.preferredHeight: root.bar && root.bar.vertical ? Style.spacing.hairline : Math.max(8, root.bar.barSize * 0.38)
      Layout.alignment: Qt.AlignCenter
      radius: Style.spacing.hairline
      color: Util.alpha(root.bar ? root.bar.barForeground : Color.foreground, 0.25)
    }

    BarIconButton {
      id: desktopButton

      visible: !root.degraded && !!root.service
      bar: root.bar
      // Use the same native bar glyph path as Omarchy's built-in icons. This
      // keeps optical centering and color identical to ordinary bar controls:
      // WidgetButton.foreground -> bar.barForeground -> Color.bar.text.
      text: "󰍹"
      useActiveColor: false
      slotSize: Math.max(14, Math.round((root.bar ? root.bar.barSize : Style.bar.sizeHorizontal) * 0.62))
      opticalSize: Math.max(13, Math.round(slotSize * 0.66))

      // The secondary pointer-action cue must not recolor the main control or
      // use the accent role. It inherits the exact same bar foreground and is
      // parked in the slot corner so it does not change the glyph's optical
      // center.
      LucideIcon {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Math.max(1, Math.round(parent.width * 0.02))
        anchors.topMargin: Math.max(1, Math.round(parent.height * 0.05))
        width: Math.max(5, Math.round(parent.width * 0.34))
        height: width
        name: "mouse-pointer-click"
        iconSize: width
        color: desktopButton.foreground
        opacity: 0.72
      }

      tooltipText: "Show desktop\nRight click: Dwindle ↔ Scrolling"
      onPressed: function(button) {
        if (!root.service) return
        if (button === Qt.RightButton) root.toggleWorkspaceLayout()
        else if (button === Qt.LeftButton) root.service.showDesktop()
      }
    }
  }

  WindowPreview {
    id: windowPreview

    anchorItem: previewAnchorProxy
    bar: root.bar
    owner: previewCoordinator
    captureSource: root.previewCaptureSource
    title: root.previewTitle
    appName: root.previewAppName
    iconSource: root.previewIconSource
    metadata: root.previewMetadata
    matched: root.previewMatched
    open: root.previewOpen

    onContainsMouseChanged: {
      if (windowPreview.containsMouse) previewCloseTimer.stop()
      else if (root.previewOpen) previewCloseTimer.restart()
    }
  }

  Timer {
    id: previewOpenTimer

    interval: 320
    onTriggered: root.openPendingWindowPreview()
  }

  Timer {
    id: previewCloseTimer

    interval: 160
    onTriggered: {
      if (!windowPreview.containsMouse) root.cancelWindowPreview()
    }
  }

  // Omarchy's KeyboardPanel owns real layer-shell keyboard focus. PopupCard
  // is an xdg-popup and cannot reliably receive arrow keys immediately after
  // a bar right-click, which is exactly the failure this menu must avoid.
  KeyboardPanel {
    id: windowMenu

    anchorItem: menuAnchorProxy
    bar: root.bar
    owner: root
    open: root.menuOpen
    focusTarget: menuKeyCatcher
    contentWidth: windowMenu.fittedContentWidth(Style.space(270))
    contentHeight: windowMenu.fittedContentHeight(menuColumn.implicitHeight)

    PanelKeyCatcher {
      id: menuKeyCatcher

      anchors.fill: parent
      onMoveRequested: function(dx, dy) { root.moveMenuCursor(dx, dy) }
      onActivateRequested: root.activateMenuCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.focusMenuDelta(direction) }

      Column {
        id: menuColumn

        anchors.fill: parent
        spacing: Style.spacing.xs

        Text {
          width: parent.width
          text: root.menuKind === "launcher"
            ? String(root.menuTarget.appName || "Pinned launcher")
            : (root.menuPage === "workspace"
                ? "Move to workspace"
                : (root.menuPage === "monitor"
                    ? "Move to monitor"
                    : (root.menuPage === "more"
                        ? "More window actions"
                        : String(root.menuTarget.title || root.menuTarget.appName || "Window"))))
          color: Color.menu.text
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          font.weight: Font.Medium
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: root.menuKind === "launcher" || !!root.menuTarget.appName
          text: {
            if (root.menuKind === "launcher") return "Pinned launcher · not running"
            const workspace = root.displayWorkspace(root.menuTarget.workspaceName, root.menuTarget.workspace)
            if (root.menuPage === "workspace")
              return String(root.menuTarget.appName || "Window") + (workspace ? " · from " + workspace : "")
            if (root.menuPage === "more")
              return String(root.menuTarget.appName || "Window") + (workspace ? " · " + workspace : "")
            return String(root.menuTarget.appName || "") + (workspace ? " · " + workspace : "")
          }
          color: Color.menu.text
          opacity: 0.60
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        Repeater {
          id: menuRepeater

          model: root.menuActions()

          delegate: Button {
            id: actionButton

            required property int index
            required property var modelData

            width: menuColumn.width
            implicitHeight: Math.max(Style.space(30), actionLabel.implicitHeight + verticalPadding * 2)
            text: ""
            enabled: modelData.enabled !== false
            opacity: enabled ? 1.0 : 0.45
            leftAlign: false
            focusable: false
            hasCursor: index === root.menuFocusIndex
            foreground: modelData.action === "close" ? Color.urgent : Color.menu.text
            accent: modelData.action === "close" ? Color.urgent : Color.menu.selectedBorder
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            horizontalPadding: Style.spacing.rowPaddingX
            verticalPadding: Style.spacing.controlPaddingY

            LucideIcon {
              id: actionIcon

              anchors.left: parent.left
              anchors.leftMargin: actionButton.horizontalPadding
              anchors.verticalCenter: parent.verticalCenter
              name: root.menuIconFor(actionButton.modelData)
              iconSize: Style.font.body
              color: actionButton.modelData.action === "close"
                ? Color.urgent
                : (actionButton.hasCursor ? Color.menu.selectedText : Color.menu.text)
              opacity: 0.88
            }

            Text {
              id: actionLabel

              anchors.left: actionIcon.right
              anchors.leftMargin: Style.spacing.controlGap
              anchors.right: submenuChevron.visible ? submenuChevron.left : parent.right
              anchors.rightMargin: submenuChevron.visible ? Style.spacing.controlGap : actionButton.horizontalPadding
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: String(actionButton.modelData.label || "")
              color: actionButton.modelData.action === "close"
                ? Color.urgent
                : (actionButton.hasCursor ? Color.menu.selectedText : Color.menu.text)
              font.family: actionButton.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            LucideIcon {
              id: submenuChevron

              visible: root.menuActionHasSubmenu(actionButton.modelData)
              anchors.right: parent.right
              anchors.rightMargin: actionButton.horizontalPadding
              anchors.verticalCenter: parent.verticalCenter
              name: "chevron-right"
              iconSize: Style.font.bodySmall
              color: actionButton.hasCursor ? Color.menu.selectedText : Color.menu.text
              opacity: 0.65
            }

            Accessible.role: Accessible.MenuItem
            Accessible.name: modelData.label
            Accessible.focusable: enabled
            Accessible.onPressAction: if (enabled) root.runMenuAction(modelData)

            onHovered: function(isHovered) {
              if (isHovered && enabled) root.menuFocusIndex = index
            }
            onClicked: root.runMenuAction(modelData)
          }
        }
      }
    }
  }

  function capturePreviewAnchor(anchor) {
    if (!anchor) return
    const point = anchor.mapToItem(root, 0, 0)
    previewAnchorProxy.x = Math.round(point.x)
    previewAnchorProxy.y = Math.round(point.y)
    previewAnchorProxy.width = Math.max(1, Math.round(anchor.width))
    previewAnchorProxy.height = Math.max(1, Math.round(anchor.height))
  }

  function requestWindowPreview(anchor) {
    previewCloseTimer.stop()
    if (root.menuOpen || !anchor || anchor.busy || !anchor.previewSource) return

    if (root.previewOpen && root.previewAnchor === anchor) return
    if (root.previewOpen) root.previewOpen = false

    root.previewAnchor = anchor
    previewOpenTimer.restart()
  }

  function releaseWindowPreview(anchor) {
    if (root.previewAnchor !== anchor) return
    previewOpenTimer.stop()
    if (root.previewOpen) previewCloseTimer.restart()
    else root.previewAnchor = null
  }

  function openPendingWindowPreview() {
    const anchor = root.previewAnchor
    if (root.menuOpen || !anchor || anchor.busy || !anchor.previewSource) return

    root.capturePreviewAnchor(anchor)
    root.previewCaptureSource = anchor.previewSource
    root.previewTitle = String(anchor.title || "")
    root.previewAppName = String(anchor.appName || "")
    root.previewIconSource = String(anchor.iconSource || "")
    root.previewMetadata = String(anchor.previewMetadata || "")
    root.previewMatched = !!anchor.matched
    root.previewOpen = true
    if (root.bar) root.bar.hideTooltip(anchor)
  }

  function cancelWindowPreview() {
    previewOpenTimer.stop()
    previewCloseTimer.stop()
    root.previewOpen = false
    root.previewAnchor = null
  }

  function close() {
    root.menuOpen = false
    root.menuKind = ""
    root.menuPage = "main"
    root.menuFocusIndex = -1
  }

  function captureMenuAnchor(anchor) {
    if (!anchor) return
    root.cancelWindowPreview()
    const point = anchor.mapToItem(root, 0, 0)
    menuAnchorProxy.x = Math.round(point.x)
    menuAnchorProxy.y = Math.round(point.y)
    menuAnchorProxy.width = Math.max(1, Math.round(anchor.width))
    menuAnchorProxy.height = Math.max(1, Math.round(anchor.height))
    if (root.bar) root.bar.hideTooltip(anchor)
  }

  function openWindowMenu(anchor, target) {
    root.menuOpen = false
    root.captureMenuAnchor(anchor)
    Hyprland.refreshMonitors()
    root.menuKind = "window"
    root.menuPage = "main"
    root.menuTarget = target || ({})
    Qt.callLater(function() { root.menuOpen = true })
  }

  function openLauncherMenu(anchor, target) {
    root.menuOpen = false
    root.captureMenuAnchor(anchor)
    root.menuKind = "launcher"
    root.menuPage = "main"
    root.menuTarget = target || ({})
    Qt.callLater(function() { root.menuOpen = true })
  }

  function toggleWorkspaceLayout() {
    if (!root.bar) return
    root.cancelWindowPreview()
    root.close()
    root.bar.run("omarchy-hyprland-workspace-layout-toggle")
  }

  function scheduleMenuFocus() {
    Qt.callLater(function() { root.focusFirstMenuAction() })
  }

  function focusFirstMenuAction() {
    if (!root.menuOpen) return
    for (let i = 0; i < menuRepeater.count; i++) {
      const item = menuRepeater.itemAt(i)
      if (!item || !item.enabled) continue
      root.menuFocusIndex = i
      return
    }
    root.menuFocusIndex = -1
  }

  function focusMenuDelta(delta) {
    if (!root.menuOpen || menuRepeater.count <= 0) return
    const count = menuRepeater.count
    let start = root.menuFocusIndex
    if (start < 0 || start >= count) start = delta >= 0 ? -1 : 0

    for (let step = 1; step <= count; step++) {
      const index = (start + delta * step + count * 2) % count
      const item = menuRepeater.itemAt(index)
      if (!item || !item.enabled) continue
      root.menuFocusIndex = index
      return
    }
  }

  function currentMenuAction() {
    if (root.menuFocusIndex < 0 || root.menuFocusIndex >= menuRepeater.count) return null
    const item = menuRepeater.itemAt(root.menuFocusIndex)
    return item && item.enabled ? item.modelData : null
  }

  function activateMenuCursor() {
    const action = root.currentMenuAction()
    if (action) root.runMenuAction(action)
  }

  function moveMenuCursor(dx, dy) {
    if (dy !== 0) {
      root.focusMenuDelta(dy > 0 ? 1 : -1)
      return
    }

    if (dx < 0) {
      if (root.menuPage !== "main") root.menuPage = "main"
      else root.close()
      return
    }

    if (dx > 0) {
      const action = root.currentMenuAction()
      if (!action) return
      const name = String(action.action || "")
      if (name === "workspace-menu" || name === "monitor-menu" || name === "more-menu") root.runMenuAction(action)
    }
  }

  function menuActionHasSubmenu(item) {
    const name = String(item && item.action || "")
    return name === "workspace-menu" || name === "monitor-menu" || name === "more-menu"
  }

  function menuIconFor(item) {
    const data = item || ({})
    const name = String(data.action || "")
    const label = String(data.label || "")
    const argument = String(data.argument || "")

    if (name === "menu-back") return "arrow-left"
    if (name === "launch-app") return label.indexOf("new") !== -1 ? "square-plus" : "square-arrow-out-up-right"
    if (name === "pin-app") return "pin"
    if (name === "unpin-app") return "pin-off"
    if (name === "pin-move") return Number(argument || 0) < 0 ? "arrow-left" : "arrow-right"
    if (name === "minimize") return "minus"
    if (name === "restore") return "undo-2"
    if (name === "maximized-toggle") return label.indexOf("Restore") === 0 ? "minimize-2" : "maximize-2"
    if (name === "pop-toggle") return "picture-in-picture-2"
    if (name === "workspace-menu") return "layout-grid"
    if (name === "monitor-menu" || name === "move-monitor") return "monitor"
    if (name === "move-workspace") return argument === "special:scratchpad" ? "square-dashed" : "move-right"
    if (name === "more-menu") return "ellipsis"
    if (name === "float-toggle") return label.indexOf("Tile") === 0 ? "panels-top-left" : "square-arrow-out-up-right"
    if (name === "fullscreen-toggle") return label.indexOf("Exit") === 0 ? "minimize-2" : "maximize-2"
    if (name === "pseudo-toggle") return "scaling"
    if (name === "group-toggle") return "group"
    if (name === "float-pin-toggle") return label.indexOf("Unpin") === 0 ? "pin-off" : "pin"
    if (name === "close") return "x"
    return "ellipsis"
  }

  function displayWorkspace(workspaceName, workspaceId) {
    const name = String(workspaceName || "")
    if (name === "special:scratchpad") return "Scratchpad"
    if (name.indexOf("special:") === 0) return "Special · " + name.slice("special:".length)
    if (name) return name
    const id = Number(workspaceId || 0)
    return id > 0 ? (id === 10 ? "0" : String(id)) : ""
  }

  function monitorRows() {
    const rows = []
    const values = Hyprland.monitors ? Hyprland.monitors.values : []
    for (let i = 0; i < values.length; i++) {
      const monitor = values[i]
      if (!monitor || !monitor.name) continue
      rows.push({
        id: Number(monitor.id),
        name: String(monitor.name),
        description: String(monitor.description || ""),
        focused: !!monitor.focused
      })
    }
    rows.sort(function(left, right) { return left.id - right.id })
    return rows
  }

  function monitorCount() {
    return root.monitorRows().length
  }

  function monitorMenuActions() {
    const actions = [{ label: "Back", action: "menu-back" }]
    const current = Number(root.menuTarget.monitorId)
    const monitors = root.monitorRows()
    for (let i = 0; i < monitors.length; i++) {
      const monitor = monitors[i]
      const isCurrent = monitor.id === current
      actions.push({
        label: monitor.name + (isCurrent ? " · current" : ""),
        action: "move-monitor",
        argument: monitor.name,
        enabled: !isCurrent
      })
    }
    return actions
  }

  function workspaceIds() {
    // Match Omarchy 4.0.4's built-in workspace widget: always expose 1-5,
    // then include any live positive workspace up to 10.
    const ids = [1, 2, 3, 4, 5]
    const values = Hyprland.workspaces.values
    for (let i = 0; i < values.length; i++) {
      const id = Number(values[i].id)
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusedWorkspaceId() {
    return Hyprland.focusedWorkspace ? Number(Hyprland.focusedWorkspace.id || 0) : 0
  }

  function workspaceMenuActions() {
    const actions = [{ label: "Back", action: "menu-back" }]
    const current = Number(root.menuTarget.workspace || 0)
    const currentName = String(root.menuTarget.workspaceName || "")
    const ids = root.workspaceIds()
    for (let i = 0; i < ids.length; i++) {
      const id = ids[i]
      actions.push({
        label: "Workspace " + (id === 10 ? "0" : String(id)) + (id === current && currentName.indexOf("special:") !== 0 ? " · current" : ""),
        action: "move-workspace",
        argument: String(id),
        enabled: !(id === current && currentName.indexOf("special:") !== 0)
      })
    }
    actions.push({
      label: "Scratchpad" + (currentName === "special:scratchpad" ? " · current" : ""),
      action: "move-workspace",
      argument: "special:scratchpad",
      enabled: currentName !== "special:scratchpad"
    })
    return actions
  }

  function moreMenuActions() {
    const actions = [{ label: "Back", action: "menu-back" }]
    actions.push({ label: root.menuTarget.floating ? "Tile window" : "Float window", action: "float-toggle" })
    actions.push({
      label: Number(root.menuTarget.fullscreen || 0) === 2 || Number(root.menuTarget.fullscreenClient || 0) === 2
        ? "Exit fullscreen"
        : "Enter fullscreen",
      action: "fullscreen-toggle"
    })
    actions.push({ label: root.menuTarget.pseudo ? "Disable pseudo" : "Enable pseudo", action: "pseudo-toggle" })
    actions.push({
      label: Number(root.menuTarget.groupedCount || 0) > 0
        ? "Toggle window group · " + String(root.menuTarget.groupedCount)
        : "Toggle window group",
      action: "group-toggle"
    })
    actions.push({ label: root.menuTarget.pinned ? "Unpin + tile" : "Float + pin", action: "float-pin-toggle" })
    return actions
  }

  function launcherMenuActions() {
    const id = String(root.menuTarget.desktopId || "")
    const index = root.service ? root.service.pinIndex(id) : -1
    const count = root.service ? root.service.pinnedDesktopIds.length : 0
    return [
      { label: "Open", action: "launch-app" },
      { label: "Move pin left", action: "pin-move", argument: "-1", enabled: index > 0 },
      { label: "Move pin right", action: "pin-move", argument: "1", enabled: index >= 0 && index < count - 1 },
      { label: "Unpin from taskbar", action: "unpin-app" }
    ]
  }

  function windowMenuActions() {
    const here = root.focusedWorkspaceId()
    const current = Number(root.menuTarget.workspace || 0)

    if (root.menuTargetMinimized) {
      const minimizedActions = []
      if (root.menuTarget.desktopId) {
        minimizedActions.push({ label: "Open new window", action: "launch-app" })
        minimizedActions.push({
          label: root.service && root.service.isApplicationPinned(root.menuTarget.desktopId)
            ? "Unpin from taskbar"
            : "Pin to taskbar",
          action: root.service && root.service.isApplicationPinned(root.menuTarget.desktopId) ? "unpin-app" : "pin-app"
        })
      }
      minimizedActions.push({ label: "Restore", action: "restore" })
      if (here > 0 && here !== current)
        minimizedActions.push({ label: "Move here · Workspace " + (here === 10 ? "0" : String(here)), action: "move-workspace", argument: String(here) })
      minimizedActions.push({ label: "Move to workspace…", action: "workspace-menu" })
      minimizedActions.push({ label: "Close", action: "close" })
      return minimizedActions
    }

    const maximized = Number(root.menuTarget.fullscreen || 0) === 1 || Number(root.menuTarget.fullscreenClient || 0) === 1
    const actions = []
    if (root.menuTarget.desktopId) {
      actions.push({ label: "Open new window", action: "launch-app" })
      actions.push({
        label: root.service && root.service.isApplicationPinned(root.menuTarget.desktopId)
          ? "Unpin from taskbar"
          : "Pin to taskbar",
        action: root.service && root.service.isApplicationPinned(root.menuTarget.desktopId) ? "unpin-app" : "pin-app"
      })
    }
    actions.push({ label: "Minimize", action: "minimize" })
    actions.push({ label: maximized ? "Restore size" : "Maximize", action: "maximized-toggle" })

    if (root.menuTarget.popped)
      actions.push({ label: "Return popped window", action: "pop-toggle" })
    else if (!root.menuTarget.floating && !root.menuTarget.pinned
        && Number(root.menuTarget.fullscreen || 0) === 0
        && Number(root.menuTarget.fullscreenClient || 0) === 0)
      actions.push({ label: "Pop out window", action: "pop-toggle" })

    if (here > 0 && here !== current)
      actions.push({ label: "Move here · Workspace " + (here === 10 ? "0" : String(here)), action: "move-workspace", argument: String(here) })

    actions.push({ label: "Move to workspace…", action: "workspace-menu" })
    if (root.monitorCount() > 1) actions.push({ label: "Move to monitor…", action: "monitor-menu" })
    if (!root.menuTarget.popped) actions.push({ label: "More window actions…", action: "more-menu" })
    actions.push({ label: "Close", action: "close" })
    return actions
  }

  function menuActions() {
    if (root.menuKind === "launcher") return root.launcherMenuActions()
    if (root.menuPage === "workspace") return root.workspaceMenuActions()
    if (root.menuPage === "monitor") return root.monitorMenuActions()
    if (root.menuPage === "more") return root.moreMenuActions()
    return root.windowMenuActions()
  }

  function runMenuAction(item) {
    if (!root.service) return
    const data = item || ({})
    const name = typeof data === "string" ? String(data) : String(data.action || "")
    const argument = typeof data === "string" ? "" : String(data.argument || "")

    if (name === "workspace-menu") {
      root.menuPage = "workspace"
      return
    }
    if (name === "monitor-menu") {
      root.menuPage = "monitor"
      return
    }
    if (name === "more-menu") {
      root.menuPage = "more"
      return
    }
    if (name === "menu-back") {
      root.menuPage = "main"
      return
    }

    if (root.menuKind === "launcher") {
      const desktopId = String(root.menuTarget.desktopId || "")
      if (name === "launch-app") root.service.launchApplication(desktopId, String(root.menuTarget.appName || ""))
      else if (name === "unpin-app") root.service.unpinApplication(desktopId)
      else if (name === "pin-move") root.service.movePinnedApplication(desktopId, Number(argument || 0))
      root.close()
      return
    }

    if (name === "launch-app") {
      root.service.launchApplication(String(root.menuTarget.desktopId || ""), String(root.menuTarget.appName || ""))
      root.close()
      return
    }

    if (name === "pin-app" || name === "unpin-app") {
      const desktopId = String(root.menuTarget.desktopId || "")
      if (name === "pin-app") root.service.pinApplication(desktopId)
      else root.service.unpinApplication(desktopId)
      root.close()
      return
    }

    if (!root.menuTarget.address) return
    root.service.menuAction(name, String(root.menuTarget.address), argument)
    root.close()
  }
}
