import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Binaural 1.0
import "components"

Page {
    id: page

    property string activeBand: ""
    property string activeAmbience: ""
    property string activeNoise: ""

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
                              (activeBand !== "" ||
                               activeAmbience !== "" ||
                               activeNoise !== "")

    AudioEngine {
        id: audioEngine
    }

    onIsPlayingChanged: {
        appWindow.isPlaying = isPlaying
    }

    onActiveBandChanged: {
        checkSleepTimer()
    }

    onActiveAmbienceChanged: {
        checkSleepTimer()
    }

    onActiveNoiseChanged: {
        checkSleepTimer()
    }

    function checkSleepTimer() {
        if (appWindow.sleepTimerRunning &&
            page.activeBand === "" &&
            page.activeAmbience === "" &&
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

        if (activeAmbience !== "") {
            if (audioEngine.ambiencePaused) {
                audioEngine.resumeAmbience()
            } else if (!audioEngine.ambiencePlaying) {
                audioEngine.setAmbience(activeAmbience)
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
        page.activeAmbience = ""
        page.activeNoise = ""

        ambienceDrawer.open = false
    }

    Component {
        id: infoBinauralPageComponent
        InfoBinauralPage { }
    }

    Component {
        id: infoColoredPageComponent
        InfoColoredPage { }
    }

    // Drawer for ambient sounds.
    Drawer {
        id: ambienceDrawer

        anchors.fill: parent
        dock: Dock.Bottom
        z: 2

        // Uses extracted ambience component AmbienceDrawer
        backgroundSize: ambienceSelector.height

        background: AmbienceDrawer {
            id: ambienceSelector

            activeAmbience: page.activeAmbience
            ambiencePlaying: page.ambiencePlaying
            pausedMode: page.pausedMode

            onCloseRequested: {
                ambienceDrawer.open = false
            }

            onAmbienceSelected: {
                if (!page.pausedMode) {
                    page.activeAmbience = ambience
                    audioEngine.setAmbience(ambience)
                } else {
                    audioEngine.stopAmbience()
                    page.activeAmbience = ambience
                }
            }

            onAmbienceDeselected: {
                page.activeAmbience = ""
                audioEngine.stopAmbience()
            }

            onAmbienceVolumeChanged: {
                audioEngine.setAmbienceVolume(volume)
            }
        }

        // Main page content remains here.
        Item {
            id: foregroundContent

            anchors.fill: parent

            SilicaFlickable {
                id: foregroundPage

                anchors.fill: parent

                contentHeight: column.height + Theme.paddingLarge

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
                                 page.activeAmbience !== "" ||
                                 page.activeNoise !== ""

                        onClicked: {
                            page.deselectAllSounds()
                        }
                    }

                    MenuItem {
                        text: qsTr("Timer")

                        enabled: page.activeBand !== "" ||
                                 page.activeAmbience !== "" ||
                                 page.activeNoise !== ""

                        onClicked: {
                            pageStack.push(
                                Qt.resolvedUrl("TimerPage.qml"),
                                {
                                    appWindow: appWindow
                                }
                            )
                        }
                    }
                }

                MouseArea {
                    id: closeDrawerOnBackgroundTap

                    anchors.fill: parent
                    z: -1

                    onClicked: {
                        if (ambienceDrawer.opened) {
                            ambienceDrawer.open = false
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

                    // Binaural frequency selection.
                    SectionHeader {
                        text: qsTr("Binaural Beats")
                    }

                    // Headphone information.
                    Item {
                        width: parent.width -
                               2 * Theme.horizontalPageMargin

                        x: Theme.horizontalPageMargin
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
                                anchors.verticalCenterOffset: Theme.paddingSmall / 3

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

                    // Binaural volume slider and information button.
                    Item {
                        width: parent.width
                        height: binauralVolumeSlider.height

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
                            anchors.horizontalCenter: binauralVolumeSlider.horizontalCenter
                            anchors.horizontalCenterOffset: Theme.paddingSmall

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
                            anchors.verticalCenterOffset: Theme.paddingSmall * 1.7

                            icon.source: "image://theme/icon-m-about?" +
                                         (pressed
                                          ? Theme.highlightColor
                                          : Theme.primaryColor)

                            onClicked: {
                                pageStack.push(infoBinauralPageComponent)
                            }
                        }
                    }

                    // Colored noise selection.
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

                    // Colored noise volume slider and information button.
                    Item {
                        width: parent.width
                        height: coloredNoiseVolumeSlider.height

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
                            anchors.horizontalCenter: coloredNoiseVolumeSlider.horizontalCenter
                            anchors.horizontalCenterOffset: Theme.paddingSmall

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
                            anchors.verticalCenterOffset: Theme.paddingSmall * 1.7

                            icon.source: "image://theme/icon-m-about?" +
                                         (pressed
                                          ? Theme.highlightColor
                                          : Theme.primaryColor)

                            onClicked: {
                                pageStack.push(infoColoredPageComponent)
                            }
                        }
                    }

                    // Ambient sound button opens the drawer.
                    SectionHeader {
                        text: qsTr("Ambient Sound")
                    }

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

                            opacity: ambienceButton.highlighted
                                     ? 0.15 : 0.0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        Button {
                            id: ambienceButton

                            anchors.centerIn: parent
                            preferredWidth: Theme.buttonWidthMedium

                            text: page.activeAmbience === ""
                                  ? qsTr("Choose an ambient sound")
                                  : SoundNames.label(page.activeAmbience)

                            highlighted: page.activeAmbience !== ""

                            opacity: page.ambiencePlaying ? 1.0
                                     : page.activeAmbience !== "" ? 0.6
                                     : 1.0

                            onClicked: {
                                ambienceDrawer.open = true
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
                        height: Theme.itemSizeMedium
                    }
                }

                VerticalScrollDecorator {}
            }

            Rectangle {
                id: drawerDimmer

                anchors.fill: foregroundContent
                z: 1

                color: Theme.overlayBackgroundColor
                opacity: ambienceDrawer.opened ? 0.6 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: ambienceDrawer.opened

                    onClicked: {
                        ambienceDrawer.open = false
                    }
                }
            }
        }
    }
}
