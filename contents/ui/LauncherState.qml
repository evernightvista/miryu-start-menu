/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

// Models, metrics and settings shared by every part of the launcher.
// main.qml creates one and each component receives it as `launcher`.
Item {
    id: launcher

    required property PlasmoidItem plasmoidItem

    // Whether the launcher window is open
    property bool menuOpen: false

    // Exposed as aliases rather than typed properties: inside plasmashell, Kicker's C++
    // types fail QML's type check when an object is assigned to a property of that type
    readonly property alias rootModel: rootModelObject
    readonly property alias runnerModel: runnerModelObject
    readonly property alias processRunner: processRunnerObject

    // Kicker's favorites models (QObject* in C++)
    readonly property QtObject globalFavorites: rootModelObject.favoritesModel
    readonly property QtObject systemFavorites: rootModelObject.systemFavoritesModel

    readonly property DragSource dragSource: DragSource {} // BUG 449426

    readonly property alias user: userObject

    readonly property alias highlightItemSvg: highlightItemSvgItem
    readonly property alias panelSvg: panelSvgItem
    readonly property alias dialogSvg: dialogSvgItem
    readonly property real scrollBarWidth: scrollBarMetrics.width

    // Grid metrics
    readonly property int iconSize: {
        switch (Plasmoid.configuration.appsIconSize) {
        case 0: return Kirigami.Units.iconSizes.smallMedium;
        case 1: return Kirigami.Units.iconSizes.medium;
        case 2: return Kirigami.Units.iconSizes.large;
        case 3: return Kirigami.Units.iconSizes.huge;
        default: return 64;
        }
    }
    readonly property int cellSizeHeight: launcher.iconSize
                                          + Kirigami.Units.gridUnit * 2
                                          + 2 * Math.max(highlightItemSvgItem.margins.top + highlightItemSvgItem.margins.bottom,
                                                         highlightItemSvgItem.margins.left + highlightItemSvgItem.margins.right)
    readonly property int cellSizeWidth: launcher.cellSizeHeight
    readonly property int rows: Plasmoid.configuration.numberOfRows

    // Text settings: always use the system font (the "Use system font" toggle
    // was removed — there is no longer a custom-font option).
    readonly property string textFont: Kirigami.Theme.defaultFont.family
    readonly property real textSize: Kirigami.Theme.defaultFont.pointSize
    // Whether the custom glow color is selected instead of a preset
    readonly property bool customGlow: Plasmoid.configuration.glowColor === 3
    readonly property color customGlowColor: Plasmoid.configuration.customGlowColor
    readonly property color glowColor1: {
        switch (Plasmoid.configuration.glowColor) {
        case 0: return "#D300DC";
        case 1: return "#20bdff";
        case 3: return launcher.customGlowColor;
        default: return "#ff005d";
        }
    }
    readonly property color glowColor2: {
        switch (Plasmoid.configuration.glowColor) {
        case 0: return "#8700FF";
        case 1: return "#5433ff";
        case 3: return Qt.darker(launcher.customGlowColor, 1.6);
        default: return "#ff8b26";
        }
    }

    // Emitted when the menu contents should return to their initial state
    signal reset

    component DragSource: Item {
        property Item sourceItem
        // Favorite id of the dragged app, empty for items that can't be favorites
        property string favoriteId
        Drag.dragType: Drag.Automatic
    }

    function close(): void {
        launcher.menuOpen = false;
    }

    function toggle(): void {
        launcher.menuOpen = !launcher.menuOpen;
    }

    // Lets the config page list the real All Apps pages (rows 0-1 are the recents models)
    function publishCategoryNames(): void {
        const model = launcher.rootModel;
        const names = [];
        for (let i = 2; i < model.count; i++) {
            const name = model.data(model.index(i, 0), Qt.DisplayRole);
            // Match AllAppsList.appsCategoriesList: drop the blank separator row so
            // the config's default-page indices line up with the real chips.
            if (name === undefined || name === null || String(name).trim() === "") {
                continue;
            }
            names.push(name);
        }
        if (names.length > 0 && names.join("\n") !== Plasmoid.configuration.categoryNames.join("\n")) {
            Plasmoid.configuration.categoryNames = names;
        }
    }

    Component.onCompleted: launcher.rootModel.refresh()

    Kicker.RootModel {
        id: rootModelObject

        autoPopulate: false

        appNameFormat: Plasmoid.configuration.appNameFormat
        flat: true
        sorted: true
        showSeparators: false
        appletInterface: launcher.plasmoidItem

        showAllApps: true
        showAllAppsCategorized: false
        showTopLevelItems: true
        showRecentApps: true
        showRecentDocs: true
        showPowerSession: false
        highlightNewlyInstalledApps: Plasmoid.configuration.highlightNewlyInstalledApps

        // Favorites are persisted by KActivities stats, keyed by this client id
        Component.onCompleted: rootModelObject.favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)

        onRefreshed: {
            launcher.reset();
            launcher.publishCategoryNames();
        }
    }

    Kicker.RunnerModel {
        id: runnerModelObject

        favoritesModel: launcher.globalFavorites
        appletInterface: launcher.plasmoidItem
        mergeResults: true
        // An empty list searches with every plugin enabled in System Settings
        runners: Plasmoid.configuration.useExtraRunners ? Plasmoid.configuration.extraRunners : []
    }

    Kicker.ProcessRunner {
        id: processRunnerObject
    }

    KCoreAddons.KUser {
        id: userObject
    }

    KSvg.FrameSvgItem {
        id: highlightItemSvgItem

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    KSvg.FrameSvgItem {
        id: panelSvgItem

        visible: false
        imagePath: "widgets/panel-background"
    }

    KSvg.FrameSvgItem {
        id: dialogSvgItem

        visible: false
        imagePath: "dialogs/background"
    }

    PlasmaComponents.ScrollBar {
        id: scrollBarMetrics

        visible: false
    }
}
