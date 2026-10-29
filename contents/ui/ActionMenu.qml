/*
    SPDX-FileCopyrightText: 2013 Aurélien Gâteau <agateau@kde.org>
    SPDX-FileCopyrightText: 2014-2015 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.extras as PlasmaExtras

Item {
    id: root

    property PlasmaExtras.Menu menu
    property Item visualParent
    property var actionList
    readonly property bool opened: root.menu ? root.menu.status !== PlasmaExtras.Menu.Closed : false

    signal actionClicked(actionId: string, actionArgument: var)
    signal closed

    function open(x: real, y: real): void {
        if (!root.actionList) {
            return;
        }
        root.menu.open(x, y);
    }

    function refreshMenu(): void {
        if (root.menu) {
            root.menu.destroy();
        }

        if (!root.actionList) {
            return;
        }

        root.menu = contextMenuComponent.createObject(root) as PlasmaExtras.Menu;

        root.fillMenu(root.menu, root.actionList);
    }

    function fillMenu(menu: PlasmaExtras.Menu, items: var): void {
        items.forEach(actionItem => {
            if (actionItem.subActions) {
                // This is a menu
                const submenuItem = contextSubmenuItemComponent.createObject(menu, { "actionItem": actionItem }) as SubmenuItem;
                root.fillMenu(submenuItem.submenu, actionItem.subActions);
            } else {
                contextMenuItemComponent.createObject(menu, { "actionItem": actionItem });
            }
        });
    }

    onActionListChanged: root.refreshMenu()

    onOpenedChanged: {
        if (!root.opened) {
            root.closed();
        }
    }

    component SubmenuItem: PlasmaExtras.MenuItem {
        id: submenuItem

        property var actionItem

        property PlasmaExtras.Menu submenu: PlasmaExtras.Menu {
            visualParent: submenuItem.action
        }

        text: submenuItem.actionItem.text ? submenuItem.actionItem.text : ""
        icon: submenuItem.actionItem.icon ? submenuItem.actionItem.icon : null
    }

    Component {
        id: contextMenuComponent

        PlasmaExtras.Menu {
            visualParent: root.visualParent
        }
    }

    Component {
        id: contextSubmenuItemComponent

        SubmenuItem {}
    }

    Component {
        id: contextMenuItemComponent

        PlasmaExtras.MenuItem {
            id: menuItem

            property var actionItem

            text: menuItem.actionItem.text ? menuItem.actionItem.text : ""
            enabled: menuItem.actionItem.type !== "title" && ("enabled" in menuItem.actionItem ? menuItem.actionItem.enabled : true)
            separator: menuItem.actionItem.type === "separator"
            section: menuItem.actionItem.type === "title"
            icon: menuItem.actionItem.icon ? menuItem.actionItem.icon : null
            checkable: menuItem.actionItem.checkable ? menuItem.actionItem.checkable : false
            checked: menuItem.actionItem.checked ? menuItem.actionItem.checked : false

            onClicked: root.actionClicked(menuItem.actionItem.actionId, menuItem.actionItem.actionArgument)
        }
    }
}
