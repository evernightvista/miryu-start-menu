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
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

import "../code/tools.js" as Tools

T.ItemDelegate {
    id: allItem

    required property var model
    required property int index
    required property AppListView listView
    required property LauncherState launcher
    // The model this item belongs to; Kicker's model base class isn't exposed to QML
    required property var triggerModel

    readonly property bool compact: Plasmoid.configuration.compactListItems
    readonly property bool isSeparator: allItem.model.isSeparator === true
    readonly property bool hasActionList: allItem.model.favoriteId !== null
                                          || ("hasActionList" in allItem.model && allItem.model.hasActionList !== null)

    function openActionMenu(x: real, y: real): void {
        const actionList = allItem.hasActionList ? allItem.model.actionList : [];
        Tools.fillActionMenu(i18n, actionMenu, actionList, allItem.launcher.globalFavorites, allItem.model.favoriteId);
        actionMenu.visualParent = allItem;
        actionMenu.open(x, y);
    }

    function actionTriggered(actionId: string, actionArgument: var): void {
        if (Tools.triggerAction(allItem.triggerModel, allItem.index, actionId, actionArgument) === true) {
            allItem.launcher.close();
        }
    }

    function trigger(): void {
        allItem.triggerModel.trigger(allItem.index, "", null);
        allItem.launcher.close();
    }

    function performDrag(handler: DragHandler): void {
        const dragSource = allItem.launcher.dragSource;
        if (!handler.active) {
            dragSource.Drag.active = false;
            dragSource.Drag.imageSource = "";
            dragSource.sourceItem = null;
            dragSource.favoriteId = "";
            return;
        }
        appIcon.grabToImage(result => {
            if (!handler.active) {
                return;
            }
            dragSource.sourceItem = allItem;
            dragSource.favoriteId = allItem.model.favoriteId ?? "";
            dragSource.Drag.imageSource = result.url;
            dragSource.Drag.mimeData = {
                "text/uri-list": [allItem.model.url]
            };
            dragSource.Drag.active = handler.active;
        });
    }

    implicitWidth: Math.max(allItem.implicitBackgroundWidth + allItem.leftInset + allItem.rightInset,
                            allItem.implicitContentWidth + allItem.leftPadding + allItem.rightPadding)
    implicitHeight: Math.max(allItem.implicitBackgroundHeight + allItem.topInset + allItem.bottomInset,
                             allItem.implicitContentHeight + allItem.topPadding + allItem.bottomPadding)
    leftPadding: allItem.compact ? 5 : 8
    rightPadding: allItem.compact ? 5 : 8
    bottomPadding: allItem.compact ? 5 : 8
    topPadding: allItem.compact ? 5 : 8

    contentItem: RowLayout {
        id: row

        spacing: 8

        Kirigami.Icon {
            id: appIcon

            implicitWidth: allItem.compact ? Kirigami.Units.iconSizes.smallMedium : Kirigami.Units.iconSizes.medium
            implicitHeight: appIcon.implicitWidth
            source: allItem.model.decoration

            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

            NewAppBadge {
                anchors.top: parent.top
                anchors.right: parent.right
                visible: allItem.model.isNewlyInstalled === true
            }
        }

        GridLayout {
            id: gridLayout

            rows: allItem.compact ? 1 : 2
            columns: allItem.compact ? 2 : 1
            rowSpacing: 0
            columnSpacing: Kirigami.Units.largeSpacing

            Layout.fillWidth: true

            Label {
                id: label

                text: "name" in allItem.model ? allItem.model.name : allItem.model.display
                textFormat: Text.PlainText
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                verticalAlignment: Text.AlignVCenter
                color: Kirigami.Theme.textColor

                Layout.fillWidth: !descriptionLabel.visible
                Layout.maximumWidth: allItem.width - allItem.leftPadding - allItem.rightPadding - appIcon.width - row.spacing
            }

            Label {
                id: descriptionLabel

                visible: descriptionLabel.text.length > 0
                opacity: 0.75
                text: allItem.model.description ?? ""
                textFormat: Text.PlainText
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: allItem.compact ? Text.AlignRight : Text.AlignLeft
                maximumLineCount: 1
                color: Kirigami.Theme.textColor

                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: ma

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: !allItem.listView.movedWithWheel && !allItem.listView.blockingHoverFocus

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (allItem.hasActionList) {
                    allItem.openActionMenu(mouse.x, mouse.y);
                }
            } else {
                allItem.trigger();
            }
        }

        onEntered: {
            // When the movedWithKeyboard condition is broken, we do not want to
            // select the hovered item without moving the mouse.
            if (allItem.listView.movedWithKeyboard) {
                return;
            }

            // forceActiveFocus() touches multiple items, so check for
            // activeFocus first to be more efficient.
            if (!allItem.listView.activeFocus) {
                allItem.listView.forceActiveFocus(Qt.MouseFocusReason);
            }
            // No need to check currentIndex first because it's
            // built into QQuickListView::setCurrentIndex() already
            allItem.listView.currentIndex = allItem.index;
        }
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: (actionId, actionArgument) => allItem.actionTriggered(actionId, actionArgument)
    }

    DragHandler {
        id: dragHandler

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
        enabled: !!allItem.model.url
        target: null
        onActiveChanged: allItem.performDrag(dragHandler)
    }
}
