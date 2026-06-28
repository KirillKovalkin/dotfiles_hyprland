import Quickshell
import QtQuick
import Quickshell.Widgets
import Quickshell.Io
import "../themeswitcher"

Scope {
  id: root
  property var theme: Theme

  // ── Bar visibility toggle (IPC) ──────────────────────────────────────────
  property bool barVisible: true

  IpcHandler {
    target: "bar"
    function toggle(): void { root.barVisible = !root.barVisible; }
  }

  // ── Multi-screen bar ─────────────────────────────────────────────────────
  readonly property int barHeight: 32

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.barVisible

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: root.barHeight
      color: root.theme.bgBase

      // ── Bar content ──────────────────────────────────────────────────────
      Item {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        // ═══ LEFT: Workspaces + Now Playing ═══════════════════════════════
        Row {
          id: leftSection
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          Workspaces {}
          NowPlaying {}
        }

        // ═══ CENTER: Clock ═════════════════════════════════════════════════
        ClockWidget {
          anchors.centerIn: parent
        }

        // ═══ RIGHT: System indicators + Tray ══════════════════════════════
        Row {
          id: rightSection
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          KeyboardLayout {}
          SystemTrayWidget {}
          VolumeWidget {}
          BrightnessWidget {}

          // System info group
          NetworkWidget {}
          BatteryWidget {}
          GpuTempWidget {}
          CpuTempWidget {}
          CpuUsageWidget {}
        }
      }
    }
  }
}
