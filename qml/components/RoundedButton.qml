/*
The MIT License (MIT)

Copyright (c) 2020 Slava Monich

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

MouseArea {
    id: button

    property bool down: pressed && containsMouse
    property alias text: buttonText.text
    property color color: Theme.primaryColor
    property color backgroundColor: Theme.rgba(color, 0.2)
    property color highlightColor: Theme.highlightColor
    property color highlightBackgroundColor: Theme.highlightBackgroundColor
    property real preferredWidth: Theme.buttonWidthSmall

    readonly property bool showPress: down || pressTimer.running

    onPressedChanged: {
        if (pressed) {
            pressTimer.start()
        }
    }

    onCanceled: pressTimer.stop()

    height: Theme.itemSizeExtraSmall
    implicitWidth: Math.max(preferredWidth, buttonText.width + Theme.paddingMedium)

    Rectangle {
        anchors.fill: parent
        radius: height/2
        color: showPress ? Theme.rgba(button.highlightBackgroundColor, Theme.highlightBackgroundOpacity) : backgroundColor
        opacity: button.enabled ? 1.0 : 0.4

        Label {
            id: buttonText

            anchors.centerIn: parent
            color: showPress ? button.highlightColor : button.color
        }
    }

    Timer {
        id: pressTimer

        interval: 64
    }
}
