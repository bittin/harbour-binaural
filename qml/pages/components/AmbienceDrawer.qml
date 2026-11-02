import QtQuick 2.0
import Sailfish.Silica 1.0
import Binaural 1.0

/*
 * AmbienceDrawer: content-only drawer for selecting ambient sounds.
 * Uses ActionDrawer and PageDrawer
 */

ActionDrawer {
    id: ambienceDrawer

    property var activeAmbiences: []
    property bool ambiencePlaying: false
    property bool pausedMode: false

    signal ambienceSelected(string ambience)
    signal ambienceDeselected(string ambience)
    signal ambienceVolumeChanged(real volume)

    // Uncomment to add optional title in Drawer
    // title: qsTr("Ambient Sounds")

    // Ambient Sound Selection grid
    SilicaGridView {
        id: ambienceGrid

        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        height: Math.ceil(model.length / 2) * Theme.itemSizeMedium

        cellWidth: width / 2
        cellHeight: Theme.itemSizeMedium

        model: [
            "Wind", "Rain", "Stream", "Waves", "Lake",
            "Sailing", "Birds", "Crickets", "Chimes", "Fire"
        ]

        delegate: Item {
            width: ambienceGrid.cellWidth
            height: ambienceGrid.cellHeight

            Rectangle {
                anchors.fill: ambienceButton
                z: -1
                radius: Theme.paddingSmall
                color: ambienceButton.highlighted
                       ? Theme.highlightColor
                       : "transparent"
                opacity: ambienceButton.highlighted ? 0.15 : 0.0

                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Button {
                id: ambienceButton
                anchors.centerIn: parent
                preferredWidth: ambienceGrid.cellWidth -
                                Theme.paddingMedium

                text: SoundNames.label(modelData)
                highlighted: ambienceDrawer.activeAmbiences.indexOf(modelData) !== -1
                enabled: highlighted ||
                         ambienceDrawer.activeAmbiences.length < 3

                color: !enabled ? Theme.secondaryColor
                       : highlighted
                         ? (ambienceDrawer.ambiencePlaying
                            ? Theme.highlightColor
                            : Theme.secondaryHighlightColor)
                         : Theme.primaryColor

                opacity: !enabled ? 0.35
                         : highlighted && !ambienceDrawer.ambiencePlaying ? 0.6
                         : 1.0

                onClicked: {
                    if (highlighted) {
                        ambienceDrawer.ambienceDeselected(modelData)
                    } else if (ambienceDrawer.activeAmbiences.length < 3) {
                        ambienceDrawer.ambienceSelected(modelData)
                    }
                }
            }
        }
    }

    // Ambient Sound Volume Slider
    Item {
        width: parent.width
        height: ambienceVolumeSlider.height + Theme.iconSizeSmall

        Slider {
            id: ambienceVolumeSlider
            width: parent.width * 0.9
            anchors.horizontalCenter: parent.horizontalCenter

            minimumValue: 0
            maximumValue: 100
            value: 50

            enabled: ambienceDrawer.activeAmbiences.length > 0
            opacity: enabled ? 1.0 : 0.5

            onValueChanged:
                ambienceDrawer.ambienceVolumeChanged(value)
        }

        VolumeIcon {
            id: ambienceVolumeIcon
            value: ambienceVolumeSlider.value
            anchors.top: ambienceVolumeSlider.bottom
            anchors.topMargin: -Theme.paddingLarge
            anchors.horizontalCenter: ambienceVolumeSlider.horizontalCenter
            opacity: ambienceDrawer.activeAmbiences.length > 0 ? 1.0 : 0.5
        }
    }
}
