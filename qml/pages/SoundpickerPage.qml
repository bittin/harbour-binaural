import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import QtMultimedia 5.0
import QtGraphicalEffects 1.0

Page {
    id: page

    objectName: "SoundpickerPage"

    // Reference to the top-level ApplicationWindow.
    property var appWindow: null

    property url selectedFile: ""
    property string selectedFileName: ""

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height

        VerticalScrollDecorator {}

        Column {
            id: contentColumn

            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Custom sound")
            }

            SectionHeader {
                text: qsTr("Select an audio file")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: page.selectedFileName !== ""
                      ? page.selectedFileName
                      : qsTr("No file selected")

                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: qsTr("Choose MP3 or audio file")

                onClicked: {
                    console.log("Soundpicker: opening MusicPickerPage")
                    pageStack.animatorPush(musicPickerPage)
                }
            }

            SectionHeader {
                text: qsTr("Playback")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: {
                    if (!page.appWindow)
                        return qsTr("Audio player unavailable")

                    if (page.appWindow.customSoundPlaying)
                        return qsTr("Playing")

                    if (page.appWindow.customSoundSource.toString() !== "")
                        return qsTr("Ready to play")

                    return qsTr("Select an audio file first")
                }

                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: page.appWindow
                      && page.appWindow.customSoundPlaying
                      ? qsTr("Pause")
                      : qsTr("Play")

                // Use the selected local file as the enable condition.
                enabled: page.appWindow !== null
                         && page.selectedFile.toString() !== ""

                onClicked: {
                    if (!page.appWindow) {
                        console.log("Custom sound: appWindow reference is missing")
                        return
                    }

                    // Keep the global player source synchronized.
                    page.appWindow.customSoundSource = page.selectedFile
                    page.appWindow.customSoundName = page.selectedFileName

                    if (page.appWindow.customSoundPlaying) {
                        page.appWindow.pauseCustomSound()
                    } else {
                        page.appWindow.playCustomSound()
                    }
                }
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: qsTr("Stop")

                enabled: page.appWindow !== null
                         && page.selectedFile.toString() !== ""

                onClicked: {
                    if (page.appWindow)
                        page.appWindow.stopCustomSound()
                }
            }

            TextSwitch {
                id: loopSwitch

                text: qsTr("Loop sound")
                description: checked
                             ? qsTr("Repeat continuously")
                             : qsTr("Play once")

                checked: page.appWindow
                         ? page.appWindow.customSoundLoop
                         : true

                enabled: page.appWindow !== null

                onCheckedChanged: {
                    if (page.appWindow)
                        page.appWindow.customSoundLoop = checked
                }
            }

            SectionHeader {
                text: qsTr("Volume")
            }

            Item {
                width: parent.width
                height: customSoundVolumeSlider.height + Theme.iconSizeSmall

                Slider {
                    id: customSoundVolumeSlider

                    width: parent.width * 0.9
                    anchors.horizontalCenter: parent.horizontalCenter

                    minimumValue: 0
                    maximumValue: 100

                    value: page.appWindow
                           ? page.appWindow.customSoundVolume
                           : 50

                    valueText: Math.round(value) + "%"

                    enabled: page.appWindow !== null
                             && page.selectedFile.toString() !== ""

                    opacity: enabled ? 1.0 : 0.5

                    onValueChanged: {
                        if (page.appWindow) {
                            page.appWindow.customSoundVolume = value
                        }
                    }
                }

                Item {
                    id: customSoundVolumeIcon

                    width: Theme.iconSizeSmall * 1.6
                    height: Theme.iconSizeSmall * 1.6

                    anchors.top: customSoundVolumeSlider.bottom
                    anchors.topMargin: -Theme.paddingLarge
                    anchors.horizontalCenter: customSoundVolumeSlider.horizontalCenter

                    opacity: customSoundVolumeSlider.enabled ? 1.0 : 0.5

                    Image {
                        id: customSoundVolumeImage

                        anchors.fill: parent

                        source: customSoundVolumeSlider.value === 0
                                ? "../../images/icon-s-volume-1.svg"
                                : customSoundVolumeSlider.value <= 33
                                  ? "../../images/icon-s-volume-2.svg"
                                  : customSoundVolumeSlider.value <= 66
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
                        anchors.fill: customSoundVolumeImage
                        source: customSoundVolumeImage
                        color: Theme.primaryColor
                    }
                }
            }
        }
    }

    Component {
        id: musicPickerPage

        MusicPickerPage {
            onSelectedContentPropertiesChanged: {
                var properties = selectedContentProperties

                if (properties
                        && properties.filePath
                        && properties.filePath.toString() !== "") {

                    page.selectedFile = properties.filePath
                    page.selectedFileName = properties.fileName || ""

                    if (page.appWindow) {
                        page.appWindow.customSoundSource =
                                page.selectedFile

                        page.appWindow.customSoundName =
                                page.selectedFileName
                    } else {
                        console.log(
                                    "Custom sound: appWindow was not passed to SoundpickerPage")
                    }

                    pageStack.pop()
                }
            }
        }
    }
}
