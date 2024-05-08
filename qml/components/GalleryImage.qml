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

SilicaFlickable {
    id: galleryImage

    property real zoom: 1.0
    property real angle
    property bool isLandscape
    property alias source: image.source
    property bool invert

    readonly property real minZoom: Math.min(1, width/image.scaledImplicitWidth, height/image.scaledImplicitHeight)
    readonly property real maxZoom: MaxTextureSize ? Math.min(MaxTextureSize/image.scaledImplicitWidth, MaxTextureSize/image.scaledImplicitHeight) : 10.0
    readonly property real actualZoom: Math.min(Math.max(zoom, minZoom), maxZoom)

    property real _lastContentWidth
    property real _lastContentHeight

    signal requestZoom(var zoom)

    clip: true
    anchors.fill: parent
    quickScrollEnabled: false
    flickableDirection: Flickable.HorizontalAndVerticalFlick
    contentWidth: imagePinchArea.width
    contentHeight: imagePinchArea.height

    function centerContent() {
        contentX = originX + Math.ceil((contentHeight - height)/2.0)
        contentY = originY + Math.ceil((contentWidth - width)/2.0)
    }

    function resetZoom() {
        var viewportWidth = isLandscape ? galleryImage.height : galleryImage.width
        var viewportHeight = isLandscape ? galleryImage.width : galleryImage.height
        zoom = Math.max(minZoom, Math.min(maxZoom, viewportWidth/image.scaledImplicitWidth, viewportHeight/image.scaledImplicitHeight))
    }

    Behavior on angle {
        enabled: galleryImage.visible
        SmoothedAnimation {
            duration: 500
        }
    }

    PinchArea {
        id: imagePinchArea

        width:  Math.max(imageContainer.width * imageContainer.scale, galleryImage.width)
        height: Math.max(imageContainer.height * imageContainer.scale, galleryImage.height)

        property int _centerX
        property int _centerY
        property real _prevScale: 1

        pinch {
            target: imageContainer
            minimumScale: minZoom
            maximumScale: maxZoom
        }

        onPinchStarted: _prevScale = imageContainer.scale
        onPinchUpdated: {
            _centerX = pinch.center.x
            _centerY = pinch.center.y
            galleryImage.returnToBounds()
        }

        Connections {
            target: imagePinchArea.pinch.active ? imageContainer : null
            onScaleChanged: {
                var newWidth = imageContainer.width * imageContainer.scale
                var newHeight = imageContainer.height * imageContainer.scale
                var oldWidth = imageContainer.width * imagePinchArea._prevScale
                var oldHeight = imageContainer.height * imagePinchArea._prevScale
                var widthDifference = newWidth - oldWidth
                var heightDifference = newHeight - oldHeight

                if (oldWidth > galleryImage.width || newWidth > galleryImage.width) {
                    galleryImage.contentX += imagePinchArea._centerX / newWidth * widthDifference
                }
                if (oldHeight > galleryImage.height || newHeight > galleryImage.height) {
                    galleryImage.contentY += imagePinchArea._centerY / newHeight * heightDifference
                }
                imagePinchArea._prevScale = imageContainer.scale
            }
        }

        Item {
            id: imageContainer

            width: image.xSize
            height: image.ySize
            anchors.centerIn: parent
            scale: actualZoom

            onScaleChanged: galleryImage.requestZoom(scale)

            Image {
                id: image

                readonly property real r: galleryImage.angle * Math.PI / 180
                readonly property real a: width ? Math.atan(height/width) : 0
                readonly property real d: Math.sqrt(height * height + width * width) * scale
                readonly property real xSize: d * Math.max(Math.abs(Math.cos(r - a)), Math.abs(Math.cos(r + a)))
                readonly property real ySize: d * Math.max(Math.abs(Math.sin(r - a)), Math.abs(Math.sin(r + a)))
                readonly property real implicitDiagonal: Math.sqrt(implicitWidth * implicitWidth + implicitHeight * implicitHeight)
                readonly property real implicitScale: Math.max(implicitDiagonal ? Math.min(galleryImage.width, galleryImage.height)/implicitDiagonal : 0, 1)
                readonly property real scaledImplicitWidth: implicitWidth * implicitScale
                readonly property real scaledImplicitHeight: implicitHeight * implicitScale

                layer.enabled: invert
                layer.effect: HarbourInvertEffect {
                    source: image
                }

                anchors.centerIn: parent
                smooth: true
                scale: implicitScale
                rotation: galleryImage.angle % 360
                transformOrigin: Item.Center
            }

            // "Image.autoTransform" is not available in QtQuick 2.0
            Binding {
                target: image
                property: "autoTransform"
                value: true
            }
        }

        // Reset the zoom on double click with an animation
        HarbourDoubleClickableMouseArea {
            anchors.fill: parent
            enabled: imageContainer.scale !== 1

            onDoubleClicked: resetScale()

            function resetScale() {
                if (!resetAnimation.running) {
                    imageScaleAnimation.from = imageContainer.scale
                    flickableContentXAnimation.from = galleryImage.contentX
                    flickableContentYAnimation.from = galleryImage.contentY
                    resetAnimation.start()
                }
            }

            ParallelAnimation {
                id: resetAnimation

                alwaysRunToEnd: true

                readonly property int _duration: 200

                NumberAnimation {
                    id: imageScaleAnimation

                    target: imageContainer
                    property: "scale"
                    easing.type: Easing.InOutQuad
                    duration: resetAnimation._duration
                    to: minZoom
                }

                NumberAnimation {
                    id: flickableContentXAnimation

                    target: galleryImage
                    property: "contentX"
                    easing.type: Easing.InOutQuad
                    duration: resetAnimation._duration
                    to: 0
                }

                NumberAnimation {
                    id: flickableContentYAnimation

                    target: galleryImage
                    property: "contentY"
                    easing.type: Easing.InOutQuad
                    duration: resetAnimation._duration
                    to: 0
                }
            }
        }
    }
}
