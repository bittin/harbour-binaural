import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0
import "../pages/components"

CoverBackground {
    id: cover

    property var applicationWindow: null

    property string activeBand: ""
    property string activeNoise: ""
    property var activeAmbiences: []
    property url customSoundSource: ""

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

    // Measure the gap between the final sound label and playback controls.
    function soundLabelActionGap() {
        if (!coverSoundNames.visible ||
                !playbackActionList.enabled ||
                !coverSoundNames.text) {
            return Number.POSITIVE_INFINITY
        }

    // Cover artwork and playback equalizer.
    Item {
        id: coverBackgroundIcon

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: Math.min(parent.width - 2 * Theme.paddingSmall,
                        parent.height * 0.58)
        height: width * 0.75

        z: 0

        opacity: isPlaying ||
                 (activeBand === "" &&
                  activeAmbiences.length === 0 &&
                  activeNoise === "")
                 ? 1.0 : 0.6

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

        // Keep the artwork color treatment; no gradient or mask.
        ColorOverlay {
            anchors.fill: coverBackgroundImage
            source: coverBackgroundImage
            color: Theme.primaryColor
        }

        PlaybackEqualizerAnimation {
            id: coverEqualizer

            applicationWindow: cover.applicationWindow

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            sizeMultiplier: 1.8
            barColor: Theme.primaryColor
            opacity: 0.8
            z: 1
        }
    }

    // Status, sleep timer, and sound labels.
    // This is a Column, so its height comes from its contents.
    // Not clipped by the playback action list.
    Column {
        id: coverLabels

        anchors.top: coverBackgroundIcon.bottom
        anchors.topMargin: -Theme.paddingLarge * 0.8
        anchors.left: parent.left
        anchors.right: parent.right

        spacing: Theme.paddingSmall

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

        // Sleep timer status and icon.
        Item {
            id: coverSleepTimerRow

            visible: sleepTimerRunning
            width: parent.width

            height: Math.max(
                        Theme.iconSizeSmall * 0.8,
                        coverSleepTimerLabel.implicitHeight
                    )

            Label {
                id: coverSleepTimerLabel

                anchors.centerIn: parent

                color: sleepTimerPaused
                       ? Theme.secondaryHighlightColor
                       : Theme.highlightColor

                font.pixelSize: Theme.fontSizeSmall

                text: formatRemainingTime(sleepTimerRemainingSeconds)
            }

            Image {
                id: coverSleepTimerIcon

                width: Theme.iconSizeSmall * 0.8
                height: Theme.iconSizeSmall * 0.8

                anchors.right: coverSleepTimerLabel.left
                anchors.rightMargin: Theme.paddingSmall
                anchors.verticalCenter: coverSleepTimerLabel.verticalCenter
                anchors.verticalCenterOffset: Theme.paddingSmall / 3

                source: "image://theme/icon-s-timer?" +
                        (sleepTimerPaused
                         ? Theme.secondaryHighlightColor
                         : Theme.highlightColor)

                sourceSize: Qt.size(width, height)
            }
        }

        // Selected sound names.
        Label {
            id: coverSoundNames

            width: parent.width

            horizontalAlignment: Text.AlignHCenter

            color: isPlaying
                   ? Theme.primaryColor
                   : Theme.secondaryColor

            opacity: 0.6
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

                if (customSoundSource.toString() !== "")
                    parts.push(SoundNames.label("Custom sound"))

                return parts.join("\n")
            }
        }
    }

    // Play/pause action.
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
