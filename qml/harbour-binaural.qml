import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import Binaural 1.0
import "pages"
import "cover"
import "pages/components"

ApplicationWindow {
    id: appWindow

    bottomMargin: appWindow.playbackBarShouldShow
                  ? playbackBar.height
                  : 0

    Behavior on bottomMargin {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    property var mainPage

    property string activeBand: mainPage
                                ? mainPage.activeBand
                                : ""

    property var activeAmbiences: mainPage
                                  ? mainPage.activeAmbiences
                                  : []

    property string activeAmbience: activeAmbiences.length > 0
                                    ? activeAmbiences[0]
                                    : ""

    property string activeNoise: mainPage
                                 ? mainPage.activeNoise
                                 : ""

    property bool isPlaying: mainPage
                             ? mainPage.isPlaying
                             : false

    // Custom Sound Picker
    property url customSoundSource: ""
    property string customSoundName: ""
    property bool customSoundLoop: false

    property bool customSoundPlaying: customAudio.playbackState
                                      === Audio.PlayingState

    // Slider setting: 0 to 100 percent.
    property real customSoundVolume: 50

    // Independent gain for the sleep-timer fade.
    // 1.0 = full slider volume; 0.0 = silent.
    property real customSoundFadeGain: 1.0

    Audio {
        id: customAudio

        source: appWindow.customSoundSource
        autoPlay: false

        loops: appWindow.customSoundLoop
               ? Audio.Infinite
               : 1

        // Slider volume multiplied by the fade gain.
        volume: (appWindow.customSoundVolume / 100.0)
                * appWindow.customSoundFadeGain

        onError: {
            console.log("Custom audio error:", errorString)
        }
    }

    // Fade the custom sound to silence over 10 seconds.
    NumberAnimation {
        id: customSoundFadeOut

        target: appWindow
        property: "customSoundFadeGain"
        to: 0
        duration: 10000

        onStopped: {
            // Stop only if the fade reached silence.
            if (appWindow.customSoundFadeGain <= 0.001) {
                customAudio.stop()
                appWindow.customSoundFadeGain = 1.0
            }
        }
    }

    function playCustomSound() {
        if (customSoundSource.toString() === "")
            return

        // Cancel a pending fade and restore normal gain.
        customSoundFadeOut.stop()
        customSoundFadeGain = 1.0

        customAudio.play()
    }

    function pauseCustomSound() {
        // Cancel the fade before pausing.
        customSoundFadeOut.stop()
        customSoundFadeGain = 1.0

        customAudio.pause()
    }

    function stopCustomSound() {
        customSoundFadeOut.stop()
        customAudio.stop()

        customSoundFadeGain = 1.0
    }

    function fadeOutCustomSound() {
        if (customAudio.playbackState !== Audio.PlayingState) {
            stopCustomSound()
            return
        }

        if (customSoundFadeOut.running)
            return

        customSoundFadeOut.from = customSoundFadeGain
        customSoundFadeOut.to = 0
        customSoundFadeOut.start()
    }

    // Sleep Timer
    property bool sleepTimerRunning: false
    property bool sleepTimerPaused: false
    property int sleepTimerRemainingSeconds: 0
    property int sleepTimerDurationSeconds: 0

    // Playback bar visibility
    property bool playbackBarShouldShow: true

    function updatePlaybackBarVisibility() {
        var current = pageStack.currentPage

        playbackBarShouldShow = current === null ||
                (current.objectName !== "AboutPage" &&
                 current.objectName !== "CreditPage" &&
                 current.objectName !== "InfoBinauralPage" &&
                 current.objectName !== "InfoColoredPage")
    }

    Timer {
        id: playbackBarVisibilityTimer

        interval: 300
        repeat: false

        onTriggered: appWindow.updatePlaybackBarVisibility()
    }

    // Update after the page stack changes.
    Connections {
        target: appWindow.pageStack

        onCurrentPageChanged: {
            playbackBarVisibilityTimer.restart()
        }
    }

    function startSleepTimer(seconds) {
        if (seconds <= 0)
            return

        sleepTimer.stop()

        appWindow.sleepTimerDurationSeconds = seconds
        appWindow.sleepTimerRemainingSeconds = seconds
        appWindow.sleepTimerPaused = false
        appWindow.sleepTimerRunning = true

        sleepTimer.start()
    }

    function pauseSleepTimer() {
        if (!appWindow.sleepTimerRunning ||
                appWindow.sleepTimerPaused)
            return

        sleepTimer.stop()
        appWindow.sleepTimerPaused = true
    }

    function resumeSleepTimer() {
        if (!appWindow.sleepTimerRunning ||
                !appWindow.sleepTimerPaused)
            return

        if (appWindow.sleepTimerRemainingSeconds <= 0) {
            appWindow.cancelSleepTimer()
            return
        }

        appWindow.sleepTimerPaused = false
        sleepTimer.start()
    }

    function cancelSleepTimer() {
        sleepTimer.stop()

        appWindow.sleepTimerRunning = false
        appWindow.sleepTimerPaused = false
        appWindow.sleepTimerRemainingSeconds = 0
        appWindow.sleepTimerDurationSeconds = 0
    }

    Timer {
        id: sleepTimer

        interval: 1000
        repeat: true

        onTriggered: {
            if (appWindow.sleepTimerPaused ||
                    !appWindow.sleepTimerRunning)
                return

            if (appWindow.sleepTimerRemainingSeconds > 0)
                appWindow.sleepTimerRemainingSeconds--

            if (appWindow.sleepTimerRemainingSeconds <= 0) {
                sleepTimer.stop()

                appWindow.sleepTimerRunning = false
                appWindow.sleepTimerPaused = false
                appWindow.sleepTimerRemainingSeconds = 0
                appWindow.sleepTimerDurationSeconds = 0

                if (appWindow.mainPage) {
                    console.log("SLEEP TIMER: calling fadeOutForSleepTimer")
                    appWindow.mainPage.fadeOutForSleepTimer()
                }

                // Fade the custom sound at the same time.
                appWindow.fadeOutCustomSound()
            }
        }
    }

    // Something selected but not playing (system suspend or manual
    // stop): dimmed hint state of the playback bar.
    property bool pausedMode: !isPlaying &&
                              (activeBand !== "" ||
                               activeAmbiences.length > 0 ||
                               activeNoise !== "")

    initialPage: Component {
        MainPage {
            id: mainPageInstance

            applicationWindow: appWindow

            Component.onCompleted: {
                appWindow.mainPage = mainPageInstance
                appWindow.updatePlaybackBarVisibility()
            }
        }
    }

    cover: Component {
        CoverPage {
            activeBand: appWindow.activeBand
            activeAmbiences: appWindow.activeAmbiences
            activeNoise: appWindow.activeNoise
            isPlaying: appWindow.isPlaying
            isPaused: appWindow.pausedMode

            sleepTimerRunning: appWindow.sleepTimerRunning
            sleepTimerPaused: appWindow.sleepTimerPaused
            sleepTimerRemainingSeconds: appWindow.sleepTimerRemainingSeconds

            onPlayPauseClicked: {
                if (appWindow.mainPage) {
                    appWindow.mainPage.togglePlayback()
                }
            }
        }
    }

    Item {
        id: playbackBarContainer

        width: appWindow.width
        height: Theme.itemSizeExtraLarge

        x: 0
        z: 3

        visible: true

        y: appWindow.playbackBarShouldShow
           ? appWindow.height - height
           : appWindow.height

        Behavior on y {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutQuad
            }
        }

        PlaybackBar {
            id: playbackBar

            width: parent.width
            height: parent.height

            x: 0
            y: 0

            applicationWindow: appWindow
            enabled: appWindow.playbackBarShouldShow
        }
    }

    allowedOrientations: defaultAllowedOrientations
}
