/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2020 Slava Monich

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
import org.nemomobile.notifications 1.0
import harbour.barcode 1.0

import "../js/Utils.js" as Utils
import "../components"

Page {
    id: scanPage

    allowedOrientations: window.allowedOrientations

    property Item viewFinder
    property Item hint
    property bool showMarker
    property bool autoScan
    property int scanTimeout: 60

    readonly property bool cameraActive: viewFinder && viewFinder.cameraActive
    readonly property bool landscapeLayout: isLandscape && Screen.sizeCategory < Screen.ExtraLarge

    function createScanner() {
        if (viewFinder) {
            return
        }

        console.log("creating viewfinder ...")
        viewFinder = viewFinderComponent.createObject(viewFinderContainer, {
            viewfinderResolution: viewFinderContainer.viewfinderResolution,
            digitalZoom: AppSettings.digitalZoom,
            orientation: orientationAngle()
        })

        if (viewFinder.source.availability === Camera.Available) {
            viewFinder.source.start()
        }
    }

    function destroyScanner() {
        if (!viewFinder) {
            return
        }

        console.log("destroying viewfinder ...")
        scanner.stopScanning()
        viewFinder.source.stop()
        viewFinder.destroy()
        viewFinder = null
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
        showMarker = false
        markerImageProvider.clear()
        scanner.startScanning(scanTimeout * 1000)
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
            hint = hintComponent.createObject(scanPage)
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

    onStatusChanged: {
        if (scanPage.status === PageStatus.Active) {
            console.log("Page is ACTIVE")
            if (Qt.application.active) {
                createScanner()
            }
        } else if (scanPage.status === PageStatus.Inactive) {
            console.log("Page is INACTIVE")
            // stop scanning if page is not active
            destroyScanner()
        }
    }

    // Pause blanking while scanning
    DisplayBlanking {
        pauseRequested: scanner.scanState === BarcodeScanner.Scanning
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active) {
                console.log("Application is ACTIVE")
                if (scanPage.status === PageStatus.Active) {
                    createScanner()
                }
            } else if (!Qt.application.active) {
                console.log("Application is INACTIVE")
                destroyScanner()
            }
        }
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

    BarcodeScanner {
        id: scanner

        readonly property bool idle: scanState === BarcodeScanner.Idle ||
                                     scanState === BarcodeScanner.TimedOut

        viewFinderItem: viewFinderContainer
        markerColor: AppSettings.markerColor
        rotation: orientationAngle()

        onDecodingFinished: {
            if (result.ok) {
                statusText.text = ""
                applyResult(image, result)
                var resultViewDuration = AppSettings.resultViewDuration
                if (resultViewDuration > 0) {
                    scanPage.showMarker = true
                    resultViewTimer.interval = resultViewDuration * 1000
                    resultViewTimer.restart()
                }
                if (buzzLoader.item) {
                    buzzLoader.item.start()
                }
                if (AppSettings.sound && viewFinder) {
                    viewFinder.playBeep()
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
    }

    Timer {
        id: resultViewTimer

        onTriggered: scanPage.showMarker = false
    }

    Component {
        id: viewFinderComponent

        ViewFinder {
            beepSource: "sound/beep.wav"
            onMaximumDigitalZoom: AppSettings.maxDigitalZoom = value
        }
    }

    SilicaFlickable {
        id: scanPageFlickable

        anchors.fill: parent

        PullDownMenu {
            id: menu
            enabled: scanner.idle
            visible: enabled
            onActiveChanged: if (active) statusText.text = ""

            MenuItem {
                //: About page title, label and menu item
                //% "About CodeReader"
                text: qsTrId("about-title")
                onClicked: pageStack.push("AboutPage.qml")
            }
            MenuItem {
                //: Setting page title and menu item
                //% "Settings"
                text: qsTrId("settings-title")
                onClicked: pageStack.push("SettingsPage.qml")
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
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }

            onXChanged: viewFinderContainer.updateViewFinderPosition()
            onYChanged: viewFinderContainer.updateViewFinderPosition()
            onWidthChanged: viewFinderContainer.updateViewFinderPosition()
            onHeightChanged: viewFinderContainer.updateViewFinderPosition()

            Rectangle {
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

                readonly property real ratio_4_3: 4./3.
                readonly property real ratio_16_9: 16./9.
                readonly property bool canSwitchResolutions: typeof ViewfinderResolution_4_3 !== "undefined" &&
                    typeof ViewfinderResolution_16_9 !== "undefined"
                readonly property size viewfinderResolution: canSwitchResolutions ?
                    (AppSettings.wideMode ? ViewfinderResolution_4_3 : ViewfinderResolution_16_9) :
                    Qt.size(0,0)
                readonly property real ratio: canSwitchResolutions ? (AppSettings.wideMode ? ratio_4_3 : ratio_16_9) :
                    typeof ViewfinderResolution_4_3 !== "undefined" ? ratio_4_3 : ratio_16_9

                readonly property int portraitWidth: Math.floor((parent.height/parent.width > ratio) ? parent.width : parent.height/ratio)
                readonly property int portraitHeight: Math.floor((parent.height/parent.width > ratio) ? (parent.width * ratio) : parent.height)
                readonly property int landscapeWidth: Math.floor((parent.width/parent.height > ratio) ? (parent.height * ratio) : parent.width)
                readonly property int landscapeHeight: Math.floor((parent.width/parent.height > ratio) ? parent.height : (parent.width / ratio))

                anchors.centerIn: parent
                width: scanPage.isPortrait ? portraitWidth : landscapeWidth
                height: scanPage.isPortrait ? portraitHeight : landscapeHeight
                color: "#20000000"

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
            }

            Image {
                id: markerImage

                anchors.fill: viewFinderContainer
                z: 2
                source: scanPage.showMarker ? markerImageProvider.source : ""
                visible: status === Image.Ready
                cache: false
            }
        }

        Item {
            id: cameraControls

            height: Math.max(flashButton.height, zoomSlider.height, ratioButton.height)
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                bottom: actionButton.top
            }

            HintIconButton {
                id: flashButton

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                visible: TorchSupported
                icon.source: viewFinder && viewFinder.flashOn ?
                        "image://theme/icon-camera-flash-on" :
                        "image://theme/icon-camera-flash-off"
                onClicked: if (viewFinder) viewFinder.toggleFlash()
                //: Hint label
                //% "Toggle flashlight"
                hint: qsTrId("hint-toggle-flash")
                onShowHint: scanPage.showHint(hint)
                onHideHint: scanPage.hideHint()
            }

            Slider {
                id: zoomSlider

                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin + Theme.itemSizeSmall
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin + Theme.itemSizeSmall
                    verticalCenter: parent.verticalCenter
                }
                leftMargin: 0
                rightMargin: 0
                minimumValue: 1.0
                maximumValue: AppSettings.maxDigitalZoom
                value: 1
                stepSize: 1
                onValueChanged: {
                    AppSettings.digitalZoom = zoomSlider.value
                    if (viewFinder) {
                        viewFinder.digitalZoom = value
                    }
                }
                Component.onCompleted: {
                    value = AppSettings.digitalZoom
                    if (viewFinder) {
                        viewFinder.digitalZoom = value
                    }
                }
            }

            HintIconButton {
                id: ratioButton

                readonly property url icon_16_9: Qt.resolvedUrl("img/resolution_16_9.svg")
                readonly property url icon_4_3: Qt.resolvedUrl("img/resolution_4_3.svg")
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                icon {
                    source: AppSettings.wideMode ? icon_4_3 : icon_16_9
                    sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                    rotation: isLandscape ? 90 : 0
                }
                onClicked: AppSettings.wideMode = !AppSettings.wideMode
                hint: isLandscape ?
                    //: Hint label
                    //% "Switch the aspect ratio between 16:9 and 4:3"
                    qsTrId("hint-aspect-ratio_landscape") :
                    //: Hint label
                    //% "Switch the aspect ratio between 9:16 and 3:4"
                    qsTrId("hint-aspect-ratio")
                onShowHint: scanPage.showHint(hint)
                onHideHint: scanPage.hideHint()
            }
        }

        Item {
            id: statusArea

            anchors {
                top: cameraControls.bottom
                left: cameraControls.left
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
                readonly property string vcardText: (meCardConverter.vcard.length > 0) ? meCardConverter.vcard :
                    Utils.isVcard(normalizedText) ? normalizedText : ""
                readonly property bool isVCard: vcardText.length > 0
                readonly property bool isLink: Utils.isLink(text)
                readonly property bool isUrl: Utils.isUrl(text)

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
                            var component = Qt.createComponent("VCard.qml")
                            if (component.status === Component.Ready) {
                                vcard = component.createObject(scanPage, { content: vcardText })
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

                Behavior on opacity { FadeAnimation { } }

                MeCardConverter {
                    id: meCardConverter

                    mecard: clickableResult.normalizedText
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

                    HintIconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: "image://theme/icon-m-clipboard"
                        visible: !linkButton.visible && !vcardButton.visible
                        onClicked: {
                            Clipboard.text = clickableResult.text
                            clipboardNotification.publish()
                        }
                        //: Hint label
                        //% "Copy to clipboard"
                        hint: qsTrId("hint-copy-clipboard")
                        onShowHint: scanPage.showHint(hint)
                        onHideHint: scanPage.hideHint()
                    }

                    HintIconButton {
                        id: linkButton
                        anchors.verticalCenter: parent.verticalCenter
                        icon {
                            source: clickableResult.isLink ?
                                Qt.resolvedUrl("img/open_link.svg") :
                                Qt.resolvedUrl("img/open_url.svg")
                            sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                        }
                        visible: !clickableResult.haveContact && clickableResult.isUrl
                        enabled: visible && !holdOffTimer.running
                        hint: clickableResult.isLink ?
                            //: Hint label
                            //% "Open link in browser"
                            qsTrId("hint-open_link") :
                            //: Hint label
                            //% "Open URL in default application"
                            qsTrId("hint-open_url")
                        onShowHint: scanPage.showHint(hint)
                        onHideHint: scanPage.hideHint()
                        onClicked: {
                            console.log("opening", clickableResult.text)
                            Qt.openUrlExternally(clickableResult.text)
                            holdOffTimer.restart()
                        }
                        Timer {
                            id: holdOffTimer
                            interval: 2000
                        }
                    }

                    HintIconButton {
                        id: vcardButton
                        anchors.verticalCenter: parent.verticalCenter
                        icon {
                            source: "img/open_vcard.svg"
                            sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                        }
                        visible: clickableResult.haveContact && !clickableResult.isLink
                        //: Hint label
                        //% "Open contact card"
                        hint: qsTrId("hint-open_contact_card")
                        onShowHint: scanPage.showHint(hint)
                        onHideHint: scanPage.hideHint()
                        onClicked: {
                            // Workaround for Sailfish.Contacts not being allowed in harbour apps
                            var page = Qt.createQmlObject("import QtQuick 2.0;import Sailfish.Silica 1.0;import Sailfish.Contacts 1.0; \
    Page { id: page; signal saveContact(); property alias contact: card.contact; property alias saveText: saveMenu.text; \
    ContactCard { id: card; PullDownMenu { MenuItem { id: saveMenu; onClicked: page.saveContact(); }}}}",
                                scanPage, "ContactPage")
                            pageStack.push(page, {
                                allowedOrientations: window.allowedOrientations,
                                contact: clickableResult.vcard.contact(),
                                //: Pulley menu item (saves contact)
                                //% "Save"
                                saveText: qsTrId("contact-menu-save")
                            }).saveContact.connect(function() {
                                pageStack.pop()
                                clickableResult.vcard.importContact()
                            })
                        }
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
                            HistoryModel.remove(0)
                            if (scanPage.status === PageStatus.Active) {
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
                        text: Utils.barcodeFormat(clickableResult.format)
                        truncationMode: TruncationMode.Fade
                    }
                }

                onClicked: {
                    pageStack.push("TextPage.qml", {
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

        Button {
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
            enabled: scanner.scanState !== BarcodeScanner.Aborting
            text: scanner.idle ?
                //: Scan button label
                //% "Scan"
                qsTrId("scan-action-scan") :
                //: Scan button label
                //% "Abort"
                qsTrId("scan-action-abort")
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
                    anchors.bottomMargin: Theme.itemSizeSmall + 2 * Theme.paddingLarge
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
                    anchors.bottomMargin: Theme.paddingLarge
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
