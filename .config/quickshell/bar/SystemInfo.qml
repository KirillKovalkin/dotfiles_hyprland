pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Hyprland
import QtQuick

Singleton {
  id: root

  property string cpuUsage: "0%"
  property string networkInfo: "Disconnected"
  property string networkType: "disconnected"
  property int batteryLevelRaw: 0
  property string batteryLevel: "0%"
  property string batteryIcon: "󰂎"
  property bool batteryCharging: false
  property bool batteryAvailable: false
  property string temperature: "N/A"
  property string gpuTemperature: "N/A"
  property string keyboardLayout: "??"

  // CPU Usage
  Process {
    id: cpuProc
    command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1\"%\"}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.cpuUsage = text.trim()
      }
    }
  }

  // Temperature — Intel (Package id 0) and AMD (Tctl/Tdie)
  Process {
    id: tempProc
    command: ["sh", "-c", "sensors 2>/dev/null | awk '/Package id 0:/{gsub(/\\+/,\"\"); printf \"%.0f\", $4; exit} /Tctl:/{gsub(/\\+/,\"\"); printf \"%.0f\", $2; exit} /Tdie:/{gsub(/\\+/,\"\"); printf \"%.0f\", $2; exit}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const val = text.trim()
        root.temperature = val ? val + "°C" : "N/A"
      }
    }
  }

  // GPU Temperature — AMD (edge)
  Process {
    id: gpuTempProc
    command: ["sh", "-c", "sensors 2>/dev/null | awk '/^edge:/{gsub(/\\+/,\"\"); printf \"%.0f\", $2; exit}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const val = text.trim()
        root.gpuTemperature = val ? val + "°C" : "N/A"
      }
    }
  }

  // Initial keyboard layout — first keyboard with active_keymap
  Process {
    id: kbInitProc
    command: ["sh", "-c", "hyprctl devices | awk '/Keyboard/{found=1} found && /active keymap:/{sub(/.*active keymap: /,\"\"); sub(/ *\\(.*/,\"\"); print; exit}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const val = text.trim()
        if (val) root.keyboardLayout = val.substring(0, 2).toLowerCase()
      }
    }
  }

  // Instant layout updates via Hyprland IPC socket2 events
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activelayout") {
        const parts = event.data.split(",")
        if (parts.length >= 2) {
          const name = parts[1].replace(/ *\(.*\)/, "").trim()
          root.keyboardLayout = name.substring(0, 2).toLowerCase()
        }
      }
    }
  }

  // Network — /sys/class/net/ based, no nmcli required
  Process {
    id: netProc
    command: ["sh", "-c", "for iface in /sys/class/net/*; do name=$(basename \"$iface\"); [ \"$name\" = lo ] && continue; oper=$(cat \"$iface/operstate\" 2>/dev/null); [ \"$oper\" != up ] && continue; carrier=$(cat \"$iface/carrier\" 2>/dev/null); [ \"$carrier\" != 1 ] && continue; if [ -d \"$iface/wireless\" ] || [ -d \"$iface/phy80211\" ]; then ssid=$(iwgetid \"$name\" -r 2>/dev/null || iw dev \"$name\" link 2>/dev/null | awk -F': ' '/SSID/{print $2}'); echo \"wifi:${ssid:-WiFi}\"; else echo \"ethernet:Ethernet\"; fi; exit; done; echo 'disconnected:'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const result = text.trim()
        const colonIdx = result.indexOf(":")
        root.networkType = result.substring(0, colonIdx)
        root.networkInfo = result.substring(colonIdx + 1) || "Disconnected"
      }
    }
  }

  // Periodic update timer
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      cpuProc.running = true
      tempProc.running = true
      gpuTempProc.running = true
      netProc.running = true
      updateBattery()
    }
  }

  function updateBattery() {
    let hasBattery = false
    const devices = UPower.devices
    for (let i = 0; i < devices.length; i++) {
      if (devices[i].isLaptopBattery) {
        hasBattery = true
        break
      }
    }
    root.batteryAvailable = hasBattery

    if (!hasBattery) return

    const dd = UPower.displayDevice
    if (dd && dd.ready) {
      root.batteryLevelRaw = Math.round(dd.percentage)
      root.batteryLevel = root.batteryLevelRaw + "%"
      root.batteryCharging = dd.state === UPowerDeviceState.Charging

      if (root.batteryCharging) root.batteryIcon = ""
      else if (root.batteryLevelRaw >= 90) root.batteryIcon = "󰁹"
      else if (root.batteryLevelRaw >= 80) root.batteryIcon = "󰂂"
      else if (root.batteryLevelRaw >= 70) root.batteryIcon = "󰂁"
      else if (root.batteryLevelRaw >= 60) root.batteryIcon = "󰂀"
      else if (root.batteryLevelRaw >= 50) root.batteryIcon = "󰁿"
      else if (root.batteryLevelRaw >= 40) root.batteryIcon = "󰁾"
      else if (root.batteryLevelRaw >= 30) root.batteryIcon = "󰁽"
      else if (root.batteryLevelRaw >= 20) root.batteryIcon = "󰁼"
      else if (root.batteryLevelRaw >= 10) root.batteryIcon = "󰁻"
      else root.batteryIcon = "󰁺"
    }
  }

  Component.onCompleted: {
    updateBattery()
  }
}
