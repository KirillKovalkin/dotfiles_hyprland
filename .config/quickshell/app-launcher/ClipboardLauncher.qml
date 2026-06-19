import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"
  property int selectedIndex: -1

  ListModel { id: entriesModel }

  // List clipboard entries using `cliphist list`
  Process {
    id: listProc
    command: ["cliphist", "list"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        // Attempt to split id and preview: first token is id
        const m = line.match(/^([^\s]+)\s*(.*)$/)
        const idTok = m ? m[1] : line
        const preview = m && m[2] ? m[2] : ""
        entriesModel.append({ id: idTok, text: preview })
        // enforce max 150 entries as we stream
        while (entriesModel.count > 150) entriesModel.remove(entriesModel.count - 1)
        if (selectedIndex === -1 && entriesModel.count > 0) selectedIndex = 0
      }
    }
  }

  function refreshList() {
    entriesModel.clear()
    listProc.running = true
  }

  function copyEntry(idx) {
    if (idx < 0 || idx >= entriesModel.count) return
    const id = entriesModel.get(idx).id
    copyProc.command = ["sh", "-c", "cliphist decode '" + id.replace(/'/g, "'\\''") + "' | wl-copy || true"]
    copyProc.running = true
  }
  Process { id: copyProc; command: []; running: false }

  Component.onCompleted: refreshList()

  PanelWindow {
    id: panel
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-clipboard"

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    MouseArea { anchors.fill: parent; onClicked: panel.visible = false
      Rectangle { anchors.fill: parent; color: root.theme.bgOverlay }
    }

    Rectangle {
      id: box
      width: 640
      height: 420
      anchors.centerIn: parent
      radius: 12
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1
      focus: true

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
          event.accepted = true; root.selectedIndex = Math.min(root.selectedIndex + 1, listView.count - 1); listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        } else if (event.key === Qt.Key_Up) {
          event.accepted = true; root.selectedIndex = Math.max(root.selectedIndex - 1, 0); listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          event.accepted = true; root.copyEntry(root.selectedIndex); panel.visible = false
        } else if (event.key === Qt.Key_Escape) {
          event.accepted = true; panel.visible = false
        }
      }

      ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 8
        Text { text: "  Clipboard"; color: root.theme.accentPrimary; font.pixelSize: 14; font.family: root.font; font.bold: true }
        Text { text: entriesModel.count + " items"; color: root.theme.textMuted; font.pixelSize: 11; font.family: root.font }

        ListView {
          id: listView
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: entriesModel
          clip: true
          currentIndex: root.selectedIndex
          boundsBehavior: Flickable.StopAtBounds
          highlightMoveDuration: 120

          highlight: Rectangle { radius: 8; color: root.theme.bgSelected; visible: root.selectedIndex >= 0 }

          delegate: Rectangle {
            id: itemRoot
            width: listView.width
            height: 44
            radius: 6
            color: "transparent"

            RowLayout { anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 12; spacing: 12
              // index badge
              Rectangle { width: 36; height: 28; radius: 6; color: "transparent"; Layout.alignment: Qt.AlignVCenter
                Text { anchors.centerIn: parent; text: (index + 1).toString(); color: root.theme.textMuted; font.pixelSize: 12; font.family: root.font }
              }
              ColumnLayout { Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter
                Text { text: (model.text || ""); elide: Text.ElideRight; color: root.selectedIndex === index ? root.theme.textPrimary : root.theme.textSecondary; font.pixelSize: 13; font.family: root.font }
              }
            }

            MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: { root.copyEntry(index); panel.visible = false } onPositionChanged: root.selectedIndex = index }
          }
        }

        RowLayout { Layout.fillWidth: true; spacing: 12
          Row { spacing: 6; Rectangle { width: hintKeys.width + 8; height: 18; radius: 4; color: root.theme.bgSurface; Text { id: hintKeys; anchors.centerIn: parent; text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } } Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } }
          Row { spacing: 6; Rectangle { width: hintEnter.width + 8; height: 18; radius: 4; color: root.theme.bgSurface; Text { id: hintEnter; anchors.centerIn: parent; text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } } Text { text: "copy"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } }
          Row { spacing: 6; Rectangle { width: hintEsc.width + 8; height: 18; radius: 4; color: root.theme.bgSurface; Text { id: hintEsc; anchors.centerIn: parent; text: "Esc"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } } Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } }
          Item { Layout.fillWidth: true }
        }
      }
    }
  }

  // Toggle visibility via IPC
  IpcHandler {
    target: "clipboardLauncher"
    function toggle() { panel.visible = !panel.visible; if (panel.visible) { refreshList(); selectedIndex = entriesModel.count > 0 ? 0 : -1; box.forceActiveFocus(); } }
  }
}
