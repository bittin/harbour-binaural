import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge

        VerticalScrollDecorator { }

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

                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
            }

            // Version number
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter

                text: qsTr("Version") + " 0.8.1"

                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                text: qsTr("Application for playing binaural beats, colored noises and ambient sounds.")

                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeMedium
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            SectionHeader {
                text: qsTr("Development")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("Source code on") + " Github"

                onClicked: {
                    Qt.openUrlExternally("https://github.com/molan-git/harbour-binaural")
                }
            }

            SectionHeader {
                text: qsTr("Translations")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                text: qsTr("Help translate the application into your language.")

                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter

                text: "Hosted Weblate"

                onClicked: {
                    Qt.openUrlExternally("https://hosted.weblate.org/projects/harbour-binaural/")
                }
            }

            SectionHeader {
                text: qsTr("Support")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                text: qsTr("For small tips to support the project.")

                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter

                text: "Ko-fi"

                onClicked: {
                    Qt.openUrlExternally("https://ko-fi.com/molangit")
                }
            }

            SectionHeader {
                text: qsTr("Credits")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                property string metiqUrl: "https://github.com/metiq-xyz/android-app"

                textFormat: Text.StyledText

                //: Full sentence: "Binaural was inspired by Metiq."
                text: qsTr("Binaural was inspired by") +
                      " " +
                      "<a href=\"" + metiqUrl + "\">" +
                      "Metiq" +
                      "</a>."

                color: Theme.primaryColor
                linkColor: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap

                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("Asset credits")

                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("CreditPage.qml"))
                }
            }

            SectionHeader {
                text: qsTr("Data protection")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                text: qsTr("This application works exclusively offline and requires permission to output audio. No data is collected.")

                color: Theme.primaryColor
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

                color: Theme.primaryColor
                linkColor: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap

                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }
        }
    }
}
