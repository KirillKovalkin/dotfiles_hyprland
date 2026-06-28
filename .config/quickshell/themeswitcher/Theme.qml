pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int currentIndex: 0
    property int previewIndex: -1

    readonly property var current: {
        if (previewIndex >= 0 && previewIndex < themes.length)
            return themes[previewIndex]
        return themes[currentIndex]
    }

    readonly property int count: themes.length
    readonly property string currentName: current.name
    readonly property string currentFamily: current.family
    readonly property bool isDark: !isLightColor(current.bgBase)

    function isLightColor(c) {
        return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.5
    }

    // Reactive color properties
    readonly property color bgBase:       current.bgBase
    readonly property color bgSurface:    current.bgSurface
    readonly property color bgHover:      current.bgHover
    readonly property color bgSelected:   current.bgSelected
    readonly property color bgBorder:     current.bgBorder
    readonly property color bgOverlay:    isDark ? "#88000000" : "#88ffffff"

    readonly property color textPrimary:   current.textPrimary
    readonly property color textSecondary: current.textSecondary
    readonly property color textMuted:     current.textMuted

    readonly property color accentPrimary: current.accentPrimary
    readonly property color accentCyan:    current.accentCyan
    readonly property color accentGreen:   current.accentGreen
    readonly property color accentOrange:  current.accentOrange
    readonly property color accentRed:     current.accentRed

    // Semantic aliases
    readonly property color urgencyLow:      textMuted
    readonly property color urgencyNormal:   accentPrimary
    readonly property color urgencyCritical: accentRed
    readonly property color batteryGood:     accentGreen
    readonly property color batteryWarning:  accentOrange
    readonly property color batteryCritical: accentRed

    // Theme application is purely internal — Quickshell reacts to color property
    // changes via the reactive bindings below. No external tools (kitty/hyprland/
    // gsettings) are modified.
    function applyTheme(t) {
        // all work is done by reactive property bindings
    }

    function setTheme(index) {
        if (index >= 0 && index < themes.length) {
            currentIndex = index
            saveProc.command = ["sh", "-c",
                'printf "%s" "$1" > "$HOME/.config/quickshell/theme.conf"',
                "sh", String(index)]
            saveProc.running = true
            applyTheme(themes[index])
        }
    }

    Process { id: saveProc; running: false }

    Process {
        id: loadProc
        command: ["sh", "-c", "cat $HOME/.config/quickshell/theme.conf 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const idx = parseInt(text.trim())
                if (!isNaN(idx) && idx >= 0 && idx < root.themes.length) {
                    root.currentIndex = idx
                    root.applyTheme(root.themes[idx])
                }
            }
        }
    }

    FileView {
        id: themesFile
        path: Quickshell.env("HOME") + "/.config/quickshell/themeswitcher/themes.json"
        onTextChanged: {
            const raw = themesFile.text()
            if (!raw) return
            try {
                root.themes = JSON.parse(raw)
                loadProc.running = true
            } catch (e) {
                console.error("Failed to parse themes.json:", e)
            }
        }
    }

    property var themes: [
        {
            name: "Night", family: "Tokyo Night",
            bgBase: "#1a1b26", bgSurface: "#24283b", bgHover: "#1e2235",
            bgSelected: "#283457", bgBorder: "#32364a",
            textPrimary: "#c0caf5", textSecondary: "#a9b1d6", textMuted: "#565f89",
            accentPrimary: "#7aa2f7", accentCyan: "#7dcfff",
            accentGreen: "#9ece6a", accentOrange: "#ff9e64", accentRed: "#f7768e"
        }
    ]
}
