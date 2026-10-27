import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: playingIndicator

    property var applicationWindow
    property color barColor: Theme.highlightColor

    height: Math.min(Theme.iconSizeSmall, parent.height * 0.7)

    property var app: applicationWindow

    property bool playing: {
        return app && (app.isPlaying || app.customSoundPlaying)
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

        var builtInPlaying = app.isPlaying
        var hasBinaural = builtInPlaying && app.activeBand !== ""
        var hasNoise = builtInPlaying && app.activeNoise !== ""

        var hasAmbience = builtInPlaying
                          && app.activeAmbiences
                          && app.activeAmbiences.length > 0

        var hasCustomSound = app.customSoundPlaying

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

        // Fallback for every other sound or future sound type.
        return 0
    }

    property real barWidth: Math.max(2, Theme.iconSizeSmall / 6)
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
        duration: 1200
        loops: Animation.Infinite
        running: playingIndicator.animationMode === 1
                 || playingIndicator.animationMode === 3
    }

    // Strong vibration when binaural and colored noise are combined.
    SequentialAnimation {
        running: playingIndicator.animationMode === 3
        loops: Animation.Infinite

        NumberAnimation {
            target: playingIndicator
            property: "noiseVibration"
            to: Math.random()
            duration: 40
        }

        NumberAnimation {
            target: playingIndicator
            property: "noiseVibration"
            to: Math.random()
            duration: 55
        }

        NumberAnimation {
            target: playingIndicator
            property: "noiseVibration"
            to: Math.random()
            duration: 35
        }

        PauseAnimation {
            duration: 10
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
                                       * playingIndicator.maxBarHeight * 0.55
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

            // Colored noise alone: independent, irregular movement.
            SequentialAnimation {
                running: playingIndicator.playing
                         && playingIndicator.animationMode === 2
                loops: Animation.Infinite

                NumberAnimation {
                    target: waveBar
                    property: "barHeight"

                    to: playingIndicator.idleHeight
                        + Math.random()
                        * (playingIndicator.maxBarHeight
                           - playingIndicator.idleHeight)

                    duration: 70 + Math.random() * 150
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target: waveBar
                    property: "barHeight"

                    to: playingIndicator.idleHeight
                        + Math.random()
                        * (playingIndicator.maxBarHeight
                           - playingIndicator.idleHeight)

                    duration: 60 + Math.random() * 120
                    easing.type: Easing.InOutQuad
                }

                PauseAnimation {
                    duration: Math.random() * 70
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
                        * (0.3 + Math.random() * 0.7)

                    duration: 150 + Math.random() * 250
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: waveBar
                    property: "barHeight"
                    to: playingIndicator.idleHeight

                    duration: 150 + Math.random() * 200
                    easing.type: Easing.InOutQuad
                }

                PauseAnimation {
                    duration: Math.random() * 120
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
