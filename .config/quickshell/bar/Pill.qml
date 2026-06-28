import QtQuick
import "../themeswitcher"

Rectangle {
  id: root

  // ── Public API ───────────────────────────────────────────────────────────
  property string icon: ""
  property string label: ""
  property color iconColor: Theme.accentPrimary
  property color labelColor: Theme.textPrimary
  property color bgColor: Theme.bgSurface
  property real iconSize: 14
  property real fontSize: 12
  property string fontFamily: Theme.fontFamily
  property real maxLabelWidth: 200

  // Interactive
  property bool interactive: true
  signal clicked()
  signal wheeled(var wheel)

  // ── Geometry ─────────────────────────────────────────────────────────────
  height: 24
  radius: 12
  color: bgColor
  implicitWidth: contentRow.implicitWidth + 12

  // ── Content ──────────────────────────────────────────────────────────────
  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: 6

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.icon
      color: root.iconColor
      font.pixelSize: root.iconSize
      font.family: root.fontFamily
      visible: root.icon !== ""
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.label
      color: root.labelColor
      font.pixelSize: root.fontSize
      font.family: root.fontFamily
      elide: Text.ElideRight
      width: Math.min(implicitWidth, root.maxLabelWidth)
    }
  }

  // ── Interaction ──────────────────────────────────────────────────────────
  MouseArea {
    anchors.fill: parent
    cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.clicked()
    onWheel: (w) => root.wheeled(w)
  }
}
