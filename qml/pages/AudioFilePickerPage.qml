import QtQuick 2.0
import Sailfish.Silica 1.0
import Qt.labs.folderlistmodel 2.1

Page {
    id: page

    // "file" selects one audio file.
    // "folder" selects the currently displayed folder.
    property string selectionMode: "file"

    property url homeFolder: StandardPaths.writableLocation(StandardPaths.HomeLocation)

    signal fileSelected(url fileUrl, string fileName)
    signal folderSelected(url folderUrl, string folderName)

    allowedOrientations: Orientation.All

    function normalizedPath(value) {
        var path = value.toString()

        if (path.indexOf("file://") === 0)
            path = path.substring(7)

        return path.replace(/\/+$/, "")
    }

    property bool atHome:
        normalizedPath(folderModel.folder) === normalizedPath(homeFolder)

    function selectCurrentFolder() {
        var folderUrl = folderModel.folder
        var path = normalizedPath(folderUrl)
        var parts = path.split("/")
        var folderName = parts.length > 0
                         ? parts[parts.length - 1]
                         : path

        if (folderName === "")
            folderName = qsTr("Home")

        console.log("Audio picker: selected folder", folderUrl)

        page.folderSelected(folderUrl, folderName)
        pageStack.pop()
    }

    FolderListModel {
        id: folderModel

        folder: page.homeFolder
        rootFolder: page.homeFolder

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

        onFolderChanged: {
            console.log("Audio picker: browsing", folder)
        }
    }

    SilicaListView {
        id: fileList

        anchors.fill: parent
        model: folderModel

        header: Column {
            width: fileList.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: page.selectionMode === "folder"
                        ? qsTr("Choose folder")
                        : qsTr("Choose audio file")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: page.normalizedPath(folderModel.folder)
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WrapAnywhere
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: qsTr("Up")
                enabled: !page.atHome

                onClicked: {
                    if (page.atHome)
                        return

                    var homePath = page.normalizedPath(page.homeFolder)
                    var parentFolder = folderModel.parentFolder
                    var parentPath = page.normalizedPath(parentFolder)

                    if (parentPath === homePath ||
                            parentPath.indexOf(homePath + "/") === 0) {
                        folderModel.folder = parentFolder
                    } else {
                        folderModel.folder = page.homeFolder
                    }
                }
            }

            Button {
                visible: page.selectionMode === "folder"

                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: qsTr("Use this folder")

                onClicked: page.selectCurrentFolder()
            }

            SectionHeader {
                text: page.selectionMode === "folder"
                      ? qsTr("Open a folder or select this folder")
                      : qsTr("Folders and audio files")
            }
        }

        delegate: BackgroundItem {
            id: fileItem

            width: fileList.width
            height: Theme.itemSizeSmall

            onClicked: {
                if (fileIsDir) {
                    folderModel.folder = fileURL
                } else if (page.selectionMode === "file") {
                    console.log("Audio picker: selected", fileURL)

                    page.fileSelected(fileURL, fileName)
                    pageStack.pop()
                }
            }

            Label {
                anchors.left: parent.left
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.right: itemTypeLabel.left
                anchors.rightMargin: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter

                text: fileName

                color: fileItem.highlighted
                       ? Theme.highlightColor
                       : Theme.primaryColor

                font.pixelSize: Theme.fontSizeMedium
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: itemTypeLabel

                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter

                text: fileIsDir
                      ? qsTr("Folder  ›")
                      : qsTr("Audio")

                color: fileItem.highlighted
                       ? Theme.highlightColor
                       : Theme.secondaryColor

                font.pixelSize: Theme.fontSizeSmall
            }
        }

        ViewPlaceholder {
            enabled: folderModel.count === 0

            text: qsTr("No audio files or folders")
            hintText: qsTr("Try another folder or check where your audio files are stored.")
        }

        VerticalScrollDecorator {}
    }
}
