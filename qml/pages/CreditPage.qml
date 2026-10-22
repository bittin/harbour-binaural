import QtQuick 2.0
import Sailfish.Silica 1.0
import Binaural 1.0

Page {
    id: page
    objectName: "CreditPage"

    allowedOrientations: defaultAllowedOrientations

    property var soundCredits: [
        {
            name: SoundNames.label("Wind"),
            author: "Jurij",
            authorUrl: "https://pixabay.com/users/soundreality-31074404/",
            sourceUrl: "https://pixabay.com/"
        },
        {
            name: SoundNames.label("Rain"),
            author: "Pig Bank - Mood",
            authorUrl: "https://pixabay.com/users/boons_freak-39857343/",
            sourceUrl: "https://pixabay.com/"
        },
        {
            name: SoundNames.label("Crickets"),
            author: "freesound_community",
            authorUrl: "https://pixabay.com/users/freesound_community-46691455/",
            sourceUrl: "https://pixabay.com/"
        },
        {
            name: SoundNames.label("Lake"),
            author: "freesound_community",
            authorUrl: "https://pixabay.com/users/freesound_community-46691455/",
            sourceUrl: "https://pixabay.com/sound-effects/"
        },
        {
            name: SoundNames.label("Birds"),
            author: "Jurij",
            authorUrl: "https://pixabay.com/users/soundreality-31074404/",
            sourceUrl: "https://pixabay.com/"
        },
        {
            name: SoundNames.label("Fire"),
            author: "Jurij",
            authorUrl: "https://pixabay.com/users/soundreality-31074404/",
            sourceUrl: "https://pixabay.com/"
        },
        {
            name: SoundNames.label("Chimes"),
            author: "freesound_community",
            authorUrl: "https://pixabay.com/users/freesound_community-46691455/",
            sourceUrl: "https://pixabay.com/sound-effects/"
        },
        {
            name: SoundNames.label("Stream"),
            author: "loswin23",
            authorUrl: "https://pixabay.com/users/loswin23-15879800/",
            sourceUrl: "https://pixabay.com/"
        },
        {
            name: SoundNames.label("Sailing"),
            author: "dammafra",
            authorUrl: "https://pixabay.com/de/users/dammafra-53190480/",
            sourceUrl: "https://pixabay.com/"
        },
        {
            name: SoundNames.label("Waves"),
            author: "kokoreli777",
            authorUrl: "https://pixabay.com/de/users/kokoreli777-39793239/",
            sourceUrl: "https://pixabay.com/"
        }
    ]

    SilicaListView {
        id: creditList

        anchors.fill: parent

        header: Column {
            width: page.width

            PageHeader {
                title: qsTr("Asset credits")
            }

            SectionHeader {
                text: qsTr("Audio files")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                //: Full sentence: "Files have been manually edited for use in this app under the Pixabay Content License:"
                //: Keep the sentence natural when translating; "Pixabay Content License" is a clickable link.
                text: qsTr("Files have been manually edited for use in this app under the") +
                      " " +
                      "<a href=\"https://pixabay.com/service/license-summary/\">" +
                      qsTr("Pixabay Content License") +
                      "</a>" +
                      ":"

                color: Theme.highlightColor
                linkColor: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText

                onLinkActivated: {
                    if (link.indexOf("https://") === 0 ||
                            link.indexOf("http://") === 0) {
                        Qt.openUrlExternally(link)
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge * 2
            }
        }

        model: page.soundCredits

        delegate: ListItem {
            id: creditItem

            contentHeight: creditContent.height +
                           Theme.paddingMedium

            Column {
                id: creditContent

                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                spacing: Theme.paddingSmall

                Text {
                    width: parent.width

                    textFormat: Text.StyledText
                    wrapMode: Text.WordWrap

                    color: Theme.highlightColor
                    linkColor: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeSmall

                    text: modelData.name +
                          ": " +
                          "<a href=\"" + modelData.authorUrl + "\">" +
                          modelData.author +
                          "</a>" +
                          " - " +
                          "<a href=\"" + modelData.sourceUrl + "\">" +
                          "Pixabay" +
                          "</a>"

                    onLinkActivated: {
                        if (link.indexOf("https://") === 0 ||
                                link.indexOf("http://") === 0) {
                            Qt.openUrlExternally(link)
                        }
                    }
                }
            }
        }

        footer: Column {
            width: page.width

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            SectionHeader {
                text: qsTr("Images")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                //: Full sentence: "Binaural graph image modified for use in Binaural:"
                //: Second Binaural word means the app names which isn't translated.
                text: qsTr("Binaural graph image modified for use in") +
                      " Binaural:"

                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Text {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                textFormat: Text.StyledText
                wrapMode: Text.WordWrap

                color: Theme.highlightColor
                linkColor: Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall

                //: Full sentence: "Based on Beating_Frequency.svg - Ansgar Hellwig (Ahellwig). CC BY-SA 3.0 - Original source
                text: qsTr("Based on") +
                      " " +
                      "Beating_Frequency.svg" +
                      " - " +
                      "Ansgar Hellwig (Ahellwig)." +
                      "<br>" +
                      "<a href=\"https://creativecommons.org/licenses/by-sa/3.0/\">" +
                      "CC BY-SA 3.0" +
                      "</a>" +
                      " - " +
                      "<a href=\"https://commons.wikimedia.org/wiki/File:Beating_Frequency.svg\">" +
                      qsTr("Original source") +
                      "</a>"

                onLinkActivated: {
                    if (link.indexOf("https://") === 0 ||
                            link.indexOf("http://") === 0) {
                        Qt.openUrlExternally(link)
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
