import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../themeswitcher"

Scope {
  id: root
  property var theme: Theme

  // ── Bar visibility toggle (IPC) ──────────────────────────────────────────
  property bool barVisible: true

  // Hide bar on this output while its active workspace has a fullscreen client.
  // Matches hypr/monitors.lua — DP-1 is the 240 Hz primary/gaming monitor.
  readonly property string autoHideOutput: "DP-1"

  readonly property bool primaryFullscreenActive: {
    for (const m of Hyprland.monitors.values) {
      if (m.name === root.autoHideOutput)
        return m.activeWorkspace?.hasFullscreen ?? false
    }
    return false
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "fullscreen" || event.name === "workspace"
          || event.name === "openwindow" || event.name === "closewindow")
        Hyprland.refreshWorkspaces()
    }
  }

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

      readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
      readonly property bool hideForFullscreen:
        hyprMonitor?.name === root.autoHideOutput && root.primaryFullscreenActive

      visible: root.barVisible && !hideForFullscreen

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
