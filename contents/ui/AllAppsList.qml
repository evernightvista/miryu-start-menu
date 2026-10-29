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
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

LauncherPage {
    id: allApps

    // The All Apps pages: one per menu category, starting with "All Applications"
    // (rootModel rows 0-1 are the recents models)
    readonly property var appsCategoriesList: {
        const model = allApps.launcher.rootModel;
        const categories = [];
        for (let i = 2; i < model.count; i++) {
            const modelIndex = model.index(i, 0);
            const name = model.data(modelIndex, Qt.DisplayRole);
            // Skip empty entries. Kicker inserts a blank separator row between
            // "All Applications" and the categories; rendered as a chip it became
            // an empty, clickable placeholder that selected a blank category. It
            // must never become a selectable page, so it is dropped entirely.
            if (name === undefined || name === null || String(name).trim() === "") {
                continue;
            }
            categories.push({
                name: name,
                index: i,
                icon: model.data(modelIndex, Qt.DecorationRole)
            });
        }
        return categories;
    }

    property int currentStateIndex: allApps.defaultStateIndex()

    // The selected category; falls back to the first one if the index is out of range
    readonly property var currentCategory: {
        const list = allApps.appsCategoriesList;
        if (list.length === 0) {
            return undefined;
        }
        const index = allApps.currentStateIndex;
        return list[index >= 0 && index < list.length ? index : 0];
    }

    // The model shown by the current view
    readonly property var shownModel: allApps.launcher.rootModel.modelForRow(allApps.currentCategory ? allApps.currentCategory.index : 2)

    readonly property bool showItemsInGrid: Plasmoid.configuration.showItemsInGrid

    // The configured page may not exist on this system (category lists differ between installs)
    function defaultStateIndex(): int {
        const page = Plasmoid.configuration.defaultPage;
        return (page >= 0 && page < allApps.appsCategoriesList.length) ? page : 0;
    }

    function incrementCurrentStateIndex(): void {
        allApps.currentStateIndex = (allApps.currentStateIndex + 1) % Math.max(allApps.appsCategoriesList.length, 1);
    }

    function decrementCurrentStateIndex(): void {
        const count = Math.max(allApps.appsCategoriesList.length, 1);
        allApps.currentStateIndex = (allApps.currentStateIndex - 1 + count) % count;
    }

    function resetCurrentStateIndex(): void {
        allApps.currentStateIndex = allApps.defaultStateIndex();
    }

    viewItem: appViewLoader.item as Item

    Connections {
        target: allApps.launcher

        function onMenuOpenChanged(): void {
            allApps.resetCurrentStateIndex();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        // One chip per category
        ListView {
            id: categoryBar

            orientation: ListView.Horizontal
            spacing: Kirigami.Units.smallSpacing
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: allApps.appsCategoriesList
            currentIndex: allApps.currentStateIndex
            highlightFollowsCurrentItem: false
            implicitHeight: Kirigami.Units.gridUnit * 1.75

            Layout.fillWidth: true

            onCurrentIndexChanged: categoryBar.positionViewAtIndex(categoryBar.currentIndex, ListView.Contain)

            delegate: PlasmaComponents.ToolButton {
                id: chip

                required property var modelData
                required property int index

                height: categoryBar.height
                text: chip.modelData.name
                checkable: true
                checked: chip.index === allApps.currentStateIndex
                focusPolicy: Qt.NoFocus
                // Safety net: an empty placeholder row must never be interactive.
                enabled: chip.modelData && String(chip.modelData.name || "").trim() !== ""
                font.family: allApps.launcher.textFont
                font.pointSize: allApps.launcher.textSize * 0.9

                onClicked: allApps.currentStateIndex = chip.index
            }

            // Lets a plain mouse wheel scroll the chips sideways
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse
                onWheel: event => {
                    categoryBar.flick(event.angleDelta.y * 8, 0);
                }
            }
        }

        Loader {
            id: appViewLoader

            sourceComponent: allApps.showItemsInGrid ? applicationsGridViewComponent : applicationsListViewComponent

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Component {
        id: applicationsListViewComponent

        AppListView {
            launcher: allApps.launcher
            showSectionSeparator: false
            model: allApps.shownModel
        }
    }

    Component {
        id: applicationsGridViewComponent

        AppGridView {
            launcher: allApps.launcher
            model: allApps.shownModel
        }
    }
}
