import Quickshell.Io
import QtQuick
import "../themeswitcher"

Pill {
  id: root
  icon: "󰃠"
  label: Math.round(SystemInfo.brightnessValue * 100) + "%"
  iconColor: Theme.accentOrange
  visible: SystemInfo.brightnessAvailable

  Accessible.role: Accessible.StaticText
  Accessible.name: "Brightness: " + Math.round(SystemInfo.brightnessValue * 100) + "%"

  onWheeled: (wheel) => {
    if (brightnessSetProc.running) return;
    brightnessSetProc.command = wheel.angleDelta.y > 0
      ? ["brightnessctl", "set", "5%+"]
      : ["brightnessctl", "set", "5%-"];
    brightnessSetProc.running = true;
  }

  Process {
    id: brightnessSetProc
    running: false
  }
}
