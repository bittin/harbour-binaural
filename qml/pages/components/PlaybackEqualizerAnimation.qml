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

            property real vibration: playingIndicator.animationMode === 3
                                     ? (playingIndicator.noiseVibration - 0.5)
                                       * playingIndicator.maxBarHeight * 0.60
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
                        * (0.25 + Math.random() * 0.55)
                    duration: 140 + Math.random() * 60
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: waveBar
                    property: "barHeight"
                    to: playingIndicator.idleHeight
                        + (playingIndicator.maxBarHeight
                           - playingIndicator.idleHeight)
                        * (0.25 + Math.random() * 0.55)
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
                           - playingIndicator.idleHeight)
                        * (0.55 + Math.random() * 0.45)
                    duration: 220 + Math.random() * 280
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: waveBar
                    property: "barHeight"
                    to: playingIndicator.idleHeight
                    duration: 220 + Math.random() * 230
                    easing.type: Easing.InOutQuad
                }

                PauseAnimation {
                    duration: Math.random() * 150
                }
            }

            Connections {
                target: playingIndicator

                onPlayingChanged: {
                    if (!playingIndicator.playing)
                        waveBar.barHeight = playingIndicator.idleHeight
                }

                onAnimationModeChanged: {
                    if (!playingIndicator.playing)
                        waveBar.barHeight = playingIndicator.idleHeight
                }
            }
        }
    }

}
