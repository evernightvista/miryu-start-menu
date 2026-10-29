/*****************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>                   *
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                     *
 *   Copyright (C) 2021 by Prateek SU <pankajsunal123@gmail.com>             *
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
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmaCore.Dialog {
    id: root

    required property LauncherState launcher
    // The panel button the launcher opens from
    required property Item anchorItem

    objectName: "popupWindow"
    flags: Qt.WindowStaysOnTopHint

    // Docked location: PlasmaQuick lets popupPosition() drive x/y (so the "follow
    // the launcher button" option works) AND wires the window into KWin's slide
    // effect, which gives the open/close animation. Only "Screen center" needs the
    // free-floating location, where we position the window ourselves.
    // (This is exactly how miryu-start-main-rtm drives its animation.)
    location: Plasmoid.configuration.launcherPosition === 2 ? PlasmaCore.Types.Floating : Plasmoid.location
    // floating: 0 tells PlasmaQuick to drop the dialog frame border on the side
    // facing the panel, so the menu sits flush against the taskbar (no gap, no
    // overlap) — same approach as miryu-start-main-rtm.
    floating: 0
    hideOnWindowDeactivate: true
    visible: root.launcher.menuOpen

    onVisibleChanged: {
        // The window also hides itself when it loses focus
        root.launcher.menuOpen = root.visible;
        if (!root.visible) {
            // Reset only once the close animation is over. Relayouting the window
            // while it hides changed its height (and therefore its position), which
            // made the floating avatar slide away instead of fading out with the menu.
            // The timer lives inside MainView: a PlasmaCore.Dialog takes its
            // mainItem (a QQuickItem) as default property, so only items may be
            // declared directly here.
            mainView.scheduleReset();
        } else {
            mainView.cancelScheduledReset();
            root.updatePosition();
            root.requestActivate();
        }
    }

    onHeightChanged: root.updatePosition()
    onWidthChanged: root.updatePosition()

    function updatePosition(): void {
        const pos = root.popupPosition(root.width, root.height);
        root.x = pos.x;
        root.y = pos.y;
    }

    function popupPosition(width: real, height: real): point {
        // Use the *available* screen rect (excludes panels/docks) so the menu
        // never overlaps the taskbar. screenGeometry covers the whole screen
        // (panel included); subtracting anchor.height used to be unreliable
        // because the button height can be smaller than the real panel height
        // (applet container margins), pushing the menu into the panel.
        const screenGeom = root.launcher.plasmoidItem.screenGeometry;
        const screenAvail = root.launcher.plasmoidItem.availableScreenRect;
        const screen = Qt.rect(
            screenGeom.x + screenAvail.x,
            screenGeom.y + screenAvail.y,
            screenAvail.width > 0 ? screenAvail.width : screenGeom.width,
            screenAvail.height > 0 ? screenAvail.height : screenGeom.height
        );
        const anchor = root.anchorItem;
        const panelMargins = root.launcher.panelSvg.margins;

        // No floating offsets any more: the menu sits flush against the panel, as
        // in the original fixed3 layout. Only the fractions the panel itself needs
        // are kept.
        const position = Plasmoid.configuration.launcherPosition;

        let x = screen.x;
        let y = screen.y + screen.height - height;
        const horizMidPoint = screen.x + (screen.width / 2);
        const vertMidPoint = screen.y + (screen.height / 2);
        const appletTopLeft = anchor.mapToGlobal(0, 0);

        // Vertical panels: open beside the panel instead of over it
        if (position !== 2
            && (Plasmoid.location === PlasmaCore.Types.LeftEdge || Plasmoid.location === PlasmaCore.Types.RightEdge)) {
            if (Plasmoid.location === PlasmaCore.Types.LeftEdge) {
                x = appletTopLeft.x + anchor.width + panelMargins.right;
            } else {
                x = appletTopLeft.x - width - panelMargins.left;
            }
            if (position === 1) {
                y = vertMidPoint - height / 2;
            } else {
                y = Math.max(screen.y, Math.min(appletTopLeft.y, screen.y + screen.height - height));
            }
            return Qt.point(x, y);
        }

        if (position === 2) {
            // Screen center: the panel button is not taken into account at all
            x = horizMidPoint - width / 2;
        } else if (position === 0) {
            // Follow the panel button (the default): the menu is centred on it and
            // pushed back inside the screen when the button sits at either end of
            // the panel. A centred button gives a centred menu, a button on the far
            // left gives a menu flush with the left screen edge (mirrored right).
            x = appletTopLeft.x + anchor.width / 2 - width / 2;
            x = Math.max(screen.x, Math.min(x, screen.x + screen.width - width));
        } else if (position === 1) {
            x = horizMidPoint - width / 2;
        } else {
            // Panel edge: stick to the screen edge the button is closest to
            x = (appletTopLeft.x < horizMidPoint) ? screen.x : (screen.x + screen.width) - width;
        }

        if (position !== 2) {
            if (Plasmoid.location === PlasmaCore.Types.TopEdge) {
                // screen.y is the bottom edge of the top panel (the available area
                // starts there), so the menu begins directly under the panel. The
                // avatar is drawn inside the menu in this layout (see MainView.isTop),
                // so no extra room has to be reserved above it.
                y = screen.y;
            } else {
                // screen.y + screen.height is the top edge of the bottom panel
                // (the available area ends there). Subtracting the menu height puts
                // the menu flush on top of the taskbar.
                y = screen.y + screen.height - height;
            }
        } else {
            y = vertMidPoint - height / 2;
        }

        return Qt.point(x, y);
    }

    FocusScope {
        id: content

        // A uniform margin around MainView across Plasma themes
        readonly property real innerPadding: 15

        focus: true
        // Sized up front (not only via Layout) so the dialog never sees empty content when first shown
        width: content.Layout.minimumWidth
        height: content.Layout.minimumHeight

        Layout.minimumWidth: root.launcher.cellSizeWidth * Plasmoid.configuration.numberColumns
                             + root.launcher.scrollBarWidth
                             + content.innerPadding * 2
        Layout.minimumHeight: mainView.contentHeight + content.innerPadding / 2
        Layout.maximumWidth: content.Layout.minimumWidth
        Layout.maximumHeight: content.Layout.minimumHeight

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.launcher.close();
            }
        }

        Connections {
            target: root.launcher

            function onReset(): void {
                mainView.reset();
            }
        }

        // Extends over the dialog's frame margins, so the padding above is all MainView gets
        Item {
            x: -root.launcher.dialogSvg.margins.left
            y: -root.launcher.dialogSvg.margins.top
            width: content.width + root.launcher.dialogSvg.margins.left + root.launcher.dialogSvg.margins.right
            height: content.height + root.launcher.dialogSvg.margins.top + root.launcher.dialogSvg.margins.bottom

            MainView {
                id: mainView

                anchors.fill: parent
                anchors.margins: content.innerPadding

                launcher: root.launcher
                dialog: root
            }
        }
    }
}
