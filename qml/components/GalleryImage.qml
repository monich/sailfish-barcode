/*
The MIT License (MIT)

Copyright (c) 2020-2021 Slava Monich

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

SilicaFlickable {
    id: galleryImage

    property real zoom: 1.0
    property real angle
    property real orientation
    property bool isLandscape
    property alias source: image.source

    readonly property real minZoomX: (implicitWidth > width) ? width/implicitWidth : 0.1
    readonly property real minZoomY: (implicitHeight > height) ? height/implicitHeight : 0.1
    readonly property real minZoom: Math.min(minZoomX, minZoomY)
    readonly property real maxZoomX: (implicitWidth && MaxTextureSize) ? MaxTextureSize/implicitWidth : 10.0
    readonly property real maxZoomY: (implicitHeight && MaxTextureSize) ? MaxTextureSize/implicitHeight : 10.0
    readonly property real maxZoom: Math.min(maxZoomX, maxZoomY)
    readonly property real actualZoom: Math.min(Math.max(zoom, minZoom), maxZoom)

    readonly property bool transpose: (orientation % 180) != 0
    implicitWidth: transpose ? image.implicitHeight : image.implicitWidth
    implicitHeight: transpose ? image.implicitWidth : image.implicitHeight

    clip: true
    anchors.fill: parent
    flickableDirection: Flickable.HorizontalAndVerticalFlick
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: container.width
    contentHeight: container.height

    property real lastContentWidth
    property real lastContentHeight

    function centerContent() {
        contentX = originX + Math.ceil((contentHeight - height)/2.0)
        contentY = originY + Math.ceil((contentWidth - width)/2.0)
    }

    function resetZoom() {
        var w = transpose ? image.height : image.width
        var h = transpose ? image.width : image.height
        var viewportWidth = isLandscape ? galleryImage.height : galleryImage.width
        var viewportHeight = isLandscape ? galleryImage.width : galleryImage.height
        zoom = Math.min(viewportWidth/w, viewportHeight/h)
    }

    onContentWidthChanged: {
        if (visible && !moving) {
            contentX -= (lastContentWidth - contentWidth)/2
        }
        lastContentWidth = contentWidth
    }

    onContentHeightChanged: {
        if (visible && !moving) {
            contentY -= (lastContentHeight - contentHeight)/2
        }
        lastContentHeight = contentHeight
    }

    Behavior on angle {
        enabled: galleryImage.visible
        SmoothedAnimation {
            duration: 500
        }
    }

    Item {
        id: container

        width: Math.max(galleryImage.width, (transpose ? image.ySize : image.xSize) * image.scale)
        height: Math.max(galleryImage.height, (transpose ? image.xSize : image.ySize) * image.scale)

        Image {
            id: image

            readonly property real r: galleryImage.angle * Math.PI / 180
            readonly property real d: Math.sqrt(height * height + width * width)
            readonly property real a: width ? Math.atan(height/width) : 0
            readonly property real xSize: d * Math.max(Math.abs(Math.cos(r - a)), Math.abs(Math.cos(r + a)))
            readonly property real ySize: d * Math.max(Math.abs(Math.sin(r - a)), Math.abs(Math.sin(r + a)))

            anchors.centerIn: parent
            scale: actualZoom
            smooth: true
            rotation: (galleryImage.angle - galleryImage.orientation) % 360
            transformOrigin: Item.Center
        }
    }
}
