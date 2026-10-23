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
    property string activeAmbience: activeAmbiences.length > 0
                                    ? activeAmbiences[0] : ""

    property string ambienceDisplayName: {
        if (activeAmbiences.length === 0)
            return ""

        if (activeAmbiences.length === 1)
            return SoundNames.label(activeAmbiences[0])

        return SoundNames.label("Ambient mix")
    }

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
    onActiveAmbienceChanged: checkSleepTimer()
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
        if (isPlaying) {
            audioEngine.pauseBinaural()
            audioEngine.pauseAmbience()
            audioEngine.pauseColoredNoise()
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

        page.activeBand = ""
        page.activeAmbiences = []
        page.activeNoise = ""

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
                                 page.activeNoise !== ""

                        onClicked: {
                            page.deselectAllSounds()
                        }
                    }

                    MenuItem {
                        text: qsTr("Timer")

                        enabled: page.activeBand !== "" ||
                                 page.activeAmbiences.length > 0 ||
                                 page.activeNoise !== ""

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

                    Item {
                        width: 1
                        height: Theme.paddingLarge
                    }

                    // Binaural Beats
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
                                anchors.margins: -Theme.paddingSmall
                                radius: Theme.paddingSmall

                                color: frequencyButton.highlighted
                                       ? Theme.highlightColor
                                       : "transparent"

                                opacity: frequencyButton.highlighted
                                         ? 0.15 : 0.0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            Button {
                                id: frequencyButton

                                anchors.centerIn: parent

                                preferredWidth: frequencyGrid.cellWidth -
                                                Theme.paddingMedium

                                text: SoundNames.label(modelData)
                                highlighted: page.activeBand === modelData

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

                                Label {
                                    anchors.centerIn: parent
                                    text: parent.text

                                    color: frequencyButton.highlighted
                                           ? (page.bandPlaying
                                              ? Theme.highlightColor
                                              : Theme.secondaryHighlightColor)
                                           : Theme.primaryColor
                                }
                            }
                        }
                    }

                    // Binaural volume
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

                        Item {
                            id: binauralVolumeIcon

                            width: Theme.iconSizeSmall * 1.6
                            height: Theme.iconSizeSmall * 1.6

                            anchors.top: binauralVolumeSlider.bottom
                            anchors.topMargin: -Theme.paddingLarge
                            anchors.horizontalCenter:
                                binauralVolumeSlider.horizontalCenter
                            anchors.horizontalCenterOffset:
                                Theme.paddingSmall

                            opacity: page.activeBand !== "" ? 1.0 : 0.5

                            Image {
                                id: binauralVolumeImage

                                anchors.fill: parent

                                source: binauralVolumeSlider.value === 0
                                        ? "../images/icon-s-volume-1.svg"
                                        : binauralVolumeSlider.value <= 33
                                          ? "../images/icon-s-volume-2.svg"
                                          : binauralVolumeSlider.value <= 66
                                            ? "../images/icon-s-volume-3.svg"
                                            : "../images/icon-s-volume-4.svg"

                                sourceSize: Qt.size(
                                    Theme.iconSizeSmall * 1.6 * 2,
                                    Theme.iconSizeSmall * 1.6 * 2
                                )

                                fillMode: Image.PreserveAspectFit
                                visible: false
                            }

                            ColorOverlay {
                                anchors.fill: binauralVolumeImage
                                source: binauralVolumeImage
                                color: Theme.primaryColor
                            }
                        }

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

                    // Colored Noise
                    SectionHeader {
                        text: qsTr("Colored Noise")
                    }

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
                                anchors.margins: -Theme.paddingSmall
                                radius: Theme.paddingSmall

                                color: coloredNoiseButton.highlighted
                                       ? Theme.highlightColor
                                       : "transparent"

                                opacity: coloredNoiseButton.highlighted
                                         ? 0.15 : 0.0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            Button {
                                id: coloredNoiseButton

                                anchors.centerIn: parent

                                preferredWidth: coloredNoiseGrid.cellWidth -
                                                Theme.paddingMedium

                                text: SoundNames.label(modelData)
                                highlighted: page.activeNoise === modelData

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

                                Label {
                                    anchors.centerIn: parent
                                    text: parent.text

                                    color: coloredNoiseButton.highlighted
                                           ? (page.noisePlaying
                                              ? Theme.highlightColor
                                              : Theme.secondaryHighlightColor)
                                           : Theme.primaryColor
                                }
                            }
                        }
                    }

                    // Colored noise volume
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

                        Item {
                            id: coloredNoiseVolumeIcon

                            width: Theme.iconSizeSmall * 1.6
                            height: Theme.iconSizeSmall * 1.6

                            anchors.top: coloredNoiseVolumeSlider.bottom
                            anchors.topMargin: -Theme.paddingLarge
                            anchors.horizontalCenter:
                                coloredNoiseVolumeSlider.horizontalCenter
                            anchors.horizontalCenterOffset:
                                Theme.paddingSmall

                            opacity: page.activeNoise !== "" ? 1.0 : 0.5

                            Image {
                                id: coloredNoiseVolumeImage

                                anchors.fill: parent

                                source: coloredNoiseVolumeSlider.value === 0
                                        ? "../images/icon-s-volume-1.svg"
                                        : coloredNoiseVolumeSlider.value <= 33
                                          ? "../images/icon-s-volume-2.svg"
                                          : coloredNoiseVolumeSlider.value <= 66
                                            ? "../images/icon-s-volume-3.svg"
                                            : "../images/icon-s-volume-4.svg"

                                sourceSize: Qt.size(
                                    Theme.iconSizeSmall * 1.6 * 2,
                                    Theme.iconSizeSmall * 1.6 * 2
                                )

                                fillMode: Image.PreserveAspectFit
                                visible: false
                            }

                            ColorOverlay {
                                anchors.fill: coloredNoiseVolumeImage
                                source: coloredNoiseVolumeImage
                                color: Theme.primaryColor
                            }
                        }

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

                    // Ambient Sound
                    SectionHeader {
                        text: qsTr("Ambient Sound")
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.paddingMedium

                        // Ambient sound button with highlighted background
                        Item {
                            width: parent.width
                            height: ambienceButton.height

                            Rectangle {
                                anchors.fill: ambienceButton
                                anchors.margins: -Theme.paddingSmall
                                radius: Theme.paddingSmall

                                color: ambienceButton.highlighted
                                       ? Theme.highlightColor
                                       : "transparent"

                                opacity: ambienceButton.highlighted ? 0.15 : 0.0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            Button {
                                id: ambienceButton

                                anchors.centerIn: parent
                                width: parent.width * 0.8

                                text: page.activeAmbiences.length === 0
                                      ? qsTr("Choose an ambient sound")
                                      : page.activeAmbiences.map(function(ambience) {
                                          return SoundNames.label(ambience)
                                      }).join(", ")

                                highlighted: page.activeAmbiences.length > 0

                                opacity: page.ambiencePlaying
                                         ? 1.0
                                         : page.activeAmbiences.length > 0
                                           ? 0.6
                                           : 1.0

                                onClicked: {
                                    selectorDrawer.showingCustomSound = false
                                    selectorDrawer.open = true
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: parent.text

                                    color: ambienceButton.highlighted
                                           ? (page.ambiencePlaying
                                              ? Theme.highlightColor
                                              : Theme.secondaryHighlightColor)
                                           : Theme.primaryColor
                                }
                            }
                        }

                        Item {
                            width: 1
                            height: Theme.paddingSmall * 0.8
                        }

                        // Custom sound picker button
                        Item {
                            width: parent.width
                            height: soundPickerButton.height

                            Button {
                                id: soundPickerButton

                                anchors.centerIn: parent
                                width: parent.width * 0.8

                                text: qsTr("Choose custom sound")

                                onClicked: {
                                    selectorDrawer.showingCustomSound = true
                                    selectorDrawer.open = true
                                }

                                Label {
                                    anchors.centerIn: parent
                                    text: parent.text

                                    color: soundPickerButton.highlighted
                                           ? Theme.highlightColor
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

            // Dim the foreground while the drawer is open.
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
}
