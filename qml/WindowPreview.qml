pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland
import qs.Commons
import qs.Ui

PopupCard {
  id: root

  property QtObject captureSource: null
  property string title: ""
  property string appName: ""
  property string iconSource: ""
  property string metadata: ""
  property bool matched: false

  triggerMode: "hover"
  contentWidth: root.fittedContentWidth(Style.space(320))
  contentHeight: root.fittedContentHeight(contentColumn.implicitHeight)

  Column {
    id: contentColumn

    width: parent.width
    spacing: Style.spacing.controlGap

    Item {
      id: previewFrame

      width: parent.width
      height: Style.space(176)

      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: Style.normalFillFor(Color.foreground, Color.accent, Color.urgent)
      }

      ScreencopyView {
        id: capture

        anchors.centerIn: parent
        captureSource: root.visible ? root.captureSource : null
        paintCursor: false
        live: false
        constraintSize: Qt.size(previewFrame.width, previewFrame.height)
        width: Math.max(1, Math.min(implicitWidth, previewFrame.width))
        height: Math.max(1, Math.min(implicitHeight, previewFrame.height))
        visible: hasContent
      }

      Image {
        visible: !capture.hasContent && root.matched && root.iconSource.length > 0
        anchors.centerIn: parent
        width: Style.space(44)
        height: width
        source: root.iconSource
        sourceSize.width: width * Screen.devicePixelRatio
        sourceSize.height: height * Screen.devicePixelRatio
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        opacity: 0.72
      }

      Text {
        visible: !capture.hasContent && (!root.matched || root.iconSource.length === 0)
        anchors.centerIn: parent
        text: "!"
        color: Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.title
        font.weight: Font.Medium
        opacity: 0.62
      }
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      text: root.title || root.appName || "Window"
      color: Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      font.weight: Font.Medium
      elide: Text.ElideRight
      maximumLineCount: 1
    }

    Text {
      visible: root.metadata.length > 0
      width: parent.width
      textFormat: Text.PlainText
      text: root.metadata
      color: Util.alpha(Color.foreground, 0.66)
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
      maximumLineCount: 1
    }
  }
}
