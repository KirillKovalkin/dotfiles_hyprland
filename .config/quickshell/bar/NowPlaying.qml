import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import "../themeswitcher"

Item {
  id: root

  // ── Data model ───────────────────────────────────────────────────────────
  ScriptModel {
    id: mprisModel
    values: Mpris.players.values
    objectProp: "identity"
  }

  readonly property var activePlayer: {
    const players = mprisModel.values;
    if (!players || players.length === 0) return null;
    for (const p of players) {
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    }
    return players[0];
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  height: 24
  width: pill.implicitWidth
  // Bind directly to model length — more reliable than activePlayer chain
  // when a player quits and Mpris.players removes it from the list.
  visible: mprisModel.values.length > 0

  Pill {
    id: pill
    icon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
    label: {
      if (!activePlayer) return "";
      const artist = activePlayer.trackArtist || "";
      const title = activePlayer.trackTitle || "";
      return artist ? artist + " - " + title : title;
    }
    iconColor: Theme.accentPrimary
    maxLabelWidth: 200

    Accessible.role: Accessible.Button
    Accessible.name: {
      if (!activePlayer) return "No media";
      const artist = activePlayer.trackArtist || "";
      const title = activePlayer.trackTitle || "";
      return "Now playing: " + (artist ? artist + " - " : "") + title;
    }

    onClicked: {
      if (activePlayer) activePlayer.togglePlaying();
    }
  }
}
