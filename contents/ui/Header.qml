/*****************************************************************************
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
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

// Settings, pinned system actions and the leave menu
Item {
    id: header

    required property LauncherState launcher
    required property real iconSize

    // Host of the menu's shared hover tooltip (MainView.showTip/hideTip). A
    // PC3.ToolTip attached inside the PlasmaCore.Dialog was rendered misplaced
    // and with the wrong styling, so the window draws the tooltip itself.
    property var tipHost: null

    // Favorite ids of the system actions shown as buttons (lock-screen, suspend, ...)
    readonly property list<string> pinnedActions: Plasmoid.configuration.systemFavorites

    implicitWidth: buttonRow.implicitWidth
    implicitHeight: buttonRow.implicitHeight
    width: header.implicitWidth
    height: header.iconSize

    component HeaderButton: PC3.RoundButton {
        id: headerButton

        property var iconSource
        // Tint the icon with the text color (for the bundled monochrome icons)
        property bool maskIcon: false

        flat: true

        Layout.preferredHeight: header.iconSize * 1.5
        Layout.preferredWidth: header.iconSize * 1.5

        // Tooltip drawn by the menu window (see MainView.showTip): the attached
        // PC3.ToolTip was misplaced inside the PlasmaCore.Dialog.
        onHoveredChanged: {
            if (!header.tipHost) {
                return;
            }
            if (headerButton.hovered && headerButton.Accessible.name !== "") {
                header.tipHost.showTip(headerButton, headerButton.Accessible.name);
            } else {
                header.tipHost.hideTip(headerButton);
            }
        }
        onPressedChanged: {
            if (headerButton.pressed && header.tipHost) {
                header.tipHost.hideTip(headerButton);
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            anchors.margins: header.iconSize * 0.15
            source: headerButton.iconSource
            isMask: headerButton.maskIcon
            color: Kirigami.Theme.textColor
        }
    }

    // System actions (lock, log out, restart, ...)
    Kicker.SystemModel {
        id: systemModel

        favoritesModel: header.launcher.systemFavorites
    }

    RowLayout {
        id: buttonRow

        anchors.right: parent.right
        spacing: 0

        HeaderButton {
            id: settingsButton

            iconSource: Qt.resolvedUrl("icons/feather/stngs.svg")
            maskIcon: true
            Accessible.name: i18n("System Settings")

            onClicked: {
                KCM.KCMLauncher.openSystemSettings("kcm_landingpage");
                header.launcher.close();
            }
        }

        Repeater {
            model: systemModel

            delegate: HeaderButton {
                id: actionButton

                required property int index
                required property var model

                iconSource: actionButton.model.decoration
                visible: header.pinnedActions.includes(actionButton.model.favoriteId)
                Accessible.name: actionButton.model.display

                onClicked: {
                    header.launcher.close();
                    systemModel.trigger(actionButton.index, "", null);
                }
            }
        }

        HeaderButton {
            id: leaveButton

            iconSource: Qt.resolvedUrl("icons/feather/pwr.svg")
            maskIcon: true
            Accessible.role: Accessible.ButtonMenu
            Accessible.name: i18n("Leave")
            // Look pressed while the menu is open
            down: contextMenu.status === PlasmaExtras.Menu.Open || leaveButton.pressed

            Keys.onLeftPressed: event => {
                if (Application.layoutDirection === Qt.LeftToRight) {
                    leaveButton.nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason);
                }
            }
            Keys.onRightPressed: event => {
                if (Application.layoutDirection === Qt.RightToLeft) {
                    leaveButton.nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason);
                }
            }

            onPressed: contextMenu.openRelative()
        }
    }

    // The leave menu lists the actions that aren't pinned as buttons
    Instantiator {
        model: systemModel

        delegate: PlasmaExtras.MenuItem {
            id: menuItem

            required property int index
            required property var model

            text: menuItem.model.display
            icon: menuItem.model.decoration
            visible: !header.pinnedActions.includes(menuItem.model.favoriteId)

            onClicked: {
                header.launcher.close();
                systemModel.trigger(menuItem.index, "", null);
            }
        }

        onObjectAdded: (index, object) => contextMenu.addMenuItem(object as PlasmaExtras.MenuItem)
        onObjectRemoved: (index, object) => contextMenu.removeMenuItem(object as PlasmaExtras.MenuItem)
    }

    PlasmaExtras.Menu {
        id: contextMenu

        visualParent: leaveButton
        placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
    }
}
