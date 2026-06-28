import QtQuick
import "../themeswitcher"

Pill {
  id: root
  icon: SystemInfo.batteryIcon
  label: SystemInfo.batteryLevel
  iconColor: {
    switch (SystemInfo.batteryStatus) {
      case "charging": return Theme.accentGreen;
      case "good":     return Theme.batteryGood;
      case "warning":  return Theme.batteryWarning;
      default:         return Theme.batteryCritical;
    }
  }
  visible: SystemInfo.batteryAvailable

  Accessible.role: Accessible.StaticText
  Accessible.name: "Battery: " + SystemInfo.batteryLevel

  interactive: false
}
