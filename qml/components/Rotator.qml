/*
The MIT License (MIT)

Copyright (c) 2020-2024 Slava Monich

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
    id: rotator

    implicitWidth: Theme.itemSizeSmall
    drag.target: dragItem
    drag.axis: Drag.YAxis

    property bool inverted

    readonly property bool highlighted: pressed && containsMouse
    readonly property bool showPress: highlighted || pressTimer.running || drag.active
    readonly property real oneDegree: height / 360.

    signal reset()
    signal rotateUp(var degrees)
    signal rotateDown(var degrees)

    onPressedChanged: {
        if (pressed) {
            pressTimer.start()
        }
    }

    onMouseYChanged: {
        if (mouseY < dragItem.lastY - oneDegree) {
            var degreesUp = Math.floor((dragItem.lastY - mouseY)/oneDegree)
            dragItem.lastY -= Math.round(degreesUp * oneDegree)
            rotateUp(degreesUp)
            dragItem.direction = 1
        } else if (mouseY > dragItem.lastY + oneDegree) {
            var degreesDown = Math.floor((mouseY - dragItem.lastY)/oneDegree)
            dragItem.lastY += Math.round(degreesDown * oneDegree)
            rotateDown(degreesDown)
            dragItem.direction = -1
        }
    }

    onPressed: dragItem.lastY = mouseY

    onClicked: {
        if (mouse.y < (height - label.height)/2) {
            dragItem.direction = 1
            rotateUp(1)
        } else if (mouse.y > (height + label.height)/2) {
            dragItem.direction = -1
            rotateDown(1)
        }
    }

    Item {
        id: dragItem

        property real lastY
        property int direction

        anchors.fill: parent

        onDirectionChanged: {
            if (direction != 0) {
                directionTimer.restart()
            }
        }

        Timer {
            id: directionTimer

            interval: 500
            onTriggered: dragItem.direction = 0
        }
    }

    Label {
        id: label

        //: Rotation widget
        //% "Rotate"
        text: qsTrId("gallery-rotate")
        font.pixelSize: Theme.fontSizeSmall
        anchors.centerIn: parent
        rotation: inverted ? -90 : 90
        color: drag.active ? Theme.highlightColor : Theme.primaryColor

        HarbourDoubleClickableMouseArea {
            anchors.fill: parent
            onDoubleClicked: rotator.reset()
        }
    }

    HarbourHighlightIcon {
        y: parent.height/4 - label.height/4 - height/2
        anchors.horizontalCenter: parent.horizontalCenter
        highlightColor: (showPress && dragItem.direction > 0) ? Theme.highlightColor : Theme.primaryColor
        source: "img/rotate-up.svg"
        sourceSize.width: label.height
    }

    HarbourHighlightIcon {
        y: 3*parent.height/4 + label.height/4 - height/2
        anchors.horizontalCenter: parent.horizontalCenter
        highlightColor: (showPress && dragItem.direction < 0) ? Theme.highlightColor : Theme.primaryColor
        source: "img/rotate-down.svg"
        sourceSize.width: label.height
    }

    Timer {
        id: pressTimer

        interval: 50
    }
}
