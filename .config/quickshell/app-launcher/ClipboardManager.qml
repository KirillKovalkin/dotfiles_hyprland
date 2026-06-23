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
  property string previewSource: ""
  property string previewCaption: ""
  property int thumbGeneration: 0
  property bool decoding: false
  property var decodeQueue: []
  readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/quickshell/cliphist-thumbs"
  readonly property bool showingImagePreview: selectedIndex >= 0
      && selectedIndex < entriesModel.count
      && entriesModel.get(selectedIndex).isImage

  ListModel { id: entriesModel }

  function imageInfo(preview) {
    const m = (preview || "").match(/\[\[\s*binary data\s+(\S+\s+\S+)\s+(jpg|jpeg|png|bmp|webp|gif)\s+(\d+)x(\d+)/i)
    if (!m) return null
    let ext = m[2].toLowerCase()
    if (ext === "jpeg") ext = "jpg"
    return {
      ext: ext,
      label: m[1] + " · " + ext.toUpperCase() + " · " + m[3] + "×" + m[4],
      width: parseInt(m[3], 10),
      height: parseInt(m[4], 10)
    }
  }

  function thumbPathFor(id, ext) {
    return thumbDir + "/" + id + "." + ext
  }

  function thumbUrl(id, ext) {
    return "file://" + thumbPathFor(id, ext) + "?g=" + thumbGeneration
  }

  function queueDecode(id, ext, front) {
    if (decodeQueue.some(item => item.id === id && item.ext === ext)) return
    const entry = { id: id, ext: ext }
    if (front) decodeQueue.unshift(entry)
    else decodeQueue.push(entry)
    processDecodeQueue()
  }

  function processDecodeQueue() {
    if (decoding || decodeQueue.length === 0) return
    const item = decodeQueue.shift()
    const path = thumbPathFor(item.id, item.ext)
    const dir = thumbDir.replace(/'/g, "'\\''")
    const safePath = path.replace(/'/g, "'\\''")
    const safeId = item.id.replace(/'/g, "'\\''")
    decoding = true
    decodeProc.command = ["sh", "-c",
      "mkdir -p '" + dir + "' && " +
      "if [ -f '" + safePath + "' ]; then exit 2; fi && " +
      "cliphist decode '" + safeId + "' > '" + safePath + "'"
    ]
    decodeProc.running = true
  }

  function updatePreview() {
    if (selectedIndex < 0 || selectedIndex >= entriesModel.count) {
      previewSource = ""
      previewCaption = ""
      return
    }
    const entry = entriesModel.get(selectedIndex)
    if (!entry.isImage) {
      previewSource = ""
      previewCaption = ""
      return
    }
    previewSource = thumbUrl(entry.id, entry.imageExt)
    previewCaption = entry.imageLabel || entry.text
    queueDecode(entry.id, entry.imageExt, true)
  }

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
        const preview = m && m[2] ? m[2] : ""
        if (preview.indexOf("<meta http-equiv") === 0) return
        const img = root.imageInfo(preview)
        entriesModel.append({
          id: idTok,
          text: preview,
          isImage: img !== null,
          imageExt: img ? img.ext : "",
          imageLabel: img ? img.label : "",
          thumbPath: img ? root.thumbPathFor(idTok, img.ext) : ""
        })
        if (img) root.queueDecode(idTok, img.ext, false)
        while (entriesModel.count > 150) entriesModel.remove(entriesModel.count - 1)
        if (selectedIndex === -1 && entriesModel.count > 0) selectedIndex = 0
      }
    }
  }

  Process {
    id: decodeProc
    command: []
    running: false
    onExited: exitCode => {
      root.decoding = false
      if (exitCode === 0) {
        root.thumbGeneration++
        root.updatePreview()
      }
      root.processDecodeQueue()
    }
  }

  function refreshList() {
    entriesModel.clear()
    decodeQueue = []
    previewSource = ""
    previewCaption = ""
    listProc.running = true
  }

  function copyEntry(idx) {
    if (idx < 0 || idx >= entriesModel.count) return
    const id = entriesModel.get(idx).id
    copyProc.command = ["sh", "-c", "cliphist decode '" + id.replace(/'/g, "'\\''") + "' | wl-copy || true"]
    copyProc.running = true
  }
  Process { id: copyProc; command: []; running: false }

  function deleteEntry(idx) {
    if (idx < 0 || idx >= entriesModel.count || deleteProc.running) return
    const entry = entriesModel.get(idx)
    const safeId = entry.id.replace(/'/g, "'\\''")
    let cmd = "printf '%s\\t\\n' '" + safeId + "' | cliphist delete"
    if (entry.isImage && entry.imageExt) {
      const safePath = thumbPathFor(entry.id, entry.imageExt).replace(/'/g, "'\\''")
      cmd += " && rm -f '" + safePath + "'"
    }
    deleteProc.pendingIndex = idx
    deleteProc.command = ["sh", "-c", cmd]
    deleteProc.running = true
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
      listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    }
  }

  onSelectedIndexChanged: updatePreview()

  Component.onCompleted: refreshList()

  PanelWindow {
    id: panel
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-clipboard"

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    MouseArea { anchors.fill: parent; onClicked: panel.visible = false
      Rectangle { anchors.fill: parent; color: root.theme.bgOverlay }
    }

    Rectangle {
      id: box
      width: root.showingImagePreview ? 1120 : 640
      height: root.showingImagePreview ? 680 : 420
      anchors.centerIn: parent
      radius: 12
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1
      focus: true

      Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
      Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
          event.accepted = true; root.selectedIndex = Math.min(root.selectedIndex + 1, listView.count - 1); listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        } else if (event.key === Qt.Key_Up) {
          event.accepted = true; root.selectedIndex = Math.max(root.selectedIndex - 1, 0); listView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          event.accepted = true; root.copyEntry(root.selectedIndex); panel.visible = false
        } else if (event.key === Qt.Key_Delete) {
          event.accepted = true; root.deleteEntry(root.selectedIndex)
        } else if (event.key === Qt.Key_Escape) {
          event.accepted = true; panel.visible = false
        }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          spacing: 8
          Text { text: "  Clipboard"; color: root.theme.accentPrimary; font.pixelSize: 14; font.family: root.font; font.bold: true }
          Item { Layout.fillWidth: true }
          Text { text: entriesModel.count + " items"; color: root.theme.textMuted; font.pixelSize: 11; font.family: root.font }
        }

        Rectangle {
          id: previewPanel
          Layout.fillWidth: true
          Layout.preferredHeight: root.showingImagePreview ? 420 : 0
          visible: root.showingImagePreview
          radius: 8
          color: "#000000"
          border.color: root.theme.bgBorder
          border.width: 1
          clip: true

          Behavior on Layout.preferredHeight { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

          Image {
            id: previewImage
            anchors.fill: parent
            anchors.margins: 4
            source: root.previewSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            smooth: true
            mipmap: true
            opacity: status === Image.Ready ? 1 : 0
          }

          Column {
            anchors.centerIn: parent
            spacing: 8
            visible: previewImage.status !== Image.Ready

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰋩"
              color: root.theme.textMuted
              font.pixelSize: 32
              font.family: root.font
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.decoding ? "Loading…" : "No preview"
              color: root.theme.textMuted
              font.pixelSize: 10
              font.family: root.font
            }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 24
            color: Qt.rgba(0, 0, 0, 0.72)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 10
              text: root.previewCaption
              color: "#d0d0d0"
              font.pixelSize: 10
              font.family: root.font
              elide: Text.ElideRight
              width: parent.width - 20
            }
          }
        }

        ListView {
          id: listView
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: entriesModel
          clip: true
          currentIndex: root.selectedIndex
          boundsBehavior: Flickable.StopAtBounds

          delegate: Rectangle {
            width: listView.width
            height: 40
            radius: 8
            color: root.selectedIndex === index ? root.theme.bgSelected : "transparent"

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 12
              spacing: 10

              Rectangle {
                width: 36
                height: 24
                radius: 6
                color: "transparent"
                Layout.alignment: Qt.AlignVCenter
                Text {
                  anchors.centerIn: parent
                  text: (index + 1).toString()
                  color: root.theme.textMuted
                  font.pixelSize: 12
                  font.family: root.font
                }
              }

              Text {
                visible: model.isImage
                text: "󰋩"
                color: root.theme.accentCyan
                font.pixelSize: 14
                font.family: root.font
                Layout.alignment: Qt.AlignVCenter
              }

              Text {
                text: model.isImage ? (model.imageLabel || model.text) : (model.text || "")
                elide: Text.ElideRight
                color: root.selectedIndex === index ? root.theme.textPrimary : root.theme.textSecondary
                font.pixelSize: 13
                font.family: root.font
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: root.selectedIndex = index
              onClicked: { root.copyEntry(index); panel.visible = false }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 12
          Row { spacing: 6; Rectangle { width: hintKeys.width + 8; height: 18; radius: 4; color: root.theme.bgSurface; Text { id: hintKeys; anchors.centerIn: parent; text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } } Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } }
          Row { spacing: 6; Rectangle { width: hintEnter.width + 8; height: 18; radius: 4; color: root.theme.bgSurface; Text { id: hintEnter; anchors.centerIn: parent; text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } } Text { text: "copy"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } }
          Row { spacing: 6; Rectangle { width: hintDel.width + 8; height: 18; radius: 4; color: root.theme.bgSurface; Text { id: hintDel; anchors.centerIn: parent; text: "Del"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } } Text { text: "delete"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } }
          Row { spacing: 6; Rectangle { width: hintEsc.width + 8; height: 18; radius: 4; color: root.theme.bgSurface; Text { id: hintEsc; anchors.centerIn: parent; text: "Esc"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } } Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font } }
          Item { Layout.fillWidth: true }
        }
      }
    }
  }

  IpcHandler {
    target: "clipboard-manager"
    function toggle() { panel.visible = !panel.visible; if (panel.visible) { refreshList(); selectedIndex = entriesModel.count > 0 ? 0 : -1; box.forceActiveFocus(); } }
  }
}
