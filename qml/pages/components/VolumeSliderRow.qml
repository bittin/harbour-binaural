import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

/*
// Volume slider with speaker icon underneath and an optional
// info button on the right.
//
//   API:
//   value            - current volume 0-100 (alias of the slider)
//                      -> implicit valueChanged signal, use onValueChanged
//   enabled          - dims slider + speaker icon when false
//   showInfoButton   - false (default): full-width slider
//                      true: info button on the right, slider shrinks
//   onInfoClicked    - fired when the info button is pressed
*/

Item {
    id: root

    property alias value: slider.value
    property bool enabled: true
    property bool showInfoButton: false

    signal infoClicked()

    width: parent ? parent.width : 0
    height: slider.height + volumeIcon.height - Theme.paddingLarge

    Slider {
        id: slider

        anchors.left: parent.left
        anchors.right: infoButton.visible ? infoButton.left
                                         : parent.right
        anchors.rightMargin: infoButton.visible ? Theme.paddingLarge : 0

        minimumValue: 0
        maximumValue: 100
        value: 50

        enabled: root.enabled
        opacity: enabled ? 1.0 : 0.5
    }

    // Speaker icon under the slider
    Item {
        id: volumeIcon

        property real value: slider.value
        property real size: Theme.iconSizeSmall * 1.6

        width: size
        height: size

        anchors.top: slider.bottom
        anchors.topMargin: -Theme.paddingLarge
        anchors.horizontalCenter: slider.horizontalCenter

        opacity: root.enabled ? 1.0 : 0.5

        Image {
            id: img
            anchors.fill: parent

            source: volumeIcon.value === 0  ? "../../images/icon-s-volume-1.svg"
                   : volumeIcon.value <= 33 ? "../../images/icon-s-volume-2.svg"
                   : volumeIcon.value <= 66 ? "../../images/icon-s-volume-3.svg"
                   :                           "../../images/icon-s-volume-4.svg"

            sourceSize: Qt.size(volumeIcon.size * 2, volumeIcon.size * 2)
            fillMode: Image.PreserveAspectFit
            visible: false
        }

        ColorOverlay {
            anchors.fill: img
            source: img
            color: Theme.primaryColor
        }
    }

    // Info button - opens the module's info page
    IconButton {
        id: infoButton

        visible: root.showInfoButton

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Theme.paddingSmall * 1.7

        icon.source: "image://theme/icon-m-about?" +
                     (pressed
                      ? Theme.highlightColor
                      : Theme.primaryColor)

        onClicked: root.infoClicked()
    }
}
