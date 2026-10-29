/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: configSearch

    property alias cfg_useExtraRunners: useExtraRunners.checked
    property var cfg_extraRunners: []

    // KRunner plugins people commonly turn on or off. Ids are the plugin file names.
    readonly property var searchPlugins: [
        { id: "krunner_services", text: i18n("Applications") },
        { id: "krunner_systemsettings", text: i18n("System Settings") },
        { id: "krunner_recentdocuments", text: i18n("Recent Files") },
        { id: "baloosearch", text: i18n("File Search") },
        { id: "locations", text: i18n("Locations (paths and URLs)") },
        { id: "krunner_placesrunner", text: i18n("Places") },
        { id: "calculator", text: i18n("Calculator") },
        { id: "unitconverter", text: i18n("Unit Converter") },
        { id: "org.kde.datetime", text: i18n("Date and Time") },
        { id: "krunner_shell", text: i18n("Command Line") },
        { id: "krunner_sessions", text: i18n("Desktop Sessions") },
        { id: "krunner_powerdevil", text: i18n("Power Management") },
        { id: "windows", text: i18n("Open Windows") },
        { id: "krunner_bookmarksrunner", text: i18n("Bookmarks") },
        { id: "browserhistory", text: i18n("Browser History") },
        { id: "krunner_webshortcuts", text: i18n("Web Search Keywords") },
        { id: "krunner_charrunner", text: i18n("Special Characters") },
        { id: "krunner_dictionary", text: i18n("Dictionary") },
        { id: "krunner_spellcheck", text: i18n("Spell Checker") },
        { id: "krunner_kill", text: i18n("Terminate Applications") },
        { id: "krunner_appstream", text: i18n("Software Center") },
        { id: "krunner_konsoleprofiles", text: i18n("Konsole Profiles") },
    ]

    Kirigami.FormLayout {
        CheckBox {
            id: useExtraRunners

            Kirigami.FormData.label: i18n("Search with:")
            text: i18n("Only the plugins selected below")
        }

        Label {
            text: useExtraRunners.checked
                  ? i18n("Plugins that aren't installed are skipped.")
                  : i18n("Every plugin enabled in System Settings is used.")
            font: Kirigami.Theme.smallFont
            opacity: 0.75
            wrapMode: Text.Wrap
        }

        Repeater {
            model: configSearch.searchPlugins

            delegate: CheckBox {
                id: pluginCheck

                required property var modelData

                text: pluginCheck.modelData.text
                enabled: useExtraRunners.checked
                checked: configSearch.cfg_extraRunners.includes(pluginCheck.modelData.id)

                onToggled: {
                    const selected = Array.from(configSearch.cfg_extraRunners).filter(id => id !== pluginCheck.modelData.id);
                    if (pluginCheck.checked) {
                        selected.push(pluginCheck.modelData.id);
                    }
                    configSearch.cfg_extraRunners = selected;
                }
            }
        }

        Label {
            visible: useExtraRunners.checked && configSearch.cfg_extraRunners.length === 0
            text: i18n("No plugins selected, so every enabled plugin will be used.")
            color: Kirigami.Theme.neutralTextColor
            wrapMode: Text.Wrap
        }

        Button {
            Kirigami.FormData.label: i18n("Plugin settings:")
            text: i18n("Configure Search Plugins…")
            icon.name: "settings-configure"
            onClicked: KCM.KCMLauncher.openSystemSettings("kcm_plasmasearch")
        }
    }
}
