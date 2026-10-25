import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "timerPage"

    property var appWindow

    function selectedDurationSeconds() {
        return timerPicker.hour * 3600 +
               timerPicker.minute * 60
    }

    function formatTime(hour, minute) {
        return (hour < 10 ? "0" : "") + hour + ":" +
               (minute < 10 ? "0" : "") + minute
    }

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

    PageHeader {
        title: qsTr("Timer")
    }

    // TimePicker Circle
    TimePicker {
        id: timerPicker

        visible: !page.appWindow.sleepTimerRunning

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: page.top
            topMargin: Theme.itemSizeExtraLarge
        }

        hour: 0
        minute: 30
    }

    // Label displaying time via TimePicker Circle
    Label {
        visible: !page.appWindow.sleepTimerRunning

        anchors {
            horizontalCenter: timerPicker.horizontalCenter
            verticalCenter: timerPicker.verticalCenter
        }

        text: timerPicker.hour > 0
              ? (timerPicker.hour < 10 ? "0" : "") +
                timerPicker.hour +
                ":" +
                (timerPicker.minute < 10 ? "0" : "") +
                timerPicker.minute +
                "<font color=\"" +
                Theme.rgba(Theme.secondaryColor, 0.7) +
                "\">:00</font>"
              : (timerPicker.minute < 10 ? "0" : "") +
                timerPicker.minute +
                "<font color=\"" +
                Theme.rgba(Theme.secondaryColor, 0.7) +
                "\">:00</font>"

        textFormat: Text.StyledText

        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.DemiBold

        z: 1
    }

    // TimerDisplay circle when timer is running
    Item {
        id: timerDisplay

        visible: page.appWindow.sleepTimerRunning

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: page.top
            topMargin: Theme.itemSizeExtraLarge
        }

        width: timerPicker.width
        height: timerPicker.height

        Canvas {
            id: timerRing

            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                var centerX = width / 2
                var centerY = height / 2
                var radius = Math.min(width, height) / 2 - 10

                var progress = 0

                if (page.appWindow.sleepTimerDurationSeconds > 0) {
                    progress =
                            page.appWindow.sleepTimerRemainingSeconds /
                            page.appWindow.sleepTimerDurationSeconds
                }

                progress = Math.max(0, Math.min(1, progress))

                ctx.clearRect(0, 0, width, height)

                ctx.beginPath()
                ctx.arc(
                    centerX,
                    centerY,
                    radius,
                    -Math.PI / 2,
                    3 * Math.PI / 2,
                    false
                )

                ctx.lineWidth = 8
                ctx.strokeStyle =
                        Theme.rgba(Theme.primaryColor, 0.2)
                ctx.stroke()

                if (progress > 0) {
                    ctx.beginPath()
                    ctx.arc(
                        centerX,
                        centerY,
                        radius,
                        -Math.PI / 2,
                        -Math.PI / 2 +
                        (2 * Math.PI * progress),
                        false
                                )

                    ctx.lineWidth = 8
                    ctx.strokeStyle = Theme.highlightColor
                    ctx.stroke()
                }
            }
        }

        Connections {
            target: page.appWindow

            onSleepTimerRemainingSecondsChanged: {
                timerRing.requestPaint()
            }
        }

        Label {
            anchors.centerIn: parent

            text: page.formatRemainingTime(
                      page.appWindow.sleepTimerRemainingSeconds)

            color: page.appWindow.sleepTimerPaused
                   ? Theme.secondaryHighlightColor
                   : Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.DemiBold
        }
    }

    // Add and clear Timer Button
    IconButton {
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
}
