/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

// A page in the launcher's StackView: favorites, all apps or search results
Item {
    required property LauncherState launcher

    // The view that key presses from the search field are forwarded to
    property Item viewItem: null
}
