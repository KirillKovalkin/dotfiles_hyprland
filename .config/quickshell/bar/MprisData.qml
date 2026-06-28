pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Services.Mpris

// Shared MPRIS data — a single ScriptModel used by all NowPlaying instances
// across screens, avoiding per-screen duplication of Mpris.players tracking.
Singleton {
  id: root

  ScriptModel {
    id: mprisModel
    values: Mpris.players.values
    objectProp: "identity"
  }

  readonly property var activePlayer: {
    const players = mprisModel.values;
    if (!players || players.length === 0) return null;
    // Prefer currently playing
    for (const p of players) {
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    }
    // Fall back to the first player that can actually be controlled.
    // canTogglePlaying is canPlay || canPause depending on current state.
    // A player with canTogglePlaying=false is a zombie (e.g. browser tab
    // closed but MPRIS not yet unregistered) — skip it.
    for (const p of players) {
      if (p.canTogglePlaying) return p;
    }
    return null;
  }

  readonly property bool hasPlayers: mprisModel.values.length > 0
}
