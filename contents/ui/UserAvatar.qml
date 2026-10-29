import QtQuick
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.plasma.plasmoid

Item {
    id: avatar

    required property LauncherState launcher

    readonly property color borderGradientColor1: {
        switch (Plasmoid.configuration.glowColor) {
        case 0: return "#FEAC5E";
        case 1: return "#a5fecb";
        case 3: return Qt.lighter(avatar.launcher.customGlowColor, 1.4);
        default: return "#ff005d";
        }
    }
    readonly property color borderGradientColor2: {
        switch (Plasmoid.configuration.glowColor) {
        case 0: return "#C779D0";
        case 1: return "#20bdff";
        case 3: return avatar.launcher.customGlowColor;
        default: return "#ff005c";
        }
    }
    readonly property color borderGradientColor3: {
        switch (Plasmoid.configuration.glowColor) {
        case 0: return "#4BC0C8";
        case 1: return "#5433ff";
        case 3: return Qt.darker(avatar.launcher.customGlowColor, 1.6);
        default: return "#ff8b26";
        }
    }

    // Off-screen loader. It always reads the face icon through a *unique*,
    // cache-busting URL so a stale pixmap is never reused. The visible
    // AvatarButton only swaps to the new source once the image is fully decoded
    // (Image.Ready), so the previous image stays on screen until the new one is
    // ready — there is never a "fallback initials" flash and never a stale image.
    Image {
        id: preloader

        visible: false

        onStatusChanged: {
            if (status === Image.Ready) {
                mainFaceIcon.source = preloader.source;
            }
        }
    }

    KirigamiComponents.AvatarButton {
        id: mainFaceIcon

        anchors {
            fill: parent
            margins: Kirigami.Units.smallSpacing
        }
        source: avatar.launcher.user.faceIconUrl

        onClicked: {
            KCM.KCMLauncher.openSystemSettings("kcm_users");
            avatar.launcher.close();
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }

    // Each reload gets a fresh token so the URL is unique and Qt's pixmap cache
    // is bypassed — the new image is always read from disk.
    property int avatarLoadToken: 0

    function reloadAvatar(): void {
        const url = avatar.launcher.user.faceIconUrl;
        if (!url) {
            mainFaceIcon.source = "";
            return;
        }
        preloader.source = url + "?v=" + (++avatar.avatarLoadToken);
    }

    // The underlying face-icon file changed (e.g. the user saved a new avatar in
    // System Settings): reload so the image updates immediately, without waiting
    // for the menu to reopen.
    Connections {
        target: avatar.launcher.user

        function onFaceIconUrlChanged(): void {
            avatar.reloadAvatar();
        }
    }

    // Reload on every menu open so an avatar changed while the menu was closed
    // (or in another application) is picked up right away.
    Connections {
        target: avatar.launcher

        function onMenuOpenChanged(): void {
            if (avatar.launcher.menuOpen) {
                avatar.reloadAvatar();
            }
        }
    }

    // Gradient ring behind the avatar
    Rectangle {
        anchors.centerIn: mainFaceIcon
        width: avatar.width - 4 // Smaller than the avatar to prevent fringing
        height: width
        radius: width / 2
        visible: Plasmoid.configuration.enableGlow
        z: -1
        rotation: 270
        transformOrigin: Item.Center

        gradient: Gradient {
            GradientStop { position: 0.0; color: avatar.borderGradientColor1 }
            GradientStop { position: 0.33; color: avatar.borderGradientColor2 }
            GradientStop { position: 1.0; color: avatar.borderGradientColor3 }
        }
    }
}
