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

    property string activeBand: mainPage ? mainPage.activeBand : ""

    property var activeAmbiences: mainPage
                                  ? mainPage.activeAmbiences
                                  : []

    property string activeAmbience: activeAmbiences.length > 0
                                    ? activeAmbiences[0]
                                    : ""

    property string activeNoise: mainPage ? mainPage.activeNoise : ""

    property bool isPlaying: mainPage ? mainPage.isPlaying : false

    // Custom sound player
    property url customSoundSource: ""
    property string customSoundName: ""
    property bool customSoundLoop: false

    property bool customSoundPlaying: customAudio.playbackState
                                      === Audio.PlayingState

    property real customSoundVolume: 50
    property real customSoundFadeGain: 1.0

    // Folder playlist
    property var customSoundPlaylist: []
    property int customSoundPlaylistIndex: -1
    property bool customSoundFolderLoop: false
    property bool customSoundPlaylistActive: false

    // Used to start playback after changing the source.
    property bool customSoundStartPending: false

    Audio {
        id: customAudio

        source: appWindow.customSoundSource
        autoPlay: false

        loops: appWindow.customSoundPlaylistActive
               ? 1
               : (appWindow.customSoundLoop
                  ? Audio.Infinite
                  : 1)

        volume: (appWindow.customSoundVolume / 100.0)
                * appWindow.customSoundFadeGain

        onStatusChanged: {
            if (status === Audio.Loaded &&
                    appWindow.customSoundStartPending) {
                appWindow.customSoundStartPending = false
                customAudio.play()
            }

            if (status === Audio.EndOfMedia &&
                    appWindow.customSoundPlaylistActive) {
                console.log("Playlist: track finished")
                appWindow.playNextCustomSound()
            }

            if (status === Audio.InvalidMedia) {
                appWindow.customSoundStartPending = false
                console.log("Custom audio: invalid media",
                            appWindow.customSoundSource)
            }
        }

        onError: {
            console.log("Custom audio error:", errorString)
        }
    }

    // Fade custom sound to silence over 10 seconds.
    NumberAnimation {
        id: customSoundFadeOut

        target: appWindow
        property: "customSoundFadeGain"
        to: 0
        duration: 10000

        onStopped: {
            if (appWindow.customSoundFadeGain <= 0.001) {
                customAudio.stop()
                appWindow.customSoundFadeGain = 1.0
            }
        }
    }

    function clearCustomSoundPlaylist() {
        customSoundPlaylistActive = false
        customSoundPlaylist = []
        customSoundPlaylistIndex = -1
        customSoundFolderLoop = false
        customSoundStartPending = false
    }

    function playCustomSound() {
        if (customSoundSource.toString() === "")
            return

        // Starting single-file playback cancels the playlist.
        clearCustomSoundPlaylist()

        customSoundFadeOut.stop()
        customSoundFadeGain = 1.0
        customSoundStartPending = false

        customAudio.play()
    }

    function pauseCustomSound() {
        customSoundFadeOut.stop()
        customSoundStartPending = false
        customSoundFadeGain = 1.0

        customAudio.pause()
    }

    function resumeCustomSound() {
        customSoundFadeOut.stop()
        customSoundFadeGain = 1.0

        if (customSoundSource.toString() !== "")
            customAudio.play()
    }

    function stopCustomSound() {
        customSoundFadeOut.stop()
        clearCustomSoundPlaylist()

        customAudio.stop()
        customSoundFadeGain = 1.0
    }

    function startCustomSoundPlaylist(files, folderLoop) {
        if (!files || files.length === 0) {
            console.log("Folder playlist: no audio files found")
            return
        }

        customSoundFadeOut.stop()
        customAudio.stop()

        customSoundFadeGain = 1.0
        customSoundLoop = false

        customSoundPlaylist = files
        customSoundPlaylistIndex = 0
        customSoundFolderLoop = folderLoop
        customSoundPlaylistActive = true

        customSoundSource = files[0].url
        customSoundName = files[0].name

        console.log("Playlist: starting", customSoundName)

        // Start once the new source has loaded.
        customSoundStartPending = true
    }

    function changeCustomSoundTrack(direction) {
        if (!customSoundPlaylistActive ||
                customSoundPlaylist.length === 0) {
            console.log("Playlist: cannot change track; no active playlist")
            return
        }

        var nextIndex = customSoundPlaylistIndex + direction

        if (nextIndex < 0) {
            if (customSoundFolderLoop) {
                nextIndex = customSoundPlaylist.length - 1
            } else {
                nextIndex = 0
            }
        }

        if (nextIndex >= customSoundPlaylist.length) {
            if (customSoundFolderLoop) {
                nextIndex = 0
            } else {
                console.log("Playlist: already at the last track")
                return
            }
        }

        if (nextIndex === customSoundPlaylistIndex) {
            // Restart the current track when there is nowhere to go.
            customAudio.stop()
            customSoundFadeOut.stop()
            customSoundFadeGain = 1.0
            customAudio.play()
            return
        }

        customSoundFadeOut.stop()
        customAudio.stop()

        customSoundFadeGain = 1.0
        customSoundStartPending = true
        customSoundPlaylistIndex = nextIndex
        customSoundSource = customSoundPlaylist[nextIndex].url
        customSoundName = customSoundPlaylist[nextIndex].name

        console.log("Playlist: switching to track",
                    nextIndex, customSoundName)
    }

    function playPreviousCustomSound() {
        changeCustomSoundTrack(-1)
    }

    function playNextCustomSound() {
        changeCustomSoundTrack(1)
    }

    function skipToNextCustomSound() {
        playNextCustomSound()
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
                appWindow.sleepTimerPaused) {
            return
        }

        sleepTimer.stop()
        appWindow.sleepTimerPaused = true
    }

    function resumeSleepTimer() {
        if (!appWindow.sleepTimerRunning ||
                !appWindow.sleepTimerPaused) {
            return
        }

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
                    !appWindow.sleepTimerRunning) {
                return
            }

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

                appWindow.fadeOutCustomSound()
            }
        }
    }

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
                if (appWindow.mainPage)
                    appWindow.mainPage.togglePlayback()
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
