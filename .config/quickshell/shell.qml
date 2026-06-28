//@ pragma UseQApplication
//@ pragma Env QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import "bar"
import "applauncher"
import "clipboardmanager"
import "notifications"
import "themeswitcher"
import "osd"
import "lockscreen"

Scope {
  ThemeSwitcher { id: ts }
  Bar { theme: ts.theme }

  // ── Lazy-loaded popups (async background load — bar shows faster) ──────
  LazyLoader {
    loading: true
    AppLauncher {}
  }

  LazyLoader {
    loading: true
    ClipboardManager {}
  }

  // ── Always-loaded components ───────────────────────────────────────────
  NotificationPopup { theme: ts.theme }
  OSD { theme: ts.theme }
  LockScreen { theme: ts.theme }
}
