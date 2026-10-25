import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import QtQuick.Window 2.0
import Binaural 1.0

SilicaFlickable {
    id: ambiencePage

    property var activeAmbiences: []
    property bool ambiencePlaying: false
    property bool pausedMode: false

    signal ambienceSelected(string ambience)
    signal ambienceDeselected(string ambience)
    signal ambienceVolumeChanged(real volume)
    signal closeRequested()

    width: parent.width

    // Limit drawer height to 80% of the screen and allow scrolling.
    height: Math.min(column.height + Theme.paddingLarge,
                     Screen.height * 0.8)

    contentHeight: column.height + Theme.paddingLarge
    clip: true

    Rectangle {
        anchors.fill: parent
        color: Theme.rgba(
                   Theme.highlightBackgroundColor,
                   Theme.highlightBackgroundOpacity * 0.35
                   )
    }

    Column {
        id: column

        width: parent.width
        spacing: Theme.paddingMedium

        // Swipe handle: tap or swipe down to close the drawer.
        Item {
            id: swipeHandle

            width: parent.width
            height: Theme.itemSizeExtraSmall

            Rectangle {
                anchors.centerIn: parent
                width: Theme.itemSizeExtraSmall * 2
                height: Theme.paddingSmall
                radius: Theme.paddingSmall
                color: handleMouseArea.pressed
                       ? Theme.secondaryHighlightColor
                       : Theme.secondaryColor
                opacity: 0.6
            }

            MouseArea {
                id: handleMouseArea

                anchors.fill: parent

                property real startY: 0
                property real startX: 0

                onPressed: {
                    startY = mouse.y
                    startX = mouse.x
                }

                onClicked: {
                    ambiencePage.closeRequested()
                }

                onReleased: {
                    var deltaY = mouse.y - startY
                    var deltaX = mouse.x - startX

                    // A deliberate downward swipe closes the drawer.
                    if (deltaY > Theme.itemSizeSmall
                            && Math.abs(deltaY) > Math.abs(deltaX)) {
                        ambiencePage.closeRequested()
                    }
                }
            }
        }

        // Ambient Sound Selection grid
        SilicaGridView {
            id: ambienceGrid

            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            height: Math.ceil(model.length / 2) * Theme.itemSizeMedium

            cellWidth: width / 2
            cellHeight: Theme.itemSizeMedium

            model: [
                "Wind",
                "Rain",
                "Stream",
                "Waves",
                "Lake",
                "Sailing",
                "Birds",
                "Crickets",
                "Chimes",
                "Fire"
            ]

            delegate: Item {
                width: ambienceGrid.cellWidth
                height: ambienceGrid.cellHeight

                // Glow rectangle when sound is activated
                Rectangle {
                    anchors.fill: ambienceButton
                    z: -1
                    radius: Theme.paddingSmall

                    color: ambienceButton.highlighted
                           ? Theme.highlightColor
                           : "transparent"

                    opacity: ambienceButton.highlighted ? 0.15 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                Button {
                    id: ambienceButton

                    anchors.centerIn: parent

                    preferredWidth: ambienceGrid.cellWidth
                                    - Theme.paddingMedium

                    text: SoundNames.label(modelData)

                    highlighted: ambiencePage.activeAmbiences.indexOf(modelData) !== -1

                    enabled: highlighted || ambiencePage.activeAmbiences.length < 3

                    opacity: !enabled ? 0.35
                             : highlighted && !ambiencePage.ambiencePlaying ? 0.6
                             : 1.0

                    onClicked: {
                        if (highlighted) {
                            ambiencePage.ambienceDeselected(modelData)
                        } else if (ambiencePage.activeAmbiences.length < 3) {
                            ambiencePage.ambienceSelected(modelData)
                        }
                    }

                    Label {
                        anchors.centerIn: parent

                        text: parent.text

                        color: !ambienceButton.enabled
                               ? Theme.secondaryColor
                               : ambienceButton.highlighted
                                 ? (ambiencePage.ambiencePlaying
                                    ? Theme.highlightColor
                                    : Theme.secondaryHighlightColor)
                                 : Theme.primaryColor
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

                enabled: ambiencePage.activeAmbiences.length > 0
                opacity: enabled ? 1.0 : 0.5

                onValueChanged: {
                    ambiencePage.ambienceVolumeChanged(value)
                }
            }

            Item {
                id: ambienceVolumeIcon

                width: Theme.iconSizeSmall * 1.6
                height: Theme.iconSizeSmall * 1.6

                anchors.top: ambienceVolumeSlider.bottom
                anchors.topMargin: -Theme.paddingLarge
                anchors.horizontalCenter: ambienceVolumeSlider.horizontalCenter

                opacity: ambiencePage.activeAmbiences.length > 0 ? 1.0 : 0.5

                Image {
                    id: ambienceVolumeImage

                    anchors.fill: parent

                    source: ambienceVolumeSlider.value === 0
                            ? "../../images/icon-s-volume-1.svg"
                            : ambienceVolumeSlider.value <= 33
                              ? "../../images/icon-s-volume-2.svg"
                              : ambienceVolumeSlider.value <= 66
                                ? "../../images/icon-s-volume-3.svg"
                                : "../../images/icon-s-volume-4.svg"

                    sourceSize: Qt.size(
                                    Theme.iconSizeSmall * 1.6 * 2,
                                    Theme.iconSizeSmall * 1.6 * 2
                                    )

                    fillMode: Image.PreserveAspectFit
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: ambienceVolumeImage
                    source: ambienceVolumeImage
                    color: Theme.primaryColor
                }
            }
        }
    }

    VerticalScrollDecorator {}
}
