import QtQuick 2.0
import Sailfish.Silica 1.0
import Binaural 1.0

Page {
    id: page
    objectName: "CreditPage"

    allowedOrientations: defaultAllowedOrientations

    // List of translation credits (add names and info here)
    readonly property var translationCredits: [
        {
            language: qsTr("Norwegian"),
            name: "fsilye (Frank Paul Silye)"
        },
        {
            language: qsTr("Swedish"),
            name: "eson57 (Åke Engelbrektson)"
        },
        {
            language: qsTr("Dutch"),
            name: "Nathan"
        },
        {
            language: qsTr("Slovenian"),
            name: "Boštjan"
        }
    ]

    // List of sound credits (add names and info here)
    readonly property var soundCredits: [
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

    // Hidden text used to measure the widest "label:" column, so both credit columns align.
    Text {
        id: labelMetrics
        visible: false
        font.pixelSize: Theme.fontSizeExtraSmall
    }

    property real creditsLabelWidth: {
        var widest = 0

        var measure = function (label) {
            labelMetrics.text = label
            if (labelMetrics.implicitWidth > widest)
                widest = labelMetrics.implicitWidth
        }

        for (var i = 0; i < translationCredits.length; ++i)
            measure(translationCredits[i].language + ":")

        for (var j = 0; j < soundCredits.length; ++j)
            measure(soundCredits[j].name + ":")

        return widest
    }

    function openLink(link) {
        if (link.indexOf("https://") === 0 ||
                link.indexOf("http://") === 0) {
            Qt.openUrlExternally(link)
        }
    }

    function link(url, label) {
        return "<a href=\"" + url + "\">" + label + "</a>"
    }

    SilicaListView {
        id: creditList

        anchors.fill: parent

        header: Column {
            width: page.width

            PageHeader {
                title: qsTr("Credits")
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin

                textFormat: Text.StyledText

                //: Full sentence: "Binaural was inspired by Metiq."
                text: qsTr("Binaural was inspired by") +
                      " " +
                      page.link("https://github.com/metiq-xyz/android-app", "Metiq") +
                      "."

                color: Theme.highlightColor
                linkColor: Theme.primaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.WordWrap

                onLinkActivated: openLink(link)
            }

            SectionHeader {
                text: qsTr("Translations")
            }

            Column {
                id: translationContent

                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Repeater {
                    model: page.translationCredits

                    delegate: Item {
                        width: translationContent.width
                        height: translationRow.height + Theme.paddingSmall / 2

                        Grid {
                            id: translationRow

                            width: parent.width
                            columns: 2
                            columnSpacing: Theme.paddingMedium * 1.5

                            Text {
                                width: page.creditsLabelWidth
                                text: modelData.language + ":"

                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeExtraSmall
                                wrapMode: Text.NoWrap
                            }

                            Text {
                                width: translationRow.width -
                                       page.creditsLabelWidth -
                                       translationRow.columnSpacing

                                text: modelData.name

                                color: Theme.highlightColor
                                font.pixelSize: Theme.fontSizeExtraSmall
                                wrapMode: Text.NoWrap
                            }
                        }
                    }
                }
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
                      page.link("https://pixabay.com/service/license-summary/",
                                qsTr("Pixabay Content License")) +
                      ":"

                color: Theme.highlightColor
                linkColor: Theme.primaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText

                onLinkActivated: openLink(link)
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge * 2
            }
        }

        model: page.soundCredits

        delegate: ListItem {
            id: creditItem

            contentHeight: creditContent.height + Theme.paddingSmall / 2

            Grid {
                id: creditContent

                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                columns: 2
                columnSpacing: Theme.paddingMedium * 1.5

                Text {
                    width: page.creditsLabelWidth

                    text: modelData.name + ":"

                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    wrapMode: Text.NoWrap
                }

                Text {
                    width: creditContent.width -
                           page.creditsLabelWidth -
                           creditContent.columnSpacing

                    textFormat: Text.StyledText
                    wrapMode: Text.NoWrap

                    color: Theme.highlightColor
                    linkColor: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall

                    text: page.link(modelData.authorUrl, modelData.author) +
                          " - " +
                          page.link(modelData.sourceUrl, "Pixabay")
                    onLinkActivated: openLink(link)
                }
            }
        }

        footer: Column {
            width: page.width

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            SectionHeader {
                text: qsTr("Images")
            }

            Text {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                textFormat: Text.StyledText
                wrapMode: Text.WordWrap

                color: Theme.highlightColor
                linkColor: Theme.primaryColor
                font.pixelSize: Theme.fontSizeExtraSmall

                text: qsTr("Images have been manually edited for use in this app:") +
                      "<br>" +
                      page.link("https://commons.wikimedia.org/wiki/File:Beating_Frequency.svg",
                               "Beating_Frequency.svg") +
                      " - Ansgar Hellwig (Ahellwig)" +
                      "<br>" +
                      page.link("https://creativecommons.org/licenses/by-sa/3.0/",
                               "CC BY-SA 3.0")

                onLinkActivated: openLink(link)
            }
        }

        VerticalScrollDecorator {}
    }
}
