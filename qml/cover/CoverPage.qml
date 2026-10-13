import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0

CoverBackground {
    id: cover

    property string activeBand: ""
    property string activeAmbience: ""
    property string activeNoise: ""
    property bool isPlaying: false
    property bool isPaused: false

    property bool sleepTimerRunning: false
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
        //anchors.topMargin: Theme.paddingSmall
        anchors.horizontalCenter: parent.horizontalCenter

        width: parent.width - 2 * Theme.paddingSmall
        height: parent.height * 0.45

        z: 0

        // Dim the cover art while the system has stopped the sound.
        opacity: isPlaying || (activeBand === "" &&
                              activeAmbience === "" &&
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

        // Timer status
        Item {
            width: parent.width

            height: sleepTimerRunning
                    ? coverSleepTimerLabel.implicitHeight
                    : coverStatusLabel.implicitHeight

            Row {
                visible: sleepTimerRunning

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                spacing: Theme.paddingSmall

                Image {
                    id: coverSleepTimerIcon

                    width: Theme.iconSizeSmall * 0.8
                    height: Theme.iconSizeSmall * 0.8

                    anchors.verticalCenter: coverSleepTimerLabel.verticalCenter
                    anchors.verticalCenterOffset: Theme.paddingSmall / 3

                    source: "image://theme/icon-s-timer?" +
                            Theme.secondaryColor

                    sourceSize: Qt.size(
                        width,
                        height
                    )
                }

                Label {
                    id: coverSleepTimerLabel

                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall

                    text: formatRemainingTime(
                              sleepTimerRemainingSeconds)
                }
            }

            // Normal status text
            Label {
                id: coverStatusLabel

                visible: !sleepTimerRunning

                x: Theme.horizontalPageMargin
                width: parent.width - x * 2

                horizontalAlignment: Text.AlignHCenter

                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap

                text: (activeBand === "" &&
                       activeAmbience === "" &&
                       activeNoise === "")
                      ? qsTr("Start your sound mix")
                      : isPlaying
                        ? qsTr("Playing:")
                        : qsTr("Paused:")
            }
        }

        Label {
            width: parent.width

            horizontalAlignment: Text.AlignHCenter

            // Selected but not playing (system suspend): muted color,
            // full highlight only while actually playing.
            color: isPlaying
                   ? Theme.highlightColor
                   : Theme.secondaryHighlightColor

            font.pixelSize: Theme.fontSizeMedium
            wrapMode: Text.WordWrap

            text: {
                var parts = []
                if (activeBand !== "")
                    parts.push(SoundNames.label(activeBand))
                if (activeNoise !== "")
                    parts.push(SoundNames.label(activeNoise))
                if (activeAmbience !== "")
                    parts.push(SoundNames.label(activeAmbience))

                return parts.join("\n")
            }
        }
    }

    // Something selected: show play/pause button
    CoverActionList {
        id: playbackActionList

        enabled: activeBand !== "" ||
                 activeAmbience !== "" ||
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
