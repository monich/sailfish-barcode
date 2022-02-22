/*
The MIT License (MIT)

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
import harbour.barcode 1.0

Page {
    id: thisPage

    property string title

    readonly property var galleryModel: Qt.createQmlObject(BarcodeUtils.documentGalleryModelQml, thisPage, "GalleryModel")

    signal imageSelected(var url, var orientation)

    SilicaGridView {
        id: grid

        readonly property int columnCount: Math.floor(width / Theme.itemSizeHuge)
        readonly property real cellSize: Math.floor(width / columnCount)

        clip: true
        anchors.fill: parent
        model: galleryModel
        currentIndex: -1
        cacheBuffer: 1000
        cellWidth: cellSize
        cellHeight: cellSize

        header: PageHeader {
            id: header

            title: thisPage.title
        }

        delegate: BackgroundItem {
            id: delegate

            width: grid.cellSize
            height: grid.cellSize
            contentHeight: grid.cellSize
            contentWidth: grid.cellSize

            readonly property url modelUrl: url
            readonly property string modelMimeType: mimeType
            readonly property int modelOrientation: orientation

            Thumbnail {
                id: thumbnail
                source: modelUrl
                mimeType: modelMimeType
                width:  grid.cellSize
                height: grid.cellSize
                sourceSize.width: grid.cellSize
                sourceSize.height: grid.cellSize
                priority: Thumbnail.NormalPriority
                opacity: delegate.highlighted ? 0.7 : 1.0

                onStatusChanged: {
                    if (status === Thumbnail.Error) {
                        errorComponent.createObject(thumbnail)
                    }
                }

                Behavior on opacity { FadeAnimation {} }
            }

            Component {
                id: errorComponent
                Label {
                    //: Thumbnail image loading failed
                    //% "Error"
                    text: qsTrId("gallery-thumbnail-error")
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.paddingMedium
                    height: parent.height - 2 * Theme.paddingSmall
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.fontSizeSmall
                    fontSizeMode: Text.Fit
                }
            }

            onClicked: thisPage.imageSelected(modelUrl, modelOrientation)

            GridView.onAdd: AddAnimation { target: delegate }
            GridView.onRemove: SequentialAnimation {
                PropertyAction { target: delegate; property: "GridView.delayRemove"; value: true }
                NumberAnimation { target: delegate; properties: "opacity,scale"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
                PropertyAction { target: delegate; property: "GridView.delayRemove"; value: false }
            }
        }

        VerticalScrollDecorator { }

        ViewPlaceholder {
            //: Placeholder text
            //% "No images found in the gallery"
            text: qsTrId("gallery-empty")
            enabled: !busyIndicator.running && (!galleryModel || !galleryModel.count)
        }
    }

    BusyIndicator {
        id: busyIndicator

        size: BusyIndicatorSize.Large
        anchors.centerIn: thisPage
        running: initTimer.running && !!galleryModel && !galleryModel.count

        Timer {
            id: initTimer

            interval: 5000
            running: true
        }
    }
}
