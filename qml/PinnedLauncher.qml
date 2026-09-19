pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Commons

Item {
  id: root

  property var bar: null
  property string desktopId: ""
  property string appName: ""
  property string iconSource: ""
  property int pinIndex: -1
  property var registeredBar: null

  signal clicked(int button)

  readonly property int barSize: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal
  readonly property color foreground: root.bar ? root.bar.barForeground : Color.foreground
  readonly property color accent: Color.accent
  readonly property bool motionEnabled: !root.bar || root.bar.foregroundAnimationEnabled
  readonly property real interactionScale: mouse.pressed ? 0.93 : (mouse.containsMouse ? 1.035 : 1.0)
  readonly property string tooltip: (root.appName || root.desktopId || "Pinned application") + "\nPinned launcher · not running"

  function triggerPress(button) {
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

  activeFocusOnTab: true
  implicitWidth: root.barSize
  implicitHeight: root.barSize

  Accessible.role: Accessible.Button
  Accessible.name: root.appName || root.desktopId || "Pinned application"
  Accessible.description: root.tooltip
  Accessible.focusable: true
  Accessible.onPressAction: root.triggerPress(Qt.LeftButton)

  onBarChanged: root.syncClickRegistration()
  Component.onCompleted: root.syncClickRegistration()
  Component.onDestruction: if (root.registeredBar && root.registeredBar.unregisterClickTarget) root.registeredBar.unregisterClickTarget(root)

  onActiveFocusChanged: {
    if (!root.bar) return
    if (root.activeFocus) root.bar.showTooltip(root, root.tooltip)
    else root.bar.hideTooltip(root)
  }

  Keys.onReturnPressed: root.triggerPress(Qt.LeftButton)
  Keys.onEnterPressed: root.triggerPress(Qt.LeftButton)
  Keys.onSpacePressed: root.triggerPress(Qt.LeftButton)
  Keys.onPressed: function(event) {
    const contextMenuKey = event.key === Qt.Key_Menu
      || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))
    if (!contextMenuKey) return
    event.accepted = true
    root.triggerPress(Qt.RightButton)
  }

  Item {
    id: surface

    anchors.centerIn: parent
    width: Math.max(22, root.barSize - Style.space(6))
    height: width
    scale: root.interactionScale

    Behavior on scale {
      enabled: root.motionEnabled
      NumberAnimation { duration: 95; easing.type: Easing.OutCubic }
    }

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      visible: root.activeFocus || mouse.containsMouse || mouse.pressed
      color: mouse.pressed
        ? Style.pressedFillFor(root.foreground, root.accent)
        : (root.activeFocus
            ? Style.focusFillFor(root.foreground, root.accent)
            : Style.hoverFillFor(root.foreground, root.accent))

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
      border.color: Style.focusBorderFor(root.foreground, root.accent)
    }

    Image {
      anchors.centerIn: parent
      width: Math.max(16, parent.width - Style.space(6))
      height: width
      source: root.iconSource
      sourceSize.width: width * Screen.devicePixelRatio
      sourceSize.height: height * Screen.devicePixelRatio
      fillMode: Image.PreserveAspectFit
      asynchronous: true
    }

    Rectangle {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.rightMargin: Style.space(2)
      anchors.bottomMargin: Style.space(2)
      width: Math.max(3, Style.space(3))
      height: width
      radius: width / 2
      color: root.accent
      opacity: 0.82
    }
  }

  MouseArea {
    id: mouse

    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip)
    onExited: if (root.bar && !root.activeFocus) root.bar.hideTooltip(root)
    onClicked: function(event) { root.triggerPress(event.button) }
  }
}
