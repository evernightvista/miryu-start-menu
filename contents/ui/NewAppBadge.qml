/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami

// Dot marking an app that was installed recently and hasn't been opened yet
Rectangle {
    width: Math.round(Kirigami.Units.gridUnit / 2)
    height: width
    radius: width / 2
    color: Kirigami.Theme.highlightColor
    border.width: 1
    border.color: Kirigami.Theme.backgroundColor

    Accessible.name: i18nc("@info:tooltip", "Newly installed")
}
