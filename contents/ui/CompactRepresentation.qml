/*****************************************************************************
 *   Copyright (C) 2013-2014 by Eike Hein <hein@kde.org>                     *
 *   Copyright (C) 2021 by Prateek SU <pankajsunal123@gmail.com>             *
 *   Copyright (C) 2022 by Friedrich Schriewer <friedrich.schriewer@gmx.net> *
 *                                                                           *
 *   This program is free software; you can redistribute it and/or modify    *
 *   it under the terms of the GNU General Public License as published by    *
 *   the Free Software Foundation; either version 2 of the License, or       *
 *   (at your option) any later version.                                     *
 *                                                                           *
 *   This program is distributed in the hope that it will be useful,         *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 *   GNU General Public License for more details.                            *
 *                                                                           *
 *   You should have received a copy of the GNU General Public License       *
 *   along with this program; if not, write to the                           *
 *   Free Software Foundation, Inc.,                                         *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .          *
 ****************************************************************************/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Item {
    id: root

    required property LauncherState launcher

    readonly property bool useCustomButtonImage: Plasmoid.configuration.useCustomButtonImage
                                                 && String(Plasmoid.configuration.customButtonImage).length > 0

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Margins of the applet container that wraps this button inside the panel.
    // The Plasma 6 active-tab must extend past these margins right up to the
    // panel edge (like a real tab), otherwise the highlight looks like a small
    // box inside the button instead of the native expanded-applet tab.
    readonly property var containerMargins: {
        let item = root;
        while (item.parent) {
            item = item.parent;
            if (item.isAppletContainer)
                return item.getMargins;
        }
        return undefined;
    }

    Plasmoid.status: root.launcher.menuOpen ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.PassiveStatus

    Plasmoid.onActivated: root.launcher.toggle()

    // Plasma 6 active-tab highlight.
    // Uses the same theme element (widgets/tabbar + <edge>-active-tab) as the
    // Plasma shell draws behind expanded applets, so the open state follows the
    // current Plasma 6 appearance. Always shown while the menu is open.
    KSvg.FrameSvgItem {
        id: activeTab

        z: -1
        imagePath: "widgets/tabbar"

        anchors {
            fill: parent
            property bool returnAllMargins: true
            // Extend the tab past the applet container margins so it reaches the
            // panel edge — identical to CompactApplet.qml / miryu-start-main-rtm.
            bottomMargin: !root.vertical && root.containerMargins ? -root.containerMargins("bottom", returnAllMargins) : 0
            topMargin: !root.vertical && root.containerMargins ? -root.containerMargins("top", returnAllMargins) : 0
            leftMargin: root.vertical && root.containerMargins ? -root.containerMargins("left", returnAllMargins) : 0
            rightMargin: root.vertical && root.containerMargins ? -root.containerMargins("right", returnAllMargins) : 0
        }

        prefix: {
            let prefix;
            switch (Plasmoid.location) {
            case PlasmaCore.Types.LeftEdge:
                prefix = "west-active-tab";
                break;
            case PlasmaCore.Types.TopEdge:
                prefix = "north-active-tab";
                break;
            case PlasmaCore.Types.RightEdge:
                prefix = "east-active-tab";
                break;
            default:
                prefix = "south-active-tab";
            }
            if (!hasElementPrefix(prefix))
                prefix = "active-tab";
            return prefix;
        }

        opacity: root.launcher.menuOpen ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.InOutQuad }
        }
    }

    Kirigami.Icon {
        id: buttonIcon

        anchors.fill: parent
        source: root.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon
        active: buttonHover.hovered || root.launcher.menuOpen
        smooth: true

        scale: mouseArea.pressed ? 0.85 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
        }
    }

    // HoverHandler instead of hoverEnabled on the MouseArea: a hovering MouseArea
    // consumes the hover event, which kept the shell from showing the native
    // tooltip of the button ("Start", cf. toolTipMainText in main.qml). HoverHandler
    // observes the hover without intercepting it.
    HoverHandler {
        id: buttonHover
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        onClicked: root.launcher.toggle()
    }

    // Native "Start" tooltip above the panel button, styled and positioned by
    // Plasma itself (same component as miryu-start-main). It intercepts neither
    // clicks nor hover events. Hidden while the menu is open.
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: i18n("Start")
        active: !root.launcher.menuOpen
    }

    MenuRepresentation {
        launcher: root.launcher
        anchorItem: root
    }
}
