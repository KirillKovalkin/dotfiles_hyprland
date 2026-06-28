import QtQuick
import "../themeswitcher"

Item {
  id: root

  // ── Shared data from MprisData singleton (one ScriptModel for all screens) ──
  readonly property var activePlayer: MprisData.activePlayer

  // ── UI ───────────────────────────────────────────────────────────────────
  height: 24
  width: pill.implicitWidth
  // Hide when no functional player exists (zombie players with canPlay=false
  // are filtered out by MprisData.activePlayer — pill disappears on tab close).
  visible: root.activePlayer !== null

  Pill {
    id: pill
    icon: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
    label: {
      if (!root.activePlayer) return "";
      const artist = root.activePlayer.trackArtist || "";
      const title = root.activePlayer.trackTitle || "";
      return artist ? artist + " - " + title : title;
    }
    iconColor: Theme.accentPrimary
    maxLabelWidth: 200

    Accessible.role: Accessible.Button
    Accessible.name: {
      if (!root.activePlayer) return "No media";
      const artist = root.activePlayer.trackArtist || "";
      const title = root.activePlayer.trackTitle || "";
      return "Now playing: " + (artist ? artist + " - " : "") + title;
    }

    onClicked: {
      // Guard against stale/zombie players that still exist in Mpris.players
      // but have canTogglePlaying=false (e.g. browser tab just closed).
      // Per MprisPlayer docs: togglePlaying() may only be called if
      // canTogglePlaying is true (canPlay || canPause depending on state).
      if (root.activePlayer && root.activePlayer.canTogglePlaying) root.activePlayer.togglePlaying();
    }
  }
}
