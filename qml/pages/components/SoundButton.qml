import QtQuick 2.0
import Sailfish.Silica 1.0

// Component which defines the buttons
// used for sound selection

Item {
    id: root

    property alias text: button.text
    property real preferredWidth: -1
    property bool selected: false
    property bool playing: false

    // 'enabled' is inherited from Item

    signal clicked()

    width: button.width
    height: button.height

    // Rounded highlight background. Declared before the
    // Button so it renders underneath it.
    Rectangle {
        anchors.fill: parent
        radius: Theme.paddingSmall

        color: root.selected
               ? Theme.highlightColor
               : "transparent"

        opacity: root.selected ? 0.15 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    Button {
        id: button

        anchors.centerIn: parent
        preferredWidth: root.preferredWidth

        enabled: root.enabled
        highlighted: root.selected

        color: !enabled
               ? Theme.secondaryColor
               : highlighted
                 ? (root.playing
                    ? Theme.highlightColor
                    : Theme.secondaryHighlightColor)
                 : Theme.primaryColor

        opacity: !enabled ? 0.35
                 : highlighted && !root.playing ? 0.6
                 : 1.0

        onClicked: root.clicked()
    }
}
