import QtQuick
import "../themeswitcher"

Pill {
  icon: "󰍛"
  label: SystemInfo.temperature
  iconColor: Theme.accentRed

  Accessible.role: Accessible.StaticText
  Accessible.name: "CPU Temperature: " + SystemInfo.temperature

  interactive: false
}
