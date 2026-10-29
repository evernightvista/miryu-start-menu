import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: searchBar

    required property LauncherState launcher
    required property bool searching

    property alias textField: textField

    radius: 10

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Kirigami.Icon {
            id: searchIcon

            source: Qt.resolvedUrl("icons/feather/search.svg")
            isMask: true
            color: Kirigami.Theme.textColor

            Layout.preferredWidth: 21
            Layout.preferredHeight: 21
            Layout.margins: 10
        }

        TextField {
            id: textField

            font.pointSize: 12
            placeholderText: i18n("Search...")
            focus: true

            background: Rectangle {
                color: "transparent"
            }

            Layout.fillHeight: true
            Layout.fillWidth: true

            onTextChanged: {
                textField.forceActiveFocus(Qt.ShortcutFocusReason);
                searchBar.launcher.runnerModel.query = textField.text;
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    if (searchBar.searching) {
                        textField.clear();
                    } else {
                        searchBar.launcher.close();
                    }
                }
            }
        }
    }
}
