import QtQuick
import "../themeswitcher"

Pill {
  id: root
  icon: {
    if (SystemInfo.networkType === "ethernet") return "󰈀";
    if (SystemInfo.networkType === "wifi") return "󰖩";
    return "󰖪";
  }
  label: SystemInfo.networkInfo
  iconColor: SystemInfo.networkType === "disconnected" ? Theme.textMuted : Theme.accentGreen

  Accessible.role: Accessible.StaticText
  Accessible.name: {
    if (SystemInfo.networkType === "ethernet") return "Network: Ethernet";
    if (SystemInfo.networkType === "wifi") return "Network: WiFi " + SystemInfo.networkInfo;
    return "Network: Disconnected";
  }

  interactive: false
}
