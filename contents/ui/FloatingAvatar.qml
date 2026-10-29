/*****************************************************************************
 *   Copyright (C) 2022 by Friedrich Schriewer <friedrich.schriewer@gmx.net> *
 *                                                                           *
 *   This program is free software; you can redistribute it and/or modify    *
 *   the terms of the GNU General Public License as published by the Free    *
 *   Software Foundation; either version 2 of the License, or                *
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

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

// The user's avatar, floating over the top edge of the launcher window.
//
// It is a separate PlasmaCore.Dialog window so it can overflow above the menu.
// The avatar window has no docked location (it uses PlasmaCore.Types.Floating),
// so the compositor applies no slide/open effect to it. Instead, while the menu
// opens the avatar rises up from the greeting line to its place above the menu,
// and while the menu closes it sinks back down to the greeting line. Its
// on-screen position is tracked every frame by a plain binding to the menu
// window's live geometry, which keeps it glued to the top edge of the menu.
PlasmaCore.Dialog {
    id: avatarContainer

    required property LauncherState launcher
    // The launcher window this avatar sits on
    required property PlasmaCore.Dialog anchorWindow

    property int avatarWidth
    // Top panels keep the avatar inside the menu, so this window is hidden there
    property bool topPanel: false

    // No docked location: with Floating the compositor applies no slide/open
    // effect, so the avatar simply appears and disappears together with the menu
    // instead of animating (sliding) in and out.
    location: PlasmaCore.Types.Floating
    floating: 0
    // A Notification popup: PlasmaQuick sizes and stacks it itself, which is what
    // keeps the avatar at exactly avatarWidth. (A plain Dialog window is not
    // content-sized: it opens with the compositor default size and the avatar is
    // stretched to fill it.)
    type: PlasmaCore.Dialog.Notification
    backgroundHints: PlasmaCore.Dialog.NoBackground

    // ---------------------------------------------------------------------
    // Visibility
    // ---------------------------------------------------------------------
    // The avatar is shown while the menu is open, and it is kept on screen a
    // little longer while it sinks back down after the menu closed. Visibility is
    // set imperatively (instead of bound to the menu window) so the menu hiding
    // can't cut the close animation short.
    property bool closing: false

    function updateVisibility(): void {
        avatarContainer.visible = (avatarContainer.anchorWindow.visible || avatarContainer.closing)
                                  && avatarContainer.avatarWidth > 0
                                  && !avatarContainer.topPanel;
    }

    // ---------------------------------------------------------------------
    // Open / close animation
    // ---------------------------------------------------------------------
    // Distance in px the avatar travels from the greeting line up to its resting
    // place above the menu's top edge. The greeting sits ~50 px below the menu's
    // top edge (see MainView) and the avatar is centred on that edge, hence ~64.
    property real revealDistance: 64
    // 0 = resting on the greeting line (menu closed), 1 = final position
    property real reveal: 1

    // ---------------------------------------------------------------------
    // Size
    // ---------------------------------------------------------------------
    // PlasmaQuick keeps mainItem and the window geometry in sync: the window is
    // sized from mainItem (DialogPrivate::syncToMainItemSize) and mainItem is
    // resized to the window (Dialog::resizeEvent). The avatar window is created
    // as a *child* of the launcher window, so the compositor can give it the
    // launcher's geometry first; mainItem then follows the window and the avatar
    // is painted at window size — the giant circle.
    //
    // Pinning minimum == maximum makes the window un-resizable: every resize goes
    // through QWindow::resize(), which clamps to those limits, so the window can
    // never become larger than the avatar and mainItem follows it back to
    // avatarWidth. PlasmaQuick resets the limits in setMainItem(), so they are
    // asserted again once the component is complete and whenever the window is
    // shown.
    function pinSize(): void {
        const size = avatarContainer.avatarWidth;

        if (size <= 0) {
            return;
        }

        avatarContainer.minimumWidth = size;
        avatarContainer.maximumWidth = size;
        avatarContainer.minimumHeight = size;
        avatarContainer.maximumHeight = size;
        avatarContainer.width = size;
        avatarContainer.height = size;
    }

    Component.onCompleted: {
        pinSize();
        updateVisibility();
    }
    onAvatarWidthChanged: {
        pinSize();
        updateVisibility();
    }
    onClosingChanged: updateVisibility()
    onTopPanelChanged: updateVisibility()

    onVisibleChanged: {
        if (avatarContainer.visible) {
            pinSize();
            // PlasmaQuick sizes the window from mainItem while it is being shown,
            // so the limits have to be asserted again afterwards.
            Qt.callLater(pinSize);
        }
    }

    // ---------------------------------------------------------------------
    // Position: always follow the live menu geometry
    // ---------------------------------------------------------------------
    // No caching: the avatar must travel with the menu, never freeze in place.
    // (Only plain properties may be declared here: a PlasmaCore.Dialog takes its
    // mainItem as default property, so non-visual objects such as Timer or Binding
    // would be assigned to it and break the whole component.)
    readonly property rect anchorRect: Qt.rect(avatarContainer.anchorWindow.x,
                                               avatarContainer.anchorWindow.y,
                                               avatarContainer.anchorWindow.width,
                                               avatarContainer.anchorWindow.height)

    // The window is centred on the top edge of the menu, and the avatar is centred
    // inside the window, so the avatar always ends up half above the menu even if
    // the window geometry is not what we asked for. `reveal` shifts it down onto
    // the greeting line while the menu is closed / opening / closing.
    x: anchorRect.x + anchorRect.width / 2 - avatarContainer.width / 2
    y: anchorRect.y - avatarContainer.height / 2
       + (1 - avatarContainer.reveal) * avatarContainer.revealDistance

    // ---------------------------------------------------------------------
    // Content
    // ---------------------------------------------------------------------
    // The dialog resizes mainItem to the window, so the avatar itself keeps a fixed
    // avatarWidth instead of filling its parent: that way it can never be stretched
    // to the window size.
    mainItem: Item {
        width: avatarContainer.avatarWidth
        height: avatarContainer.avatarWidth
        // Keeps PlasmaQuick from treating the first frame as an empty dialog.
        implicitWidth: avatarContainer.avatarWidth
        implicitHeight: avatarContainer.avatarWidth

        // Non-visual objects (Connections, Timer) must live inside mainItem: a
        // PlasmaCore.Dialog takes whatever is declared at its top level as the
        // mainItem (its default property), which breaks the whole component.
        Connections {
            target: avatarContainer.anchorWindow

            function onVisibleChanged() {
                if (avatarContainer.anchorWindow.visible) {
                    // Menu (re)opened: show the avatar after the menu window so it
                    // is stacked above it, and re-assert the size immediately and
                    // once more after the window is shown (PlasmaQuick re-syncs
                    // the window from mainItem while it is being shown).
                    avatarContainer.updateVisibility();
                    avatarContainer.pinSize();
                    Qt.callLater(avatarContainer.pinSize);
                }
            }
        }

        // Some compositors apply their own geometry to a freshly mapped child window,
        // which stretched the avatar again a moment after it appeared. Nudge the size
        // back once the window is mapped.
        Timer {
            interval: 80
            running: avatarContainer.visible
            repeat: false
            onTriggered: avatarContainer.pinSize()
        }

        // Menu opened: start at the greeting line and rise up. Driven from the
        // launcher state (not the window visibility) so `reveal` is already 0
        // before the window is mapped — the avatar never pops in at its final
        // position for a frame.
        Connections {
            target: avatarContainer.launcher

            function onMenuOpenChanged() {
                if (avatarContainer.launcher.menuOpen) {
                    avatarContainer.closing = false;
                    closeTimer.stop();
                    // Start at the greeting line, then map the window and rise up.
                    avatarContainer.reveal = 0;
                    avatarContainer.updateVisibility();
                    Qt.callLater(() => openAnimation.start());
                } else {
                    // Menu closed: keep the window mapped while it sinks down.
                    avatarContainer.closing = true;
                    openAnimation.stop();
                    closeAnimation.start();
                    closeTimer.restart();
                }
            }
        }

        NumberAnimation {
            id: openAnimation

            target: avatarContainer
            property: "reveal"
            to: 1
            duration: 150
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: closeAnimation

            target: avatarContainer
            property: "reveal"
            to: 0
            duration: 120
            easing.type: Easing.InCubic
        }

        Timer {
            id: closeTimer

            interval: 140
            onTriggered: avatarContainer.closing = false
        }

        UserAvatar {
            anchors.centerIn: parent
            width: avatarContainer.avatarWidth
            height: avatarContainer.avatarWidth

            launcher: avatarContainer.launcher

            // Fades and grows in while rising; the reverse while sinking down.
            opacity: Math.min(1, avatarContainer.reveal * 1.3)
            scale: 0.75 + 0.25 * avatarContainer.reveal
            transformOrigin: Item.Center
        }
    }
}
