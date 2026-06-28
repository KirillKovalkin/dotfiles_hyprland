import Quickshell.Services.Pipewire
import QtQuick
import "../themeswitcher"

Pill {
  id: root

  // Cache the audio sink to avoid repeated Pipewire.defaultAudioSink lookups
  readonly property var audio: {
    const s = Pipewire.defaultAudioSink;
    return s?.audio ?? null;
  }

  icon: SystemInfo.volumeIcon(root.audio?.volume ?? 0, root.audio?.muted ?? true)
  label: {
    if (!root.audio) return "–";
    if (root.audio.muted) return "Mute";
    return Math.round(root.audio.volume * 100) + "%";
  }
  iconColor: (!root.audio || root.audio.muted) ? Theme.textMuted : Theme.accentPrimary

  Accessible.role: Accessible.Button
  Accessible.name: {
    if (!root.audio) return "Volume";
    if (root.audio.muted) return "Volume: muted";
    return "Volume: " + Math.round(root.audio.volume * 100) + "%";
  }

  onClicked: {
    if (root.audio) root.audio.muted = !root.audio.muted;
  }
}
