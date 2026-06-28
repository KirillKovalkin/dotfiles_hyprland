import QtQuick
import "../themeswitcher"

Pill {
  icon: "󰔏"
  label: SystemInfo.gpuTemperature
  iconColor: Theme.accentRed

  Accessible.role: Accessible.StaticText
  Accessible.name: "GPU Temperature: " + SystemInfo.gpuTemperature

  interactive: false
}
