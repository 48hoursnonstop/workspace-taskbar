import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons

Item {
  id: root

  property var bar: null
  property string address: ""
  property string title: ""
  property string appName: ""
  property string iconSource: ""
  property bool active: false
  property bool urgent: false
  property bool minimized: false
  property bool busy: false
  property bool matched: false
  property string workspaceName: ""
  property bool specialWorkspace: false
  property int monitorId: -1
  property bool floating: false
  property bool pinned: false
  property bool pseudo: false
  property int fullscreen: 0
  property int fullscreenClient: 0
  property int groupedCount: 0
  property bool popped: false
  property bool taskbarPinned: false
  property real attentionScale: 1.0
  property var registeredBar: null

  signal clicked(int button)
  signal previewEntered()
  signal previewExited()

  readonly property bool vertical: root.bar ? root.bar.vertical : false
  readonly property int barSize: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal
  readonly property color foreground: root.bar ? root.bar.barForeground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color urgentColor: root.bar ? root.bar.urgent : Color.urgent
  readonly property bool motionEnabled: !root.bar || root.bar.foregroundAnimationEnabled
  readonly property real interactionScale: mouse.pressed ? 0.93 : (mouse.containsMouse ? 1.035 : 1.0)
  readonly property string accessibleName: root.appName || root.title || "Window"
  readonly property QtObject previewSource: {
    const normalized = String(root.address || "").trim().toLowerCase().replace(/^0x/, "")
    const values = Hyprland.toplevels ? Hyprland.toplevels.values : []
    for (let i = 0; i < values.length; i++) {
      const toplevel = values[i]
      if (!toplevel) continue
      const address = String(toplevel.address || "").trim().toLowerCase().replace(/^0x/, "")
      if (address === normalized) return toplevel.wayland || null
    }
    return null
  }
  readonly property string monitorName: {
    if (root.monitorId < 0) return ""
    const values = Hyprland.monitors ? Hyprland.monitors.values : []
    for (let i = 0; i < values.length; i++) {
      const monitor = values[i]
      if (monitor && Number(monitor.id) === root.monitorId) return String(monitor.name || "")
    }
    return ""
  }

  function triggerPress(button) {
    if (root.busy) return
    if (root.bar) root.bar.hideTooltip(root)
    root.clicked(button)
  }

  function syncClickRegistration() {
    if (root.registeredBar && root.registeredBar.unregisterClickTarget)
      root.registeredBar.unregisterClickTarget(root)
    root.registeredBar = root.bar
    if (root.registeredBar && root.registeredBar.registerClickTarget)
      root.registeredBar.registerClickTarget(root)
  }

  readonly property string previewMetadata: {
    const details = []
    if (root.appName && root.appName !== root.title) details.push(root.appName)
    if (root.workspaceName) {
      const specialName = root.workspaceName.indexOf("special:") === 0
        ? root.workspaceName.slice("special:".length)
        : root.workspaceName
      if (root.specialWorkspace)
        details.push(specialName === "scratchpad" ? "Scratchpad" : "Special · " + specialName)
      else details.push("Workspace " + root.workspaceName)
    }
    if (root.monitorName && Hyprland.monitors && Hyprland.monitors.values.length > 1)
      details.push("Monitor " + root.monitorName)
    if (root.minimized) details.push("Minimized")
    return details.join(" · ")
  }

  readonly property string tooltip: {
    const primary = root.title || root.appName || root.address
    const details = []
    if (root.appName && root.appName !== primary) details.push(root.appName)
    if (root.workspaceName) {
      const specialName = root.workspaceName.indexOf("special:") === 0
        ? root.workspaceName.slice("special:".length)
        : root.workspaceName
      if (root.specialWorkspace)
        details.push(specialName === "scratchpad" ? "Scratchpad" : "Special workspace · " + specialName)
      else details.push("Workspace " + root.workspaceName)
    }
    if (root.monitorName && Hyprland.monitors && Hyprland.monitors.values.length > 1) details.push("Monitor " + root.monitorName)
    if (root.minimized) details.push("Minimized")
    if (root.popped) details.push("Popped")
    else {
      if (root.pinned) details.push("Pinned")
      else if (root.floating) details.push("Floating")
    }
    if (root.fullscreen === 2 || root.fullscreenClient === 2) details.push("Fullscreen")
    else if (root.fullscreen === 1 || root.fullscreenClient === 1) details.push("Maximized")
    if (root.pseudo) details.push("Pseudo")
    if (root.groupedCount > 0) details.push("Group " + root.groupedCount)
    if (root.taskbarPinned) details.push("Pinned to taskbar")
    if (root.urgent) details.push("Needs attention")
    if (!root.matched) details.push("No matching Omarchy launcher entry")
    return details.length > 0 ? primary + "\n" + details.join(" · ") : primary
  }

  activeFocusOnTab: !root.busy
  implicitWidth: root.barSize
  implicitHeight: root.barSize
  opacity: root.minimized ? 0.60 : 1.0

  Accessible.role: Accessible.Button
  Accessible.name: root.accessibleName
  Accessible.description: root.tooltip
  Accessible.focusable: !root.busy
  Accessible.onPressAction: if (!root.busy) root.triggerPress(Qt.LeftButton)

  onBarChanged: root.syncClickRegistration()
  onBusyChanged: if (root.busy) root.previewExited()
  Component.onDestruction: {
    root.previewExited()
    if (root.registeredBar && root.registeredBar.unregisterClickTarget) root.registeredBar.unregisterClickTarget(root)
  }

  onUrgentChanged: {
    if (!root.urgent) return
    if (root.motionEnabled) urgentPulse.restart()
    else root.attentionScale = 1.0
  }

  onActiveFocusChanged: {
    if (!root.bar) return
    if (root.activeFocus) root.bar.showTooltip(root, root.tooltip)
    else root.bar.hideTooltip(root)
  }

  Keys.onReturnPressed: root.triggerPress(Qt.LeftButton)
  Keys.onEnterPressed: root.triggerPress(Qt.LeftButton)
  Keys.onSpacePressed: root.triggerPress(Qt.LeftButton)
  Keys.onPressed: function(event) {
    if (root.busy) return
    const contextMenuKey = event.key === Qt.Key_Menu
      || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))
    if (!contextMenuKey) return
    event.accepted = true
    root.triggerPress(Qt.RightButton)
  }

  Component.onCompleted: {
    root.syncClickRegistration()
    if (root.urgent && root.motionEnabled) urgentPulse.restart()
  }

  Behavior on opacity {
    enabled: root.motionEnabled
    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
  }

  Item {
    id: surface

    anchors.centerIn: parent
    width: Math.max(22, root.barSize - Style.space(6))
    height: width
    scale: root.interactionScale * root.attentionScale

    Behavior on scale {
      enabled: root.motionEnabled
      NumberAnimation { duration: 95; easing.type: Easing.OutCubic }
    }

    Rectangle {
      id: surfaceBackground

      anchors.fill: parent
      radius: Style.cornerRadius
      visible: root.urgent || root.active || root.popped || root.activeFocus || mouse.containsMouse || mouse.pressed
      color: {
        if (root.urgent) return Util.alpha(root.urgentColor, Math.max(Style.selectedFillAlpha, 0.16))
        if (mouse.pressed) return Style.pressedFillFor(root.foreground, root.accent, root.urgentColor)
        if (root.activeFocus) return Style.focusFillFor(root.foreground, root.accent, root.urgentColor)
        if (root.active) return Style.selectedFillFor(root.foreground, root.accent, root.urgentColor)
        if (mouse.containsMouse) return Style.hoverFillFor(root.foreground, root.accent, root.urgentColor)
        return Style.normalFillFor(root.foreground, root.accent, root.urgentColor)
      }

      Behavior on color {
        enabled: root.motionEnabled
        ColorAnimation { duration: 110 }
      }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: -Math.max(1, Style.spacing.hairline)
      visible: root.activeFocus
      radius: Style.cornerRadius + Math.max(1, Style.spacing.hairline)
      color: Util.alpha(root.accent, 0.05)
      border.width: Math.max(1, Style.focusBorderWidth)
      border.color: Style.focusBorderFor(root.foreground, root.accent, root.urgentColor)
      opacity: root.activeFocus ? 0.90 : 0.0

      Behavior on opacity {
        enabled: root.motionEnabled
        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
      }
    }

    Image {
      id: iconImage

      visible: root.matched && root.iconSource.length > 0
      anchors.centerIn: parent
      width: Math.max(16, parent.width - Style.space(6))
      height: width
      source: root.iconSource
      sourceSize.width: width * Screen.devicePixelRatio
      sourceSize.height: height * Screen.devicePixelRatio
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      opacity: root.busy ? 0.52 : 1.0

      Behavior on opacity {
        enabled: root.motionEnabled
        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
      }
    }

    Text {
      visible: !root.matched || root.iconSource.length === 0 || iconImage.status === Image.Error
      anchors.centerIn: parent
      text: "!"
      color: root.urgent ? root.urgentColor : root.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.title
      font.weight: Font.Medium
      opacity: root.busy ? 0.45 : 0.80

      Behavior on opacity {
        enabled: root.motionEnabled
        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
      }
    }

    Rectangle {
      id: poppedBadge

      anchors.left: parent.left
      anchors.top: parent.top
      anchors.leftMargin: Style.space(3)
      anchors.topMargin: Style.space(3)
      width: Math.max(4, Style.space(4))
      height: width
      radius: Style.spacing.hairline
      rotation: 45
      color: root.accent
      opacity: root.popped ? 0.95 : 0.0
      scale: root.popped ? 1.0 : 0.45

      Behavior on opacity {
        enabled: root.motionEnabled
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
      }

      Behavior on scale {
        enabled: root.motionEnabled
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
      }
    }

    Rectangle {
      id: busyBadge

      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: Style.space(2)
      anchors.topMargin: Style.space(2)
      width: Math.max(4, Style.space(4))
      height: width
      radius: width / 2
      color: root.accent
      opacity: root.busy ? 1.0 : 0.0
      scale: root.busy ? 1.0 : 0.35

      Behavior on opacity {
        enabled: root.motionEnabled
        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
      }

      Behavior on scale {
        enabled: root.motionEnabled
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
      }
    }
  }

  Rectangle {
    id: stateIndicator

    readonly property real maxLongSize: Math.max(10, root.barSize * 0.46)
    readonly property real thickSize: Style.space(2)
    readonly property real extentScale: root.minimized
      ? 0.34
      : (root.active || root.urgent ? 1.0 : (root.popped ? 0.78 : 0.58))

    width: root.vertical ? stateIndicator.thickSize : stateIndicator.maxLongSize
    height: root.vertical ? stateIndicator.maxLongSize : stateIndicator.thickSize
    anchors.horizontalCenter: root.vertical ? undefined : parent.horizontalCenter
    anchors.verticalCenter: root.vertical ? parent.verticalCenter : undefined
    anchors.right: root.vertical ? parent.right : undefined
    anchors.bottom: root.vertical ? undefined : parent.bottom
    radius: Math.max(1, stateIndicator.thickSize / 2)
    color: root.urgent ? root.urgentColor : ((root.active || root.popped) ? root.accent : root.foreground)
    opacity: root.minimized ? 0.34 : ((root.active || root.urgent) ? 1.0 : (root.popped ? 0.82 : 0.46))
    transform: Scale {
      id: indicatorTransform

      origin.x: stateIndicator.width / 2
      origin.y: stateIndicator.height / 2
      xScale: root.vertical ? 1.0 : stateIndicator.extentScale
      yScale: root.vertical ? stateIndicator.extentScale : 1.0

      Behavior on xScale {
        enabled: root.motionEnabled
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
      }

      Behavior on yScale {
        enabled: root.motionEnabled
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
      }
    }

    Behavior on opacity {
      enabled: root.motionEnabled
      NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
  }

  SequentialAnimation {
    id: urgentPulse

    NumberAnimation {
      target: root
      property: "attentionScale"
      to: 1.075
      duration: 80
      easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root
      property: "attentionScale"
      to: 1.0
      duration: 150
      easing.type: Easing.OutCubic
    }
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    enabled: !root.busy
    onEntered: {
      if (root.bar) root.bar.showTooltip(root, root.tooltip)
      root.previewEntered()
    }
    onExited: {
      if (root.bar && !root.activeFocus) root.bar.hideTooltip(root)
      root.previewExited()
    }
    onClicked: function(event) { root.triggerPress(event.button) }
  }
}
