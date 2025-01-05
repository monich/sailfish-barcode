/*
The MIT License (MIT)

Copyright (c) 2024 Slava Monich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../harbour"

PageHeader {
    id: header

    property alias badgeText: badge.text
    property alias searchText: search.text
    property bool searchVisible

    function loseFocus() {
        search.focus = false
    }

    HarbourBadge {
        id: badge

        anchors {
            right: header.extraContent.right
            rightMargin: Theme.paddingLarge
            verticalCenter: '_titleItem' in header ? header._titleItem.verticalCenter : header.extraContent.verticalCenter
        }
        maxWidth: header.extraContent.width - anchors.rightMargin
    }

    SearchField {
        id: search

        anchors {
            left: header.extraContent.left
            right: header.extraContent.right
            // Try to position the "clear" button right over the badge
            rightMargin: Theme.paddingLarge - Theme.horizontalPageMargin - Theme.paddingMedium
            verticalCenter: '_titleItem' in header ? header._titleItem.verticalCenter : header.extraContent.verticalCenter
        }

        autoScrollEnabled: false
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: focus = false
        visible: opacity > 0
        opacity: searchVisible ? 1 : 0

        Behavior on opacity { FadeAnimation {} }

        onVisibleChanged: {
            if (!searchVisible) {
                text = ""
            }
        }
    }
}
