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
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.plasma.plasmoid

GridView {
    id: grid

    required property LauncherState launcher
    // The search field; while it has focus, Left/Right move its text cursor instead
    property Item searchField: null

    property bool movedWithKeyboard: false
    property bool movedWithWheel: false

    property bool showScrollBar: true
    readonly property int columns: Plasmoid.configuration.numberColumns

    function focusCurrentItem(event: KeyEvent, focusReason: int): void {
        grid.currentItem.forceActiveFocus(focusReason);
        event.accepted = true;
    }

    focus: true
    clip: true
    currentIndex: grid.count > 0 ? 0 : -1
    interactive: grid.height < grid.contentHeight
    reuseItems: false
    boundsBehavior: Flickable.StopAtBounds
    // default keyboard navigation doesn't allow focus reasons to be used
    // and eats up/down key events when at the beginning or end of the list.
    keyNavigationEnabled: false
    keyNavigationWraps: false

    highlightMoveDuration: 0

    cellWidth: grid.launcher.cellSizeWidth
    cellHeight: grid.launcher.cellSizeHeight

    highlight: Highlight {
        hideBg: Plasmoid.configuration.enableGlow
    }

    delegate: FavoriteItem {
        grid: grid
        launcher: grid.launcher
        triggerModel: grid.model
    }

    move: normalTransition
    moveDisplaced: normalTransition

    onModelChanged: grid.currentIndex = 0

    PC3.ScrollBar.vertical: PC3.ScrollBar {
        id: verticalScrollBar

        parent: grid
        z: 2
        height: grid.height
        anchors.right: parent.right
        policy: grid.showScrollBar ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
    }

    Keys.onPressed: event => {
        const searchFieldFocused = grid.searchField !== null && grid.searchField.activeFocus;
        const columns = grid.columns;
        const currentIndex = grid.currentIndex;
        const count = grid.count;
        const mirrored = Application.layoutDirection === Qt.RightToLeft;
        const targetX = grid.currentItem ? grid.currentItem.x : grid.contentX;
        let targetY = grid.currentItem ? grid.currentItem.y : grid.contentY;
        let targetIndex = currentIndex;
        // supports mirroring
        const atLeft = currentIndex % columns === (mirrored ? columns - 1 : 0);
        // at the beginning of a line
        const isLeading = currentIndex % columns === 0;
        // at the top of a given column and in the top row
        const atTop = currentIndex < columns;
        // supports mirroring
        const atRight = currentIndex % columns === (mirrored ? 0 : columns - 1);
        // at the end of a line
        const isTrailing = currentIndex % columns === columns - 1;
        // at bottom of a given column, not necessarily in the last row
        const atBottom = currentIndex >= count - columns;
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        // Implements the keyboard navigation described in https://www.w3.org/TR/wai-aria-practices-1.2/#grid
        if (count > 1) {
            switch (event.key) {
            case Qt.Key_Left: if (!atLeft && !searchFieldFocused) {
                grid.moveCurrentIndexLeft();
                grid.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_H: if (!atLeft && !searchFieldFocused && ctrl) {
                grid.moveCurrentIndexLeft();
                grid.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_Up: if (!atTop) {
                grid.moveCurrentIndexUp();
                grid.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_K: if (!atTop && ctrl) {
                grid.moveCurrentIndexUp();
                grid.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_Right: if (!atRight && !searchFieldFocused) {
                grid.moveCurrentIndexRight();
                grid.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_L: if (!atRight && !searchFieldFocused && ctrl) {
                grid.moveCurrentIndexRight();
                grid.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_Down: if (!atBottom) {
                grid.moveCurrentIndexDown();
                grid.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_J: if (!atBottom && ctrl) {
                grid.moveCurrentIndexDown();
                grid.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_Home: if (event.modifiers === Qt.ControlModifier && currentIndex !== 0) {
                grid.currentIndex = 0;
                grid.focusCurrentItem(event, Qt.BacktabFocusReason);
            } else if (!isLeading) {
                targetIndex -= currentIndex % columns;
                grid.currentIndex = Math.max(targetIndex, 0);
                grid.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_End: if (event.modifiers === Qt.ControlModifier && currentIndex !== count - 1) {
                grid.currentIndex = count - 1;
                grid.focusCurrentItem(event, Qt.TabFocusReason);
            } else if (!isTrailing) {
                targetIndex += columns - 1 - (currentIndex % columns);
                grid.currentIndex = Math.min(targetIndex, count - 1);
                grid.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_PageUp: if (!atTop) {
                targetY = targetY - grid.height + 1;
                targetIndex = grid.indexAt(targetX, targetY);
                // TODO: Find a more efficient, but accurate way to do this
                while (targetIndex === -1) {
                    targetY += 1;
                    targetIndex = grid.indexAt(targetX, targetY);
                }
                grid.currentIndex = Math.max(targetIndex, 0);
                grid.focusCurrentItem(event, Qt.BacktabFocusReason);
            } break;
            case Qt.Key_PageDown: if (!atBottom) {
                targetY = targetY + grid.height - 1;
                targetIndex = grid.indexAt(targetX, targetY);
                // TODO: Find a more efficient, but accurate way to do this
                while (targetIndex === -1) {
                    targetY -= 1;
                    targetIndex = grid.indexAt(targetX, targetY);
                }
                grid.currentIndex = Math.min(targetIndex, count - 1);
                grid.focusCurrentItem(event, Qt.TabFocusReason);
            } break;
            case Qt.Key_Return:
                /* Fall through*/
            case Qt.Key_Enter: {
                const item = grid.currentItem as FavoriteItem;
                if (item) {
                    item.trigger();
                    item.forceActiveFocus(Qt.ShortcutFocusReason);
                }
                event.accepted = true;
                break;
            }
            }
        }
        grid.movedWithKeyboard = event.accepted;
        if (grid.movedWithKeyboard) {
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
        id: wheelHandler

        target: grid
        filterMouseEvents: true
        // `20 * Application.styleHints.wheelScrollLines` is the default speed.
        horizontalStepSize: 20 * Application.styleHints.wheelScrollLines
        verticalStepSize: 20 * Application.styleHints.wheelScrollLines

        onWheel: wheel => {
            grid.movedWithWheel = true;
            grid.movedWithKeyboard = false;
            movedWithWheelTimer.restart();
        }
    }

    Connections {
        target: grid.launcher

        function onMenuOpenChanged(): void {
            if (!grid.launcher.menuOpen) {
                grid.currentIndex = 0;
                grid.positionViewAtBeginning();
            }
        }
    }

    // Used to block hover events temporarily after using keyboard navigation.
    // If you have one hand on the touch pad or mouse and another hand on the keyboard,
    // it's easy to accidentally reset the highlight/focus position to the mouse position.
    Timer {
        id: movedWithKeyboardTimer

        interval: 200
        onTriggered: grid.movedWithKeyboard = false
    }

    Timer {
        id: movedWithWheelTimer

        interval: 200
        onTriggered: grid.movedWithWheel = false
    }
}
