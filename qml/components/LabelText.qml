/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2022 Slava Monich

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

Column {
    property alias label: label.text
    property alias text: text.text
    property alias description: description.text
    property alias color: text.color
    property bool separator: true

    spacing: Theme.paddingMedium
    x: Theme.horizontalPageMargin
    width: parent.width - 2 * x

    Label {
        id: label

        width: parent.width
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.highlightColor
        truncationMode: TruncationMode.Fade
        visible: label.text.length > 0
    }

    Label {
        id: text

        width: parent.width
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        visible: text.text.length > 0
    }

    Label {
        id: description

        width: parent.width
        font.pixelSize: Theme.fontSizeExtraSmall
        wrapMode: Text.Wrap
        visible: description.text.length > 0
        opacity: 0.6
    }

    Separator {
        width: parent.width
        color: Theme.highlightColor
        horizontalAlignment: Qt.AlignHCenter
        opacity: separator ? 1 : 0 // Keep is visible to apply spacing above it
    }
}
