import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.Window 2.0

/*
 * PageDrawer = page-side behavior (dimmer, tap-to-close, one per drawer on the page)
 * ActionDrawer = panel-side look (handle, tint, height cap, shared by all drawer contents)
 */

SilicaFlickable {
    id: drawer

    // ----- Public API -----
    property string title: ""

    // Content injected by the caller lands inside this column,
    // after the swipe handle / title.
    default property alias content: contentColumn.data

    signal closeRequested()

    width: parent.width
    height: Math.min(contentColumn.height + 2 * Theme.paddingLarge,
                     Screen.height * 0.8)
    contentHeight: contentColumn.height + Theme.paddingLarge
    clip: true

    // Chrome effect
    Rectangle {
        anchors.fill: parent
        color: Theme.rgba(Theme.highlightBackgroundColor,
                          Theme.highlightBackgroundOpacity * 0.35)
    }

    Column {
        id: contentColumn

        width: parent.width
        spacing: Theme.paddingMedium

        // Swipe handle: tap or swipe down to close.
        Item {
            width: parent.width
            height: Theme.itemSizeExtraSmall

            Rectangle {
                anchors.centerIn: parent
                width: Theme.itemSizeSmall * 2
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

                property real startY
                property real startX

                onPressed: { startY = mouse.y; startX = mouse.x }

                onReleased: {
                    var dy = mouse.y - startY
                    var dx = mouse.x - startX
                    if ((Math.abs(dy) < 5 && Math.abs(dx) < 5) ||
                        (dy > Theme.itemSizeSmall &&
                         Math.abs(dy) > Math.abs(dx))) {
                        drawer.closeRequested()
                    }
                }
            }
        }

        SectionHeader {
            visible: drawer.title !== ""
            text: drawer.title
        }

        // Guard so injected content lands after the handle/title
        Item { width: parent.width; height: 0 }
    }

    VerticalScrollDecorator {}
}
