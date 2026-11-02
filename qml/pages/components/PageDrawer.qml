import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * PageDrawer = page-side behavior (dimmer, tap-to-close, one per drawer on the page)
 * ActionDrawer = panel-side look (handle, tint, height cap, shared by all drawer contents)
 */

Drawer {
    id: root

    anchors.fill: parent
    dock: Dock.Bottom

    // The drawer panel content (an ActionDrawer instance).
    property alias drawerContent: contentHost.data

    // The page content the drawer slides up over.
    default property alias pageContent: pageHost.data

    backgroundSize: contentHost.childrenRect.height

    background: Item {
        id: contentHost
        width: root.width
        height: childrenRect.height
    }

    // Foreground: page content + dimmer + tap interceptor
    Item {
        id: pageHost
        anchors.fill: parent
    }

    // Dim the foreground while the drawer is open.
    Rectangle {
        anchors.fill: parent
        z: 1
        color: Theme.overlayBackgroundColor
        opacity: root.opened ? 0.6 : 0.0

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // Taps on the visible foreground close the drawer
    // instead of activating page buttons in background.
    MouseArea {
        anchors.fill: parent
        z: 2
        enabled: root.opened

        onClicked: root.open = false
    }
}
