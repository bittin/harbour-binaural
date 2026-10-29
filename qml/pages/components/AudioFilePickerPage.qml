import QtQuick 2.0
import Sailfish.Silica 1.0
import Qt.labs.folderlistmodel 2.1

Dialog {
    id: picker
    objectName: "AudioFilePickerPage"

    property string selectionMode: "file"

    // Start in the system Music directory, with a fallback for this device.
    property url homeFolder: StandardPaths.music !== ""
                             ? StandardPaths.music
                             : "file:///home/defaultuser/Music"

    property url currentFolder: homeFolder

    signal fileSelected(url fileUrl, string fileName)
    signal folderSelected(url folderUrl, string folderName)

    allowedOrientations: Orientation.All

    property bool atHome:
        normalizedPath(currentFolder) === normalizedPath(homeFolder)

    function normalizedPath(value) {
        var path = value.toString()

        if (path.indexOf("file://") === 0)
            path = path.substring(7)

        return path.replace(/\/+$/, "") || "/"
    }

    property bool hasAudioFiles: {
        for (var i = 0; i < folderModel.count; ++i) {
            if (!folderModel.get(i, "fileIsDir"))
                return true
        }
        return false
    }

    canAccept: {
        for (var i = 0; i < folderModel.count; ++i) {
            if (!folderModel.get(i, "fileIsDir"))
                return true
        }
        return false
    }

    function selectCurrentFolder() {
        var folderUrl = folderModel.folder
        var path = normalizedPath(folderUrl)
        var parts = path.split("/")
        var folderName = parts.length > 0
                ? parts[parts.length - 1]
                : path

        if (folderName === "")
            folderName = qsTr("Music")

        folderSelected(folderUrl, folderName)
        accept()
    }

    Column {
        anchors.fill: parent
        spacing: 0

        DialogHeader {
            id: dialogHeader

            acceptText: qsTr("Use folder")
            cancelText: qsTr("Cancel")
        }

        SilicaListView {
            id: fileList

            width: parent.width
            height: parent.height - dialogHeader.height

            model: folderModel
            clip: true

            header: Column {
                width: fileList.width
                spacing: 0

                // Shows current folder
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin

                    // Show Music or folder in Music (Music/folder)
                    text: {
                        var current = picker.normalizedPath(folderModel.folder)
                        var music = picker.normalizedPath(picker.homeFolder)

                        if (current === music)
                            return "Music"

                        if (current.indexOf(music + "/") === 0)
                            return "Music" + current.substring(music.length)

                        return current
                    }

                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WrapAnywhere
                }

                // Up button to go back to parent folder
                ListItem {
                    width: fileList.width
                    height: Theme.itemSizeMedium

                    Image {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                        source: "image://theme/icon-m-up"
                        opacity: picker.atHome ? 0.35 : 1.0
                    }

                    onClicked: {
                        if (!picker.atHome) {
                            var path = picker.normalizedPath(folderModel.folder)
                            var parentPath = path.substring(0, path.lastIndexOf("/"))
                            picker.currentFolder = "file://" + parentPath
                        }
                    }
                }
            }

            // Lists folders or audio files with an icon
            delegate: ListItem {
                width: fileList.width
                height: Theme.itemSizeMedium

                Image {
                    id: rowIcon

                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter

                    width: Theme.iconSizeMedium
                    height: Theme.iconSizeMedium

                    source: fileIsDir
                            ? "image://theme/icon-m-file-folder"
                            : "image://theme/icon-m-file-audio"

                    fillMode: Image.PreserveAspectFit
                }

                Label {
                    anchors.left: rowIcon.right
                    anchors.leftMargin: Theme.paddingMedium
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter

                    text: fileName
                    font.pixelSize: Theme.fontSizeMedium
                    truncationMode: TruncationMode.Fade

                    color: highlighted
                           ? Theme.highlightColor
                           : Theme.primaryColor
                }

                onClicked: {
                    if (fileIsDir) {
                        // In folder mode, tapping a folder navigates into it.
                        // Use folder selection to choose the current directory.
                        picker.currentFolder = fileURL
                    } else if (picker.selectionMode === "file") {
                        picker.fileSelected(fileURL, fileName)
                        picker.reject()
                    }
                }
            }

            ViewPlaceholder {
                enabled: folderModel.status === FolderListModel.Ready
                         && folderModel.count === 0

                text: qsTr("No audio files or folders")
                hintText: qsTr(
                              "Try another folder or check where your audio files are stored."
                              )
            }

            VerticalScrollDecorator {}
        }
    }

    FolderListModel {
        id: folderModel

        folder: picker.currentFolder

        showDirs: true
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

    onAccepted: {
        picker.selectCurrentFolder()
    }
}
