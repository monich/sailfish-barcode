/*
The MIT License (MIT)

Copyright (c) 2019-2020 Slava Monich

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
import harbour.barcode 1.0

import "../js/Utils.js" as Utils

ListItem {
    id: item

    highlighted: down || selected || menuOpen
    property string value
    property string timestamp
    property string format
    property bool selected

    Column {
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - (2 * Theme.horizontalPageMargin)
            color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            maximumLineCount: 1
            truncationMode: TruncationMode.Fade
            text: Utils.getValueText(item.value)
        }

        Item {
            width: parent.width
            height: Math.max(timestampLabel.height, formatLabel.height)

            Label {
                id: timestampLabel

                anchors {
                    left: parent.left
                    margins: Theme.horizontalPageMargin
                }
                color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: HistoryModel.formatTimestamp(item.timestamp)
            }

            Label {
                id: formatLabel

                anchors {
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: Utils.barcodeFormat(item.format)
            }
        }
    }
}
