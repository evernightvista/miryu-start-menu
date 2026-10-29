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
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

import "../code/tools.js" as Tools

Item {
    id: favItem

    required property var model
    required property int index
    required property url url
    required property AppGridView grid
    required property LauncherState launcher
    // The model this item belongs to; Kicker's model base class isn't exposed to QML
    required property var triggerModel

    readonly property bool hasActionList: favItem.model.favoriteId !== null
                                          || ("hasActionList" in favItem.model && favItem.model.hasActionList !== null)
    readonly property bool isCurrentItem: favItem.GridView.isCurrentItem

    function openActionMenu(visualParent: Item, x: real, y: real): void {
        const actionList = favItem.model.hasActionList !== null ? favItem.model.actionList : [];
        Tools.fillActionMenu(i18n, actionMenu, actionList, favItem.launcher.globalFavorites, favItem.model.favoriteId);
        actionMenu.visualParent = visualParent;
        actionMenu.open(x, y);
    }

    function trigger(): void {
        favItem.triggerModel.trigger(favItem.index, "", null);
        favItem.launcher.close();
    }

    function actionTriggered(actionId: string, actionArgument: var): void {
        if (Tools.triggerAction(favItem.triggerModel, favItem.index, actionId, actionArgument) === true) {
            favItem.launcher.close();
        }
    }

    function performDrag(handler: DragHandler): void {
        const dragSource = favItem.launcher.dragSource;
        if (!handler.active) {
            dragSource.Drag.active = false;
            dragSource.Drag.imageSource = "";
            dragSource.sourceItem = null;
            dragSource.favoriteId = "";
            return;
        }
        appicon.grabToImage(result => {
            if (!handler.active) {
                return;
            }
            dragSource.sourceItem = favItem;
            dragSource.favoriteId = favItem.model.favoriteId ?? "";
            dragSource.Drag.imageSource = result.url;
            dragSource.Drag.mimeData = {
                "text/uri-list": [favItem.url]
            };
            dragSource.Drag.active = handler.active;
        });
    }

    width: favItem.launcher.cellSizeWidth
    height: favItem.launcher.cellSizeHeight
    z: dragHandler.active ? 4 : 1

    Kirigami.Icon {
        id: appicon

        y: 2 * favItem.launcher.highlightItemSvg.margins.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: favItem.launcher.iconSize
        height: appicon.width
        source: favItem.model.decoration

        NewAppBadge {
            anchors.top: parent.top
            anchors.right: parent.right
            visible: favItem.model.isNewlyInstalled === true
        }
    }

    PlasmaComponents.Label {
        id: appname

        anchors {
            top: appicon.bottom
            left: parent.left
            right: parent.right
            topMargin: Kirigami.Units.smallSpacing
            leftMargin: Kirigami.Units.smallSpacing
            rightMargin: Kirigami.Units.smallSpacing
        }

        text: "name" in favItem.model ? favItem.model.name : favItem.model.display
        font.family: favItem.launcher.textFont
        font.pointSize: favItem.launcher.textSize
        color: Kirigami.Theme.textColor
        textFormat: Text.PlainText
        elide: Text.ElideMiddle
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 2
        wrapMode: Text.Wrap
    }

    // Glow around the current item's icon and name
    component Glow: MultiEffect {
        visible: Plasmoid.configuration.enableGlow
        opacity: favItem.isCurrentItem ? 1 : 0
        shadowEnabled: true
        shadowColor: favItem.launcher.glowColor1
        shadowBlur: 0.9
        blurMax: 16

        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
    }

    Glow {
        anchors.fill: appicon
        source: appicon
    }

    Glow {
        anchors.fill: appname
        source: appname
    }

    MouseArea {
        id: ma

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: !favItem.grid.movedWithWheel

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (favItem.hasActionList) {
                    favItem.openActionMenu(favItem, mouse.x, mouse.y);
                }
            } else {
                favItem.trigger();
            }
        }

        onEntered: {
            // When the movedWithKeyboard condition is broken, we do not want to
            // select the hovered item without moving the mouse.
            if (favItem.grid.movedWithKeyboard) {
                return;
            }

            // forceActiveFocus() touches multiple items, so check for
            // activeFocus first to be more efficient.
            if (!favItem.grid.activeFocus) {
                favItem.grid.forceActiveFocus(Qt.MouseFocusReason);
            }
            // No need to check currentIndex first because it's
            // built into QQuickListView::setCurrentIndex() already
            favItem.grid.currentIndex = favItem.index;
        }
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: (actionId, actionArgument) => favItem.actionTriggered(actionId, actionArgument)
    }

    DragHandler {
        id: dragHandler

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
        target: null // Using this Item fixes drag and drop causing delegates to reset to a 0 X position and overlapping each other.
        onActiveChanged: favItem.performDrag(dragHandler)
    }
}
