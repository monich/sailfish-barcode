/*
The MIT License (MIT)

Copyright (c) 2018-2020 Slava Monich

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

MouseArea {
    property alias icon: image
    property bool down: pressed && containsMouse
    property bool highlighted: down
    property string hint

    signal showHint(var text)
    signal hideHint()

    width: Theme.itemSizeSmall
    height: Theme.itemSizeSmall

    readonly property bool _showPress: highlighted || pressTimer.running

    onPressedChanged: {
        if (pressed) {
            pressTimer.start()
        }
    }

    onClicked: hideHint()

    onReleased: hideHint()

    onPressAndHold: if (hint !== "") showHint(hint)

    onCanceled: {
        pressTimer.stop()
        hideHint()
    }

    Timer {
        id: pressTimer

        interval: 50
    }

    HarbourHighlightIcon {
        id: image

        highlightColor: _showPress ? Theme.highlightColor : Theme.primaryColor
        anchors.centerIn: parent
        opacity: parent.enabled ? 1.0 : 0.4
    }
}
