/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2024 Slava Monich

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
import QtMultimedia 5.4
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import org.nemomobile.notifications 1.0
import harbour.barcode 1.0

import "../js/Utils.js" as Utils
import "../components"
import "../harbour"

Page {
    id: thisPage

    allowedOrientations: window.allowedOrientations

    property bool autoScan
    readonly property bool cameraActive: viewFinder && viewFinder.cameraActive

    // Internal properties
    property Item galleryImage
    property Item viewFinder
    property Item hint

    property bool showMarker
    readonly property real screenHeight: isPortrait ? Screen.height : Screen.width
    readonly property bool mustShowViewFinder: (thisPage.status === PageStatus.Active) && Qt.application.active && !scanningGalleryImage && !showMarker
    readonly property bool hintActive: hint && hint.visible
    readonly property bool landscapeLayout: width > height
    readonly property bool scanningGalleryImage: galleryImage && galleryImage.visible
    readonly property bool useVolumeKeys: AppSettings.volumeZoom && (thisPage.status === PageStatus.Active) && Qt.application.active
    readonly property int toolIconFadeDuration: 64
    readonly property int scanTimeout: 60

    readonly property var volumeUp: Qt.createQmlObject(BarcodeUtils.mediaKeyQml, thisPage, "VolumeKey")
    readonly property var volumeDown: Qt.createQmlObject(BarcodeUtils.mediaKeyQml, thisPage, "VolumeKey")
    readonly property var permissions: Qt.createQmlObject(BarcodeUtils.permissionsQml, thisPage, "Permissions")

    Binding { target: permissions; property: "enabled"; value: useVolumeKeys }
    Binding { target: volumeUp; property: "enabled"; value: useVolumeKeys }
    Binding { target: volumeUp;  property: "key"; value: Qt.Key_VolumeUp }
    Binding { target: volumeDown; property: "enabled"; value: useVolumeKeys }
    Binding { target: volumeDown;  property: "key"; value: Qt.Key_VolumeDown }

    Connections {
        target: volumeUp
        ignoreUnknownSignals: true
        onPressed: zoomSlider.zoomIn()
        onRepeat: zoomSlider.zoomIn()
    }

    Connections {
        target: volumeDown
        ignoreUnknownSignals: true
        onPressed: zoomSlider.zoomOut()
        onRepeat: zoomSlider.zoomOut()
    }

    function destroyViewFinder() {
        if (viewFinder) {
            console.log("destroying viewfinder ...")
            viewFinder.source.stop()
            viewFinder.destroy()
            viewFinder = null
        }
    }

    function destroyScanner() {
        destroyViewFinder()
        scanner.stopScanning()
    }

    function applyResult(image,result) {
        var text = result.text
        console.log(result.format, text)
        markerImageProvider.image = image
        if (text.length > 0) {
            Clipboard.text = text
            var recId = HistoryModel.insert(image, text, result.format)
            clickableResult.setValue(recId, text, result.format)
        }
    }

    function requestScan() {
        if (cameraActive) {
            startScan()
        } else {
            autoScan = true // start scanning when camera becomes active
        }
    }

    function startScan() {
        hideGalleryImage()
        showMarker = false
        markerImageProvider.clear()
        scanner.startScanning(scanTimeout * 1000)
    }

    function hideGalleryImage() {
        if (galleryImage) {
            galleryImage.visible = false
            galleryImage.source = ""
        }
        zoomSlider.value = AppSettings.digitalZoom
        if (viewFinder) {
            viewFinder.visible = true
        }
    }

    function scanFromGallery(url) {
        if (url) {
            console.log("Scanning", url)
            if (!galleryImage) {
                galleryImage = galleryImageComponent.createObject(viewFinderContainer)
            }
            if (galleryImage) {
                destroyViewFinder()
                galleryImage.angle = 0
                galleryImage.source = url
                // Give user a chance to move the image before it gets scanned
                galleryScanTimer.restart()
                galleryImage.visible = true
                galleryImage.resetZoom()
                galleryImage.centerContent()
                zoomSlider.value = galleryImage.actualZoom
                galleryImage.requestZoom.connect(function(zoom) { zoomSlider.value = zoom })
                scanner.startScanning(0)
            }
        }
    }

    Timer {
        id: galleryScanTimer

        interval: 1000
    }

    onCameraActiveChanged: {
        if (cameraActive) {
            console.log("camera has started")
            if (autoScan) {
                console.log("auto-starting scan ...")
                autoScan = false
                startScan()
            }
        }
    }

    Component {
        id: hintComponent
        Hint { }
    }

    function showHint(text) {
        if (!hint) {
            hint = hintComponent.createObject(thisPage)
        }
        hint.text = text
        hint.opacity = 1.0
    }

    function hideHint() {
        if (hint) {
            hint.opacity = 0.0
        }
    }

    function orientationAngle() {
        switch (orientation) {
        case Orientation.Landscape: return 90
        case Orientation.PortraitInverted: return 180
        case Orientation.LandscapeInverted: return 270
        case Orientation.Portrait: default: return  0
        }
    }

    onOrientationChanged: {
        if (viewFinder) {
            viewFinder.orientation = orientationAngle()
        }
    }

    onMustShowViewFinderChanged: {
        if (mustShowViewFinder && !viewFinder) {
            console.log("creating viewfinder ...")
            viewFinder = viewFinderComponent.createObject(viewFinderContainer, {
                viewfinderResolution: viewFinderContainer.viewfinderResolution,
                frontCamera: AppSettings.frontCamera,
                digitalZoom: AppSettings.digitalZoom,
                orientation: orientationAngle()
            })
            if (viewFinder.source.availability === Camera.Available) {
                viewFinder.source.start()
            }
            viewFinderContainer.updateSupportedResolution_4_3(viewFinder.supportedWideResolution)
            viewFinderContainer.updateSupportedResolution_16_9(viewFinder.supportedNarrowResolution)
        }
    }

    onStatusChanged: {
        if (thisPage.status === PageStatus.Inactive) {
            console.log("Page is INACTIVE")
            // stop scanning if page is not active
            destroyScanner()
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (!Qt.application.active) {
                console.log("Application is INACTIVE")
                destroyScanner()
            }
        }
    }

    // Pause blanking while scanning
    DisplayBlanking {
        pauseRequested: scanner.scanState === BarcodeScanner.Scanning
    }

    Notification {
        id: clipboardNotification
        //: Pop-up notification
        //% "Copied to clipboard"
        previewBody: qsTrId("notification-copied_to_clipboard")
        expireTimeout: 2000
        Component.onCompleted: {
            if ("icon" in clipboardNotification) {
                clipboardNotification.icon = "icon-s-clipboard"
            }
        }
    }

    Loader {
        id: buzzLoader

        active: AppSettings.buzzOnScan
        source: "../components/Buzz.qml"
    }

    Loader {
        id: beepLoader

        active: AppSettings.sound
        sourceComponent: Component {
            SoundEffect {
                source:  Qt.resolvedUrl("sound/beep.wav")
            }
        }
    }

    BarcodeScanner {
        id: scanner

        readonly property bool idle: scanState === BarcodeScanner.Idle ||
                                     scanState === BarcodeScanner.TimedOut

        viewFinderItem: viewFinderContainer
        markerColor: AppSettings.markerColor
        rotation: orientationAngle()
        canGrab: (!galleryImage || !galleryImage.moving) && !galleryScanTimer.running
        inverted: invertButton.down
        mirrored: viewFinder && viewFinder.mirrored
        decodingHints: AppSettings.decodingHints

        onDecodingFinished: {
            if (result.ok) {
                statusText.text = ""
                applyResult(image, result)
                if (AppSettings.resultViewDuration > 0) {
                    thisPage.showMarker = true
                    resultViewTimer.restart()
                }
                if (buzzLoader.item) {
                    buzzLoader.item.start()
                }
                if (beepLoader.item) {
                    beepLoader.item.play()
                }
            }
        }

        onScanStateChanged: {
            if (viewFinder && scanState !== BarcodeScanner.Scanning) {
                viewFinder.turnFlashOff()
            }
            switch (scanState) {
            case BarcodeScanner.Idle:
                statusText.text = ""
                hideGalleryImage()
                break
            case BarcodeScanner.Scanning:
                //: Scan status label
                //% "Scan in progress ..."
                statusText.text = qsTrId("scan-status-busy")
                clickableResult.clear()
                break
            case BarcodeScanner.TimedOut:
                //: Scan status label
                //% "No code detected! Try again."
                statusText.text = qsTrId("scan-status-nothing_found")
                break
            }
        }
    }

    SingleImageProvider {
        id: markerImageProvider

        mirrorHorizontally: AppSettings.frontCamera && !scanningGalleryImage
    }

    Timer {
        id: resultViewTimer

        interval: AppSettings.resultViewDuration * 1000
        onTriggered: thisPage.showMarker = false
    }

    Component {
        id: viewFinderComponent

        ViewFinder {
            onMaximumDigitalZoom: AppSettings.maxDigitalZoom = value
            showFocusArea: !scanner.grabbing
        }
    }

    Component {
        id: galleryImageComponent

        GalleryImage {
            visible: false
            isLandscape: thisPage.isLandscape
            z: 1
        }
    }

    SilicaFlickable {
        id: scanPageFlickable

        width: parent.width
        height: screenHeight
        interactive: !(invertButton.visible && invertButton.down)

        PullDownMenu {
            enabled: scanner.idle && !hintActive
            visible: enabled
            onActiveChanged: if (active) statusText.text = ""

            MenuItem {
                //: About page title, label and menu item
                //% "About CodeReader"
                text: qsTrId("about-title")
                onClicked: pageStack.push("AboutPage.qml")
            }
            MenuItem {
                //: Pulley menu item
                //% "Scan from Gallery"
                text: qsTrId("scan-gallery-menu")
                onClicked: {
                    var picker = pageStack.push("Sailfish.Pickers.ImagePickerPage", {
                        allowedOrientations: thisPage.allowedOrientations
                    })
                    var imageUrl
                    picker.onSelectedContentChanged.connect(function() {
                        imageUrl = picker.selectedContent
                    })
                    // Don't start scanning until the transition is finished
                    // to avoid scanning a code from a gallery page thumbnail.
                    picker.statusChanged.connect(function() {
                        if (picker.status === PageStatus.Inactive && imageUrl) {
                            scanFromGallery(imageUrl)
                        }
                    })
                }
            }
            MenuItem {
                //: Setting page title and menu item
                //% "Settings"
                text: qsTrId("settings-title")
                onClicked: pageStack.push("SettingsPage.qml")
            }
        }

        Loader {
            y: viewFinderArea.y
            width: Theme.itemSizeSmall
            height: viewFinderArea.height
            active: opacity > 0
            opacity: isNeeded ? 1 : 0
            readonly property bool isNeeded: scanningGalleryImage && scanner.scanState === BarcodeScanner.Scanning
            FadeAnimation on opacity { }
            sourceComponent: Component {
                Rotator {
                    onReset: galleryImage.angle = 0
                    onRotateUp: galleryImage.angle += degrees
                    onRotateDown: galleryImage.angle -= degrees
                }
            }
        }

        Loader {
            x: parent.width - width
            y: viewFinderArea.y
            height: viewFinderArea.height
            active: opacity > 0
            opacity: isNeeded ? 1 : 0
            readonly property bool isNeeded: scanningGalleryImage && scanner.scanState === BarcodeScanner.Scanning
            FadeAnimation on opacity { }
            sourceComponent: Component {
                Rotator {
                    inverted: true
                    onReset: galleryImage.angle = 0
                    onRotateUp: galleryImage.angle -= degrees
                    onRotateDown: galleryImage.angle += degrees
                }
            }
        }

        Item {
            id: viewFinderArea

            anchors {
                top: parent.top
                topMargin: Theme.paddingLarge
                bottom: cameraControls.top
                bottomMargin: Theme.paddingLarge
                left: parent.left
                leftMargin: horizontalMargin
                right: parent.right
                rightMargin: horizontalMargin
            }

            readonly property real horizontalMargin: scanningGalleryImage ? Theme.itemSizeSmall : Theme.horizontalPageMargin

            onXChanged: viewFinderContainer.updateViewFinderPosition()
            onYChanged: viewFinderContainer.updateViewFinderPosition()
            onWidthChanged: viewFinderContainer.updateViewFinderPosition()
            onHeightChanged: viewFinderContainer.updateViewFinderPosition()

            Rectangle {
                id: viewFinderScanBorder

                readonly property int thickness: Theme.paddingSmall
                anchors {
                    fill: viewFinderContainer
                    margins: -thickness
                }
                border {
                    color: Theme.highlightColor
                    width: thickness
                }
                radius: thickness
                smooth: true
                color: "transparent"
                visible: opacity > 0
                opacity: scanner.idle ? 0 : 1
                Behavior on opacity {
                    enabled: scanner.idle
                    FadeAnimation { duration: 500 }
                }
                SequentialAnimation on opacity {
                    running: !scanner.idle
                    loops: Animation.Infinite
                    PropertyAnimation { to: 1.0; duration: 500 }
                    PropertyAnimation { to: 0.01; duration: 500 }
                }
            }

            Rectangle {
                id: viewFinderContainer

                readonly property real defaultRatio: AppSettings.narrowRatio
                readonly property bool canSwitchResolutions:
                    AppSettings.wideResolution.width > 0 && AppSettings.wideResolution.height > 0 &&
                    AppSettings.narrowResolution.width > 0 && AppSettings.narrowResolution.height > 0
                readonly property size viewfinderResolution: canSwitchResolutions ?
                    (AppSettings.wideMode ? AppSettings.wideResolution : AppSettings.narrowResolution) :
                    Qt.size(0,0)
                readonly property real ratio: canSwitchResolutions ?
                    (AppSettings.wideMode ? AppSettings.wideRatio : AppSettings.narrowRatio) :
                    (AppSettings.wideResolution.width > 0 && AppSettings.wideResolution.height > 0) ? AppSettings.wideRatio :
                    AppSettings.narrowRatio

                readonly property int portraitWidth: Math.floor((parent.height/parent.width > ratio) ? parent.width : parent.height/ratio)
                readonly property int portraitHeight: Math.floor((parent.height/parent.width > ratio) ? (parent.width * ratio) : parent.height)
                readonly property int landscapeWidth: Math.floor((parent.width/parent.height > ratio) ? (parent.height * ratio) : parent.width)
                readonly property int landscapeHeight: Math.floor((parent.width/parent.height > ratio) ? parent.height : (parent.width / ratio))

                anchors.centerIn: parent
                width: scanningGalleryImage ? parent.width : (thisPage.isPortrait ? portraitWidth : landscapeWidth)
                height: scanningGalleryImage ? parent.height : (thisPage.isPortrait ? portraitHeight : landscapeHeight)
                color: "#20000000"
                opacity: markerImage.visible ? 0 : 1
                FadeAnimation on opacity { }

                onWidthChanged: updateViewFinderPosition()
                onHeightChanged: updateViewFinderPosition()
                onXChanged: updateViewFinderPosition()
                onYChanged: updateViewFinderPosition()

                onViewfinderResolutionChanged: {
                    if (viewFinder && viewfinderResolution && canSwitchResolutions) {
                        viewFinder.viewfinderResolution = viewfinderResolution
                    }
                }

                function updateViewFinderPosition() {
                    scanner.viewFinderRect = Qt.rect(x + parent.x, y + parent.y, width, height)
                }

                function updateSupportedResolution_4_3(res) {
                    if (res.width > AppSettings.wideResolution.width) {
                        AppSettings.wideResolution = res
                    }
                }

                function updateSupportedResolution_16_9(res) {
                    if (res.width > AppSettings.narrowResolution.width) {
                        AppSettings.narrowResolution = res
                    }
                }

                Connections {
                    target: viewFinder
                    onSupportedWideResolutionChanged: viewFinderContainer.updateSupportedResolution_4_3(viewFinder.supportedWideResolution)
                    onSupportedNarrowResolutionChanged: viewFinderContainer.updateSupportedResolution_16_9(viewFinder.supportedNarrowResolution)
                }
            }

            Image {
                id: markerImage

                anchors.centerIn: viewFinderContainer
                z: 2
                source: thisPage.showMarker ? markerImageProvider.source : ""
                visible: status === Image.Ready
                cache: false
            }
        }

        Item {
            id: cameraControls

            height: Theme.itemSizeMedium
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                bottom: actionButton.top
            }

            HarbourHintIconButton {
                id: flashButton

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                enabled: TorchSupported && !scanningGalleryImage && !AppSettings.frontCamera
                opacity: enabled ? 1.0 : 0.0
                visible: TorchSupported && opacity > 0.0
                icon.source: viewFinder && viewFinder.flashOn ?
                        Qt.resolvedUrl("img/flash-on.svg") :
                        Qt.resolvedUrl("img/flash-off.svg")
                onClicked: if (viewFinder) viewFinder.toggleFlash()
                //: Hint label
                //% "Toggle flashlight"
                hint: qsTrId("hint-toggle-flash")
                onShowHint: thisPage.showHint(hint)
                onHideHint: thisPage.hideHint()
                FadeAnimation on opacity { duration: toolIconFadeDuration }
            }

            Slider {
                id: zoomSlider

                property bool completed

                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge + Theme.iconSizeMedium
                    right: parent.right
                    rightMargin: Theme.paddingLarge + Theme.iconSizeMedium
                    verticalCenter: parent.verticalCenter
                }
                leftMargin: 0
                rightMargin: 0
                minimumValue: scanningGalleryImage ? galleryImage.minZoom : 1.0
                maximumValue: scanningGalleryImage ? galleryImage.maxZoom : AppSettings.maxDigitalZoom
                value: 1
                //: Slider label
                //% "Zoom"
                label: qsTrId("scan-slider-zoom")
                enabled: !markerImage.visible
                onSliderValueChanged: {
                    if (enabled && completed) {
                        if (scanningGalleryImage) {
                            galleryImage.zoom = sliderValue
                        } else {
                            AppSettings.digitalZoom = sliderValue
                            if (viewFinder) {
                                viewFinder.digitalZoom = sliderValue
                            }
                        }
                    }
                }
                Component.onCompleted: {
                    value = AppSettings.digitalZoom
                    if (viewFinder) {
                        viewFinder.digitalZoom = sliderValue
                    }
                    completed = true
                }
                onEnabledChanged: {
                    if (!enabled) {
                        zoomSlider.cancel()
                    }
                }
                function zoomIn() {
                    if (value < maximumValue) {
                        var newValue = value + stepSize
                        if (newValue < maximumValue) {
                            value = newValue
                        } else {
                            value = maximumValue
                        }
                    }
                }
                function zoomOut() {
                    if (value > minimumValue) {
                        var newValue = value - stepSize
                        if (newValue > minimumValue) {
                            value = newValue
                        } else {
                            value = minimumValue
                        }
                    }
                }
            }

            HarbourHintIconButton {
                id: ratioButton

                readonly property url icon_16_9: Qt.resolvedUrl("img/resolution_16_9.svg")
                readonly property url icon_4_3: Qt.resolvedUrl("img/resolution_4_3.svg")
                readonly property bool isNeeded: viewFinderContainer.canSwitchResolutions && scanner.scanState !== BarcodeScanner.Scanning
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                icon {
                    source: AppSettings.wideMode ? icon_4_3 : icon_16_9
                    sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                    rotation: isLandscape ? 90 : 0
                }
                opacity: isNeeded ? 1.0 : 0.0
                visible: opacity > 0.0
                FadeAnimation on opacity { duration: toolIconFadeDuration }
                onClicked: AppSettings.wideMode = !AppSettings.wideMode
                hint: isLandscape ?
                    //: Hint label
                    //% "Switch the aspect ratio between 16:9 and 4:3"
                    qsTrId("hint-aspect-ratio_landscape") :
                    //: Hint label
                    //% "Switch the aspect ratio between 9:16 and 3:4"
                    qsTrId("hint-aspect-ratio")
                onShowHint: thisPage.showHint(hint)
                onHideHint: thisPage.hideHint()
            }

            HarbourHintIconButton {
                id: invertButton

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                icon {
                    source: Qt.resolvedUrl("img/invert.svg")
                    sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                    rotation: invertButton.down ? 180 : 0
                }
                opacity: ((viewFinder || galleryImage) && !ratioButton.isNeeded) ? 1.0 : 0.0
                visible: opacity > 0.0
                FadeAnimation on opacity { duration: toolIconFadeDuration }
                Binding { target: viewFinder;  property: "invert"; value: invertButton.down }
                Binding { target: galleryImage;  property: "invert"; value: invertButton.down }
            }
        }

        Item {
            id: statusArea

            anchors {
                top: cameraControls.bottom
                left: cameraControls.left
                bottomMargin: Theme.paddingLarge
            }

            Label {
                id: statusText

                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                wrapMode: Text.WordWrap
                color: Theme.highlightColor
            }

            Item {
                id: clickableResult

                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }

                property string recordId
                property string text
                property string format

                property var vcard: null
                readonly property bool haveContact: vcard && vcard.count > 0
                readonly property string normalizedText: Utils.convertLineBreaks(text)
                readonly property bool isCovidCertificate: dgCert.valid
                readonly property string vcardText: (isCovidCertificate || isVEvent) ? "" :
                    (meCardConverter.vcard.length > 0) ? meCardConverter.vcard :
                    Utils.isVcard(normalizedText) ? normalizedText : ""
                readonly property bool isVEvent: !isCovidCertificate && Utils.isVevent(normalizedText)
                readonly property bool isVCard: !isCovidCertificate && vcardText.length > 0
                readonly property bool isLink: !isCovidCertificate && Utils.isLink(text)
                readonly property bool isUrl: !isCovidCertificate && Utils.isUrl(text)

                function setValue(recId, text, format) {
                    clickableResult.recordId = recId
                    clickableResult.text = text
                    clickableResult.format = format
                    opacity = 1.0
                }

                function clear() {
                    opacity = 0.0
                    clickableResult.recordId = ""
                    clickableResult.text = ""
                    clickableResult.format = ""
                }

                onVcardTextChanged: {
                    if (vcardText.length > 0) {
                        if (vcard) {
                            vcard.content = vcardText
                        } else {
                            var component = Qt.createComponent("../components/VCard.qml")
                            if (component.status === Component.Ready) {
                                vcard = component.createObject(thisPage, { content: vcardText })
                            }
                        }
                    } else {
                        if (vcard) {
                            vcard.destroy()
                            vcard = null
                        }
                    }
                }

                height: Math.max(resultItem.height, Theme.itemSizeSmall)
                width: parent.width
                visible: opacity > 0.0

                FadeAnimation on opacity { }

                MeCardConverter {
                    id: meCardConverter

                    mecard: clickableResult.normalizedText
                }

                DGCertRecognizer {
                    id: dgCert

                    text: clickableResult.text
                }

                TemporaryFile {
                    id: calendarEvent

                    // Calendar app can't access /tmp in Sailfish OS >= 4.0
                    location: SystemInfo.osVersionCompare("4.0") >= 0 ? TemporaryFile.Downloads : TemporaryFile.Tmp
                    fileTemplate: clickableResult.isVEvent ? "barcodeXXXXXX.vcs" : ""
                }

                // Clear results when the first history item gets deleted
                Connections {
                    target: HistoryModel
                    onRowsRemoved: if (first == 0) clickableResult.clear()
                }

                Item {
                    height: parent.height
                    visible: clickableResult.text.length > 0
                    anchors.verticalCenter: parent.verticalCenter

                    HarbourHintIconButton {
                        id: covidButton

                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: visible ? "img/covid.svg" : ""
                        visible: clickableResult.isCovidCertificate
                        enabled: visible
                        //: Hint label
                        //% "Show EU digital COVID certificate"
                        hint: qsTrId("hint-covid_certificate")
                        onShowHint: thisPage.showHint(hint)
                        onHideHint: thisPage.hideHint()
                        onClicked: {
                            pageStack.push("CovidPage.qml", {
                                allowedOrientations: thisPage.allowedOrientations,
                                text: dgCert.text
                            })
                        }
                    }

                    HarbourHintIconButton {
                        id: vcardButton

                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: visible ? "img/open_vcard.svg" : ""
                        visible: !covidButton.visible && clickableResult.haveContact
                        //: Hint label
                        //% "Open contact card"
                        hint: qsTrId("hint-open_contact_card")
                        onShowHint: thisPage.showHint(hint)
                        onHideHint: thisPage.hideHint()
                        onClicked: {
                            pageStack.push("VCardPage.qml", {
                                allowedOrientations: thisPage.allowedOrientations,
                                contact: clickableResult.vcard.contact(),
                            }).saveContact.connect(function() {
                                pageStack.pop()
                                clickableResult.vcard.importContact()
                            })
                        }
                    }

                    HarbourHintIconButton {
                        id: veventButton

                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: visible ? "img/calendar.svg" : ""
                        visible: !covidButton.visible && !vcardButton.visible && clickableResult.isVEvent
                        enabled: visible && !holdOffTimer.running
                        onClicked: {
                            // This actually creates a temporary file
                            calendarEvent.content = Utils.calendarText(clickableResult.normalizedText)
                            console.log("importing", calendarEvent.url)
                            Qt.openUrlExternally(calendarEvent.url)
                            holdOffTimer.restart()
                        }
                        //: Hint label
                        //% "Add event to calendar"
                        hint: qsTrId("hint-add_to_calendar")
                        onShowHint: thisPage.showHint(hint)
                        onHideHint: thisPage.hideHint()
                    }

                    HarbourHintIconButton {
                        id: linkButton
                        anchors.verticalCenter: parent.verticalCenter
                        icon {
                            source: !visible ? "" :
                                clickableResult.isLink ?
                                Qt.resolvedUrl("img/open_link.svg") :
                                Qt.resolvedUrl("img/open_url.svg")
                            sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                        }
                        visible: !covidButton.visible && !vcardButton.visible && !veventButton.visible && clickableResult.isUrl
                        enabled: visible && !holdOffTimer.running
                        hint: clickableResult.isLink ?
                            //: Hint label
                            //% "Open link in browser"
                            qsTrId("hint-open_link") :
                            //: Hint label
                            //% "Open URL in default application"
                            qsTrId("hint-open_url")
                        onShowHint: thisPage.showHint(hint)
                        onHideHint: thisPage.hideHint()
                        onClicked: {
                            console.log("opening", clickableResult.text)
                            Qt.openUrlExternally(clickableResult.text)
                            holdOffTimer.restart()
                        }
                    }

                    HarbourHintIconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: "img/clipboard.svg"
                        visible: !covidButton.visible && !linkButton.visible && !vcardButton.visible && !veventButton.visible
                        onClicked: {
                            Clipboard.text = clickableResult.text
                            clipboardNotification.publish()
                        }
                        //: Hint label
                        //% "Copy to clipboard"
                        hint: qsTrId("hint-copy-clipboard")
                        onShowHint: thisPage.showHint(hint)
                        onHideHint: thisPage.hideHint()
                    }

                    Timer {
                        id: holdOffTimer
                        interval: 2000
                    }
                }
            }

            BackgroundItem {
                id: resultItem

                x: zoomSlider.x
                height: Math.max(resultColumn.height, implicitHeight)
                width: parent.width - x
                enabled: scanner.idle && clickableResult.text
                anchors.verticalCenter: parent.verticalCenter

                function deleteItem() {
                    var remorse = remorseComponent.createObject(null)
                    //: Remorse popup text
                    //% "Deleting"
                    remorse.execute(resultItem, qsTrId("history-menu-delete_remorse"),
                        function() {
                            HistoryModel.remove(clickableResult.recordId)
                            if (thisPage.status === PageStatus.Active) {
                                HistoryModel.commitChanges()
                            }
                            remorse.destroy()
                        })
                    actionButton.clicked.connect(remorse.destroy)
                }

                Column {
                    id: resultColumn
                    x: Theme.paddingSmall
                    width: parent.width - x
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        text: Utils.getValueText(clickableResult.text)
                        color: resultItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        font.underline: clickableResult.isLink
                    }
                    Label {
                        width: parent.width
                        color: resultItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: BarcodeUtils.barcodeFormatName(clickableResult.format)
                        truncationMode: TruncationMode.Fade
                    }
                }

                onClicked: {
                    pageStack.push("TextPage.qml", {
                        allowedOrientations: thisPage.allowedOrientations,
                        hasImage: AppSettings.saveImages,
                        recordId: clickableResult.recordId,
                        text: clickableResult.text,
                        format: clickableResult.format,
                        canDelete: true
                    }).deleteEntry.connect(function() {
                        pageStack.pop()
                        resultItem.deleteItem()
                    })
                }
            }
        }

        RoundedButton {
            id: actionButton

            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingLarge
            }
            onClicked: {
                if (scanner.scanState === BarcodeScanner.Scanning) {
                    scanner.stopScanning()
                } else {
                    startScan()
                }
            }
            backgroundColor: scanner.idle ?
                Theme.rgba(Theme.primaryColor, 0.2) :
                Theme.rgba(Theme.highlightColor, viewFinderScanBorder.opacity * Theme.highlightBackgroundOpacity)
            enabled: scanner.scanState !== BarcodeScanner.Aborting
            text: scanner.idle ?
                //: Scan button label
                //% "Scan"
                qsTrId("scan-action-scan") :
                //: Scan button label
                //% "Cancel"
                qsTrId("scan-action-cancel")
        }
    }

    Component {
        id: remorseComponent
        RemorseItem { }
    }

    states: [
        State {
            name: "portrait"
            when: !landscapeLayout
            changes: [
                PropertyChanges {
                    target: cameraControls
                    anchors.bottomMargin: Theme.itemSizeSmall + Theme.paddingLarge
                },
                AnchorChanges {
                    target: statusArea
                    anchors {
                        bottom: actionButton.top
                        right: cameraControls.right
                    }
                },
                PropertyChanges {
                    target: statusArea
                    anchors.rightMargin: 0
                },
                PropertyChanges {
                    target: statusText
                    anchors.leftMargin: 0
                    horizontalAlignment: Text.AlignHCenter
                },
                AnchorChanges {
                    target: actionButton
                    anchors {
                        right: undefined
                        horizontalCenter: parent.horizontalCenter
                    }
                },
                PropertyChanges {
                    target: actionButton
                    anchors.rightMargin: 0
                }
            ]
        },
        State {
            name: "landscape"
            when: landscapeLayout
            changes: [
                PropertyChanges {
                    target: cameraControls
                    anchors.bottomMargin: 0
                },
                AnchorChanges {
                    target: statusArea
                    anchors {
                        bottom: parent.bottom
                        right: actionButton.left
                    }
                },
                PropertyChanges {
                    target: statusArea
                    anchors.rightMargin: Theme.paddingLarge
                },
                PropertyChanges {
                    target: statusText
                    anchors.leftMargin: zoomSlider.x
                    horizontalAlignment: Text.AlignLeft
                },
                AnchorChanges {
                    target: actionButton
                    anchors {
                        right: parent.right
                        horizontalCenter: undefined
                    }
                },
                PropertyChanges {
                    target: actionButton
                    anchors.rightMargin: Theme.horizontalPageMargin
                }
            ]
        }
    ]
}
