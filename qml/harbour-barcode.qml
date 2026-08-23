/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2026 Slava Monich

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

import "pages"

ApplicationWindow {
    id: window

    initialPage: mainPage
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: {
        switch (AppSettings.orientation) {
        default:
        case Settings.OrientationPrimary:
        case Settings.OrientationAny: return Orientation.Portrait | Orientation.LandscapeMask
        case Settings.OrientationPortrait:
        case Settings.OrientationPortraitAny: return Orientation.Portrait
        case Settings.OrientationLandscape:
        case Settings.OrientationLandscapeAny: return Orientation.LandscapeMask
        }
    }

    function startScan() {
        while (pageStack.pop(null, PageStackAction.Immediate));
        while (pageStack.depth > 1 && pageStack.popAttached(null, PageStackAction.Immediate));
        pageStack.pushAttached(historyPage)
        pageStack.currentPage.requestScan()
    }

    Binding {
        target: HistoryModel
        property: "maxCount"
        value: AppSettings.historySize
    }

    Binding {
        target: HistoryModel
        property: "saveImages"
        value: AppSettings.saveImages
    }

    Component.onCompleted: pageStack.pushAttached(historyPage)

    Component {
        id: mainPage
        ScanPage {
            autoScan: AppSettings.scanOnStart
        }
    }

    Component {
        id: historyPage
        HistoryPage {}
    }
}


