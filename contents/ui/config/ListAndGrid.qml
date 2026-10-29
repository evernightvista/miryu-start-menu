import QtQuick
import QtQuick.Controls
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: listAndGrid

    property alias cfg_compactListItems: compactListItems.checked
    property alias cfg_showItemsInGrid: showItemsInGrid.checked
    property alias cfg_appsIconSize: appsIconSize.currentIndex
    property alias cfg_numberColumns: numberColumns.value
    property alias cfg_numberOfRows: numberOfRows.value
    property alias cfg_appNameFormat: appNameFormat.currentIndex
    property alias cfg_highlightNewlyInstalledApps: highlightNewlyInstalledApps.checked

    Kirigami.FormLayout {
        CheckBox {
            id: compactListItems

            Kirigami.FormData.label: i18n("Lists:")
            text: i18n("Compact list items")
        }

        CheckBox {
            id: showItemsInGrid

            Kirigami.FormData.label: i18n("All applications view:")
            text: i18n("show items in grid")
        }

        ComboBox {
            id: appNameFormat

            Kirigami.FormData.label: i18n("Show apps as:")
            model: [
                i18n("Name only"),
                i18n("Description only"),
                i18n("Name (Description)"),
                i18n("Description (Name)"),
            ]
        }

        CheckBox {
            id: highlightNewlyInstalledApps

            text: i18n("Mark newly installed apps")
        }

        ComboBox {
            id: appsIconSize

            Kirigami.FormData.label: i18n("Grid icon size:")
            model: [i18n("Small"), i18n("Medium"), i18n("Large"), i18n("Huge")]
        }

        SpinBox {
            id: numberColumns

            Kirigami.FormData.label: i18n("Number of columns in grid")
            from: 4
            to: 8
        }

        SpinBox {
            id: numberOfRows

            Kirigami.FormData.label: i18n("Number of rows in grid")
            from: 3
            to: 8
        }
    }
}
