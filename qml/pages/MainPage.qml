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

    // effects on timer when activeBand is changed
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
            audioEngine.stop()
            audioEngine.stopAmbience()
            audioEngine.stopColoredNoise()
        } else {
            resumeAll()
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

    // Drawer to open Ambience sounds which opens above playbackBar.
    Drawer {
        id: ambienceDrawer

        anchors.fill: parent

        dock: Dock.Bottom
        z: 2

        backgroundSize: ambienceBackground.height

        background: SilicaFlickable {
            id: ambienceBackground

            width: parent.width
            height: ambienceColumn.height + 2 * Theme.paddingLarge
            contentHeight: ambienceColumn.height + 2 * Theme.paddingLarge
            contentWidth: width

            Rectangle {
                anchors.fill: parent

                color: Theme.rgba(
                    Theme.highlightBackgroundColor,
                    Theme.highlightBackgroundOpacity * 0.35
                )
            }

            // Swipe down action to close ambienceDrawer.
            MouseArea {
                id: drawerSwipeArea

                anchors.fill: parent
                z: -1

                property real startY: 0

                onPressed: {
                    startY = mouse.y
                }

                onReleased: {
                    var deltaY = mouse.y - startY

                    if (deltaY > Theme.itemSizeSmall) {
                        ambienceDrawer.open = false
                    }
                }
            }

            Column {
                id: ambienceColumn

                width: parent.width
                spacing: Theme.paddingMedium

                Item {
                    width: 1
                    height: Theme.paddingLarge
                }

                // Ambience selection grid.
                SilicaGridView {
                    id: ambienceDrawerGrid

                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    height: Math.ceil(model.length / 2) *
                            Theme.itemSizeMedium
                    cellWidth: width / 2
                    cellHeight: Theme.itemSizeMedium

                    model: ["Wind", "Waves", "Crickets", "Stream",
                            "Rain", "Birds", "Fire", "Chimes"]

                    delegate: Item {
                        width: ambienceDrawerGrid.cellWidth
                        height: ambienceDrawerGrid.cellHeight

                        Rectangle {
                            anchors.fill: ambienceDrawerButton
                            anchors.margins: -Theme.paddingSmall
                            radius: Theme.paddingSmall

                            color: ambienceDrawerButton.highlighted
                                   ? Theme.highlightColor
                                   : "transparent"

                            opacity: ambienceDrawerButton.highlighted
                                     ? 0.15
                                     : 0.0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        Button {
                            id: ambienceDrawerButton

                            anchors.centerIn: parent

                            preferredWidth: ambienceDrawerGrid.cellWidth -
                                            Theme.paddingMedium

                            text: SoundNames.label(modelData)
                            highlighted: page.activeAmbience === modelData

                            // Visual hint when nothing is playing.
                            opacity: highlighted && !page.ambiencePlaying
                                      ? 0.6 : 1.0

                            onClicked: {
                                if (ambienceDrawerButton.highlighted) {
                                    // Deselect.
                                    page.activeAmbience = ""
                                    audioEngine.stopAmbience()
                                } else if (!page.pausedMode) {
                                    // Playing, or no selection at all
                                    // (fresh start): switch immediately.
                                    page.activeAmbience = modelData
                                    audioEngine.setAmbience(modelData)
                                } else {
                                    // Paused mode: selection only.
                                    audioEngine.stopAmbience()
                                    page.activeAmbience = modelData
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                text: parent.text
                                color: ambienceDrawerButton.highlighted
                                       ? (page.ambiencePlaying
                                          ? Theme.highlightColor
                                          : Theme.secondaryHighlightColor)
                                       : Theme.primaryColor
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: ambienceVolumeSlider.height

                    Slider {
                        id: ambienceVolumeSlider

                        width: parent.width * 0.9
                        anchors.horizontalCenter: parent.horizontalCenter

                        minimumValue: 0
                        maximumValue: 100
                        value: 50

                        enabled: page.activeAmbience !== ""
                        opacity: enabled ? 1.0 : 0.5

                        onValueChanged: {
                            audioEngine.setAmbienceVolume(value)
                        }
                    }

                    Item {
                        id: ambienceVolumeIcon

                        width: Theme.iconSizeSmall * 1.6
                        height: Theme.iconSizeSmall * 1.6

                        anchors.top: ambienceVolumeSlider.bottom
                        // moves icon closer to volume slider
                        anchors.topMargin: -Theme.paddingLarge
                        anchors.horizontalCenter: ambienceVolumeSlider.horizontalCenter

                        opacity: page.activeAmbience !== "" ? 1.0 : 0.5

                        Image {
                            id: ambienceVolumeImage

                            anchors.fill: parent

                            source: ambienceVolumeSlider.value === 0
                                    ? "../images/icon-s-volume-1.svg"
                                    : ambienceVolumeSlider.value <= 33
                                      ? "../images/icon-s-volume-2.svg"
                                      : ambienceVolumeSlider.value <= 66
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
                            anchors.fill: ambienceVolumeImage

                            source: ambienceVolumeImage
                            color: Theme.primaryColor
                        }
                    }
                }
            }

            VerticalScrollDecorator {}
        }

        Item {
            id: foregroundContent

            anchors.fill: parent

            SilicaFlickable {
                id: foregroundPage

                anchors.fill: parent

                contentHeight: column.height +
                               Theme.paddingLarge

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

                    // Binaural frequency selection grid.
                    SectionHeader {
                        text: qsTr("Binaural Beats")
                    }

                    // Info text about headphones with image.
                    Item {
                        width: parent.width - 2 * Theme.horizontalPageMargin
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

                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: Theme.paddingSmall / 3
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
                                         ? 0.15
                                         : 0.0

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

                                // Visual hint when nothing is playing.
                                opacity: highlighted && !page.bandPlaying
                                          ? 0.6 : 1.0

                                onClicked: {
                                    if (frequencyButton.highlighted) {
                                        // Deselect.
                                        page.activeBand = ""
                                        audioEngine.stop()
                                    } else if (!page.pausedMode) {
                                        // Playing, or no selection at all
                                        // (fresh start): start immediately.
                                        page.activeBand = modelData
                                        audioEngine.setFrequencyBand(
                                            modelData
                                        )
                                        audioEngine.start()
                                    } else {
                                        // Paused mode: selection only.
                                        audioEngine.stop()
                                        page.activeBand = modelData
                                        audioEngine.setFrequencyBand(
                                            modelData
                                        )
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
                            // Moves icon closer to volume slider.
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
                                pageStack.push(
                                    infoBinauralPageComponent
                                )
                            }
                        }
                    }

                    // Colored Noise selection grid.
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
                                         ? 0.15
                                         : 0.0

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

                                // Visual hint when nothing is playing.
                                opacity: highlighted && !page.noisePlaying
                                          ? 0.6 : 1.0

                                onClicked: {
                                    if (coloredNoiseButton.highlighted) {
                                        // Deselect.
                                        page.activeNoise = ""
                                        audioEngine.stopColoredNoise()
                                    } else if (!page.pausedMode) {
                                        // Playing, or no selection at all
                                        // (fresh start): start immediately.
                                        page.activeNoise = modelData
                                        audioEngine.setColoredNoise(modelData)
                                    } else {
                                        // Paused mode: selection only.
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
                            // Moves icon closer to volume slider.
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
                                pageStack.push(
                                    infoColoredPageComponent
                                )
                            }
                        }
                    }

                    // Ambience selection with button that opens drawer.
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
                                     ? 0.15
                                     : 0.0

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
                                  : SoundNames.label(
                                        page.activeAmbience
                                    )

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
