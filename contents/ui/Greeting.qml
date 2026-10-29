import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Item {
    id: greeting

    required property LauncherState launcher

    property real textSize
    readonly property real textWidth: nameLabel.width

    // Reads the current hour (0..23) from the operating system clock.
    // NOTE: Qt6 removed Qt.formatDateTime(), so we use Date.getHours() which
    // returns a number directly and reads the system local clock.
    property int currentHour: new Date().getHours()

    function refreshClock() {
        greeting.currentHour = new Date().getHours();
    }

    // Greeting text based on the system clock:
    //   06:00 – 11:59  Good morning
    //   12:00 – 12:59  Good noon
    //   13:00 – 17:59  Good afternoon
    //   18:00 – 05:59  Good evening
    readonly property string timeGreeting: {
        const h = currentHour;
        if (h >= 6 && h <= 11) return i18n("Good morning, %1");
        if (h === 12) return i18n("Good noon, %1");
        if (h >= 13 && h <= 17) return i18n("Good afternoon, %1");
        return i18n("Good evening, %1"); // 18..23 and 0..5
    }

    // Refresh once a minute while the component exists, and immediately on
    // completion so the menu never opens with a stale greeting.
    Component.onCompleted: refreshClock()

    Timer {
        id: clockTimer
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: greeting.refreshClock()
    }

    Text {
        id: nameLabel

        text: {
            const config = Plasmoid.configuration;
            const user = greeting.launcher.user;
            if (config.enableGreeting && config.customGreeting) {
                return config.customGreeting;
            }
            if (!config.enableGreeting) {
                return i18n("%1@%2", user.loginName, user.host);
            }
            return greeting.timeGreeting.arg(user.fullName);
        }
        color: Kirigami.Theme.textColor
        font.family: greeting.launcher.textFont
        font.pixelSize: greeting.textSize
        font.bold: true
    }

    // Text glow
    MultiEffect {
        anchors.fill: nameLabel
        source: nameLabel
        visible: Plasmoid.configuration.enableGlow
        shadowEnabled: true
        shadowColor: greeting.launcher.glowColor1
        shadowBlur: 0.6
        blurMax: 16
    }
}
