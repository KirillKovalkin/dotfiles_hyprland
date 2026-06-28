pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import QtQuick

Singleton {
  id: root

  // Single PwObjectTracker for the whole shell
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

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

  // Battery semantic status — used by Bar.qml for color mapping
  readonly property string batteryStatus: {
    if (!batteryAvailable) return "none";
    if (batteryCharging) return "charging";
    if (batteryLevelRaw > 20) return "good";
    if (batteryLevelRaw > 10) return "warning";
    return "critical";
  }

  // Shared volume icon — pure function, used by Bar + OSD
  function volumeIcon(volume, muted) {
    if (muted || volume <= 0) return "󰖁";
    if (volume < 0.33) return "󰕿";
    if (volume < 0.66) return "󰖀";
    return "󰕾";
  }

  // ── Brightness (shared with Bar + OSD) ───────────────────────────────────
  property real brightnessValue: 0
  readonly property bool brightnessAvailable: brightnessFile.path !== ""
  property bool brightnessReady: false

  FileView {
    id: brightnessFile
    path: ""
    watchChanges: true
    onFileChanged: brightnessReadProc.running = true
  }

  Process {
    id: brightnessReadProc
    command: ["brightnessctl", "get"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const val = parseInt(text.trim());
        if (!isNaN(val) && root.brightnessMax > 0) {
          root.brightnessValue = val / root.brightnessMax;
          root.brightnessReady = true;
        }
      }
    }
  }

  property real brightnessMax: 1

  Process {
    id: backlightDiscovery
    command: ["sh", "-c", "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length >= 2) {
          const max = parseInt(lines[1]);
          if (!isNaN(max) && max > 0) {
            root.brightnessMax = max;
            brightnessFile.path = lines[0];
            brightnessReadProc.running = true;
            backlightRetry.stop();
          }
        }
      }
    }
  }

  // Retry backlight discovery — handles delayed udev/sysfs at boot
  // Limited retries to avoid infinite shell forking on desktop (no /sys/class/backlight)
  property int _backlightRetries: 0
  readonly property int _backlightMaxRetries: 5

  Timer {
    id: backlightRetry
    interval: 2000
    running: brightnessFile.path === "" && root._backlightRetries < root._backlightMaxRetries
    repeat: true
    onTriggered: {
      if (brightnessFile.path !== "") { stop(); return; }
      root._backlightRetries++
      if (!backlightDiscovery.running) backlightDiscovery.running = true;
      if (root._backlightRetries >= root._backlightMaxRetries) stop();
    }
  }

  // ── CPU (reads /proc/stat via pipe — POSIX sh compatible) ───────────────
  Process {
    id: cpuProc
    command: ["sh", "-c",
      "{ head -1 /proc/stat; sleep 0.2; head -1 /proc/stat; } | awk 'NR==1{u=$2+$4;t=$2+$3+$4+$5;i=$5} NR==2{u2=$2+$4;t2=$2+$3+$4+$5;i2=$5; printf \"%.0f%%\", (1-(i2-i)/(t2-t))*100}'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: { root.cpuUsage = text.trim() }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: { if (!cpuProc.running) cpuProc.running = true }
  }

  // ── Temperature (CPU + GPU in one sensors call) ──────────────────────────
  Process {
    id: tempProc
    command: ["sh", "-c",
      "sensors 2>/dev/null | awk '/^edge:/{gsub(/\\+/,\"\"); gpu=int($2); hasGpu=1} /Package id 0:/{gsub(/\\+/,\"\"); cpu=int($4); hasCpu=1} /Tctl:/{gsub(/\\+/,\"\"); if(!hasCpu){cpu=int($2); hasCpu=1}} /Tdie:/{gsub(/\\+/,\"\"); if(!hasCpu){cpu=int($2); hasCpu=1}} END{printf \"cpu:%s\\ngpu:%s\\n\", hasCpu?cpu\"°C\":\"N/A\", hasGpu?gpu\"°C\":\"N/A\"}'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
          const parts = lines[i].split(":")
          if (parts[0] === "cpu") root.temperature = parts[1]
          if (parts[0] === "gpu") root.gpuTemperature = parts[1]
        }
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: { if (!tempProc.running) tempProc.running = true }
  }

  // ── Keyboard layout (event-driven via Hyprland IPC) ──────────────────────
  Process {
    id: kbInitProc
    command: ["sh", "-c",
      "hyprctl devices | awk '/Keyboard/{found=1} found && /active keymap:/{sub(/.*active keymap: /,\"\"); sub(/ *\\(.*/,\"\"); print; exit}'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const val = text.trim()
        if (val) root.keyboardLayout = val.substring(0, 2).toLowerCase()
      }
    }
  }

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

  // ── Network (event-driven via FileView, tab-separated, colon-safe) ──────
  Process {
    id: netProc
    command: ["sh", "-c",
      "for iface in /sys/class/net/*; do name=$(basename \"$iface\"); [ \"$name\" = lo ] && continue; oper=$(cat \"$iface/operstate\" 2>/dev/null); [ \"$oper\" != up ] && continue; carrier=$(cat \"$iface/carrier\" 2>/dev/null); [ \"$carrier\" != 1 ] && continue; if [ -d \"$iface/wireless\" ] || [ -d \"$iface/phy80211\" ]; then ssid=$(iwgetid \"$name\" -r 2>/dev/null || iw dev \"$name\" link 2>/dev/null | awk -F': ' '/SSID/{print $2}'); printf 'wifi\t%s\t%s\n' \"${ssid:-WiFi}\" \"$name\"; else printf 'ethernet\tEthernet\t%s\n' \"$name\"; fi; exit; done; printf 'disconnected\t\t\n'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const result = text.trim()
        const parts = result.split("\t")
        root.networkType = parts[0]
        root.networkInfo = parts[1] || "Disconnected"
        // Watch operstate of the active interface for instant connect/disconnect detection
        const iface = parts[2]
        netWatcher.path = iface ? "/sys/class/net/" + iface + "/operstate" : ""
      }
    }
  }

  // React instantly to interface link up/down
  FileView {
    id: netWatcher
    path: ""
    watchChanges: true
    onFileChanged: { if (path !== "") netProc.running = true }
  }

  // Polling fallback — only when disconnected, to detect new connections
  Timer {
    interval: 5000
    running: root.networkType === "disconnected"
    repeat: true
    onTriggered: { if (!netProc.running) netProc.running = true }
  }

  // ── Battery (event-driven via UPower D-Bus) ────────────────────────────
  function _updateBatteryIcon() {
    if (root.batteryCharging) { root.batteryIcon = ""; return; }
    const lvl = root.batteryLevelRaw;
    if (lvl >= 90) root.batteryIcon = "󰁹";
    else if (lvl >= 80) root.batteryIcon = "󰂂";
    else if (lvl >= 70) root.batteryIcon = "󰂁";
    else if (lvl >= 60) root.batteryIcon = "󰂀";
    else if (lvl >= 50) root.batteryIcon = "󰁿";
    else if (lvl >= 40) root.batteryIcon = "󰁾";
    else if (lvl >= 30) root.batteryIcon = "󰁽";
    else if (lvl >= 20) root.batteryIcon = "󰁼";
    else if (lvl >= 10) root.batteryIcon = "󰁻";
    else root.batteryIcon = "󰁺";
  }

  function _syncBattery() {
    const dd = UPower.displayDevice;
    if (!dd || !dd.ready) return;
    root.batteryLevelRaw = Math.round(dd.percentage);
    root.batteryLevel = root.batteryLevelRaw + "%";
    root.batteryCharging = dd.state === UPowerDeviceState.Charging;
    _updateBatteryIcon();
  }

  function _checkBatteryAvailable() {
    const devs = UPower.devices.values;
    for (let i = 0; i < devs.length; i++) {
      if (devs[i].isLaptopBattery) {
        root.batteryAvailable = true;
        _syncBattery();
        return;
      }
    }
    root.batteryAvailable = false;
  }

  // React to battery changes
  Connections {
    target: UPower.displayDevice
    function onPercentageChanged() { if (root.batteryAvailable) root._syncBattery() }
    function onStateChanged()      { if (root.batteryAvailable) root._syncBattery() }
  }

  // Detect battery on startup + handle late UPower initialization
  property int _batteryRetries: 0
  readonly property int _batteryMaxRetries: 5

  Timer {
    id: batteryDiscoveryTimer
    interval: 2000
    running: !root.batteryAvailable && root._batteryRetries < root._batteryMaxRetries
    repeat: true
    onTriggered: {
      root._checkBatteryAvailable()
      root._batteryRetries++
      if (root.batteryAvailable || root._batteryRetries >= root._batteryMaxRetries) {
        stop()
        // Desktop: no battery — never poll again, widget stays hidden
      }
    }
  }

  Component.onCompleted: {
    root._checkBatteryAvailable()
  }
}
