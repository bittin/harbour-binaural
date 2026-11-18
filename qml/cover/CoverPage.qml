import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0

CoverBackground {
    id: cover

    property var mainState: null

    property bool hasActiveSounds: mainState
                                   ? mainState.hasActiveSounds
                                   : false

    property bool isPlaying: false

    property bool sleepTimerRunning: false
    property bool sleepTimerPaused: false
    property int sleepTimerRemainingSeconds: 0

    signal playPauseClicked()

    function formatRemainingTime(seconds) {
        var hours = Math.floor(seconds / 3600)
        var minutes = Math.floor((seconds % 3600)  / 60)
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

        // Dim the cover art while the system has stopped the sound.
        opacity: isPlaying || !hasActiveSounds ? 1.0 : 0.6

        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        Image {
            id: coverBackgroundImage

            anchors.fill: parent

            source: "../images/binaural-cover.svg"

            sourceSize: Qt.size(width * 2, height * 2)

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
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge

        // One horizontal margin for everything below the art.
        // Cover text never touches the cover edges.
        x: Theme.paddingLarge
        width: parent.width - 2 * Theme.paddingLarge

        spacing: Theme.paddingSmall

        // Status text: only visible when no sounds are selected.
        Label {
            id: coverStatusLabel

            visible: !sleepTimerRunning && !hasActiveSounds

            width: parent.width

            horizontalAlignment: Text.AlignHCenter

            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap

            text: SoundNames.label("Start your sound mix")
        }

        // Sleep timer status.
        Row {
            id: coverSleepTimerRow

            visible: sleepTimerRunning

            anchors.horizontalCenter: parent.horizontalCenter
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

                sourceSize: Qt.size(width, height)
            }

            Label {
                id: coverSleepTimerLabel

                color: sleepTimerPaused
                       ? Theme.secondaryColor
                       : Theme.primaryColor

                font.pixelSize: Theme.fontSizeSmall

                text: formatRemainingTime(sleepTimerRemainingSeconds)
            }
        }

        // Selected sound names.
        // One ambience shows its name; multiple ambiences show "Ambient mix".
        Label {
            id: coverSoundNames

            visible: hasActiveSounds

            width: parent.width

            horizontalAlignment: Text.AlignHCenter

            // Highlight only while playing.
            color: isPlaying
                   ? Theme.highlightColor
                   : Theme.secondaryHighlightColor

            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap

            // Never let a long mix fill the whole cover:
            // defined maximum lines, rest elided.
            maximumLineCount: 3
            elide: Text.ElideRight

            text: mainState ? mainState.mixLabel : ""
        }

        // Push labels to the bottom of the cover, away from the art.
        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
    }

    // Show the play/pause button whenever at least one sound is selected.
    CoverActionList {
        id: playbackActionList

        enabled: hasActiveSounds

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
