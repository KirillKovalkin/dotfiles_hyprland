import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../themeswitcher"

Scope {
  id: root
  property var theme: Theme
  property string font: Theme.fontFamily
  property int selectedIndex: -1
  property bool showPreview: false
  property int previewRevision: 0
  // Tracks input mode: "keyboard" = mouse ignored, "mouse" = mouse active
  property string _inputMode: "keyboard"
  property real _lastMouseX: -1
  property real _lastMouseY: -1
  // Refresh was requested while listProc was running — retry on exit
  property bool _refreshPending: false

  // ── Data ──────────────────────────────────────────────────────────────────
  ListModel { id: entriesModel }

  function isImageEntry(text) {
    return /^\[\[.*\]\]$/.test(text.trim())
  }

  function imageSizeLabel(text) {
    const m = text.match(/(\d+)\s+bytes/)
    return m ? "Image · " + Number(m[1]).toLocaleString() + " B" : "Image"
  }

  // ── Processes ─────────────────────────────────────────────────────────────
  Process {
    id: listProc
    command: ["cliphist", "list"]
    running: false
    stdout: SplitParser {
      onRead: data => {
        const line = data.trim()
        if (line === "") return
        const m = line.match(/^([^\s]+)\s*(.*)$/)
        const idTok = m ? m[1] : line
        const preview = m && m[2] ? m[2].trim() : ""
        if (preview.startsWith("<meta http-equiv")) return
        const img = root.isImageEntry(preview)
        entriesModel.append({ id: idTok, text: preview, isImage: img })
        if (entriesModel.count > 150) entriesModel.remove(entriesModel.count - 1)
        if (root.selectedIndex === -1 && entriesModel.count > 0) root.selectedIndex = 0
      }
    }
    onExited: {
      if (root._refreshPending) {
        root._refreshPending = false
        root.refreshList()
      }
    }
  }

  // Shell safety: IDs are passed as positional $1 to sh -c, not interpolated
  Process {
    id: copyProc
    command: []
    running: false
  }

  Process {
    id: deleteProc
    command: []
    running: false
    property int pendingIndex: -1
    onExited: exitCode => {
      const idx = pendingIndex
      pendingIndex = -1
      if (exitCode !== 0 || idx < 0 || idx >= entriesModel.count) return
      entriesModel.remove(idx)
      if (entriesModel.count === 0) {
        root.selectedIndex = -1
      } else if (idx < root.selectedIndex) {
        root.selectedIndex--
      } else if (root.selectedIndex >= entriesModel.count) {
        root.selectedIndex = entriesModel.count - 1
      }
      if (root.selectedIndex >= 0)
        listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    }
  }

  Process {
    id: previewProc
    command: []
    running: false
    onExited: exitCode => {
      if (exitCode === 0) root.previewRevision++
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  function refreshList() {
    if (listProc.running) {
      _refreshPending = true
      return
    }
    _refreshPending = false
    entriesModel.clear()
    selectedIndex = -1
    showPreview = false
    _inputMode = "keyboard"
    _lastMouseX = -1
    _lastMouseY = -1
    listProc.running = true
  }

  function copyEntry(idx) {
    if (idx < 0 || idx >= entriesModel.count) return
    const entry = entriesModel.get(idx)
    // $1 positional param — no shell injection
    copyProc.command = ["sh", "-c", 'cliphist decode "$1" | wl-copy || true', "sh", entry.id]
    copyProc.running = true
  }

  function deleteEntry(idx) {
    if (idx < 0 || idx >= entriesModel.count || deleteProc.running) return
    const entry = entriesModel.get(idx)
    deleteProc.pendingIndex = idx
    deleteProc.command = ["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete', "sh", entry.id]
    deleteProc.running = true
  }

  function updatePreview() {
    if (selectedIndex < 0 || selectedIndex >= entriesModel.count) {
      showPreview = false
      return
    }
    const entry = entriesModel.get(selectedIndex)
    if (!entry.isImage) {
      showPreview = false
      return
    }
    showPreview = true
    if (!previewProc.running) {
      previewProc.command = ["sh", "-c",
        'cliphist decode "$1" > /tmp/qs-clipboard-preview.png', "sh", entry.id]
      previewProc.running = true
    }
  }

  onSelectedIndexChanged: previewDebounce.restart()
  Component.onCompleted: refreshList()

  // Debounce preview toggling — avoids rapid width animation glitching
  // during keyboard navigation (200ms = matches box width animation duration)
  Timer {
    id: previewDebounce
    interval: 200
    onTriggered: updatePreview()
  }

  // ── IPC ───────────────────────────────────────────────────────────────────
  IpcHandler {
    target: "clipboard-manager"
    function toggle() {
      panel.visible = !panel.visible
      if (panel.visible) {
        refreshList()
        box.forceActiveFocus()
      }
    }
  }

  // ── Window ────────────────────────────────────────────────────────────────
  PanelWindow {
    id: panel
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-clipboard"
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; bottom: true; left: true; right: true }

    // Backdrop
    MouseArea {
      anchors.fill: parent
      onClicked: panel.visible = false
      Rectangle { anchors.fill: parent; color: root.theme.bgOverlay }
    }

    // Main box — expands right when preview is visible
    Rectangle {
      id: box
      anchors.centerIn: parent
      // 580 base (same as AppLauncher) + 16 spacing + 260 preview panel
      width: root.showPreview ? 856 : 580
      height: 480
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1
      focus: true

      Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
      }

      Keys.onPressed: event => {
        root._inputMode = "keyboard"
        if (event.key === Qt.Key_Down) {
          event.accepted = true
          if (listView.count > 0)
            root.selectedIndex = (root.selectedIndex + 1) % listView.count
        } else if (event.key === Qt.Key_Up) {
          event.accepted = true
          if (listView.count > 0)
            root.selectedIndex = (root.selectedIndex - 1 + listView.count) % listView.count
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          event.accepted = true
          root.copyEntry(root.selectedIndex)
          panel.visible = false
        } else if (event.key === Qt.Key_Delete) {
          event.accepted = true
          root.deleteEntry(root.selectedIndex)
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
          event.accepted = true
          if (listView.count > 0) {
            if (event.key === Qt.Key_Backtab)
              root.selectedIndex = (root.selectedIndex - 1 + listView.count) % listView.count
            else
              root.selectedIndex = (root.selectedIndex + 1) % listView.count
          }
        } else if (event.key === Qt.Key_Escape) {
          event.accepted = true
          panel.visible = false
        }
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // ── List panel ─────────────────────────────────────────────────────
        ColumnLayout {
          // Fixed 548px = 580 box - 2×16 margins (same inner width as AppLauncher)
          Layout.preferredWidth: 548
          Layout.fillHeight: true
          spacing: 12

          // Header
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
              text: "  Clipboard"
              color: root.theme.accentPrimary
              font.pixelSize: 14
              font.family: root.font
              font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
              text: entriesModel.count + " item" + (entriesModel.count !== 1 ? "s" : "")
              color: root.theme.textMuted
              font.pixelSize: 11
              font.family: root.font
            }
          }

          // List
          ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: entriesModel
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: root.selectedIndex
            highlightMoveDuration: 150
            highlightMoveVelocity: -1

            highlight: Rectangle {
              radius: 8
              color: root.theme.bgSelected
              visible: root.selectedIndex >= 0

              Rectangle {
                width: 3
                height: 24
                radius: 2
                color: root.theme.accentPrimary
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            delegate: Rectangle {
              id: delegateRoot
              required property var modelData
              required property int index

              width: listView.width
              height: 44
              radius: 8
              color: "transparent"

              Accessible.role: Accessible.ListItem
              Accessible.name: delegateRoot.modelData.isImage
                ? "Image clipboard entry " + (delegateRoot.index + 1)
                : "Text clipboard entry: " + (delegateRoot.modelData.text || "").substring(0, 80)

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // Type icon: \uF03E = nf-fa-picture-o (image), \uF0F6 = nf-fa-file-text (text)
                Text {
                  text: delegateRoot.modelData.isImage ? "\uF03E" : "\uF0F6"
                  color: root.selectedIndex === delegateRoot.index
                    ? root.theme.accentPrimary
                    : root.theme.textMuted
                  font.pixelSize: 15
                  font.family: root.font
                  Layout.alignment: Qt.AlignVCenter
                }

                // Content preview
                Text {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  text: delegateRoot.modelData.isImage
                    ? root.imageSizeLabel(delegateRoot.modelData.text)
                    : (delegateRoot.modelData.text || "")
                  color: root.selectedIndex === delegateRoot.index
                    ? root.theme.textPrimary
                    : root.theme.textSecondary
                  font.pixelSize: 13
                  font.family: root.font
                  font.bold: root.selectedIndex === delegateRoot.index
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.copyEntry(delegateRoot.index); panel.visible = false }
                onPositionChanged: mouse => {
                  const g = mapToGlobal(mouse.x, mouse.y)
                  if (root._inputMode === "keyboard") {
                    // First position report after opening — just record, don't select
                    if (root._lastMouseX < 0) {
                      root._lastMouseX = g.x
                      root._lastMouseY = g.y
                      return
                    }
                    // Mouse moved (≥2px) → switch to mouse mode and select
                    if (Math.abs(g.x - root._lastMouseX) >= 2 ||
                        Math.abs(g.y - root._lastMouseY) >= 2) {
                      root._inputMode = "mouse"
                    } else {
                      // Same position — Qt delegate-appeared-under-cursor quirk, ignore
                      return
                    }
                  }
                  // Mouse mode: update selection on movement
                  if (Math.abs(g.x - root._lastMouseX) < 1 &&
                      Math.abs(g.y - root._lastMouseY) < 1) return
                  root._lastMouseX = g.x
                  root._lastMouseY = g.y
                  root.selectedIndex = delegateRoot.index
                }
              }
            }

            // Empty state
            Text {
              anchors.centerIn: parent
              text: "  Clipboard is empty"
              color: root.theme.textMuted
              font.pixelSize: 14
              font.family: root.font
              visible: listView.count === 0
            }
          }

          // Footer hints
          RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Repeater {
              model: [
                { key: "↑↓",     label: "navigate" },
                { key: "⏎",      label: "copy" },
                { key: "Del",    label: "delete" },
                { key: "Tab",    label: "next" },
                { key: "⇧Tab",   label: "prev" },
                { key: "Esc",    label: "close" }
              ]

              Row {
                spacing: 4
                Rectangle {
                  width: hintKey.width + 8; height: 18; radius: 4
                  color: root.theme.bgSurface
                  Text {
                    id: hintKey
                    anchors.centerIn: parent
                    text: modelData.key
                    color: root.theme.textMuted
                    font.pixelSize: 10
                    font.family: root.font
                  }
                }
                Text {
                  text: modelData.label
                  color: root.theme.textMuted
                  font.pixelSize: 10
                  font.family: root.font
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }

            Item { Layout.fillWidth: true }
          }
        }

        // ── Image preview panel (visible only for image entries) ────────────
        Rectangle {
          Layout.preferredWidth: 260
          Layout.fillHeight: true
          radius: 12
          color: root.theme.bgSurface
          border.color: root.theme.bgBorder
          border.width: 1
          visible: root.showPreview
          clip: true

          opacity: root.showPreview ? 1.0 : 0.0
          Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Preview header
            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: "\uF03E  Preview"
                color: root.theme.accentPrimary
                font.pixelSize: 12
                font.family: root.font
                font.bold: true
              }

              Item { Layout.fillWidth: true }

              Rectangle {
                width: 3; height: 14; radius: 2
                color: root.theme.accentPrimary
                opacity: 0.5
              }
            }

            // Image container
            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              color: root.theme.bgBase
              radius: 8
              clip: true

              Image {
                id: previewImage
                anchors.fill: parent
                anchors.margins: 8
                source: root.showPreview
                  ? ("file:///tmp/qs-clipboard-preview.png?" + root.previewRevision)
                  : ""
                fillMode: Image.PreserveAspectFit
                cache: false
                smooth: true
                asynchronous: true
              }

              // Loading indicator
              Text {
                anchors.centerIn: parent
                text: "\uF021"
                color: root.theme.textMuted
                font.pixelSize: 20
                font.family: root.font
                visible: previewImage.status === Image.Loading
              }

              // Error state
              Text {
                anchors.centerIn: parent
                text: "\uF071  Load error"
                color: root.theme.textMuted
                font.pixelSize: 12
                font.family: root.font
                visible: previewImage.status === Image.Error
              }
            }
          }
        }
      }
    }
  }
}
