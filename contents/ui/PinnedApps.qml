pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.plasmoid

// Favorite apps, recent apps or recent files, depending on the "Main page" setting
LauncherPage {
    id: pinnedApps

    property Item searchField: null

    viewItem: pinnedAppsGrid

    DropArea {
        id: dropArea

        anchors.fill: parent

        // Reorders favorites while one is dragged within the grid
        onPositionChanged: drag => {
            if (drag.source !== pinnedApps.launcher.dragSource) {
                return;
            }
            const source = pinnedApps.launcher.dragSource.sourceItem as FavoriteItem;
            if (source === null || source.grid !== pinnedAppsGrid || Plasmoid.configuration.pinnedModel !== 0) {
                return;
            }
            const pos = dropArea.mapToItem(pinnedAppsGrid.contentItem, drag.x, drag.y);
            const targetIndex = pinnedAppsGrid.indexAt(pos.x, pos.y);
            if (targetIndex >= 0 && targetIndex !== source.index) {
                pinnedApps.launcher.globalFavorites.moveRow(source.index, targetIndex);
            }
        }

        AppGridView {
            id: pinnedAppsGrid

            anchors.fill: parent
            leftMargin: pinnedApps.launcher.scrollBarWidth / 1.5

            launcher: pinnedApps.launcher
            searchField: pinnedApps.searchField
            showScrollBar: false

            model: {
                switch (Plasmoid.configuration.pinnedModel) {
                case 1: return pinnedApps.launcher.rootModel.modelForRow(0); // Recent apps
                case 2: return pinnedApps.launcher.rootModel.modelForRow(1); // Recent files
                default: return pinnedApps.launcher.globalFavorites;
                }
            }
        }
    }
}
