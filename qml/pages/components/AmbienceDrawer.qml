import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0

SilicaFlickable {
    id: ambiencePage

    property string activeAmbience: ""
    property bool ambiencePlaying: false
    property bool pausedMode: false

    signal ambienceSelected(string ambience)
    signal ambienceDeselected()
    signal ambienceVolumeChanged(real volume)
    signal closeRequested()

    width: parent ? parent.width : 0
    height: column.height + Theme.paddingLarge

    contentWidth: width
    contentHeight: height
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

        // swipeHandle which indicated possibility to swipe down
        Item {
            id: swipeHandle

            width: parent.width
            height: Theme.itemSizeExtraSmall

            Rectangle {
                anchors.centerIn: parent
                width: Theme.itemSizeExtraSmall * 2
                height: Theme.paddingSmall
                radius: Theme.paddingSmall
                color: Theme.secondaryColor
                opacity: 0.6
            }

            MouseArea {
                anchors.fill: parent

                property real startX: 0
                property real startY: 0

                onPressed: {
                    startX = mouse.x
                    startY = mouse.y
                }

                onReleased: {
                    var deltaX = Math.abs(mouse.x - startX)
                    var deltaY = mouse.y - startY

                    if (deltaY > Theme.itemSizeSmall
                            && deltaY > deltaX) {
                        ambiencePage.closeRequested()
                    }
                }
            }
        }

        // Ambient sound selection
        SilicaGridView {
            id: ambienceGrid

            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            height: Math.ceil(model.length / 2) * Theme.itemSizeMedium

            cellWidth: width / 2
            cellHeight: Theme.itemSizeMedium

            model: [
                "Wind",
                "Waves",
                "Crickets",
                "Stream",
                "Rain",
                "Birds",
                "Fire",
                "Chimes"
            ]

            delegate: Item {
                width: ambienceGrid.cellWidth
                height: ambienceGrid.cellHeight

                Rectangle {
                    anchors.fill: ambienceButton
                    anchors.margins: -Theme.paddingSmall

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

                    highlighted: ambiencePage.activeAmbience === modelData

                    opacity: highlighted && !ambiencePage.ambiencePlaying
                             ? 0.6 : 1.0

                    onClicked: {
                        if (highlighted) {
                            ambiencePage.ambienceDeselected()
                        } else {
                            ambiencePage.ambienceSelected(modelData)
                        }
                    }

                    Label {
                        anchors.centerIn: parent

                        text: parent.text

                        color: ambienceButton.highlighted
                               ? (ambiencePage.ambiencePlaying
                                  ? Theme.highlightColor
                                  : Theme.secondaryHighlightColor)
                               : Theme.primaryColor
                    }
                }
            }
        }

        // Volume control
        Item {
            width: parent.width
            height: ambienceVolumeSlider.height

            Slider {
                id: ambienceVolumeSlider

                width: parent.width * 0.9
                anchors.horizontalCenter: parent.horizontalCenter

                minimumValue: 0
                maximumValue: 100
                value: 50

                enabled: ambiencePage.activeAmbience !== ""
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

                opacity: ambiencePage.activeAmbience !== "" ? 1.0 : 0.5

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

        Item {
            width: 1
            height: Theme.paddingMedium
        }
    }

    VerticalScrollDecorator {}
}
