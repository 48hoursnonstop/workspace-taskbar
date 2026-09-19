pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "qml"

BarWidget {
  id: root

  moduleName: "workspace-taskbar"

  property var manifest: null
  readonly property bool menuOpen: root.service ? root.service.menuOpened : false
  property alias menuAnchor: menuAnchorProxy
  property bool tearingDown: false
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
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  onMenuOpenChanged: if (root.menuOpen) root.cancelWindowPreview()
  onServiceChanged: if (root.service && !root.service.menuHost) root.service.menuHost = root
  Component.onCompleted: if (root.service && !root.service.menuHost) root.service.menuHost = root
  Component.onDestruction: {
    root.tearingDown = true
    if (root.service && root.service.menuHost === root) root.service.menuHost = null
  }
  Connections {
    target: root.service
    function onMenuHostChanged() {
      if (!root.tearingDown && root.bar && root.service && !root.service.menuHost)
        root.service.menuHost = root
    }
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
    if (root.pluginShell) root.pluginShell.hide(root.moduleName)
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

  function summonMenu(anchor, target, kind) {
    if (!root.service || !root.pluginShell) return
    root.captureMenuAnchor(anchor)
    root.service.menuHost = root
    const payload = Object.assign({}, target, {kind: kind})
    root.pluginShell.summon(root.moduleName, JSON.stringify(payload))
  }

  function openWindowMenu(anchor, target) { root.summonMenu(anchor, target, "window") }
  function openLauncherMenu(anchor, target) { root.summonMenu(anchor, target, "launcher") }

  function toggleWorkspaceLayout() {
    if (!root.bar) return
    root.cancelWindowPreview()
    root.close()
    root.bar.run("omarchy-hyprland-workspace-layout-toggle")
  }

}
