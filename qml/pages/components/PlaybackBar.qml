import QtQuick 2.0
import Sailfish.Silica 1.0
import Binaural 1.0

DockedPanel {
    id: playbackBar

    property var applicationWindow: null

    property bool timerPageActive: applicationWindow &&
                                   applicationWindow.pageStack &&
                                   applicationWindow.pageStack.currentPage &&
                                   applicationWindow.pageStack.currentPage.objectName === "timerPage"

    width: parent ? parent.width : 0
    height: Theme.itemSizeExtraLarge

    x: 0
    z: 3

    dock: Dock.Bottom
    open: true

    // Dim the playback bar when nothing is playing.
    Rectangle {
        anchors.fill: parent
        color: "black"

        opacity: playbackBar.applicationWindow &&
                 (playbackBar.applicationWindow.isPlaying ||
                  playbackBar.applicationWindow.customSoundPlaying)
                 ? 0.0 : 0.2

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }
    }

    // Playback button.
    IconButton {
        id: playbackButton

        width: Theme.iconSizeMedium
        height: Theme.iconSizeMedium

        anchors.left: parent.left
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter

        icon.source: playbackBar.applicationWindow &&
                     (playbackBar.applicationWindow.isPlaying ||
                      playbackBar.applicationWindow.customSoundPlaying)
                     ? "image://theme/icon-m-pause"
                     : "image://theme/icon-m-play"

        enabled: {
            var app = playbackBar.applicationWindow

            if (!app || !app.mainPage)
                return false

            var page = app.mainPage
            var ambiences = page.activeAmbiences || []

            return app.activeBand !== "" ||
                   app.activeNoise !== "" ||
                   ambiences.length > 0 ||
                   app.customSoundSource.toString() !== ""
        }

        opacity: enabled ? 1.0 : 0.5

        onClicked: {
            if (playbackBar.applicationWindow &&
                    playbackBar.applicationWindow.mainPage) {
                playbackBar.applicationWindow.mainPage.togglePlayback()
            }
        }
    }

    // Current sound mix label.
    Label {
        id: soundLabel

        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }

        color: {
            var app = playbackBar.applicationWindow

            if (!app || !app.mainPage)
                return Theme.secondaryColor

            var page = app.mainPage
            var ambiences = page.activeAmbiences || []

            var hasBuiltInSound = page.activeBand !== "" ||
                                  page.activeNoise !== "" ||
                                  ambiences.length > 0

            var hasCustomSound = app.customSoundSource.toString() !== ""

            if (!hasBuiltInSound && !hasCustomSound)
                return Theme.secondaryColor

            return (app.isPlaying || app.customSoundPlaying)
                   ? Theme.highlightColor
                   : Theme.secondaryHighlightColor
        }

        anchors.left: playbackButton.right
        anchors.leftMargin: Theme.paddingMedium
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter

        anchors.verticalCenterOffset:
            playbackBar.applicationWindow &&
            playbackBar.applicationWindow.sleepTimerRunning
            ? -Theme.paddingMedium * 1.5
            : 0

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: 350
                easing.type: Easing.Linear
            }
        }

        font.pixelSize: Theme.fontSizeMedium
        elide: Text.ElideRight

        text: {
            var app = playbackBar.applicationWindow

            if (!app || !app.mainPage)
                return qsTr("Start your sound mix")

            var page = app.mainPage
            var parts = []
            var ambiences = page.activeAmbiences || []

            if (page.activeBand !== "")
                parts.push(SoundNames.label(page.activeBand))

            if (page.activeNoise !== "")
                parts.push(SoundNames.label(page.activeNoise))

            if (ambiences.length === 1) {
                parts.push(SoundNames.label(ambiences[0]))
            } else if (ambiences.length > 1) {
                parts.push(SoundNames.label("Ambient mix"))
            }

            if (app.customSoundSource.toString() !== "") {
                parts.push(SoundNames.label("Custom sound"))
            }

            return parts.length > 0
                   ? parts.join(" & ")
                   : SoundNames.label("Start your sound mix")
        }
    }

    // Sleep timer icon and countdown.
    Item {
        id: sleepTimerRow

        anchors.left: playbackButton.right
        anchors.leftMargin: Theme.paddingLarge
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin

        anchors.top: soundLabel.bottom
        anchors.topMargin: 0

        height: Theme.iconSizeSmall
        opacity: 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }

        // Sleep timer icon.
        Image {
            id: sleepTimerIcon

            anchors.left: parent.left
            anchors.verticalCenter: sleepTimerLabel.verticalCenter
            anchors.verticalCenterOffset: Theme.paddingSmall / 3

            width: Theme.iconSizeSmall * 0.88
            height: Theme.iconSizeSmall * 0.88

            source: "image://theme/icon-s-timer?" +
                    (playbackBar.timerPageActive
                     ? Theme.secondaryHighlightColor
                     : timerMouseArea.pressed
                       ? Theme.highlightColor
                       : playbackBar.applicationWindow &&
                         playbackBar.applicationWindow.sleepTimerPaused
                         ? Theme.secondaryColor
                         : Theme.primaryColor)

            sourceSize: Qt.size(width, height)
        }

        // Sleep timer label showing time.
        Label {
            id: sleepTimerLabel

            anchors.left: sleepTimerIcon.right
            anchors.leftMargin: Theme.paddingSmall
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right

            text: {
                if (!playbackBar.applicationWindow)
                    return ""

                var seconds =
                        playbackBar.applicationWindow.sleepTimerRemainingSeconds

                var hours = Math.floor(seconds / 3600)
                var minutes = Math.floor((seconds % 3600) / 60)
                var secs = seconds % 60

                return (hours > 0
                        ? (hours < 10 ? "0" : "") + hours + ":"
                        : "") +
                        (minutes < 10 ? "0" : "") + minutes + ":" +
                        (secs < 10 ? "0" : "") + secs
            }

            color: playbackBar.timerPageActive
                   ? Theme.secondaryHighlightColor
                   : timerMouseArea.pressed
                     ? Theme.highlightColor
                     : playbackBar.applicationWindow &&
                       playbackBar.applicationWindow.sleepTimerPaused
                       ? Theme.secondaryColor
                       : Theme.primaryColor

            font.pixelSize: Theme.fontSizeSmall
        }

        // Makes sleep timer icon and label clickable when active.
        // Deactivated when on TimerPage itself.
        MouseArea {
            id: timerMouseArea

            anchors.fill: parent
            z: 1

            enabled: !playbackBar.timerPageActive

            onClicked: {
                var window = playbackBar.applicationWindow

                if (!window || !window.pageStack)
                    return

                var stack = window.pageStack

                // If TimerPage is already open, don't push another copy.
                var existingPage = stack.find(function(page) {
                    return page.objectName === "timerPage"
                })

                if (existingPage) {
                    // If it isn't the current page, return to the existing one.
                    if (stack.currentPage !== existingPage)
                        stack.pop(existingPage)

                    return
                }

                // No existing TimerPage: open it.
                stack.push(Qt.resolvedUrl("../TimerPage.qml"), {
                               "appWindow": window,
                               "objectName": "timerPage"
                           })
            }
        }
    }

    // Delay showing the timer row to avoid a sudden appearance.
    Timer {
        id: sleepTimerLabelDelay

        interval: 150
        repeat: false

        onTriggered: {
            if (playbackBar.applicationWindow &&
                    playbackBar.applicationWindow.sleepTimerRunning) {
                sleepTimerRow.opacity = 1.0
            }
        }
    }

    // Keep the timer row synchronized with the sleep timer state.
    Connections {
        target: playbackBar.applicationWindow

        onSleepTimerRunningChanged: {
            if (!playbackBar.applicationWindow)
                return

            if (playbackBar.applicationWindow.sleepTimerRunning) {
                sleepTimerLabelDelay.restart()
            } else {
                sleepTimerLabelDelay.stop()
                sleepTimerRow.opacity = 0.0
            }
        }
    }

    Component.onCompleted: {
        if (applicationWindow &&
                applicationWindow.sleepTimerRunning) {
            sleepTimerLabelDelay.restart()
        }
    }
}
