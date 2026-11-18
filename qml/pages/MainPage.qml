import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0
import "components"

Page {
    id: page

    property string activeBand: ""
    property string activeNoise: ""
    property var activeAmbiences: []
    property bool isCustomBinaural: false
    property bool noiseWavesEnabled: false

    property bool bandPlaying: audioEngine.binauralPlaying
    property bool ambiencePlaying: audioEngine.ambiencePlaying
    property bool noisePlaying: audioEngine.coloredNoisePlaying

    property bool customSoundPlaying: audioEngine.customSoundPlaying

    property bool customSoundSelected:
        audioEngine.customSoundSource.toString() !== ""

    // Anything selected - used by menus, bar, cover, pausedMode, sleep timer
    property bool hasActiveSounds:
        activeBand !== "" ||
        activeNoise !== "" ||
        activeAmbiences.length > 0 ||
        customSoundSelected

    // Mix label ("Alpha & Custom", "Rain & White noise", ...)
    property string mixLabel: {
        var parts = []

        if (activeBand !== "")
            parts.push(SoundNames.label(activeBand))

        if (activeNoise !== "")
            parts.push(SoundNames.label(activeNoise))

        if (activeAmbiences.length === 1)
            parts.push(SoundNames.label(activeAmbiences[0]))
        else if (activeAmbiences.length > 1)
            parts.push(SoundNames.label("Ambient mix"))

        if (customSoundSelected)
            parts.push(SoundNames.label("Custom sound"))

        return parts.join(", ")
    }

    property bool isPlaying: bandPlaying ||
                             ambiencePlaying ||
                             noisePlaying ||
                             customSoundPlaying

    property bool pausedMode: !isPlaying && hasActiveSounds

    AudioEngine {
        id: audioEngine
    }

    onIsPlayingChanged: {
        appWindow.isPlaying = isPlaying
    }

    onActiveBandChanged: checkSleepTimer()
    onActiveAmbiencesChanged: checkSleepTimer()
    onActiveNoiseChanged: checkSleepTimer()
    onCustomSoundSelectedChanged: checkSleepTimer()

    function checkSleepTimer() {
        if (appWindow.sleepTimerRunning && !page.hasActiveSounds)
            appWindow.cancelSleepTimer()
    }

    function fadeOutForSleepTimer() {
        audioEngine.fadeOutForSleepTimer()
    }

    function resumeAll() {
        if (activeBand !== "") {
            if (audioEngine.binauralPaused) {
                audioEngine.resumeBinaural()
            } else if (!audioEngine.binauralPlaying) {
                audioEngine.start()
            }
        }

        if (activeAmbiences.length > 0) {
            if (audioEngine.ambiencePaused)
                audioEngine.resumeAmbience()

            for (var i = 0; i < activeAmbiences.length; ++i)
                audioEngine.setAmbience(activeAmbiences[i])
        }

        if (audioEngine.customSoundSource.toString() !== "") {
            if (audioEngine.customSoundPaused) {
                audioEngine.resumeCustomSound()
            } else if (!audioEngine.customSoundPlaying) {
                audioEngine.playCustomSound()
            }
        }

        if (activeNoise !== "") {
            if (audioEngine.coloredNoisePaused) {
                audioEngine.resumeColoredNoise()
            } else if (!audioEngine.coloredNoisePlaying) {
                audioEngine.setColoredNoise(activeNoise)
            }
        }
    }

    function togglePlayback() {
        if (isPlaying) {
            audioEngine.pauseBinaural()
            audioEngine.pauseAmbience()
            audioEngine.pauseColoredNoise()
            audioEngine.pauseCustomSound()
            appWindow.pauseSleepTimer()
        } else {
            resumeAll()
            appWindow.resumeSleepTimer()
        }
    }

    function deselectAllSounds() {
        audioEngine.stop()
        audioEngine.stopAmbience()
        audioEngine.stopColoredNoise()
        audioEngine.stopCustomSound()
        noiseWaveDrawer.open = false

        page.activeBand = ""
        page.activeAmbiences = []
        page.activeNoise = ""
        page.isCustomBinaural = false

        audioEngine.customSoundSource = ""
        audioEngine.customSoundName = ""

        ambienceDrawer.open = false
        binauralDrawer.open = false
        soundPickerDrawer.open = false
    }

    function beatBand(freq) {
        if (freq >= 0.5  && freq < 4)    return "Delta"
        if (freq >= 4    && freq < 8)    return "Theta"
        if (freq >= 8    && freq < 13)   return "Alpha"
        if (freq >= 13   && freq < 30)   return "Beta"
        if (freq >= 30   && freq <= 100) return "Gamma"
        return ""
    }

    Component {
        id: infoBinauralPageComponent
        InfoBinauralPage {}
    }

    Component {
        id: infoColoredPageComponent
        InfoColoredPage {}
    }

    PageDrawer {
        id: ambienceDrawer

        drawerContent: AmbienceDrawer {
            id: ambienceSelector

            activeAmbiences: page.activeAmbiences
            ambiencePlaying: page.ambiencePlaying
            pausedMode: page.pausedMode
            customSoundSelected: page.customSoundSelected

            onCloseRequested: ambienceDrawer.open = false

            onAmbienceSelected: {
                if (page.activeAmbiences.indexOf(ambience) !== -1)
                    return

                if (page.activeAmbiences.length
                        + (page.customSoundSelected ? 1 : 0) >= 3)
                    return

                var wasPaused = page.pausedMode
                page.activeAmbiences = page.activeAmbiences.concat([ambience])
                audioEngine.setAmbience(ambience)

                if (wasPaused)
                    audioEngine.pauseAmbience()
            }

            onAmbienceDeselected: {
                var updated = page.activeAmbiences.slice()
                var index = updated.indexOf(ambience)

                if (index === -1)
                    return

                updated.splice(index, 1)
                page.activeAmbiences = updated
                audioEngine.stopAmbienceByName(ambience)
            }

            onAmbienceVolumeChanged: {
                audioEngine.setAmbienceVolume(volume)
            }
        }

        PageDrawer {
            id: binauralDrawer

            drawerContent: CustomBinauralDrawer {
                id: customBinauralPanel

                customActive: page.isCustomBinaural
                playing: page.bandPlaying

                onCloseRequested: {
                    binauralDrawer.open = false
                }

                onFrequencyChanged: {
                    if (page.isCustomBinaural) {
                        audioEngine.setBinauralFrequency(carrier, beat)

                        var band = page.beatBand(beat)

                        if (band !== "")
                            page.activeBand = band
                    }
                }

                onStartRequested: {
                    var band = page.beatBand(beat)
                    if (page.pausedMode) {
                        audioEngine.stop()
                        page.activeBand = band
                        page.isCustomBinaural = true
                        audioEngine.setBinauralFrequency(carrier, beat)
                    } else {
                        page.activeBand = band
                        page.isCustomBinaural = true
                        audioEngine.setBinauralFrequency(carrier, beat)
                        audioEngine.start()
                    }
                }

                onStopRequested: {
                    page.activeBand = ""
                    page.isCustomBinaural = false
                    audioEngine.stop()
                }
            }

            PageDrawer {
                id: noiseWaveDrawer

                drawerContent: NoiseWaveDrawer {
                    id: noiseWavePanel

                    wavesActive: page.noiseWavesEnabled
                    playing: page.noisePlaying

                    onCloseRequested: {
                        noiseWaveDrawer.open = false
                    }

                    onWaveChanged: {
                        if (page.noiseWavesEnabled) {
                            audioEngine.setNoiseWave(
                                        true, depth, period)
                        }
                    }

                    onEnableRequested: {
                        audioEngine.setNoiseWave(
                                    true, depth, period)
                        page.noiseWavesEnabled = true
                    }

                    onDisableRequested: {
                        audioEngine.setNoiseWave(
                                    false, 0, 8)
                        page.noiseWavesEnabled = false
                        noiseWaveDrawer.open = false
                    }
                }

                PageDrawer {
                    id: soundPickerDrawer

                    drawerContent: SoundPickerDrawer {
                        id: soundPickerPanel

                        audioEngine: audioEngine
                        pausedMode: page.pausedMode

                        onCloseRequested:
                        soundPickerDrawer.open = false
                    }

                    // The container is the Drawer foreground.
                    // The dimmer and click handler move with the foreground,
                    // leaving the exposed drawer background interactive.
                    Item {
                        id: foregroundContent

                        anchors.fill: parent

                        SilicaFlickable {
                            id: foregroundPage

                            anchors.fill: parent
                            contentHeight: column.height + Theme.paddingLarge
                            clip: true

                            PullDownMenu {
                                MenuItem {
                                    text: qsTr("About")

                                    onClicked: {
                                        pageStack.push(
                                                    Qt.resolvedUrl("AboutPage.qml")
                                                    )
                                    }
                                }

                                MenuItem {
                                    text: qsTr("Deselect all sounds")
                                    enabled: page.hasActiveSounds

                                    onClicked: {
                                        page.deselectAllSounds()
                                    }
                                }

                                MenuItem {
                                    text: qsTr("Timer")
                                    enabled: page.hasActiveSounds

                                    onClicked: {
                                        pageStack.push(
                                                    Qt.resolvedUrl("TimerPage.qml"),
                                                    { appWindow: appWindow }
                                                    )
                                    }
                                }
                            }

                            Column {
                                id: column

                                width: parent.width
                                spacing: Theme.paddingMedium

                                // Move slightly down for display notch on modern devices
                                Item {
                                    width: parent.width
                                    height: Theme.paddingLarge
                                }

                                // Binaural Beats Section
                                SectionHeader {
                                    text: qsTr("Binaural Beats")
                                }

                                Item {
                                    x: Theme.horizontalPageMargin
                                    width: parent.width -
                                           2 * Theme.horizontalPageMargin
                                    height: Theme.fontSizeExtraSmall

                                    Row {
                                        anchors.right: parent.right
                                        spacing: Theme.paddingSmall

                                        Label {
                                            text: qsTr("To be used with")
                                            color: Theme.secondaryHighlightColor
                                            font.pixelSize: Theme.fontSizeExtraSmall
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Item {
                                            width: Theme.fontSizeExtraSmall
                                            height: Theme.fontSizeExtraSmall

                                            anchors.verticalCenter: parent.verticalCenter

                                            Image {
                                                id: headsetImage

                                                anchors.fill: parent
                                                source: "../images/icon-s-headset.svg"
                                                fillMode: Image.PreserveAspectFit
                                                smooth: true
                                                visible: false
                                            }

                                            ColorOverlay {
                                                anchors.fill: headsetImage
                                                source: headsetImage
                                                color: Theme.secondaryHighlightColor
                                                opacity: 0.8
                                            }
                                        }
                                    }
                                }

                                // Binaural Beats Selection grid
                                SilicaGridView {
                                    id: frequencyGrid

                                    x: Theme.horizontalPageMargin
                                    width: parent.width - 2 * Theme.horizontalPageMargin
                                    height: contentHeight

                                    cellWidth: width / 3
                                    cellHeight: Theme.itemSizeMedium

                                    model: ListModel {
                                        ListElement {
                                            bandName: "Delta"
                                            symbol: "δ"
                                        }
                                        ListElement {
                                            bandName: "Delta/Theta"
                                            symbol: "δ / θ"
                                        }
                                        ListElement {
                                            bandName: "Theta"
                                            symbol: "θ"
                                        }
                                        ListElement {
                                            bandName: "Alpha"
                                            symbol: "α"
                                        }
                                        ListElement {
                                            bandName: "Beta"
                                            symbol: "β"
                                        }
                                        ListElement {
                                            bandName: "Gamma"
                                            symbol: "γ"
                                        }
                                    }

                                    delegate: Item {
                                        width: frequencyGrid.cellWidth
                                        height: frequencyGrid.cellHeight

                                        SoundButton {
                                            anchors.centerIn: parent
                                            preferredWidth: frequencyGrid.cellWidth - Theme.paddingMedium

                                            text: symbol

                                            selected: page.activeBand === bandName
                                                      && !page.isCustomBinaural
                                            playing: page.bandPlaying

                                            onClicked: {
                                                if (selected) {
                                                    page.activeBand = ""
                                                    page.isCustomBinaural = false
                                                    audioEngine.stop()
                                                } else if (!page.pausedMode) {
                                                    page.activeBand = bandName
                                                    page.isCustomBinaural = false
                                                    audioEngine.setFrequencyBand(bandName)
                                                    audioEngine.start()
                                                } else {
                                                    audioEngine.stop()
                                                    page.activeBand = bandName
                                                    page.isCustomBinaural = false
                                                    audioEngine.setFrequencyBand(bandName)
                                                }
                                            }
                                        }
                                    }
                                }

                                // Custom frequencies button
                                Item {
                                    width: parent.width
                                    height: customFrequenciesButton.height

                                    SoundButton {
                                        id: customFrequenciesButton

                                        anchors.centerIn: parent
                                        preferredWidth: frequencyGrid.width - Theme.paddingMedium

                                        text: {
                                            if (page.isCustomBinaural) {
                                                var carrier = customBinauralPanel.carrierHz
                                                var beat    = customBinauralPanel.beatHz
                                                var label   = carrier + " Hz / " + beat.toFixed(1) + " Hz"
                                                var band    = page.beatBand(beat)
                                                if (band !== "")
                                                    label += " - " + SoundNames.label(band)
                                                return label
                                            }
                                            return qsTr("Custom frequencies")
                                        }

                                        selected: page.isCustomBinaural
                                        playing: page.bandPlaying

                                        onClicked: {
                                            binauralDrawer.open = true
                                        }
                                    }
                                }

                                // Binaural Beats Volume slider
                                VolumeSliderRow {
                                    width: parent.width - 2 * Theme.horizontalPageMargin
                                    x: Theme.horizontalPageMargin

                                    showInfoButton: true
                                    enabled: page.activeBand !== ""

                                    onValueChanged: audioEngine.setBinauralVolume(value)
                                    onInfoClicked: pageStack.push(infoBinauralPageComponent)
                                }

                                // Colored Noise Section
                                SectionHeader {
                                    text: qsTr("Colored Noise")
                                }

                                // Colored Noise Selection grid
                                SilicaGridView {
                                    id: coloredNoiseGrid

                                    x: Theme.horizontalPageMargin
                                    width: parent.width -
                                           2 * Theme.horizontalPageMargin
                                    height: contentHeight

                                    cellWidth: width / 2
                                    cellHeight: Theme.itemSizeMedium

                                    model: ["White", "Pink", "Brown", "Grey"]

                                    delegate: Item {
                                        width: coloredNoiseGrid.cellWidth
                                        height: coloredNoiseGrid.cellHeight

                                        SoundButton {
                                            anchors.centerIn: parent
                                            preferredWidth: coloredNoiseGrid.cellWidth -
                                                            Theme.paddingMedium

                                            text: SoundNames.label(modelData)

                                            selected: page.activeNoise === modelData
                                            playing: page.noisePlaying

                                            onClicked: {
                                                if (selected) {
                                                    page.activeNoise = ""
                                                    audioEngine.stopColoredNoise()
                                                } else if (!page.pausedMode) {
                                                    page.activeNoise = modelData
                                                    audioEngine.setColoredNoise(modelData)
                                                } else {
                                                    audioEngine.stopColoredNoise()
                                                    page.activeNoise = modelData
                                                }
                                            }
                                        }
                                    }
                                }

                                // Wave motion button
                                Item {
                                    width: parent.width
                                    height: waveMotionButton.height

                                    SoundButton {
                                        id: waveMotionButton

                                        anchors.centerIn: parent
                                        preferredWidth: frequencyGrid.width - Theme.paddingMedium

                                        text: qsTr("Wave motion")

                                        selected: page.noiseWavesEnabled
                                        playing: page.noisePlaying

                                        onClicked: {
                                            noiseWaveDrawer.open = true
                                        }
                                    }
                                }

                                // Colored Noise Volume slider
                                VolumeSliderRow {
                                    width: parent.width - 2 * Theme.horizontalPageMargin
                                    x: Theme.horizontalPageMargin

                                    showInfoButton: true
                                    enabled: page.activeNoise !== ""

                                    onValueChanged: audioEngine.setColoredNoiseVolume(value)
                                    onInfoClicked: pageStack.push(infoColoredPageComponent)
                                }

                                // Ambient Sound Section
                                SectionHeader {
                                    text: qsTr("Ambient Sound")
                                }

                                // AmbienceDrawer button
                                Item {
                                    width: parent.width
                                    height: ambienceButton.height

                                    SoundButton {
                                        id: ambienceButton

                                        anchors.centerIn: parent
                                        preferredWidth: frequencyGrid.width - Theme.paddingMedium

                                        text: page.activeAmbiences.length === 0
                                              ? qsTr("Ambient sounds")
                                              : page.activeAmbiences.map(function(ambience) {
                                                  return SoundNames.label(ambience)
                                              }).join(", ")

                                        selected: page.activeAmbiences.length > 0
                                        playing: page.ambiencePlaying

                                        onClicked: {
                                            ambienceDrawer.open = true
                                        }
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Theme.paddingSmall / 2
                                }

                                // Custom sound button
                                Item {
                                    width: parent.width
                                    height: customSoundButton.height

                                    SoundButton {
                                        id: customSoundButton

                                        anchors.centerIn: parent
                                        preferredWidth: frequencyGrid.width - Theme.paddingMedium

                                        // Added spaces "  " to add inside button padding
                                        // when custom sound has long file name.
                                        text: "  " + (audioEngine.customSoundName !== ""
                                                      ? audioEngine.customSoundName
                                                      : SoundNames.label("Custom sound")) + "  "

                                        enabled: page.customSoundSelected
                                                 || page.activeAmbiences.length < 3

                                        selected: page.customSoundSelected
                                        playing: page.customSoundPlaying

                                        onClicked: {
                                            soundPickerDrawer.open = true
                                        }
                                    }
                                }

                                Item {
                                    width: parent.width
                                    height: Theme.itemSizeMedium
                                }
                            }

                            VerticalScrollDecorator {}
                        }
                    }
                }
            }
        }
    }
}
