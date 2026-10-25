import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0

FullscreenContentPage {
    id: page
    objectName: "InfoColoredPage"

    Rectangle {
        anchors.fill: parent
        color: Theme.overlayBackgroundColor
        z: -1
    }

    SilicaFlickable {
        id: flickable

        anchors.fill: parent
        contentHeight: scrollContent.height + Theme.paddingLarge
        clip: true

        VerticalScrollDecorator { }

        Item {
            id: scrollContent

            width: flickable.width
            height: contentColumn.y + contentColumn.height

            IconButton {
                id: dismissButton

                y: Theme.paddingLarge

                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }

                icon.source: "image://theme/icon-m-dismiss?" + Theme.primaryColor

                onClicked: pageStack.pop()
            }

            Column {
                id: contentColumn

                y: 0
                width: parent.width
                spacing: Theme.paddingLarge

                Item {
                    width: parent.width
                    height: dismissButton.y + dismissButton.height +
                            Theme.paddingSmall
                }

                Label {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin

                    text: qsTr("Colored Noise")
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    wrapMode: Text.WordWrap
                }

                Label {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin

                    text: qsTr("Sound with different amounts of energy at different frequencies. Each color has a different character and is commonly used for different purposes.")

                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: Text.WordWrap
                }

                Item {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin
                    height: width * 324 / 870.236

                    Image {
                        id: binauralGraphImage

                        anchors.fill: parent
                        source: "../../images/image-colornoise-graph.svg"
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: binauralGraphImage
                        source: binauralGraphImage
                        color: Theme.primaryColor
                    }
                }

                Label {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin

                    text: qsTr("Choose from:")
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: Text.WordWrap
                }

                Grid {
                    id: noiseGrid

                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin

                    columns: 2
                    columnSpacing: Theme.paddingMedium * 1.5
                    rowSpacing: Theme.paddingMedium

                    property real labelWidth: Math.max(
                                                  whiteLabel.implicitWidth,
                                                  pinkLabel.implicitWidth,
                                                  brownLabel.implicitWidth,
                                                  greyLabel.implicitWidth
                                                  )

                    Label {
                        id: whiteLabel
                        width: noiseGrid.labelWidth
                        text: SoundNames.label("White")
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: noiseGrid.width -
                               noiseGrid.labelWidth -
                               noiseGrid.columnSpacing

                        text: qsTr("Focus, sleep and background noise masking")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        id: pinkLabel
                        width: noiseGrid.labelWidth
                        text: SoundNames.label("Pink")
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: noiseGrid.width -
                               noiseGrid.labelWidth -
                               noiseGrid.columnSpacing

                        text: qsTr("Relaxation, sleep and concentration")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        id: brownLabel
                        width: noiseGrid.labelWidth
                        text: SoundNames.label("Brown")
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: noiseGrid.width -
                               noiseGrid.labelWidth -
                               noiseGrid.columnSpacing

                        text: qsTr("Relaxation, sleep and reducing distracting sounds")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        id: greyLabel
                        width: noiseGrid.labelWidth
                        text: SoundNames.label("Grey")
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: noiseGrid.width -
                               noiseGrid.labelWidth -
                               noiseGrid.columnSpacing

                        text: qsTr("Sound masking and general listening")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                }

                Item {
                    width: 1
                    height: Theme.paddingSmall
                }

                Label {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin

                    text: SoundNames.label("Individual experiences may vary.")
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
