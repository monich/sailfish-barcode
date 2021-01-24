/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2021 Slava Monich

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

CoverBackground {
    id: cover

    HarbourHighlightIcon {
        id: icon

        y: x
        readonly property int size: Math.floor(cover.width * 0.56) & (-2)
        highlightColor: Theme.secondaryColor
        source: "cover-image.svg"
        fillMode: Image.PreserveAspectFit
        anchors.horizontalCenter: parent.horizontalCenter
        sourceSize: Qt.size(size, size)
    }

    Label {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: icon.bottom
            bottom: parent.bottom
            bottomMargin: (Theme.itemSizeSmall + Theme.iconSizeSmall)/2/cover.parent.scale
        }
        verticalAlignment: Text.AlignVCenter
        truncationMode: TruncationMode.Fade
        minimumPixelSize: Theme.fontSizeTiny
        wrapMode: Text.NoWrap
        color: Theme.highlightColor
        text: "CodeReader"
        font.bold: true
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: {
                window.startScan()
                window.activate();
            }
        }
    }
}


