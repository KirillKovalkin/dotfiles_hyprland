import QtQuick
import "../themeswitcher"

Pill {
  icon: "󰻠"
  label: SystemInfo.cpuUsage
  iconColor: Theme.accentOrange

  Accessible.role: Accessible.StaticText
  Accessible.name: "CPU: " + SystemInfo.cpuUsage

  interactive: false
}
