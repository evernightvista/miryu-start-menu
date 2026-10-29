/***************************************************************************
 *   Copyright (C) 2014-2015 by Eike Hein <hein@kde.org>                   *
 *   Copyright (C) 2021 by Prateek SU <pankajsunal123@gmail.com>           *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: kicker

    // Let the Plasma shell draw the native hover highlight (Plasma 6 look).
    // While the menu is open the custom active-tab takes over, so suppress the
    // shell background then to avoid a double highlight.
    Plasmoid.backgroundHints: launcherState.menuOpen ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground

    preferredRepresentation: fullRepresentation

    compactRepresentation: null
    fullRepresentation: CompactRepresentation {
        launcher: launcherState
    }

    Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon

    // Native Plasma tooltip shown by the shell above the panel button (same
    // approach as miryu-start-main: toolTipMainText is a direct property of
    // the PlasmoidItem root, not a Plasmoid.* attached property).
    toolTipMainText: i18n("Start")

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications…")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: launcherState.processRunner.runMenuEditor()
        }
    ]

    LauncherState {
        id: launcherState

        plasmoidItem: kicker
    }
}
