import QtQuick
import "../themeswitcher"

Pill {
  id: root
  icon: ""
  label: Time.displayString
  labelColor: Theme.textPrimary

  Accessible.role: Accessible.StaticText
  Accessible.name: "Clock: " + Time.displayString

  onClicked: Time.showFullDate = !Time.showFullDate
}
