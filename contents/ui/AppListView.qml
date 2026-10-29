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
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras

ListView {
    id: listView

    required property LauncherState launcher

    readonly property real availableWidth: listView.width - verticalScrollBar.width

    property bool showSectionSeparator: true

    // This helps to prevent list focus back to cursor position when search changes
    property var interceptedPosition: null
    property bool blockingHoverFocus: false

    // This helps to prevent focus getting back to cursor position when navigating through the list
    property bool movedWithKeyboard: false
    property bool movedWithWheel: false

    function focusCurrentItem(event: KeyEvent, focusReason: int): void {
        listView.currentItem.forceActiveFocus(focusReason);
        event.accepted = true;
    }

    // Skips separators, which can't be selected
    function currentIsSeparator(): bool {
        const item = listView.currentItem as AppListViewDelegate;
        return item !== null && item.isSeparator;
    }

    Accessible.role: Accessible.List

    focus: true
    clip: true
    currentIndex: listView.count > 0 ? 0 : -1
    interactive: listView.height < listView.contentHeight
    boundsBehavior: Flickable.StopAtBounds
    // default keyboard navigation doesn't allow focus reasons to be used
    // and eats up/down key events when at the beginning or end of the list.
    keyNavigationEnabled: false
    keyNavigationWraps: false
    // This is actually needed. The highlight will animate from thin to wide otherwise.
    highlightResizeDuration: 0
    highlightMoveDuration: 50
    highlight: Highlight {
        width: listView.width - listView.leftMargin - listView.rightMargin
    }
    delegate: AppListViewDelegate {
        width: listView.availableWidth
        listView: listView
        launcher: listView.launcher
        triggerModel: listView.model
    }

    move: normalTransition
    moveDisplaced: normalTransition

    onModelChanged: listView.currentIndex = 0

    section {
        property: listView.showSectionSeparator ? "group" : "nosection"
        criteria: ViewSection.FullString
        delegate: PlasmaExtras.ListSectionHeader {
            required property string section
            width: listView.availableWidth
            text: section
        }
    }

    PC3.ScrollBar.vertical: PC3.ScrollBar {
        id: verticalScrollBar

        parent: listView
        z: 2
        height: listView.height
        anchors.right: parent.right
    }

    Keys.onPressed: event => {
        const currentIndex = listView.currentIndex;
        const count = listView.count;
        const targetX = listView.currentItem ? listView.currentItem.x : listView.contentX;
        let targetY = listView.currentItem ? listView.currentItem.y : listView.contentY;
        let targetIndex = currentIndex;
        const atFirst = currentIndex === 0;
        const atLast = currentIndex === count - 1;
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        if (count >= 1) {
            switch (event.key) {
            case Qt.Key_Up: if (!atFirst) {
                listView.decrementCurrentIndex();
                if (listView.currentIsSeparator()) {
                    listView.decrementCurrentIndex();
                }
                listView.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_K: if (!atFirst && ctrl) {
                listView.decrementCurrentIndex();
                listView.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_Down: if (!atLast) {
                listView.incrementCurrentIndex();
                if (listView.currentIsSeparator()) {
                    listView.incrementCurrentIndex();
                }
                listView.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_J: if (!atLast && ctrl) {
                listView.incrementCurrentIndex();
                listView.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_Home: if (!atFirst) {
                listView.currentIndex = 0;
                listView.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_End: if (!atLast) {
                listView.currentIndex = count - 1;
                listView.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_PageUp: if (!atFirst) {
                targetY = targetY - listView.height + 1;
                targetIndex = listView.indexAt(targetX, targetY);
                // TODO: Find a more efficient, but accurate way to do this
                while (targetIndex === -1) {
                    targetY += 1;
                    targetIndex = listView.indexAt(targetX, targetY);
                }
                listView.currentIndex = Math.max(targetIndex, 0);
                listView.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_PageDown: if (!atLast) {
                targetY = targetY + listView.height - 1;
                targetIndex = listView.indexAt(targetX, targetY);
                // TODO: Find a more efficient, but accurate way to do this
                while (targetIndex === -1) {
                    targetY -= 1;
                    targetIndex = listView.indexAt(targetX, targetY);
                }
                listView.currentIndex = Math.min(targetIndex, count - 1);
                listView.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_Return:
                /* Fall through*/
            case Qt.Key_Enter: {
                const item = listView.currentItem as AppListViewDelegate;
                if (item) {
                    item.trigger();
                    item.forceActiveFocus(Qt.ShortcutFocusReason);
                }
                event.accepted = true;
                break;
            }
            }
        }
        listView.movedWithKeyboard = event.accepted;
        if (listView.movedWithKeyboard) {
            movedWithKeyboardTimer.restart();
        }
    }

    Transition {
        id: normalTransition

        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            properties: "x, y"
            easing.type: Easing.OutCubic
        }
    }

    Kirigami.WheelHandler {
        target: listView
        filterMouseEvents: true
        // `20 * Application.styleHints.wheelScrollLines` is the default speed.
        horizontalStepSize: 20 * Application.styleHints.wheelScrollLines
        verticalStepSize: 20 * Application.styleHints.wheelScrollLines

        onWheel: wheel => {
            listView.movedWithWheel = true;
            listView.movedWithKeyboard = false;
            movedWithWheelTimer.restart();
        }
    }

    Connections {
        target: listView.launcher

        function onMenuOpenChanged(): void {
            if (!listView.launcher.menuOpen) {
                listView.currentIndex = 0;
                listView.positionViewAtBeginning();
            }
        }
    }

    // Used to block hover events temporarily after using keyboard navigation.
    // If you have one hand on the touch pad or mouse and another hand on the keyboard,
    // it's easy to accidentally reset the highlight/focus position to the mouse position.
    Timer {
        id: movedWithKeyboardTimer

        interval: 200
        onTriggered: listView.movedWithKeyboard = false
    }

    Timer {
        id: movedWithWheelTimer

        interval: 200
        onTriggered: listView.movedWithWheel = false
    }

    Connections {
        target: blockHoverFocusHandler
        enabled: blockHoverFocusHandler.enabled && !listView.interceptedPosition

        function onPointChanged(): void {
            listView.interceptedPosition = blockHoverFocusHandler.point.position;
        }
    }

    Connections {
        target: blockHoverFocusHandler
        enabled: blockHoverFocusHandler.enabled && listView.interceptedPosition && listView.blockingHoverFocus

        function onPointChanged(): void {
            if (blockHoverFocusHandler.point.position === listView.interceptedPosition) {
                return;
            }
            listView.blockingHoverFocus = false;
        }
    }

    HoverHandler {
        id: blockHoverFocusHandler

        enabled: !listView.interceptedPosition || listView.blockingHoverFocus
    }
}
