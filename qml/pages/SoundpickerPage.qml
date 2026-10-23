import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import QtGraphicalEffects 1.0
import Qt.labs.folderlistmodel 2.1

Page {
    id: page

    objectName: "SoundpickerPage"

    property var appWindow: null

    // Selected audio file
    property url selectedFile: ""
    property string selectedFileName: ""

    // Selected folder
    property url selectedFolder: ""
    property string selectedFolderName: ""
    property bool loopFolder: false

    // Browser selection mode: "file" or "folder"
    property string pickerSelectionMode: "file"

    property bool startFolderWhenReady: false

    allowedOrientations: Orientation.All

    Component.onCompleted: {
        if (page.appWindow &&
                page.appWindow.customSoundSource.toString() !== "") {
            page.selectedFile = page.appWindow.customSoundSource
            page.selectedFileName = page.appWindow.customSoundName
        }
    }

    function startFolderPlayback() {
        if (!page.appWindow) {
            console.log("Custom sound: appWindow reference is missing")
            return
        }

        if (page.selectedFolder.toString() === "") {
            console.log("Custom sound: no folder selected")
            return
        }

        page.startFolderWhenReady = true
        folderPlaylistModel.folder = page.selectedFolder
        folderPlaylistTimer.restart()
    }

    function buildFolderPlaylist() {
        if (!page.startFolderWhenReady)
            return

        if (folderPlaylistModel.status !== FolderListModel.Ready) {
            folderPlaylistTimer.restart()
            return
        }

        page.startFolderWhenReady = false

        var files = []

        for (var i = 0; i < folderPlaylistModel.count; i++) {
            if (!folderPlaylistModel.get(i, "fileIsDir")) {
                files.push({
                               "url": folderPlaylistModel.get(i, "fileURL"),
                               "name": folderPlaylistModel.get(i, "fileName")
                           })
            }
        }

        if (files.length === 0) {
            console.log("Custom sound: no audio files found in folder")
            return
        }

        page.appWindow.startCustomSoundPlaylist(files, page.loopFolder)

        page.selectedFile = files[0].url
        page.selectedFileName = files[0].name

        console.log("Custom sound: starting playlist with",
                    files.length, "files")
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height

        VerticalScrollDecorator {}

        Column {
            id: contentColumn

            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Custom sound")
            }

            // Single-file selection
            SectionHeader {
                text: qsTr("Audio file")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: page.selectedFileName !== ""
                      ? page.selectedFileName
                      : qsTr("No file selected")

                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: qsTr("Choose audio file")

                onClicked: {
                    page.pickerSelectionMode = "file"
                    pageStack.push(audioFilePicker)
                }
            }

            // Folder playback
            SectionHeader {
                text: qsTr("Folder playback")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: page.selectedFolderName !== ""
                      ? page.selectedFolderName
                      : qsTr("No folder selected")

                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: qsTr("Choose folder")

                onClicked: {
                    page.pickerSelectionMode = "folder"
                    pageStack.push(audioFilePicker)
                }
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: qsTr("Play folder")

                enabled: page.appWindow !== null &&
                         page.selectedFolder.toString() !== ""

                onClicked: page.startFolderPlayback()
            }

            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium

                Button {
                    width: (parent.width - parent.spacing) / 2

                    text: qsTr("Previous")

                    enabled: page.appWindow !== null &&
                             page.appWindow.customSoundPlaylistActive

                    onClicked: page.appWindow.playPreviousCustomSound()
                }

                Button {
                    width: (parent.width - parent.spacing) / 2

                    text: qsTr("Next")

                    enabled: page.appWindow !== null &&
                             page.appWindow.customSoundPlaylistActive

                    onClicked: page.appWindow.playNextCustomSound()
                }
            }

            TextSwitch {
                text: qsTr("Loop folder")

                description: checked
                             ? qsTr("Repeat the folder continuously")
                             : qsTr("Stop after the last audio file")

                checked: page.loopFolder

                onCheckedChanged: page.loopFolder = checked
            }

            // Playback controls
            SectionHeader {
                text: qsTr("Playback")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: {
                    if (!page.appWindow)
                        return qsTr("Audio player unavailable")

                    if (page.appWindow.customSoundPlaying)
                        return qsTr("Playing")

                    if (page.appWindow.customSoundSource.toString() !== "")
                        return qsTr("Ready to play")

                    return qsTr("Select an audio file first")
                }

                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: page.appWindow &&
                      page.appWindow.customSoundPlaying
                      ? qsTr("Pause")
                      : qsTr("Play")

                enabled: page.appWindow !== null &&
                         (page.selectedFile.toString() !== "" ||
                          page.appWindow.customSoundPlaylistActive)

                onClicked: {
                    if (!page.appWindow)
                        return

                    if (page.appWindow.customSoundPlaying) {
                        page.appWindow.pauseCustomSound()
                    } else if (page.appWindow.customSoundPlaylistActive) {
                        page.appWindow.resumeCustomSound()
                    } else {
                        page.appWindow.customSoundSource = page.selectedFile
                        page.appWindow.customSoundName = page.selectedFileName
                        page.appWindow.playCustomSound()
                    }
                }
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: qsTr("Stop")

                enabled: page.appWindow !== null &&
                         (page.selectedFile.toString() !== "" ||
                          page.appWindow.customSoundPlaylistActive)

                onClicked: {
                    if (page.appWindow)
                        page.appWindow.stopCustomSound()
                }
            }

            TextSwitch {
                text: qsTr("Loop sound")

                description: checked
                             ? qsTr("Repeat the selected sound continuously")
                             : qsTr("Play the selected sound once")

                checked: page.appWindow
                         ? page.appWindow.customSoundLoop
                         : false

                enabled: page.appWindow !== null &&
                         !page.appWindow.customSoundPlaylistActive

                onCheckedChanged: {
                    if (page.appWindow)
                        page.appWindow.customSoundLoop = checked
                }
            }

            // Volume control
            SectionHeader {
                text: qsTr("Volume")
            }

            Item {
                id: volumeControl

                width: parent.width
                height: customSoundVolumeSlider.height +
                        Theme.iconSizeSmall

                Slider {
                    id: customSoundVolumeSlider

                    width: parent.width * 0.9
                    anchors.horizontalCenter: parent.horizontalCenter

                    minimumValue: 0
                    maximumValue: 100

                    value: page.appWindow
                           ? page.appWindow.customSoundVolume
                           : 50

                    valueText: Math.round(value) + "%"

                    enabled: page.appWindow !== null
                    opacity: enabled ? 1.0 : 0.5

                    onValueChanged: {
                        if (page.appWindow)
                            page.appWindow.customSoundVolume = value
                    }
                }

                Item {
                    id: customSoundVolumeIcon

                    width: Theme.iconSizeSmall * 1.6
                    height: Theme.iconSizeSmall * 1.6

                    anchors.top: customSoundVolumeSlider.bottom
                    anchors.topMargin: -Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter

                    opacity: customSoundVolumeSlider.enabled ? 1.0 : 0.5

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

            Item {
                width: 1
                height: Theme.paddingLarge
            }
        }
    }

    // Wait for FolderListModel to finish loading.
    Timer {
        id: folderPlaylistTimer

        interval: 200
        repeat: false

        onTriggered: {
            if (page.startFolderWhenReady)
                page.buildFolderPlaylist()
        }
    }

    // Audio files in the selected folder.
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

    Component {
        id: audioFilePicker

        AudioFilePickerPage {
            selectionMode: page.pickerSelectionMode

            onFileSelected: {
                page.selectedFile = fileUrl
                page.selectedFileName = fileName

                if (page.appWindow) {
                    page.appWindow.customSoundSource = fileUrl
                    page.appWindow.customSoundName = fileName
                }

                console.log("Custom sound: selected file", fileUrl)
            }

            onFolderSelected: {
                page.selectedFolder = folderUrl
                page.selectedFolderName = folderName

                console.log("Custom sound: selected folder", folderUrl)
            }
        }
    }

}
