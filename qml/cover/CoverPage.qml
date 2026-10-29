import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0

CoverBackground {
    id: cover

    property string activeBand: ""
    property var activeAmbiences: []
    property string activeNoise: ""

    property bool isPlaying: false
    property bool isPaused: false

    property bool sleepTimerRunning: false
    property bool sleepTimerPaused: false
    property int sleepTimerRemainingSeconds: 0

    signal playPauseClicked()

    function formatRemainingTime(seconds) {
        var hours = Math.floor(seconds / 3600)
        var minutes = Math.floor((seconds % 3600) / 60)
        var secs = seconds % 60

        return (hours > 0
                ? (hours < 10 ? "0" : "") + hours + ":"
                : "") +
               (minutes < 10 ? "0" : "") + minutes + ":" +
               (secs < 10 ? "0" : "") + secs
    }

    Item {
        id: coverBackgroundIcon

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: parent.width - 2 * Theme.paddingSmall
        height: parent.height * 0.45

        z: 0

        // Dim the cover art while the system has stopped the sound.
        opacity: isPlaying || (activeBand === "" &&
                              activeAmbiences.length === 0 &&
                              activeNoise === "")
                 ? 1.0
                 : 0.6

        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        Image {
            id: coverBackgroundImage

            anchors.fill: parent

            source: "../images/binaural-cover.svg"

            sourceSize: Qt.size(
                            width * 2,
                            height * 2
                            )

            fillMode: Image.PreserveAspectFit
            visible: false
        }

        ColorOverlay {
            anchors.fill: coverBackgroundImage

            source: coverBackgroundImage
            color: Theme.primaryColor
        }
    }

    Column {
        id: coverLabels

        anchors.top: coverBackgroundIcon.bottom
        anchors.topMargin: -Theme.paddingLarge * 0.8
        anchors.left: parent.left
        anchors.right: parent.right

        spacing: Theme.paddingSmall

        // Status text: only visible when no sounds are selected.
        Label {
            id: coverStatusLabel

            visible: !sleepTimerRunning &&
                     activeBand === "" &&
                     activeAmbiences.length === 0 &&
                     activeNoise === ""

            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin

            horizontalAlignment: Text.AlignHCenter

            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap

            text: SoundNames.label("Start your sound mix")
        }

        // Sleep timer status.
        Item {
            id: coverSleepTimerRow

            visible: sleepTimerRunning
            width: parent.width
            height: Math.max(
                        Theme.iconSizeSmall * 0.8,
                        coverSleepTimerLabel.implicitHeight)

            Row {
                anchors.centerIn: parent
                spacing: Theme.paddingSmall

                Image {
                    id: coverSleepTimerIcon

                    width: Theme.iconSizeSmall * 0.8
                    height: Theme.iconSizeSmall * 0.8

                    anchors.verticalCenter: coverSleepTimerLabel.verticalCenter
                    anchors.verticalCenterOffset: Theme.paddingSmall / 3

                    source: "image://theme/icon-s-timer?" +
                            (sleepTimerPaused
                             ? Theme.secondaryColor
                             : Theme.primaryColor)

                    sourceSize: Qt.size(
                                    width,
                                    height
                                    )
                }

                Label {
                    id: coverSleepTimerLabel

                    color: sleepTimerPaused
                           ? Theme.secondaryColor
                           : Theme.primaryColor

                    font.pixelSize: Theme.fontSizeSmall

                    text: formatRemainingTime(
                              sleepTimerRemainingSeconds)
                }
            }
        }

        // Selected sound names.
        // One ambience shows its name; multiple ambiences show "Ambient mix".
        Label {
            id: coverSoundNames

            width: parent.width

            horizontalAlignment: Text.AlignHCenter

            // Highlight only while playing.
            color: isPlaying
                   ? Theme.highlightColor
                   : Theme.secondaryHighlightColor

            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap

            text: {
                var parts = []

                if (activeBand !== "")
                    parts.push(SoundNames.label(activeBand))

                if (activeNoise !== "")
                    parts.push(SoundNames.label(activeNoise))

                if (activeAmbiences.length === 1) {
                    parts.push(SoundNames.label(activeAmbiences[0]))
                } else if (activeAmbiences.length > 1) {
                    parts.push(SoundNames.label("Ambient mix"))
                }

                return parts.join("\n")
            }
        }
    }

    // Show the play/pause button whenever at least one sound is selected.
    CoverActionList {
        id: playbackActionList

        enabled: activeBand !== "" ||
                 activeAmbiences.length > 0 ||
                 activeNoise !== ""

        CoverAction {
            iconSource: isPlaying
                        ? "image://theme/icon-cover-pause"
                        : "image://theme/icon-cover-play"

            onTriggered: {
                playPauseClicked()
            }
        }
    }
}
