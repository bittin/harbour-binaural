import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0

FullscreenContentPage {
    id: page
    objectName: "InfoBinauralPage"

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

                    text: qsTr("Binaural Beats")
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    wrapMode: Text.WordWrap
                }

                Label {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin

                    text: qsTr("Are created by playing two slightly different tones, one in each ear. The brain processes the difference as a rhythmic beat. Different beat frequencies can be used to support focus, relaxation, meditation, or sleep.")

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
                        source: "../../images/image-binaural-graph.svg"
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
                    id: frequencyGrid

                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin

                    columns: 2
                    columnSpacing: Theme.paddingMedium * 1.5
                    rowSpacing: Theme.paddingMedium

                    property real labelWidth: Math.max(
                                                  deltaLabel.implicitWidth,
                                                  deltaThetaLabel.implicitWidth,
                                                  thetaLabel.implicitWidth,
                                                  alphaLabel.implicitWidth,
                                                  betaLabel.implicitWidth,
                                                  gammaLabel.implicitWidth
                                                  )

                    Label {
                        id: deltaLabel
                        width: frequencyGrid.labelWidth
                        text: SoundNames.label("Delta") + " 2 Hz"
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: frequencyGrid.width - frequencyGrid.labelWidth - frequencyGrid.columnSpacing
                        text: qsTr("Deep sleep, rest")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        id: deltaThetaLabel
                        width: frequencyGrid.labelWidth
                        text: SoundNames.label("Delta/Theta") + " 4 Hz"
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: frequencyGrid.width - frequencyGrid.labelWidth - frequencyGrid.columnSpacing
                        text: qsTr("Deep relaxation, sleep")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        id: thetaLabel
                        width: frequencyGrid.labelWidth
                        text: SoundNames.label("Theta") + " 6 Hz"
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: frequencyGrid.width - frequencyGrid.labelWidth - frequencyGrid.columnSpacing
                        text: qsTr("Meditation and relaxation")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        id: alphaLabel
                        width: frequencyGrid.labelWidth
                        text: SoundNames.label("Alpha") + " 10 Hz"
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: frequencyGrid.width - frequencyGrid.labelWidth - frequencyGrid.columnSpacing
                        text: qsTr("Calm and relaxed wakefulness")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        id: betaLabel
                        width: frequencyGrid.labelWidth
                        text: SoundNames.label("Beta") + " 20 Hz"
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: frequencyGrid.width - frequencyGrid.labelWidth - frequencyGrid.columnSpacing
                        text: qsTr("Alertness and focus")
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        id: gammaLabel
                        width: frequencyGrid.labelWidth
                        text: SoundNames.label("Gamma") + " 40 Hz"
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.NoWrap
                    }

                    Label {
                        width: frequencyGrid.width - frequencyGrid.labelWidth - frequencyGrid.columnSpacing
                        text: qsTr("Complex thinking and information processing")
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
