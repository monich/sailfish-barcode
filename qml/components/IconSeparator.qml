/*
The MIT License (MIT)

Copyright (c) 2022 Slava Monich

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

Item {
    property alias iconSource: icon.source
    property int iconSize
    property alias color: icon.highlightColor

    height: iconSize + 2 * Theme.paddingSmall

    HarbourHighlightIcon {
        id: icon

        anchors.centerIn: parent
        source: visible ? "img/contact-phone.svg" : ""
        sourceSize.height: iconSize
    }

    Separator {
        anchors {
            left: parent.left
            right: icon.left
            rightMargin: Theme.paddingSmall
            verticalCenter: parent.verticalCenter
        }

        color: icon.highlightColor
        horizontalAlignment: Qt.AlignRight
    }

    Separator {
        anchors {
            left: icon.right
            leftMargin: Theme.paddingSmall
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        color: icon.highlightColor
        horizontalAlignment: Qt.AlignLeft
    }
}
