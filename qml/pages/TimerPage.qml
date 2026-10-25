import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "timerPage"

    property var appWindow

    function selectedDurationSeconds() {
        return timerPicker.hour * 3600
             + timerPicker.minute * 60
    }

    TimePicker {
        id: timerPicker

        visible: !page.appWindow.sleepTimerRunning

        hour: 0
        minute: 30
    }

    Label {
        anchors {
            horizontalCenter: timerPicker.horizontalCenter
            verticalCenter: timerPicker.verticalCenter
        }

        visible: timerPicker.visible

        text: qsTr("Set sleep timer")
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeMedium
    }

    Item {
        id: timerDisplay

        visible: page.appWindow.sleepTimerRunning

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        width: Math.min(parent.width * 0.7, 400)
        height: width

        Canvas {
            id: timerCanvas

            anchors.fill: parent

            property real progress: page.appWindow.sleepTimerProgress

            onProgressChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                var centerX = width / 2
                var centerY = height / 2
                var radius = Math.min(width, height) / 2 - Theme.paddingLarge

                ctx.beginPath()
                ctx.arc(centerX, centerY, radius, 0, Math.PI * 2, false)
                ctx.lineWidth = Theme.paddingSmall
                ctx.strokeStyle = Theme.rgba(Theme.highlightColor, 0.2)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(
                    centerX,
                    centerY,
                    radius,
                    -Math.PI / 2,
                    -Math.PI / 2 + Math.PI * 2 * progress,
                    false
                )
                ctx.lineWidth = Theme.paddingSmall
                ctx.strokeStyle = Theme.highlightColor
                ctx.stroke()
            }
        }

        Label {
            anchors.centerIn: parent

            text: page.appWindow.sleepTimerRemainingText
            font.pixelSize: Theme.fontSizeExtraLarge
            color: Theme.highlightColor
        }
    }

    IconButton {
        id: timerToggleButton

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: page.appWindow.sleepTimerRunning
                 ? timerDisplay.bottom
                 : timerPicker.bottom
            topMargin: Theme.paddingLarge * 1.5
        }

        icon.source: page.appWindow.sleepTimerRunning
                     ? "image://theme/icon-l-clear?"
                     : "image://theme/icon-l-add"

        enabled: page.appWindow.sleepTimerRunning ||
                 (page.selectedDurationSeconds() > 0 &&
                  page.appWindow.isPlaying)

        onClicked: {
            if (page.appWindow.sleepTimerRunning) {
                page.appWindow.cancelSleepTimer()
            } else {
                page.appWindow.startSleepTimer(
                    page.selectedDurationSeconds()
                )
            }
        }
    }

    Button {
        id: testSleepTimerButton

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: timerToggleButton.bottom
            topMargin: Theme.paddingLarge
        }

        text: "Test 5-second fade"

        enabled: page.appWindow.isPlaying

        onClicked: {
            page.appWindow.startSleepTimer(5)
        }
    }
}
