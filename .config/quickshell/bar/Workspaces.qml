import QtQuick
import Quickshell.Hyprland
import "../themeswitcher"

Row {
  id: root
  spacing: 4

  Repeater {
    model: Hyprland.workspaces

    Rectangle {
      id: wsPill
      required property var modelData
      property bool urgentBlink: false

      Accessible.role: Accessible.Button
      Accessible.name: "Workspace " + modelData.id
        + (modelData.focused ? ", active" : "")
        + (modelData.urgent ? ", urgent" : "")

      width: modelData.focused ? 32 : 24
      height: 24
      radius: 12
      color: modelData.focused ? Theme.accentPrimary
        : modelData.urgent && urgentBlink ? Theme.accentRed
        : Theme.bgSurface

      Behavior on color { ColorAnimation { duration: 150 } }

      // Urgent blink animation
      SequentialAnimation {
        loops: Animation.Infinite
        running: wsPill.modelData.urgent && !wsPill.modelData.focused

        PropertyAction { target: wsPill; property: "urgentBlink"; value: true }
        PauseAnimation { duration: 500 }
        PropertyAction { target: wsPill; property: "urgentBlink"; value: false }
        PauseAnimation { duration: 500 }

        onStopped: wsPill.urgentBlink = false
      }

      Text {
        anchors.centerIn: parent
        text: wsPill.modelData.id
        color: wsPill.modelData.focused ? Theme.bgBase : Theme.textPrimary
        font.pixelSize: 12
        font.family: Theme.fontFamily
        font.bold: wsPill.modelData.focused
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: wsPill.modelData.activate()
      }

      Behavior on width { NumberAnimation { duration: 150 } }
    }
  }
}
