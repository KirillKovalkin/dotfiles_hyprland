import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../themeswitcher"
import "../bar"

Scope {
  id: root
  property var theme: Theme
  property string font: Theme.fontFamily

  // ── Wallpaper path ──────────────────────────────────────────────────────
  readonly property string wallpaperPath:
    Quickshell.env("HOME") + "/Pictures/Wallpaper/wallpaper.webp"

  // ── Auth state ───────────────────────────────────────────────────────────
  property string password: ""
  property bool authFailed: false
  property bool pamActive: false
  property string pamErrorText: ""
  property int authAttempts: 0
  property bool pamResponded: false

  // ── Shake animation proxy (Component isolates inner ids) ──────────────
  property real shakeOffset: 0

  // ── Lockout ─────────────────────────────────────────────────────────────
  readonly property int maxAttempts: 3
  readonly property int lockoutSeconds: 10
  property int lockoutRemaining: 0
  readonly property bool lockedOut: lockoutRemaining > 0

  // ── Keyboard layout (reactively bound to SystemInfo singleton) ───────────
  readonly property string kbLayout: SystemInfo.keyboardLayout

  // ── Clock ────────────────────────────────────────────────────────────────
  // Uses Time singleton (bar/Time.qml) — no duplicate SystemClock

  // ══════════════════════════════════════════════════════════════════════════
  // PAM authentication
  // ══════════════════════════════════════════════════════════════════════════
  PamContext {
    id: pam

    onResponseRequiredChanged: {
      if (pam.responseRequired && !root.pamResponded && root.password.length > 0) {
        root.pamResponded = true
        pam.respond(root.password)
      }
    }

    onCompleted: result => {
      root.pamActive = false
      root.pamResponded = false
      if (result === PamResult.Success) {
        root.password = ""
        root.authFailed = false
        root.authAttempts = 0
        root.lockoutRemaining = 0
        lock.locked = false
      } else {
        root.authFailed = true
        root.authAttempts++
        root.password = ""
        pam.active = false
        if (pam.message && pam.messageIsError) {
          root.pamErrorText = pam.message
        }
        // Lockout after max failed attempts
        if (root.authAttempts >= root.maxAttempts) {
          root.lockoutRemaining = root.lockoutSeconds
          lockoutTimer.start()
        } else {
          shakeAnim.start()
        }
      }
    }

    onError: err => {
      root.pamActive = false
      root.pamResponded = false
      root.authFailed = true
      root.pamErrorText = "Authentication error"
      root.password = ""
      pam.active = false
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Lockout timer
  // ══════════════════════════════════════════════════════════════════════════
  Timer {
    id: lockoutTimer
    interval: 1000
    repeat: true
    onTriggered: {
      root.lockoutRemaining--
      if (root.lockoutRemaining <= 0) {
        stop()
        root.authAttempts = 0
        root.authFailed = false
        root.pamErrorText = ""
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IPC: qs ipc call lockscreen lock
  // ══════════════════════════════════════════════════════════════════════════
  IpcHandler {
    target: "lockscreen"

    function lock(): void {
      if (lock.locked) return
      root.password = ""
      root.authFailed = false
      root.pamErrorText = ""
      root.authAttempts = 0
      root.pamResponded = false
      root.lockoutRemaining = 0
      lockoutTimer.stop()
      pam.active = false
      lock.locked = true
    }

    function unlock(): void {
      if (lock.locked) {
        lock.locked = false
        root.password = ""
        root.authFailed = false
        root.authAttempts = 0
        root.lockoutRemaining = 0
        lockoutTimer.stop()
        pam.active = false
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Shake animation for wrong password
  // ══════════════════════════════════════════════════════════════════════════
  SequentialAnimation {
    id: shakeAnim

    NumberAnimation {
      target: root; property: "shakeOffset"
      to: -12; duration: 50; easing.type: Easing.OutCubic
    }
    NumberAnimation {
      target: root; property: "shakeOffset"
      to: 12; duration: 80; easing.type: Easing.InOutCubic
    }
    NumberAnimation {
      target: root; property: "shakeOffset"
      to: -8; duration: 80; easing.type: Easing.InOutCubic
    }
    NumberAnimation {
      target: root; property: "shakeOffset"
      to: 6; duration: 80; easing.type: Easing.InOutCubic
    }
    NumberAnimation {
      target: root; property: "shakeOffset"
      to: 0; duration: 60; easing.type: Easing.InCubic
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Session Lock
  // ══════════════════════════════════════════════════════════════════════════
  WlSessionLock {
    id: lock

    surface: Component {
      WlSessionLockSurface {
        id: lockSurface
        color: root.theme.bgBase

        // ── Blurred wallpaper background ──────────────────────────────────
        Image {
          id: bgImage
          anchors.fill: parent
          source: "file://" + root.wallpaperPath
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: false
          visible: true

          layer.enabled: true
          layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 64
            blur: 0.8
            saturation: 0.3
            brightness: 0.3
          }
        }

        // Dark overlay on top of blurred wallpaper
        Rectangle {
          anchors.fill: parent
          color: root.theme.bgOverlay
        }

        // ── Center content ─────────────────────────────────────────────────
        Item {
          id: contentCenter
          anchors.centerIn: parent
          width: Math.min(480, parent.width - 40)
          height: contentColumn.implicitHeight

          ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            width: parent.width
            spacing: 0

            // ── Time: HH:MM ────────────────────────────────────────────────
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: Qt.formatDateTime(Time.currentDate, "hh:mm")
              color: root.theme.textPrimary
              font.pixelSize: 72
              font.family: root.font
              font.bold: true

              Behavior on color { ColorAnimation { duration: 150 } }
            }

            // ── Date: DDDD MM YYYY ─────────────────────────────────────────
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: Qt.formatDateTime(Time.currentDate, "dddd dd MMMM yyyy")
              color: root.theme.textSecondary
              font.pixelSize: 22
              font.family: root.font

              Behavior on color { ColorAnimation { duration: 150 } }
            }

            // Spacer
            Item { Layout.preferredHeight: 28 }

            // ── Password input bar ─────────────────────────────────────────
            Rectangle {
              id: inputBar
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredWidth: 360
              Layout.preferredHeight: 50
              radius: 14
              color: root.theme.bgSurface
              border.color: root.authFailed
                ? root.theme.accentRed
                : (passwordInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder)
              border.width: 1.5

              transform: Translate {
                id: inputBarTransform
                x: root.shakeOffset
              }

              Behavior on color { ColorAnimation { duration: 150 } }
              Behavior on border.color { ColorAnimation { duration: 150 } }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 14
                spacing: 10

                // Lock icon
                Text {
                  text: root.authFailed ? "󰌿" : "󰌾"
                  color: root.authFailed ? root.theme.accentRed : root.theme.textMuted
                  font.pixelSize: 20
                  font.family: root.font
                  Layout.alignment: Qt.AlignVCenter

                  Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Password input — always focused
                TextInput {
                  id: passwordInput
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  color: root.theme.textPrimary
                  font.pixelSize: 17
                  font.family: root.font
                  echoMode: TextInput.Password
                  passwordCharacter: "●"
                  passwordMaskDelay: 800
                  focus: true
                  activeFocusOnPress: true
                  selectByMouse: false
                  maximumLength: 128

                  cursorDelegate: Rectangle {
                    visible: passwordInput.activeFocus
                    width: 2
                    height: passwordInput.font.pixelSize + 2
                    color: root.theme.accentPrimary
                  }

                  onTextChanged: {
                    if (root.lockedOut) {
                      text = ""
                      return
                    }
                    root.password = text
                    if (root.authFailed && text.length > 0) {
                      root.authFailed = false
                      root.pamErrorText = ""
                    }
                  }

                  Keys.onReturnPressed: {
                    if (root.lockedOut) return
                    if (root.password.length > 0 && !pam.active) {
                      root.authFailed = false
                      root.pamErrorText = ""
                      root.pamResponded = false
                      pam.active = true
                    }
                  }

                  Keys.onEscapePressed: {
                    if (root.lockedOut) return
                    root.password = ""
                    root.authFailed = false
                    root.pamErrorText = ""
                    root.pamResponded = false
                    pam.active = false
                  }

                  Keys.onPressed: event => {
                    if (event.key === Qt.Key_Backspace
                        && root.password.length === 0) {
                      root.authFailed = false
                      root.pamErrorText = ""
                    }
                  }

                  Component.onCompleted: forceActiveFocus()

                  Behavior on color { ColorAnimation { duration: 150 } }
                }

                // ── Keyboard layout indicator ──────────────────────────────
                Rectangle {
                  Layout.alignment: Qt.AlignVCenter
                  Layout.preferredWidth: 32
                  Layout.preferredHeight: 26
                  radius: 8
                  color: root.theme.bgHover

                  Behavior on color { ColorAnimation { duration: 150 } }

                  Text {
                    anchors.centerIn: parent
                    text: root.kbLayout.toUpperCase()
                    color: root.theme.accentPrimary
                    font.pixelSize: 13
                    font.family: root.font
                    font.bold: true

                    Behavior on color { ColorAnimation { duration: 150 } }
                  }
                }
              }
            }

            // ── Error / PAM message ────────────────────────────────────────
            Item {
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredHeight: 28
              Layout.fillWidth: true

              Text {
                anchors.centerIn: parent
                text: {
                  if (root.lockedOut)
                    return "Too many attempts — wait " + root.lockoutRemaining + "s"
                  if (root.authFailed && root.pamErrorText) return root.pamErrorText
                  if (root.authFailed) return "Wrong password"
                  return ""
                }
                color: root.authFailed ? root.theme.accentRed : root.theme.textMuted
                font.pixelSize: 13
                font.family: root.font
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                elide: Text.ElideRight
                visible: text !== ""

                Behavior on color { ColorAnimation { duration: 150 } }
              }
            }
          }
        }

        // Click anywhere to refocus the password input
        MouseArea {
          anchors.fill: parent
          z: -1
          onClicked: passwordInput.forceActiveFocus()
        }
      }
    }
  }

}
