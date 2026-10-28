import QtQuick 2.6
import Sailfish.Silica 1.0

// Used in playbackBar and CoverPage
Item {
    id: playingIndicator

    property var applicationWindow
    property color barColor: Theme.highlightColor
    property real sizeMultiplier: 1.0

    // Makes the component genuinely reusable at different sizes.
    height: Math.min(
                Theme.iconSizeSmall * sizeMultiplier,
                parent ? parent.height * 0.7 : Theme.iconSizeSmall * sizeMultiplier
            )

    property var app: applicationWindow

    property bool playing: {
        return app
               && (app.isPlaying || app.customSoundPlaying)
               && !app.pausedMode
    }

    property bool binauralActive: {
        return app && app.activeBand !== ""
    }

    property bool noiseActive: {
        return app && app.activeNoise !== ""
    }

    // 0 = standard fallback, 1 = binaural, 2 = colored noise, 3 = both
    property int animationMode: {
        if (!playing || !app)
            return 0

        var builtInPlaying = app.isPlaying === true

        var hasBinaural = builtInPlaying
                          && app.activeBand
                          && app.activeBand !== ""

        var hasNoise = builtInPlaying
                       && app.activeNoise
                       && app.activeNoise !== ""

        var hasAmbience = builtInPlaying
                          && app.activeAmbiences
                          && app.activeAmbiences.length > 0

        var hasCustomSound = app.customSoundPlaying === true

        // Any ambience or custom sound uses the standard animation.
        if (hasAmbience || hasCustomSound)
            return 0

        // Use special animations only for recognized combinations.
        if (hasBinaural && hasNoise)
            return 3

        if (hasBinaural && !hasNoise)
            return 1

        if (hasNoise && !hasBinaural)
            return 2

        // Fallback for every other sound.
        return 0
    }

    property real barWidth: Math.max(
                                2,
                                Theme.iconSizeSmall * sizeMultiplier / 6
                            )
    property real barGap: barWidth
    property real idleHeight: height * 0.22
    property real maxBarHeight: height * 0.9

    property real wavePhase: 0
    property real noiseVibration: 0

    // Shared spike factor for side bars (index 0 and 2) in default mode.
    property real sideSpike: 0.55 + Math.random() * 0.45

    width: barWidth * 3 + barGap * 2

    // Continuously moving wave for binaural modes.
    NumberAnimation {
        target: playingIndicator
        property: "wavePhase"
        from: 0
        to: 2 * Math.PI
        duration: 1000
        loops: Animation.Infinite
        running: playingIndicator.animationMode === 1
                 || playingIndicator.animationMode === 3
    }

    // Wave and vibration when binaural and colored noise are combined.
    SequentialAnimation {
        running: playingIndicator.animationMode === 3
        loops: Animation.Infinite

        NumberAnimation {
            target: playingIndicator
            property: "noiseVibration"
            to: Math.random()
            duration: 100
        }

        NumberAnimation {
            target: playingIndicator
            property: "noiseVibration"
            to: Math.random()
            duration: 125
        }

        PauseAnimation {
            duration: 30
        }
    }

    // Updates the shared side-bar spike each default-mode cycle (300+250+100).
    Timer {
        interval: 650
        repeat: true
        running: playingIndicator.playing
                 && playingIndicator.animationMode === 0
        onTriggered: playingIndicator.sideSpike = 0.55 + Math.random() * 0.45
    }

    Repeater {
        model: 3

        Rectangle {
            id: waveBar

            property real wavePosition: playingIndicator.wavePhase
                                        - index * 1.5

            property real waveHeight: playingIndicator.idleHeight
                                      + (playingIndicator.maxBarHeight
                                         - playingIndicator.idleHeight)
                                      * (0.5 + 0.5 * Math.sin(wavePosition))

            // Phase-shifted per-bar jitter so bars are never in sync (mode 3).
            property real vibration: playingIndicator.animationMode === 3
                                     ? Math.sin(playingIndicator.noiseVibration * 10 + index * 2.1) * 0.5
                                       // make spiking less wild, lower the number:
                                       * playingIndicator.maxBarHeight * 0.30
                                     : 0

            // Animations control this property in modes 0 and 2.
            property real barHeight: playingIndicator.idleHeight

            width: playingIndicator.barWidth

            height: Math.max(
                        playingIndicator.idleHeight * 0.5,
                        Math.min(
                            playingIndicator.maxBarHeight,
                            barHeight
                            )
                        )

            radius: width / 2

            x: index * (playingIndicator.barWidth
                        + playingIndicator.barGap)

            anchors.verticalCenter: parent.verticalCenter

            color: playingIndicator.barColor

            // Binaural modes: bind height to the traveling wave.
            Binding {
                target: waveBar
                property: "barHeight"

                value: Math.max(
                           playingIndicator.idleHeight * 0.5,
                           Math.min(
                               playingIndicator.maxBarHeight,
                               waveBar.waveHeight + waveBar.vibration
                               )
                           )

                when: playingIndicator.animationMode === 1
                      || playingIndicator.animationMode === 3
            }

            // Colored noise: balanced, independent movement.
            SequentialAnimation {
                running: playingIndicator.playing
                         && playingIndicator.animationMode === 2
                loops: Animation.Infinite

                NumberAnimation {
                    target: waveBar
                    property: "barHeight"
                    to: playingIndicator.idleHeight
                        + (playingIndicator.maxBarHeight
                           - playingIndicator.idleHeight)
                        * (0.20 + Math.random() * 0.40)
                    duration: 140 + Math.random() * 60
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: waveBar
                    property: "barHeight"
                    to: playingIndicator.idleHeight
                        + (playingIndicator.maxBarHeight
                           - playingIndicator.idleHeight)
                        * (0.20 + Math.random() * 0.40)
                    duration: 140 + Math.random() * 60
                    easing.type: Easing.InOutQuad
                }

                PauseAnimation {
                    duration: Math.random() * 40
                }
            }

            // Default animation: all other playback combinations.
            SequentialAnimation {
                running: playingIndicator.playing
                         && playingIndicator.animationMode === 0
                loops: Animation.Infinite

                NumberAnimation {
                    target: waveBar
                    property: "barHeight"
                    to: playingIndicator.idleHeight
                        + (playingIndicator.maxBarHeight
                           * (model.index === 1 ? 1.0 : 0.7)
                           - playingIndicator.idleHeight)
                        * (model.index === 1
                           ? (0.80 + Math.random() * 0.20)   // range 0.80–1.00
                           : playingIndicator.sideSpike)
                    duration: 300
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: waveBar
                    property: "barHeight"
                    to: playingIndicator.idleHeight
                    duration: 250
                    easing.type: Easing.InOutQuad
                }

                PauseAnimation {
                    duration: 100
                }
            }

            // Smooth fade to idle on stop/pause.
            NumberAnimation {
                id: stopFade
                target: waveBar
                property: "barHeight"
                duration: 100
                easing.type: Easing.OutQuad
            }

            Connections {
                target: playingIndicator

                onPlayingChanged: {
                    if (!playingIndicator.playing) {
                        stopFade.to = playingIndicator.idleHeight
                        stopFade.start()
                    }
                }

                onAnimationModeChanged: {
                    if (!playingIndicator.playing) {
                        stopFade.to = playingIndicator.idleHeight
                        stopFade.start()
                    }
                }
            }
        }
    }
}
