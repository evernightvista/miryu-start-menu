pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg

Rectangle {
    id: highlight

    /*!
    This property holds whether the control is hovered.

    This is set automatically when used in a ListView and GridView.
    */
    property bool hovered: highlight.ListView.view !== null || highlight.GridView.view !== null

    /*!
      This property holds whether the highlight has a pressed appearance.
    */
    property bool pressed: false

    /*!
      \qmlproperty int Highlight::marginHints

      This property holds the margin hints used by the background.
    */
    property alias marginHints: background.margins

    /*!
      This property holds whether the item is active. True by default. Set it to
      false to visually mark an item that's in the "current item" or "selected"
      state but is not currently being hovered.
    */
    property bool active: true

    /*!
      This property holds whether the item should not show a background. False by default. Set it to
      true to visually hide the background, mainly used when glow is enabled in plasmoid config
    */
    property bool hideBg: false

    radius: 10
    z: -20
    color: "transparent"
    clip: true

    // Rounded corners
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: roundedMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        id: roundedMask

        anchors.fill: parent
        radius: highlight.radius
        visible: false
        layer.enabled: true
    }

    KSvg.FrameSvgItem {
        id: background

        width: highlight.width + highlight.radius
        height: highlight.height + highlight.radius
        anchors.centerIn: parent

        opacity: highlight.hideBg ? 0 : 1

        imagePath: "widgets/viewitem"
        prefix: {
            if (highlight.pressed) {
                return highlight.hovered ? "selected+hover" : "selected";
            }
            return highlight.hovered ? "hover" : "normal";
        }

        Behavior on opacity {
            enabled: Kirigami.Units.veryShortDuration > 0
            NumberAnimation {
                duration: Kirigami.Units.veryShortDuration
                easing.type: Easing.OutQuad
            }
        }
    }
}
