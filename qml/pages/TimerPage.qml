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

    // Time display with h/min units inside TimePicker
    Column {
        visible: !page.appWindow.sleepTimerRunning
        anchors {
            horizontalCenter: timerPicker.horizontalCenter
            verticalCenter: timerPicker.verticalCenter
        }
        spacing: 0

        // Hour display
        Row {
            visible: timerPicker.hour > 0
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall

            Label {
                id: hourValue
                text: timerPicker.hour
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
            }
            Label {
                //: SI symbol for hour. Keep as-is for Latin-script locales.
                text: qsTr("h")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                anchors.baseline: hourValue.baseline
            }
        }

        // Minute display
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.paddingSmall

            Label {
                id: minuteValue
                text: timerPicker.minute
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.DemiBold
            }
            Label {
                //: SI symbol for minute. Keep as-is for Latin-script locales.
                text: qsTr("min")
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                anchors.baseline: minuteValue.baseline
            }
        }
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

        // Outer countdown timer ring
        Canvas {
            id: timerRing
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                var centerX = width / 2
                var centerY = height / 2
                var ringWidth = Theme.paddingMedium
                var radius = Math.min(width, height) / 2 - ringWidth

                var progress = 0
                if (page.appWindow.sleepTimerDurationSeconds > 0) {
                    progress = page.appWindow.sleepTimerRemainingSeconds
                               / page.appWindow.sleepTimerDurationSeconds
                }
                progress = Math.max(0, Math.min(1, progress))

                ctx.clearRect(0, 0, width, height)

                // Main ring (track)
                ctx.beginPath()
                ctx.arc(centerX, centerY, radius,
                        -Math.PI / 2, 3 * Math.PI / 2, false)
                ctx.lineWidth = ringWidth
                ctx.lineCap = "butt"
                ctx.strokeStyle = Theme.rgba(Theme.primaryColor, 0.2)
                ctx.stroke()

                // Main ring (progress)
                if (progress > 0) {
                    ctx.beginPath()
                    ctx.arc(centerX, centerY, radius,
                            -Math.PI / 2,
                            -Math.PI / 2 + (2 * Math.PI * progress),
                            false)
                    ctx.lineWidth = ringWidth
                    ctx.lineCap = "round"
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

        // Inner orbiting dot - one turn per minute
        Item {
            id: orbitContainer
            anchors.centerIn: parent
            width: 0
            height: 0

            // Angle =nfunction of elapsed time
            property real orbitAngle: {
                if (!page.appWindow.sleepTimerRunning)
                    return 0
                var elapsed = page.appWindow.sleepTimerDurationSeconds
                              - page.appWindow.sleepTimerRemainingSeconds
                return (elapsed / 60.0) * 360.0 - 90.0
            }

            property real orbitRadius: Math.min(timerDisplay.width, timerDisplay.height) / 2
                                       - Theme.paddingMedium * 3
                                       - Theme.iconSizeSmall / 2

            Rectangle {
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
                radius: width / 2
                color: Theme.highlightColor
                opacity: 0.4

                x: orbitContainer.orbitRadius * Math.cos(orbitContainer.orbitAngle * Math.PI / 180) - width / 2
                y: orbitContainer.orbitRadius * Math.sin(orbitContainer.orbitAngle * Math.PI / 180) - height / 2
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
                    : "image://theme/icon-l-add?"

        enabled: page.appWindow.sleepTimerRunning ||
                 (page.selectedDurationSeconds() > 0 &&
                  page.appWindow.isPlaying)

        onClicked: {
            if (page.appWindow.sleepTimerRunning) {
                page.appWindow.cancelSleepTimer()
            } else {
                page.appWindow.startSleepTimer(
                    page.selectedDurationSeconds())
            }
        }
    }
}
