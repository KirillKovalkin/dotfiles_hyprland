import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../themeswitcher"

Item {
  id: root
  height: 24
  width: trayToggle.width + trayBox.width + 4

  // ── Toggle button ────────────────────────────────────────────────────────
  Rectangle {
    id: trayToggle
    height: 24
    width: 24
    radius: 12
    color: Theme.bgSurface

    Text {
      anchors.centerIn: parent
      text: "󰅁"
      color: Theme.textPrimary
      font.pixelSize: 12
      font.family: Theme.fontFamily
    }
  }

  // ── Expandable tray area ─────────────────────────────────────────────────
  Rectangle {
    id: trayBox
    anchors.left: trayToggle.right
    anchors.leftMargin: 4
    height: 24
    width: trayHover.containsMouse ? trayIcons.implicitWidth + 4 : 0
    radius: 12
    color: Theme.bgSurface
    visible: trayRepeater.count > 0
    clip: true

    Behavior on width { NumberAnimation { duration: 300 } }

    RowLayout {
      id: trayIcons
      anchors.centerIn: parent
      spacing: 2

      Repeater {
        id: trayRepeater
        model: SystemTray.items

        MouseArea {
          id: trayDelegate
          required property SystemTrayItem modelData

          Accessible.role: Accessible.Button
          Accessible.name: modelData.tooltipTitle || modelData.title || "System tray item"

          Layout.preferredWidth: 24
          Layout.preferredHeight: 24
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

          onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
              modelData.activate();
            } else if (mouse.button === Qt.RightButton) {
              if (modelData.hasMenu) menuAnchor.open();
            } else if (mouse.button === Qt.MiddleButton) {
              modelData.secondaryActivate();
            }
          }

          IconImage {
            anchors.centerIn: parent
            source: trayDelegate.modelData.icon
            implicitSize: 16
          }

          QsMenuAnchor {
            id: menuAnchor
            menu: trayDelegate.modelData.menu
            anchor.window: trayDelegate.QsWindow.window
            anchor.adjustment: PopupAdjustment.Flip
            anchor.onAnchoring: {
              const window = trayDelegate.QsWindow.window;
              const widgetRect = window.contentItem.mapFromItem(
                trayDelegate, 0, trayDelegate.height,
                trayDelegate.width, trayDelegate.height);
              menuAnchor.anchor.rect = widgetRect;
            }
          }
        }
      }
    }
  }

  // ── Hover detector (drives trayBox expansion) ────────────────────────────
  MouseArea {
    id: trayHover
    anchors.fill: parent
    hoverEnabled: true
  }
}
