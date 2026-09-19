import QtQuick

// Non-visual menu entry point. Omarchy 4.0.4 exposes the scoped AppLibrary
// facade to third-party plugins that declare the menu capability. The actual
// taskbar context menu is an inline PopupCard in Taskbar.qml; keeping this
// entry point non-visual avoids a second independent menu lifecycle.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property var service: null
  property bool opened: false

  visible: false
  width: 0
  height: 0

  function open(payloadJson) {
    root.opened = false
  }

  function close() {
    root.opened = false
  }
}
