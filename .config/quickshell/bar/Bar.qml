import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../themeswitcher"
Scope {
  id: root
  property var theme: Theme
  property string font: "JetBrainsMono Nerd Font"
  property bool barVisible: true

  // MPRIS active player — reactive via ScriptModel
  ScriptModel {
    id: mprisModel
    values: Mpris.players.values
    objectProp: "identity"
  }

  property var activePlayer: {
    const players = mprisModel.values;
    if (!players || players.length === 0) return null;
    for (const p of players) {
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    }
    return players[0];
  }

  IpcHandler {
    target: "bar"
    function toggle(): void { root.barVisible = !root.barVisible; }
  }

  // Brightness set (values read from SystemInfo singleton)
  Process {
    id: brightnessSetProc
    running: false
  }

  // Keyboard layout switching (hyprctl — works in Lua mode)
  Process {
    id: kbSwitchProc
    command: ["hyprctl", "switchxkblayout", "all", "next"]
    running: false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: root.barVisible

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 32
      color: root.theme.bgBase

      Item {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        // Left section: Workspaces + Now Playing
        Row {
          id: leftSection
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          // Workspaces
          Row {
            spacing: 4

            Repeater {
              model: Hyprland.workspaces

              Rectangle {
                id: wsPill
                required property var modelData
                property bool urgentBlink: false

                Accessible.role: Accessible.Button
                Accessible.name: "Workspace " + modelData.id + (modelData.focused ? ", active" : "") + (modelData.urgent ? ", urgent" : "")

                width: modelData.focused ? 32 : 24
                height: 24
                radius: 12
                color: modelData.focused ? root.theme.accentPrimary :
                       modelData.urgent && urgentBlink ? root.theme.accentRed : root.theme.bgSurface

                Behavior on color {
                  ColorAnimation { duration: 150 }
                }

                SequentialAnimation {
                  loops: Animation.Infinite
                  running: wsPill.modelData.urgent && !wsPill.modelData.focused

                  PropertyAction { target: wsPill; property: "urgentBlink"; value: true }
                  PauseAnimation { duration: 500 }
                  PropertyAction { target: wsPill; property: "urgentBlink"; value: false }
                  PauseAnimation { duration: 500 }

                  onStopped: wsPill.urgentBlink = false
                }

                Text {
                  anchors.centerIn: parent
                  text: wsPill.modelData.id
                  color: wsPill.modelData.focused ? root.theme.bgBase : root.theme.textPrimary
                  font.pixelSize: 12
                  font.family: root.font
                  font.bold: wsPill.modelData.focused
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: wsPill.modelData.activate()
                }

                Behavior on width {
                  NumberAnimation { duration: 150 }
                }
              }
            }
          }

          // Now Playing
          Rectangle {
            height: 24
            width: nowPlayingContent.width + 16
            radius: 12
            color: root.theme.bgSurface
            visible: root.activePlayer !== null

            Accessible.role: Accessible.Button
            Accessible.name: {
              if (!root.activePlayer) return "No media";
              const artist = root.activePlayer.trackArtist || "";
              const title = root.activePlayer.trackTitle || "";
              return "Now playing: " + (artist ? artist + " - " : "") + title;
            }

            Row {
              id: nowPlayingContent
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 8
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
                color: root.theme.accentPrimary
                font.pixelSize: 14
                font.family: root.font
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  if (!root.activePlayer) return "";
                  const artist = root.activePlayer.trackArtist || "";
                  const title = root.activePlayer.trackTitle || "";
                  return artist ? artist + " - " + title : title;
                }
                color: root.theme.textPrimary
                font.pixelSize: 12
                font.family: root.font
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 200)
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activePlayer.togglePlaying()
            }
          }
        }

        // Center section: Clock (left click toggles format)
        Rectangle {
          anchors.centerIn: parent
          height: 24
          width: centerClockText.width + 16
          radius: 12
          color: root.theme.bgSurface

          Text {
            id: centerClockText
            anchors.centerIn: parent
            text: Time.displayString
            color: root.theme.textPrimary
            font.pixelSize: 12
            font.family: root.font
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Time.showFullDate = !Time.showFullDate
          }
        }

        // Right section: System Info + System Tray
        Row {
          id: rightSection
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          // Keyboard Layout
          Rectangle {
            height: 24
            width: kbRow.width + 12
            radius: 12
            color: root.theme.bgSurface

            Row {
              id: kbRow
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰌌"
                color: root.theme.accentCyan
                font.pixelSize: 14
                font.family: root.font
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: SystemInfo.keyboardLayout
                color: root.theme.accentCyan
                font.pixelSize: 12
                font.family: root.font
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: kbSwitchProc.running = true
            }
          }

          // System Tray
          // There's an issue that some tray not display correctly.
          // https://github.com/quickshell-mirror/quickshell/issues/26
          // https://github.com/quickshell-mirror/quickshell/pull/777

          Item {
            id: trayContainer
            height: 24
            width: trayToggle.width + trayBox.width + 4

            Rectangle {
              id: trayToggle
              height: 24
              width: 24
              radius: 12
              color: root.theme.bgSurface

              Text {
                anchors.centerIn: parent
                text: "󰅁"
                color: root.theme.textPrimary
                font.pixelSize: 12
                font.family: root.font
              }
            }

            Rectangle {
              id: trayBox
              anchors.left: trayToggle.right
              anchors.leftMargin: 4
              height: 24
              width: trayHover.containsMouse ? trayIcons.implicitWidth + 4 : 0
              radius: 12
              color: root.theme.bgSurface
              visible: trayRepeater.count > 0
              clip: true

              Behavior on width {
                NumberAnimation { duration: 300 }
              }

              RowLayout {
                id: trayIcons
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                  id: trayRepeater
                  model: SystemTray.items

                  MouseArea {
                    id: trayDelegate
                    required property SystemTrayItem modelData

                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.tooltipTitle || modelData.title || "System tray item"

                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24

                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: (mouse) => {
                      if (mouse.button === Qt.LeftButton) {
                        modelData.activate()
                      } else if (mouse.button === Qt.RightButton) {
                        if (modelData.hasMenu) {
                          menuAnchor.open()
                        }
                      } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate()
                      }
                    }

                    IconImage {
                      anchors.centerIn: parent
                      source: trayDelegate.modelData.icon
                      implicitSize: 16
                    }

                    QsMenuAnchor {
                      id: menuAnchor
                      menu: trayDelegate.modelData.menu

                      anchor.window: trayDelegate.QsWindow.window
                      anchor.adjustment: PopupAdjustment.Flip
                      anchor.onAnchoring: {
                        const window = trayDelegate.QsWindow.window;
                        const widgetRect = window.contentItem.mapFromItem(
                          trayDelegate, 0, trayDelegate.height,
                          trayDelegate.width, trayDelegate.height);
                        menuAnchor.anchor.rect = widgetRect;
                      }
                    }
                  }
                }
              }
            }

            MouseArea {
              id: trayHover
              anchors.fill: parent
              hoverEnabled: true
            }
          }

          // Volume
          Rectangle {
            height: 24
            width: volContent.width + 12
            radius: 12
            color: root.theme.bgSurface

            Accessible.role: Accessible.Button
            Accessible.name: {
              const sink = Pipewire.defaultAudioSink;
              if (!sink || !sink.audio) return "Volume";
              if (sink.audio.muted) return "Volume: muted";
              return "Volume: " + Math.round(sink.audio.volume * 100) + "%";
            }

            Row {
              id: volContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  const s = Pipewire.defaultAudioSink;
                  return SystemInfo.volumeIcon(s?.audio?.volume ?? 0, s?.audio?.muted ?? true);
                }
                color: {
                  const sink = Pipewire.defaultAudioSink;
                  if (!sink || !sink.audio || sink.audio.muted) return root.theme.textMuted;
                  return root.theme.accentPrimary;
                }
                font.pixelSize: 14
                font.family: root.font
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                  const sink = Pipewire.defaultAudioSink;
                  if (!sink || !sink.audio) return "–";
                  if (sink.audio.muted) return "Mute";
                  return Math.round(sink.audio.volume * 100) + "%";
                }
                color: root.theme.textPrimary
                font.pixelSize: 12
                font.family: root.font
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                const sink = Pipewire.defaultAudioSink;
                if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
              }
            }

          }

          // Brightness
          Rectangle {
            height: 24
            width: brightContent.width + 12
            radius: 12
            color: root.theme.bgSurface
            visible: SystemInfo.brightnessAvailable

            Accessible.role: Accessible.StaticText
            Accessible.name: "Brightness: " + Math.round(SystemInfo.brightnessValue * 100) + "%"

            Row {
              id: brightContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰃠"
                color: root.theme.accentOrange
                font.pixelSize: 14
                font.family: root.font
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(SystemInfo.brightnessValue * 100) + "%"
                color: root.theme.textPrimary
                font.pixelSize: 12
                font.family: root.font
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onWheel: (wheel) => {
                brightnessSetProc.command = wheel.angleDelta.y > 0
                  ? ["brightnessctl", "set", "5%+"]
                  : ["brightnessctl", "set", "5%-"];
                brightnessSetProc.running = true;
              }
            }
          }

          // System Info
          Row {
            id: sysInfo

            readonly property color batteryColor: {
              switch (SystemInfo.batteryStatus) {
                case "charging": return root.theme.accentGreen;
                case "good": return root.theme.batteryGood;
                case "warning": return root.theme.batteryWarning;
                default: return root.theme.batteryCritical;
              }
            }

            spacing: 4

            // Network
            Rectangle {
              height: 24
              width: netContent.width + 12
              radius: 12
              color: root.theme.bgSurface
              Accessible.role: Accessible.StaticText
              Accessible.name: {
                if (SystemInfo.networkType === "ethernet") return "Network: Ethernet"
                if (SystemInfo.networkType === "wifi") return "Network: WiFi " + SystemInfo.networkInfo
                return "Network: Disconnected"
              }

              Row {
                id: netContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: {
                    if (SystemInfo.networkType === "ethernet") return "󰈀"
                    if (SystemInfo.networkType === "wifi") return "󰖩"
                    return "󰖪"
                  }
                  color: SystemInfo.networkType === "disconnected" ? root.theme.textMuted : root.theme.accentGreen
                  font.pixelSize: 14
                  font.family: root.font
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.networkInfo
                  color: root.theme.textPrimary
                  font.pixelSize: 12
                  font.family: root.font
                }
              }
            }

            // Battery
            Rectangle {
              height: 24
              width: battContent.width + 12
              radius: 12
              color: root.theme.bgSurface
              visible: SystemInfo.batteryAvailable
              Accessible.role: Accessible.StaticText
              Accessible.name: "Battery: " + SystemInfo.batteryLevel

              Row {
                id: battContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.batteryIcon
                  color: sysInfo.batteryColor
                  font.pixelSize: 14
                  font.family: root.font
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.batteryLevel
                  color: root.theme.textPrimary
                  font.pixelSize: 12
                  font.family: root.font
                }
              }
            }

            // GPU Temperature
            Rectangle {
              height: 24
              width: gpuTempContent.width + 12
              radius: 12
              color: root.theme.bgSurface

              Row {
                id: gpuTempContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰔏"
                  color: root.theme.accentRed
                  font.pixelSize: 14
                  font.family: root.font
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.gpuTemperature
                  color: root.theme.textPrimary
                  font.pixelSize: 12
                  font.family: root.font
                }
              }
            }

            // Temperature
            Rectangle {
              height: 24
              width: tempContent.width + 12
              radius: 12
              color: root.theme.bgSurface
              Accessible.role: Accessible.StaticText
              Accessible.name: "Temperature: " + SystemInfo.temperature

              Row {
                id: tempContent
                anchors.centerIn: parent
                spacing: 6

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "󰍛"
                  color: root.theme.accentRed
                  font.pixelSize: 14
                  font.family: root.font
                }
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: SystemInfo.temperature
                  color: root.theme.textPrimary
                  font.pixelSize: 12
                  font.family: root.font
                }
              }
            }
          }

          // CPU
          Rectangle {
            height: 24
            width: cpuContent.width + 12
            radius: 12
            color: root.theme.bgSurface
            Accessible.role: Accessible.StaticText
            Accessible.name: "CPU: " + SystemInfo.cpuUsage

            Row {
              id: cpuContent
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰻠"
                color: root.theme.accentOrange
                font.pixelSize: 14
                font.family: root.font
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: SystemInfo.cpuUsage
                color: root.theme.textPrimary
                font.pixelSize: 12
                font.family: root.font
              }
            }
                    }
        }
      }

    }
  }
}
