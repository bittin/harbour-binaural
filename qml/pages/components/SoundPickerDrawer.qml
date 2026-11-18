import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import Qt.labs.folderlistmodel 2.1

ActionDrawer {
    id: page

    property var audioEngine: null
    property bool pausedMode: false

    property url selectedFile: ""
    property string selectedFileName: ""

    property url selectedFolder: ""
    property string selectedFolderName: ""

    property bool loopFolder: false
    property bool startFolderWhenReady: false

    property int previousFolderCount: -1
    property int stableFolderCountTicks: 0
    property int folderWaitTicks: 0

    Component.onCompleted: {
        if (!audioEngine)
            return

        if (audioEngine.customSoundPlaylistActive && selectedFile.toString() === "") {
            // Nothing to restore, but keep the label consistent
            return
        }

        if (audioEngine.customSoundSource) {
            selectedFile = audioEngine.customSoundSource
            selectedFileName = audioEngine.customSoundName
                    ? audioEngine.customSoundName : ""
        }
    }

    // Open the picker as a separate PageStack entry.
    function openAudioPicker() {
        var dialog = pageStack.push(
                    Qt.resolvedUrl("../AudioFilePickerPage.qml"),
                    { "selectionMode": "file" })

        dialog.fileSelected.connect(function(fileUrl, fileName) {
            page.handleFileSelected(fileUrl, fileName)
        })

        dialog.folderSelected.connect(function(folderUrl, folderName) {
            page.handleFolderSelected(folderUrl, folderName)
        })
    }

    function handleFileSelected(fileUrl, fileName) {
        selectedFile = fileUrl
        selectedFileName = fileName.replace(/\.[^.]+$/, "")

        selectedFolder = ""
        selectedFolderName = ""

        startFolderWhenReady = false
        folderPlaylistTimer.stop()

        if (audioEngine) {
            audioEngine.stopCustomSound()
            audioEngine.customSoundSource = fileUrl
            audioEngine.customSoundName = selectedFileName

            if (!page.pausedMode)
                audioEngine.playCustomSound()
        }
    }

    function handleFolderSelected(folderUrl, folderName) {
        selectedFolder = folderUrl
        selectedFolderName = folderName

        selectedFile = ""
        selectedFileName = ""

        if (audioEngine)
            loopFolder = audioEngine.customSoundLoop

        startFolderPlayback()
    }

    function clearSelection() {
        folderPlaylistTimer.stop()
        startFolderWhenReady = false

        selectedFile = ""
        selectedFileName = ""
        selectedFolder = ""
        selectedFolderName = ""

        previousFolderCount = -1
        stableFolderCountTicks = 0
        folderWaitTicks = 0
        loopFolder = false

        if (audioEngine) {
            audioEngine.stopCustomSound()
            audioEngine.customSoundSource = ""
            audioEngine.customSoundName = ""
            audioEngine.customSoundLoop = false
        }
    }

    function startFolderPlayback() {
        if (!audioEngine || selectedFolder.toString() === "") {
            console.log("Folder playback: no audioEngine or folder selected")
            return
        }

        folderPlaylistTimer.stop()

        startFolderWhenReady = true
        previousFolderCount = -1
        stableFolderCountTicks = 0
        folderWaitTicks = 0

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
                               "name": fileName.replace(/\.[^.]+$/, "")
                           })
            }
        }

        if (files.length === 0) {
            console.log("Folder playback: no supported audio files found in",
                        selectedFolder.toString())
            return
        }

        if (!audioEngine || !audioEngine.startCustomSoundPlaylist) {
            console.log("Folder playback: startCustomSoundPlaylist unavailable")
            return
        }

        console.log("Folder playback: starting playlist with",
                    files.length, "tracks")

        var shouldRemainPaused = page.pausedMode

        audioEngine.startCustomSoundPlaylist(files, loopFolder)

        if (shouldRemainPaused)
            audioEngine.pauseCustomSound()

        selectedFile = files[0].url
        selectedFileName = files[0].name
    }

    Column {
        id: contentColumn

        width: parent.width
        spacing: Theme.paddingMedium

        // Selected folder and current track information
        Item {
            id: trackInfoContainer

            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.7

            property bool showTrackInfo:
                selectedFolderName !== ""
                && audioEngine !== null
                && audioEngine.customSoundPlaylistActive

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
                      : selectedFileName

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

                text: page.audioEngine
                      ? page.audioEngine.customSoundName : ""

                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        // Playback controls buttons
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
                    page.audioEngine !== null
                    && (page.selectedFile.toString() !== ""
                        || page.audioEngine.customSoundPlaylistActive)

                property bool isPlaying:
                    page.audioEngine !== null
                    && page.audioEngine.customSoundPlaying
                    && !page.audioEngine.customSoundPaused

                property bool hasPlaylist:
                    page.audioEngine !== null
                    && page.selectedFolder.toString() !== ""
                    && page.audioEngine.customSoundPlaylistActive
                    && folderPlaylistModel.count > 1

                // Previous track button
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
                        opacity: enabled ? 1.0 : 0.5

                        onClicked: {
                            if (enabled && page.audioEngine)
                                page.audioEngine.playPreviousCustomSound()
                        }
                    }
                }

                // Add or Clear custom sound selection button
                Item {
                    id: audioActionButton

                    width: playbackButtons.playButtonSize
                    height: playbackButtons.playButtonSize

                    property bool hasSelection:
                        page.selectedFile.toString() !== ""
                        || page.selectedFolder.toString() !== ""

                    Icon {
                        id: audioActionIcon

                        anchors.centerIn: parent
                        width: playbackButtons.playButtonSize
                        height: playbackButtons.playButtonSize

                        source: "image://theme/"
                                + (audioActionButton.hasSelection
                                   ? "icon-l-clear?"
                                   : "icon-l-add?")
                                + (audioActionMouseArea.pressed
                                   ? Theme.highlightColor
                                   : Theme.primaryColor)

                        sourceSize: Qt.size(width * 2, height * 2)

                        layer.enabled: page.audioEngine
                                       && page.audioEngine.customSoundPlaying

                        layer.effect: DropShadow {
                            transparentBorder: true
                            horizontalOffset: 0
                            verticalOffset: 0
                            radius: 0
                            samples: 1
                            color: Theme.highlightColor
                            opacity: 0.9
                        }
                    }

                    MouseArea {
                        id: audioActionMouseArea
                        anchors.fill: parent

                        onClicked: {
                            if (audioActionButton.hasSelection) {
                                if (page.audioEngine)
                                    page.audioEngine.stopCustomSound()

                                page.clearSelection()
                            } else {
                                page.openAudioPicker()
                            }
                        }
                    }
                }

                // Restart selected custom sound button
                Item {
                    id: restartButton

                    width: playbackButtons.playButtonSize
                    height: playbackButtons.playButtonSize

                    property bool hasSelection:
                        page.selectedFile.toString() !== ""
                        || page.selectedFolder.toString() !== ""

                    property bool canRestart:
                        hasSelection
                        && page.audioEngine !== null

                    Icon {
                        id: restartIcon

                        anchors.centerIn: parent
                        width: playbackButtons.playButtonSize
                        height: playbackButtons.playButtonSize

                        source: "../../images/icon-l-restart.svg"
                        sourceSize: Qt.size(width * 2, height * 2)

                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: restartIcon
                        source: restartIcon

                        opacity: restartButton.canRestart ? 1.0 : 0.5

                        color: restartMouseArea.pressed && restartButton.canRestart
                               ? Theme.highlightColor
                               : restartButton.canRestart
                                 ? Theme.primaryColor
                                 : Theme.secondaryColor
                    }

                    MouseArea {
                        id: restartMouseArea

                        anchors.fill: parent
                        enabled: restartButton.canRestart

                        onClicked: {
                            if (!page.audioEngine)
                                return

                            page.audioEngine.restartCustomSound()
                        }
                    }
                }

                // Next track button
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
                        opacity: enabled ? 1.0 : 0.5

                        onClicked: {
                            if (enabled && page.audioEngine)
                                page.audioEngine.playNextCustomSound()
                        }
                    }
                }
            }
        }

        // Custom Sound Volume Slider + Loop/Crossfade switches
        Column {
            id: customSoundControls

            width: parent.width
            spacing: Theme.paddingMedium

            VolumeSliderRow {
                id: customSoundVolumeRow

                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter

                value: page.audioEngine
                       ? page.audioEngine.customSoundVolume
                       : 50

                enabled: page.audioEngine
                         && page.audioEngine.customSoundSource.toString() !== ""

                onValueChanged: {
                    if (page.audioEngine)
                        page.audioEngine.customSoundVolume = value
                }
            }

            // Loop & Crossfade switches
            Row {
                id: switchesRow

                anchors.top: customSoundVolumeIcon.bottom
                anchors.topMargin: Theme.paddingMedium
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                Switch {
                    id: loopButton

                    icon.source: "image://theme/icon-m-repeat"

                    checked: page.audioEngine
                             ? page.audioEngine.customSoundLoop
                             : false

                    onCheckedChanged: {
                        page.loopFolder = checked
                        if (page.audioEngine)
                            page.audioEngine.customSoundLoop = checked
                    }

                    opacity: page.audioEngine
                             && page.audioEngine.customSoundSource.toString() !== ""
                             ? 1.0 : 0.5

                    enabled: page.audioEngine
                             && page.audioEngine.customSoundSource.toString() !== ""
                }

                Switch {
                    id: crossfadeButton

                    icon.source: "../../images/icon-m-crossfade.svg"
                    icon.sourceSize: Qt.size(Theme.iconSizeMedium * 0.9, Theme.iconSizeMedium * 0.9)

                    checked: page.audioEngine
                             ? page.audioEngine.customSoundCrossfade
                             : true

                    onCheckedChanged: {
                        if (page.audioEngine)
                            page.audioEngine.customSoundCrossfade = checked
                    }

                    enabled: page.audioEngine
                             && page.audioEngine.customSoundSource.toString() !== ""

                    opacity: enabled ? 1.0 : 0.5
                }
            }
        }
    }

    // Folder playlist loading timer
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

            // Wait for the model to populate and stabilize
            if (page.folderWaitTicks >= 5
                    && page.stableFolderCountTicks >= 3) {
                stop()
                page.buildFolderPlaylist()
            }

            // Avoid waiting forever if the folder cannot be read
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
}
