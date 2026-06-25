import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"
  property int selectedIndex: -1
  property bool showPreview: false
  property int previewRevision: 0
  // Tracks real mouse position to distinguish actual movement from list-scroll drift
  property real lastGlobalMouseX: -1
  property real lastGlobalMouseY: -1

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
  }

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
    entriesModel.clear()
    selectedIndex = -1
    showPreview = false
    listProc.running = true
  }

  function copyEntry(idx) {
    if (idx < 0 || idx >= entriesModel.count) return
    const id = entriesModel.get(idx).id
    copyProc.command = ["sh", "-c",
      "cliphist decode '" + id.replace(/'/g, "'\\''") + "' | wl-copy || true"]
    copyProc.running = true
  }

  function deleteEntry(idx) {
    if (idx < 0 || idx >= entriesModel.count || deleteProc.running) return
    const entry = entriesModel.get(idx)
    const safeId = entry.id.replace(/'/g, "'\\''")
    deleteProc.pendingIndex = idx
    deleteProc.command = ["sh", "-c",
      "printf '%s\\t\\n' '" + safeId + "' | cliphist delete"]
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
      const safeId = entry.id.replace(/'/g, "'\\''")
      previewProc.command = ["sh", "-c",
        "cliphist decode '" + safeId + "' > /tmp/qs-clipboard-preview.png"]
      previewProc.running = true
    }
  }

  onSelectedIndexChanged: updatePreview()
  Component.onCompleted: refreshList()

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
        if (event.key === Qt.Key_Down) {
          event.accepted = true
          if (listView.count > 0) {
            root.selectedIndex = (root.selectedIndex + 1) % listView.count
            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
          }
        } else if (event.key === Qt.Key_Up) {
          event.accepted = true
          if (listView.count > 0) {
            root.selectedIndex = (root.selectedIndex - 1 + listView.count) % listView.count
            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
          }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          event.accepted = true
          root.copyEntry(root.selectedIndex)
          panel.visible = false
        } else if (event.key === Qt.Key_Delete) {
          event.accepted = true
          root.deleteEntry(root.selectedIndex)
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
                  if (Math.abs(g.x - root.lastGlobalMouseX) < 1 &&
                      Math.abs(g.y - root.lastGlobalMouseY) < 1) return
                  root.lastGlobalMouseX = g.x
                  root.lastGlobalMouseY = g.y
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

            Row {
              spacing: 4
              Rectangle {
                width: hk1.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
                Text { id: hk1; anchors.centerIn: parent; text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
              }
              Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              spacing: 4
              Rectangle {
                width: hk2.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
                Text { id: hk2; anchors.centerIn: parent; text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
              }
              Text { text: "copy"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              spacing: 4
              Rectangle {
                width: hk3.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
                Text { id: hk3; anchors.centerIn: parent; text: "Del"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
              }
              Text { text: "delete"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
              spacing: 4
              Rectangle {
                width: hk4.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
                Text { id: hk4; anchors.centerIn: parent; text: "Esc"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
              }
              Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
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
