import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

Item {
    property real value: 50
    property real size: Theme.iconSizeSmall * 1.6
    property color tint: Theme.primaryColor

    width: size
    height: size

    Image {
        id: img
        anchors.fill: parent

        source: value === 0    ? "../../images/icon-s-volume-1.svg"
               : value <= 33   ? "../../images/icon-s-volume-2.svg"
               : value <= 66   ? "../../images/icon-s-volume-3.svg"
               :                 "../../images/icon-s-volume-4.svg"

        sourceSize: Qt.size(size * 2, size * 2)
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    ColorOverlay {
        anchors.fill: img
        source: img
        color: tint
    }
}
