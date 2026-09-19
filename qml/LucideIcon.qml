import QtQuick
import QtQuick.Effects
import qs.Commons

Item {
  id: root

  property string name: ""
  property color color: Color.foreground
  property real iconSize: 16

  implicitWidth: root.iconSize
  implicitHeight: root.iconSize

  Image {
    id: sourceImage

    anchors.fill: parent
    source: root.name ? Qt.resolvedUrl("../icons/lucide/" + root.name + ".svg") : ""
    sourceSize.width: Math.max(1, Math.round(width * Screen.devicePixelRatio))
    sourceSize.height: Math.max(1, Math.round(height * Screen.devicePixelRatio))
    fillMode: Image.PreserveAspectFit
    smooth: true
    asynchronous: false

    // Same symbolic-icon pattern used by Omarchy's tray: keep a hidden layer
    // available as a texture, then tint it through MultiEffect.
    visible: false
    layer.enabled: true
  }

  MultiEffect {
    anchors.fill: sourceImage
    source: sourceImage
    visible: root.name !== "" && sourceImage.status !== Image.Error
    // Lucide SVGs use `currentColor`, which Qt resolves to black when loaded
    // through Image. MultiEffect colorization preserves source luminance, so a
    // black source stays black. Qt's own SVG tint example first raises the
    // source to white with brightness: 1.0, then applies the semantic color.
    brightness: 1.0
    colorization: 1.0
    colorizationColor: root.color
  }
}
