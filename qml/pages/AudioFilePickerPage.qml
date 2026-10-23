import QtQuick 2.0
import Sailfish.Silica 1.0
import Qt.labs.folderlistmodel 2.1

Page {
    id: page

    signal fileSelected(url fileUrl, string fileName)

    property url homeFolder: "file:///home/nemo"

    property bool atHome:
        folderModel.folder.toString().replace(/\/+$/, "") ===
        homeFolder.toString().replace(/\/+$/, "")

    allowedOrientations: Orientation.All

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
            "*.mp3",  "*.MP3",
            "*.wav",  "*.WAV",
            "*.ogg",  "*.OGG",
            "*.oga",  "*.OGA",
            "*.flac", "*.FLAC",
            "*.m4a",  "*.M4A",
            "*.aac",  "*.AAC",
            "*.opus", "*.OPUS",
            "*.wma",  "*.WMA",
            "*.aif",  "*.AIF",
            "*.aiff", "*.AIFF",
            "*.m4b",  "*.M4B",
            "*.3gp",  "*.3GP"
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
                title: qsTr("Choose audio file")
            }

            Label {
                x: Theme.horizontalPageMargin

                width: parent.width -
                       2 * Theme.horizontalPageMargin

                text: folderModel.folder.toString()
                          .replace("file://", "")

                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall

                wrapMode: Text.WrapAnywhere
            }

            Row {
                x: Theme.horizontalPageMargin

                width: parent.width -
                       2 * Theme.horizontalPageMargin

                spacing: Theme.paddingSmall

                Button {
                    width: (parent.width - parent.spacing) / 2

                    text: qsTr("Home")

                    onClicked: {
                        folderModel.folder = page.homeFolder
                    }
                }

                Button {
                    width: (parent.width - parent.spacing) / 2

                    text: qsTr("Up")

                    enabled: !page.atHome

                    onClicked: {
                        if (!page.atHome) {
                            folderModel.folder =
                                    folderModel.parentFolder
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Folders and audio files")
            }
        }

        delegate: BackgroundItem {
            id: fileItem

            width: fileList.width
            height: Theme.itemSizeSmall

            onClicked: {
                if (fileIsDir) {
                    // Open the selected folder.
                    folderModel.folder = fileURL
                } else {
                    // Return the selected audio file.
                    console.log(
                        "Audio picker: selected",
                        fileURL
                    )

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

            hintText: qsTr(
                "Try another folder or check where your audio files are stored."
            )
        }

        VerticalScrollDecorator {}
    }
}
