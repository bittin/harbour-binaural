import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0
import "components"

Page {
    id: page

    property var applicationWindow: null

    property string activeBand: ""
    property string activeNoise: ""
    property var activeAmbiences: []

    property bool bandPlaying: audioEngine.binauralPlaying
    property bool ambiencePlaying: audioEngine.ambiencePlaying
    property bool noisePlaying: audioEngine.coloredNoisePlaying

    property bool bandPaused: audioEngine.binauralPaused
    property bool ambiencePaused: audioEngine.ambiencePaused
    property bool noisePaused: audioEngine.coloredNoisePaused

    property bool isPlaying: bandPlaying ||
                             ambiencePlaying ||
                             noisePlaying

    property bool pausedMode: !isPlaying &&
                              (activeBand !== "" || activeAmbiences.length > 0 || activeNoise !== "")

    AudioEngine {
        id: audioEngine
    }

    onIsPlayingChanged: {
        appWindow.isPlaying = isPlaying
    }

    onActiveBandChanged: checkSleepTimer()
    onActiveAmbiencesChanged: checkSleepTimer()
    onActiveNoiseChanged: checkSleepTimer()

    function checkSleepTimer() {
        if (appWindow.sleepTimerRunning &&
                page.activeBand === "" &&
                page.activeAmbiences.length === 0 &&
                page.activeNoise === "") {
            appWindow.cancelSleepTimer()
        }
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

        if (activeNoise !== "") {
            if (audioEngine.coloredNoisePaused) {
                audioEngine.resumeColoredNoise()
            } else if (!audioEngine.coloredNoisePlaying) {
                audioEngine.setColoredNoise(activeNoise)
            }
        }
    }

    function togglePlayback() {
        var customSoundIsPlaying =
                appWindow && appWindow.customSoundPlaying

        if (isPlaying || customSoundIsPlaying) {
            // Pause all sounds.
            audioEngine.pauseBinaural()
            audioEngine.pauseAmbience()
            audioEngine.pauseColoredNoise()

            if (appWindow && appWindow.customSoundPlaying)
                appWindow.pauseCustomSound()

            appWindow.pauseSleepTimer()
        } else {
            // Resume all selected sounds.
            resumeAll()

            if (applicationWindow &&
                    applicationWindow.customSoundSource.toString() !== "" &&
                    !applicationWindow.customSoundPlaying) {
                applicationWindow.resumeCustomSound()
            }

            appWindow.resumeSleepTimer()
        }
    }

    function deselectAllSounds() {
        // Stop binaural beats.
        audioEngine.stop()

        // Stop ambient sounds.
        audioEngine.stopAmbience()

        // Stop colored noise.
        audioEngine.stopColoredNoise()

        // Clear the custom sound selection in the drawer, if available.
        if (selectorLoader.item
                && selectorLoader.item.clearSelection) {
            selectorLoader.item.clearSelection()
        } else if (applicationWindow) {
            // Fallback if the custom sound drawer isn't currently loaded.
            applicationWindow.stopCustomSound()
            applicationWindow.customSoundSource = ""
            applicationWindow.customSoundName = ""
            applicationWindow.customSoundLoop = false
        }

        // Clear selected sounds on the main page.
        page.activeBand = ""
        page.activeAmbiences = []
        page.activeNoise = ""

        // Close the selector drawer.
        selectorDrawer.open = false
    }

    Component {
        id: infoBinauralPageComponent
        InfoBinauralPage {}
    }

    Component {
        id: infoColoredPageComponent
        InfoColoredPage {}
    }

    // Components used as the shared drawer's background panels.
    Component {
        id: ambiencePanelComponent

        AmbienceDrawer {
            width: selectorLoader.width

            activeAmbiences: page.activeAmbiences
            ambiencePlaying: page.ambiencePlaying
            pausedMode: page.pausedMode

            onCloseRequested: selectorDrawer.open = false

            onAmbienceSelected: {
                if (page.activeAmbiences.indexOf(ambience) !== -1)
                    return

                if (page.activeAmbiences.length >= 3)
                    return

                var wasPaused = page.pausedMode
                page.activeAmbiences =
                        page.activeAmbiences.concat([ambience])

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
    }

    Component {
        id: customSoundPanelComponent

        SoundPickerDrawer {
            width: selectorLoader.width
            appWindow: page.applicationWindow

            onCloseRequested: selectorDrawer.open = false
        }
    }

    Drawer {
        id: selectorDrawer

        anchors.fill: parent
        dock: Dock.Bottom

        // false = ambience panel; true = custom sound panel
        property bool showingCustomSound: false

        backgroundSize: selectorLoader.height

        background: Loader {
            id: selectorLoader

            width: parent.width

            sourceComponent: selectorDrawer.showingCustomSound
                             ? customSoundPanelComponent
                             : ambiencePanelComponent

            height: item ? item.height : 0
        }

        // KEEP your existing foregroundContent Item here, unchanged:
        // - foreground SilicaFlickable and all main-page controls
        // - PullDownMenu
        // - drawerDimmer, with opacity based on selectorDrawer.opened
        // - MouseArea, enabled when selectorDrawer.opened,
        //   closing selectorDrawer on click

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

                        enabled: page.activeBand !== "" ||
                                 page.activeAmbiences.length > 0 ||
                                 page.activeNoise !== "" ||
                                 (page.applicationWindow &&
                                  page.applicationWindow.customSoundSource.toString() !== "")

                        onClicked: {
                            page.deselectAllSounds()
                        }
                    }

                    MenuItem {
                        text: qsTr("Timer")

                        enabled: page.activeBand !== "" ||
                                 page.activeAmbiences.length > 0 ||
                                 page.activeNoise !== "" ||
                                 (page.applicationWindow &&
                                  page.applicationWindow.customSoundSource.toString() !== "")

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
                                anchors.verticalCenterOffset:
                                    Theme.paddingSmall / 3

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
                        width: parent.width -
                               2 * Theme.horizontalPageMargin
                        height: contentHeight

                        cellWidth: width / 2
                        cellHeight: Theme.itemSizeMedium

                        model: [
                            "Delta",
                            "Delta/Theta",
                            "Theta",
                            "Alpha",
                            "Beta",
                            "Gamma"
                        ]

                        delegate: Item {
                            width: frequencyGrid.cellWidth
                            height: frequencyGrid.cellHeight

                            Rectangle {
                                anchors.fill: frequencyButton
                                radius: Theme.paddingSmall

                                color: frequencyButton.highlighted
                                       ? Theme.highlightColor
                                       : "transparent"

                                opacity: frequencyButton.highlighted ? 0.15 : 0.0

                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                            }

                            Button {
                                id: frequencyButton

                                anchors.centerIn: parent

                                preferredWidth: frequencyGrid.cellWidth -
                                                Theme.paddingMedium

                                text: SoundNames.label(modelData)
                                highlighted: page.activeBand === modelData

                                color: highlighted
                                       ? (page.bandPlaying
                                          ? Theme.highlightColor
                                          : Theme.secondaryHighlightColor)
                                       : Theme.primaryColor

                                opacity: highlighted && !page.bandPlaying
                                         ? 0.6 : 1.0

                                onClicked: {
                                    if (frequencyButton.highlighted) {
                                        page.activeBand = ""
                                        audioEngine.stop()
                                    } else if (!page.pausedMode) {
                                        page.activeBand = modelData
                                        audioEngine.setFrequencyBand(modelData)
                                        audioEngine.start()
                                    } else {
                                        audioEngine.stop()
                                        page.activeBand = modelData
                                        audioEngine.setFrequencyBand(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Binaural Beats Volume slider
                    Item {
                        width: parent.width

                        height: binauralVolumeSlider.height +
                                binauralVolumeIcon.height -
                                Theme.paddingLarge

                        Slider {
                            id: binauralVolumeSlider

                            anchors.left: parent.left
                            anchors.leftMargin: Theme.horizontalPageMargin
                            anchors.right: infoBinauralsButton.left
                            anchors.rightMargin: Theme.paddingLarge

                            minimumValue: 0
                            maximumValue: 100
                            value: 50

                            enabled: page.activeBand !== ""
                            opacity: enabled ? 1.0 : 0.5

                            onValueChanged: {
                                audioEngine.setBinauralVolume(value)
                            }
                        }

                        // Uses VolumeIcon.qml component
                        VolumeIcon {
                            id: binauralVolumeIcon
                            value: binauralVolumeSlider.value
                            anchors.top: binauralVolumeSlider.bottom
                            anchors.topMargin: -Theme.paddingLarge
                            anchors.horizontalCenter: binauralVolumeSlider.horizontalCenter
                            anchors.horizontalCenterOffset: Theme.paddingSmall
                            opacity: page.activeBand !== "" ? 1.0 : 0.5
                        }

                        // Opens InfoBinauralPage
                        IconButton {
                            id: infoBinauralsButton

                            anchors.right: parent.right
                            anchors.rightMargin: Theme.horizontalPageMargin
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset:
                                Theme.paddingSmall * 1.7

                            icon.source: "image://theme/icon-m-about?" +
                                         (pressed
                                          ? Theme.highlightColor
                                          : Theme.primaryColor)

                            onClicked: {
                                pageStack.push(infoBinauralPageComponent)
                            }
                        }
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

                            Rectangle {
                                anchors.fill: coloredNoiseButton
                                radius: Theme.paddingSmall

                                color: coloredNoiseButton.highlighted
                                       ? Theme.highlightColor
                                       : "transparent"

                                opacity: coloredNoiseButton.highlighted ? 0.15 : 0.0

                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                            }

                            Button {
                                id: coloredNoiseButton

                                anchors.centerIn: parent

                                preferredWidth: coloredNoiseGrid.cellWidth -
                                                Theme.paddingMedium

                                text: SoundNames.label(modelData)
                                highlighted: page.activeNoise === modelData

                                color: highlighted
                                       ? (page.noisePlaying
                                          ? Theme.highlightColor
                                          : Theme.secondaryHighlightColor)
                                       : Theme.primaryColor

                                opacity: highlighted && !page.noisePlaying
                                         ? 0.6 : 1.0

                                onClicked: {
                                    if (coloredNoiseButton.highlighted) {
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

                    // Colored Noise Volume slider
                    Item {
                        width: parent.width

                        height: coloredNoiseVolumeSlider.height +
                                coloredNoiseVolumeIcon.height -
                                Theme.paddingLarge

                        Slider {
                            id: coloredNoiseVolumeSlider

                            anchors.left: parent.left
                            anchors.leftMargin: Theme.horizontalPageMargin
                            anchors.right: infoColoredButton.left
                            anchors.rightMargin: Theme.paddingLarge

                            minimumValue: 0
                            maximumValue: 100
                            value: 50

                            enabled: page.activeNoise !== ""
                            opacity: enabled ? 1.0 : 0.5

                            onValueChanged: {
                                audioEngine.setColoredNoiseVolume(value)
                            }
                        }

                        // Uses VolumeIcon.qml component
                        VolumeIcon {
                            id: coloredNoiseVolumeIcon
                            value: coloredNoiseVolumeSlider.value
                            anchors.top: coloredNoiseVolumeSlider.bottom
                            anchors.topMargin: -Theme.paddingLarge
                            anchors.horizontalCenter: coloredNoiseVolumeSlider.horizontalCenter
                            anchors.horizontalCenterOffset: Theme.paddingSmall
                            opacity: page.activeNoise !== "" ? 1.0 : 0.5
                        }

                        // Opens InfoColoredPage
                        IconButton {
                            id: infoColoredButton

                            anchors.right: parent.right
                            anchors.rightMargin: Theme.horizontalPageMargin
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset:
                                Theme.paddingSmall * 1.7

                            icon.source: "image://theme/icon-m-about?" +
                                         (pressed
                                          ? Theme.highlightColor
                                          : Theme.primaryColor)

                            onClicked: {
                                pageStack.push(infoColoredPageComponent)
                            }
                        }
                    }

                    // Ambient Sound Section
                    SectionHeader {
                        text: qsTr("Ambient Sound")
                    }

                    // Ambient sound button with highlighted background
                    Item {
                        width: parent.width
                        height: ambienceButton.height

                        Rectangle {
                            anchors.fill: ambienceButton
                            radius: Theme.paddingSmall

                            color: ambienceButton.highlighted
                                   ? Theme.highlightColor
                                   : "transparent"

                            opacity: ambienceButton.highlighted ? 0.15 : 0.0

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        Button {
                            id: ambienceButton

                            anchors.centerIn: parent
                            width: parent.width * 0.8

                            text: page.activeAmbiences.length === 0
                                  ? qsTr("Choose ambient sounds")
                                  : page.activeAmbiences.map(function(ambience) {
                                      return SoundNames.label(ambience)
                                  }).join(", ")

                            color: page.activeAmbiences.length > 0
                                   ? (page.ambiencePlaying
                                      ? Theme.highlightColor
                                      : Theme.secondaryHighlightColor)
                                   : Theme.primaryColor

                            opacity: page.ambiencePlaying
                                     ? 1.0
                                     : page.activeAmbiences.length > 0
                                       ? 0.6
                                       : 1.0

                            onClicked: {
                                selectorDrawer.showingCustomSound = false
                                selectorDrawer.open = true
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Theme.itemSizeMedium
                    }

                    // Custom sound picker button
                    Item {
                        width: parent.width
                        height: soundPickerButton.height

                        Rectangle {
                            anchors.fill: soundPickerButton
                            radius: Theme.paddingSmall

                            color: soundPickerButton.highlighted
                                   ? Theme.highlightColor
                                   : "transparent"

                            opacity: soundPickerButton.highlighted ? 0.15 : 0.0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        Button {
                            id: soundPickerButton
                            anchors.centerIn: parent
                            width: parent.width * 0.8

                            text: ""

                            // Disable custom sound selection when 3 ambiences are active
                            enabled: page.activeAmbiences.length < 3
                                     || (applicationWindow
                                         && applicationWindow.customSoundSource.toString() !== "")

                            highlighted: applicationWindow
                                         && applicationWindow.customSoundSource.toString() !== ""

                            opacity: !enabled ? 0.35
                                     : highlighted
                                       ? (applicationWindow.customSoundPlaying ? 1.0 : 0.6)
                                       : 1.0

                            onClicked: {
                                selectorDrawer.showingCustomSound = true
                                selectorDrawer.open = true
                            }

                            Label {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.paddingMedium
                                anchors.rightMargin: Theme.paddingMedium

                                text: applicationWindow
                                      && applicationWindow.customSoundName !== ""
                                      ? applicationWindow.customSoundName
                                      : qsTr("Choose custom sound")

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight

                                color: !soundPickerButton.enabled
                                       ? Theme.secondaryColor
                                       : soundPickerButton.highlighted
                                         ? (applicationWindow.customSoundPlaying
                                            ? Theme.highlightColor
                                            : Theme.secondaryHighlightColor)
                                         : Theme.primaryColor
                            }
                        }
                    }
                }

                // Spacing after the complete Ambient Sound section
                Item {
                    width: 1
                    height: Theme.itemSizeMedium
                }
            }

            VerticalScrollDecorator {}
        }

        // Dim the foreground while Drawers are open.
        // This rectangle moves with the foreground and does not
        // cover the exposed drawer background.
        Rectangle {
            id: drawerDimmer

            anchors.fill: parent
            z: 1

            color: Theme.overlayBackgroundColor
            opacity: selectorDrawer.opened ? 0.6 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        // Intercept taps on the visible foreground while open.
        // Taps close the drawer instead of activating page buttons.
        MouseArea {
            anchors.fill: parent
            z: 2
            enabled: selectorDrawer.opened

            onClicked: {
                selectorDrawer.open = false
            }
        }
    }
}
