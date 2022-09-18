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
import org.nemomobile.configuration 1.0
import harbour.barcode 1.0

import "../harbour"

Page {
    id: codePage

    allowedOrientations: window.allowedOrientations
    clip: true
    property alias model: slideView.model
    property alias currentIndex: slideView.currentIndex

    signal deleteItemAt(var index)
    signal requestIndex(var index)

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            // Hide the keyboard on flick
            codePage.forceActiveFocus()
        }
    }

    SlideshowView {
        id: slideView

        // Leave certain amount of space (Theme.itemSizeLarge) at the top
        // not covered by PathView, to make it easier to swipe back to the
        // previous page. Delegates draw on the entire page, though.
        y: Theme.itemSizeLarge
        height: parent.height - y
        width: parent.width
        pathItemCount: 3

        Component.onCompleted: positionViewAtIndex(currentIndex, PathView.Center)

        onCurrentIndexChanged: {
            if (codePage.status === PageStatus.Active) {
                codePage.requestIndex(currentIndex)
            }
        }

        delegate: CodeItem {
            allowedOrientations: codePage.allowedOrientations
            offsetY: -slideView.y
            width: slideView.width
            height: slideView.height
            hasImage: model.hasImage
            recordId: model.id
            text: model.value
            format: model.format
            timestamp: model.timestamp
            isPortrait: codePage.isPortrait
            canDelete: true
            onDeleteEntry: codePage.deleteItemAt(model.index)
        }
    }

    Loader {
        id: historySwipeHintLoader

        anchors.fill: parent
        active: opacity > 0
        opacity: (hintNeeded || running) ? 1 : 0
        readonly property bool running: item ? item.hintRunning : false
        readonly property bool hintNeeded: historySwipeCount.value < Settings.MaximumHintCount &&
            codePage.status === PageStatus.Active && slideView.count > 1 && !hintSeen
        property bool hintSeen
        sourceComponent: Component {
            HarbourHorizontalSwipeHint {
                //: Hint text for a swipe (either left or right)
                //% "Swipe to see other history entries"
                text: qsTrId("hint-history_swipe")
                hintEnabled: historySwipeHintLoader.hintNeeded
                bothWays: true
                loops: 1
                onHintShown: {
                    historySwipeCount.value++
                    historySwipeHintLoader.hintSeen = true
                }
            }
        }

        ConfigurationValue {
            id: historySwipeCount

            key: AppSettings.hintKey("historySwipe")
            defaultValue: 0
        }

        Behavior on opacity { FadeAnimation {} }
    }
}
