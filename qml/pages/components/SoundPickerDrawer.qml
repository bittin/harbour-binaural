import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Qt.labs.folderlistmodel 2.1
import ".."

SilicaFlickable {
    id: page

    property var appWindow: null

    property url selectedFile: ""
    property string selectedFileName: ""

    property url selectedFolder: ""
    property string selectedFolderName: ""

    property bool loopFolder: false
    property bool startFolderWhenReady: false

    property int previousFolderCount: -1
    property int stableFolderCountTicks: 0
    property int folderWaitTicks: 0

    signal closeRequested()

    width: parent ? parent.width : Screen.width
    height: Math.min(contentColumn.height + Theme.paddingLarge,
                     Screen.height * 0.8)

    contentHeight: contentColumn.height + Theme.paddingLarge
    clip: true

    Component.onCompleted: {
        if (appWindow && appWindow.customSoundSource) {
            selectedFile = appWindow.customSoundSource
            selectedFileName = appWindow.customSoundName
                    ? appWindow.customSoundName : ""
        }
    }

    function openAudioPicker() {
        pageStack.push(customAudioPicker)
    }

    function startFolderPlayback() {
        if (!appWindow || selectedFolder.toString() === "") {
            console.log("Folder playback: no appWindow or folder selected")
            return
        }

        folderPlaylistTimer.stop()

        startFolderWhenReady = true
        previousFolderCount = -1
        stableFolderCountTicks = 0
        folderWaitTicks = 0

        folderPlaylistModel.folder = selectedFolder
        folderPlaylistTimer.start()
    }

    function buildFolderPlaylist() {
        if (!startFolderWhenReady)
            return

        startFolderWhenReady = false
        folderPlaylistTimer.stop()

        var files = []

        for (var i = 0; i < folderPlaylistModel.count; ++i) {
            var fileUrl = folderPlaylistModel.get(i, "fileURL")
            var fileName = folderPlaylistModel.get(i, "fileName")

            if (fileUrl && fileName) {
                files.push({
                    "url": fileUrl,
                    "name": fileName
                })
            }
        }

        if (files.length === 0) {
            console.log("Folder playback: no supported audio files found in",
                        selectedFolder.toString())
            return
        }

        if (!appWindow || !appWindow.startCustomSoundPlaylist) {
            console.log("Folder playback: startCustomSoundPlaylist unavailable")
            return
        }

        console.log("Folder playback: starting playlist with",
                    files.length, "tracks")

        appWindow.startCustomSoundPlaylist(files, loopFolder)

        selectedFile = files[0].url
        selectedFileName = files[0].name
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.rgba(
                   Theme.highlightBackgroundColor,
                   Theme.highlightBackgroundOpacity * 0.35)
    }

    Column {
        id: contentColumn

        width: parent.width
        spacing: Theme.paddingMedium

        // Drawer handle: tap or swipe down to close.
        Item {
            width: parent.width
            height: Theme.itemSizeExtraSmall

            Rectangle {
                anchors.centerIn: parent
                width: Theme.itemSizeExtraSmall * 2
                height: Theme.paddingSmall
                radius: Theme.paddingSmall

                color: handleMouseArea.pressed
                       ? Theme.secondaryHighlightColor
                       : Theme.secondaryColor

                opacity: 0.6
            }

            MouseArea {
                id: handleMouseArea

                anchors.fill: parent

                property real startY: 0
                property real startX: 0

                onPressed: {
                    startY = mouse.y
                    startX = mouse.x
                }

                onClicked: page.closeRequested()

                onReleased: {
                    var deltaY = mouse.y - startY
                    var deltaX = mouse.x - startX

                    if (deltaY > Theme.itemSizeSmall
                            && Math.abs(deltaY) > Math.abs(deltaX)) {
                        page.closeRequested()
                    }
                }
            }
        }

        // Playback controls.
        Item {
            id: playbackControlsContainer

            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            height: playbackButtons.height + 2 * Theme.paddingMedium

            property real playbackIconSize: Theme.iconSizeMedium

            Row {
                id: playbackButtons

                anchors.centerIn: parent
                spacing: Theme.paddingLarge

                property real normalButtonSize:
                    playbackControlsContainer.playbackIconSize

                property real playButtonSize:
                    normalButtonSize * 1.5

                property bool hasAudio:
                    page.appWindow !== null
                    && (page.selectedFile.toString() !== ""
                        || page.appWindow.customSoundPlaylistActive)

                property bool isPlaying:
                    page.appWindow !== null
                    && page.appWindow.customSoundPlaying
                    && !page.appWindow.customSoundPaused

                property bool hasPlaylist:
                    page.appWindow !== null
                    && page.appWindow.customSoundPlaylistActive

                // Previous track.
                Item {
                    width: playbackButtons.playButtonSize
                    height: playbackButtons.playButtonSize

                    IconButton {
                        anchors.centerIn: parent

                        width: playbackButtons.normalButtonSize
                        height: playbackButtons.normalButtonSize

                        icon.source: "image://theme/icon-m-previous?"
                                     + (pressed
                                        ? Theme.highlightColor
                                        : (playbackButtons.hasPlaylist
                                           ? Theme.primaryColor
                                           : Theme.secondaryColor))

                        enabled: playbackButtons.hasPlaylist

                        onClicked: {
                            if (enabled && page.appWindow) {
                                page.appWindow.playPreviousCustomSound()
                            }
                        }
                    }
                }

                // Play / Pause.
                Item {
                    width: playbackButtons.playButtonSize
                    height: playbackButtons.playButtonSize

                    Icon {
                        anchors.centerIn: parent

                        width: playbackButtons.playButtonSize
                        height: playbackButtons.playButtonSize

                        source: "image://theme/"
                                + (playbackButtons.isPlaying
                                   ? "icon-m-pause?"
                                   : "icon-m-play?")
                                + (playPauseMouseArea.pressed
                                   ? Theme.highlightColor
                                   : (playbackButtons.hasAudio
                                      ? Theme.primaryColor
                                      : Theme.secondaryColor))
                    }

                    MouseArea {
                        id: playPauseMouseArea

                        anchors.fill: parent
                        enabled: playbackButtons.hasAudio

                        onClicked: {
                            if (!page.appWindow)
                                return

                            if (page.appWindow.customSoundPlaying
                                    && !page.appWindow.customSoundPaused) {
                                page.appWindow.pauseCustomSound()
                            } else if (page.appWindow.customSoundPaused
                                       || page.appWindow.customSoundPlaylistActive) {
                                page.appWindow.resumeCustomSound()
                            } else if (page.selectedFile.toString() !== "") {
                                page.appWindow.customSoundSource =
                                        page.selectedFile
                                page.appWindow.customSoundName =
                                        page.selectedFileName
                                page.appWindow.playCustomSound()
                            }
                        }
                    }
                }

                // Next track.
                Item {
                    width: playbackButtons.playButtonSize
                    height: playbackButtons.playButtonSize

                    IconButton {
                        anchors.centerIn: parent

                        width: playbackButtons.normalButtonSize
                        height: playbackButtons.normalButtonSize

                        icon.source: "image://theme/icon-m-next?"
                                     + (pressed
                                        ? Theme.highlightColor
                                        : (playbackButtons.hasPlaylist
                                           ? Theme.primaryColor
                                           : Theme.secondaryColor))

                        enabled: playbackButtons.hasPlaylist

                        onClicked: {
                            if (enabled && page.appWindow) {
                                page.appWindow.playNextCustomSound()
                            }
                        }
                    }
                }
            }
        }

        Button {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin

            text: qsTr("Open audio file or folder")

            onClicked: page.openAudioPicker()
        }

        // Selected folder and current track information.
        Item {
            id: trackInfoContainer

            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin

            property bool showTrackInfo:
                selectedFolderName !== ""
                && appWindow !== null
                && appWindow.customSoundPlaylistActive

            property real expandedHeight:
                folderNameLabel.implicitHeight
                + Theme.paddingSmall
                + (showTrackInfo
                   ? trackNameLabel.implicitHeight + Theme.paddingSmall
                   : 0)

            height: expandedHeight

            Behavior on height {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Label {
                id: folderNameLabel

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                text: selectedFolderName !== ""
                      ? selectedFolderName
                      : (selectedFileName !== ""
                         ? selectedFileName
                         : qsTr("No file selected"))

                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
            }

            Label {
                id: trackNameLabel

                anchors {
                    top: folderNameLabel.bottom
                    topMargin: Theme.paddingSmall
                    left: parent.left
                    right: parent.right
                }

                visible: trackInfoContainer.showTrackInfo

                text: page.appWindow
                      ? page.appWindow.customSoundName : ""

                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        // Volume slider + volume icon + Repeat switch
        // Volume and repeat controls in one responsive row
        Row {
            id: customSoundControls

            width: parent.width - 2 * Theme.horizontalPageMargin
            x: Theme.horizontalPageMargin
            spacing: 0

            // Volume slider and original icon
            Item {
                id: customSoundVolumeContainer

                y: Theme.paddingSmall  // Moves slider and icon down slightly

                width: parent.width - loopButton.width
                       - customSoundControls.spacing
                height: customSoundVolumeSlider.height
                        + customSoundVolumeIcon.height
                        - Theme.paddingLarge

                Slider {
                    id: customSoundVolumeSlider

                    anchors.left: parent.left
                    anchors.right: parent.right

                    minimumValue: 0
                    maximumValue: 100
                    value: appWindow ? appWindow.customSoundVolume : 50

                    onValueChanged: {
                        if (appWindow &&
                                appWindow.customSoundVolume !== value) {
                            appWindow.customSoundVolume = value
                        }
                    }
                }

                // Original volume icon: size, placement and appearance preserved
                Item {
                    id: customSoundVolumeIcon

                    width: Theme.iconSizeSmall * 1.6
                    height: Theme.iconSizeSmall * 1.6

                    anchors.top: customSoundVolumeSlider.bottom
                    anchors.topMargin: -Theme.paddingLarge
                    anchors.horizontalCenter: customSoundVolumeSlider.horizontalCenter

                    Image {
                        id: customSoundVolumeImage

                        anchors.fill: parent

                        source: customSoundVolumeSlider.value === 0
                                ? "../../images/icon-s-volume-1.svg"
                                : customSoundVolumeSlider.value <= 33
                                  ? "../../images/icon-s-volume-2.svg"
                                  : customSoundVolumeSlider.value <= 66
                                    ? "../../images/icon-s-volume-3.svg"
                                    : "../../images/icon-s-volume-4.svg"

                        sourceSize: Qt.size(
                                        Theme.iconSizeSmall * 1.6 * 2,
                                        Theme.iconSizeSmall * 1.6 * 2
                                        )

                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: customSoundVolumeImage
                        source: customSoundVolumeImage
                        color: Theme.primaryColor
                    }
                }
            }

            // Repeat toggle
            Switch {
                id: loopButton

                x: -Theme.paddingSmall

                anchors.verticalCenter: customSoundVolumeContainer.verticalCenter

                icon.source: "image://theme/icon-m-repeat"
                automaticCheck: false
                checked: appWindow ? appWindow.customSoundLoop : false

                onClicked: {
                    if (appWindow) {
                        appWindow.customSoundLoop =
                                !appWindow.customSoundLoop
                    }
                }
            }
        }

    }

    // File picker remains a separate navigation page.
    AudioFilePickerPage {
        id: customAudioPicker

        selectionMode: "file"

        onFileSelected: {
            page.selectedFile = fileUrl
            page.selectedFileName = fileName

            page.selectedFolder = ""
            page.selectedFolderName = ""

            page.startFolderWhenReady = false
            folderPlaylistTimer.stop()

            if (page.appWindow) {
                page.appWindow.stopCustomSound()
                page.appWindow.customSoundSource = fileUrl
                page.appWindow.customSoundName = fileName
                page.appWindow.playCustomSound()
            }
        }

        onFolderSelected: {
            page.selectedFolder = folderUrl
            page.selectedFolderName = folderName

            page.selectedFile = ""
            page.selectedFileName = ""

            page.startFolderPlayback()
        }
    }

    Timer {
        id: folderPlaylistTimer

        interval: 200
        repeat: true

        onTriggered: {
            if (!page.startFolderWhenReady) {
                stop()
                return
            }

            page.folderWaitTicks++

            var currentCount = folderPlaylistModel.count

            if (currentCount === page.previousFolderCount) {
                page.stableFolderCountTicks++
            } else {
                page.previousFolderCount = currentCount
                page.stableFolderCountTicks = 0
            }

            // Wait for the model to populate and stabilize.
            if (page.folderWaitTicks >= 5
                    && page.stableFolderCountTicks >= 3) {
                stop()
                page.buildFolderPlaylist()
            }

            // Avoid waiting forever if the folder cannot be read.
            if (page.folderWaitTicks >= 50) {
                stop()
                page.buildFolderPlaylist()
            }
        }
    }

    FolderListModel {
        id: folderPlaylistModel

        folder: page.selectedFolder

        showDirs: false
        showFiles: true
        showHidden: false
        showOnlyReadable: true

        sortField: FolderListModel.Name

        nameFilters: [
            "*.mp3", "*.MP3",
            "*.wav", "*.WAV",
            "*.ogg", "*.OGG",
            "*.oga", "*.OGA",
            "*.flac", "*.FLAC",
            "*.m4a", "*.M4A",
            "*.aac", "*.AAC",
            "*.opus", "*.OPUS",
            "*.wma", "*.WMA",
            "*.aif", "*.AIF",
            "*.aiff", "*.AIFF",
            "*.m4b", "*.M4B",
            "*.3gp", "*.3GP"
        ]
    }

    VerticalScrollDecorator {}
}
