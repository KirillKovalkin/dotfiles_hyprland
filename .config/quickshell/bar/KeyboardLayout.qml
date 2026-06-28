import Quickshell.Io
import QtQuick
import "../themeswitcher"

Pill {
  id: root
  icon: "󰌌"
  label: SystemInfo.keyboardLayout
  iconColor: Theme.accentCyan

  Accessible.role: Accessible.Button
  Accessible.name: "Keyboard layout: " + SystemInfo.keyboardLayout

  onClicked: { if (!kbSwitchProc.running) kbSwitchProc.running = true }

  Process {
    id: kbSwitchProc
    command: ["hyprctl", "switchxkblayout", "all", "next"]
    running: false
  }

  Component.onDestruction: {
    if (kbSwitchProc.running) kbSwitchProc.running = false
  }
}
