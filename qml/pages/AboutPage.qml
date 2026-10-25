import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "AboutPage"

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge

        Column {
            id: contentColumn

            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("About")
            }

            Image {
                anchors.horizontalCenter: parent.horizontalCenter

                width: Theme.iconSizeExtraLarge
                height: Theme.iconSizeExtraLarge

                source: "/usr/share/icons/hicolor/172x172/apps/harbour-binaural.png"
                fillMode: Image.PreserveAspectFit
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter

                text: "Binaural"

                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
            }

            // Release Version number
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter

                text: qsTr("Version") + " 0.8.2"

                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                text: qsTr("Application for playing binaural beats, colored noises and ambient sounds.")

                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            SectionHeader {
                text: qsTr("Development")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                text: "molan (molan-git)"

                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            Button {
                width: parent.width * 0.8
                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("Source code")

                onClicked: {
                    Qt.openUrlExternally("https://github.com/molan-git/harbour-binaural")
                }
            }

            Button {
                width: parent.width * 0.8
                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("Credits")

                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("CreditPage.qml"))
                }
            }

            SectionHeader {
                text: qsTr("Support")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                text: qsTr("Help translate the application into your language.")

                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            Button {
                width: parent.width * 0.8
                anchors.horizontalCenter: parent.horizontalCenter

                text: "Hosted Weblate"

                onClicked: {
                    Qt.openUrlExternally("https://hosted.weblate.org/projects/harbour-binaural/harbour-binaural/")
                }
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                text: qsTr("For small tips to support the project.")

                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            Button {
                width: parent.width * 0.8
                anchors.horizontalCenter: parent.horizontalCenter

                text: "Ko-fi"

                onClicked: {
                    Qt.openUrlExternally("https://ko-fi.com/molangit")
                }
            }

            SectionHeader {
                text: qsTr("Data protection")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                text: qsTr("This application works exclusively offline and requires permission to output audio. No data is collected.")

                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            SectionHeader {
                text: qsTr("License")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                property string gplUrl: "https://www.gnu.org/licenses/gpl-3.0.html"

                textFormat: Text.StyledText

                text: "<a href=\"" + gplUrl + "\">" +
                      "GNU General Public License v3.0 or later" +
                      "</a>"

                color: Theme.highlightColor
                linkColor: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap

                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }
        }

        VerticalScrollDecorator {}
    }
}
