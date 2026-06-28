pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  property bool showFullDate: false

  readonly property string displayString: {
    if (showFullDate) return fullDateString
    return simpleTimeString
  }

  readonly property string simpleTimeString: {
    Qt.formatDateTime(clock.date, "dddd hh:mm")
  }

  readonly property string fullDateString: {
    const d = clock.date
    return Qt.formatDateTime(d, "d MMMM") + " W" + isoWeek(d) + " " + Qt.formatDateTime(d, "yyyy")
  }

  function isoWeek(d) {
    const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
    date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7))
    const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1))
    return Math.ceil(((date - yearStart) / 86400000 + 1) / 7)
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
