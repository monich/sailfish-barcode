/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
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

import "../js/Utils.js" as Utils

Item {
    id: codeItem

    property int allowedOrientations
    property string text
    property string recordId
    property bool hasImage
    property string format
    property string timestamp
    property bool isPortrait
    property bool canDelete: true
    property real offsetY

    readonly property string normalizedText: Utils.convertLineBreaks(text)
    readonly property bool isUrl: Utils.isUrl(text) && !isVCard && !isVEvent
    readonly property bool isLink: Utils.isLink(text) && !isVCard && !isVEvent
    readonly property bool isVCard: (meCardConverter.vcard.length > 0 || Utils.isVcard(normalizedText)) && !isVEvent
    readonly property bool isVEvent: Utils.isVevent(normalizedText)
    readonly property bool haveContact: vcard ? (vcard.count > 0) : false
    property var vcard

    signal deleteEntry()

    function updateVcard() {
        if (vcard) {
            vcard.content = meCardConverter.vcard ? meCardConverter.vcard : normalizedText
        }
    }

    onNormalizedTextChanged: {
        textArea.text = normalizedText
        updateVcard()
    }

    onIsVCardChanged: {
        if (isVCard && !vcard) {
            var component = Qt.createComponent("../components/VCard.qml")
            if (component.status === Component.Ready) {
                vcard = component.createObject(codeItem, {
                    content: meCardConverter.vcard ? meCardConverter.vcard : normalizedText
                })
            }
        }
    }

    DGCertRecognizer {
        id: dgCert

        text: normalizedText
    }

    MeCardConverter {
        id: meCardConverter

        mecard: normalizedText
        onVcardChanged: updateVcard()
    }

    TemporaryFile {
        id: calendarEvent

        location: SystemInfo.osVersionCompare("4.0") >= 0 ? TemporaryFile.Downloads : TemporaryFile.Tmp
        fileTemplate: isVEvent ? "barcodeXXXXXX.vcs" : ""
    }

    ReceiptFetcher {
        id: receiptFetcher

        code: codeItem.text
    }

    SilicaFlickable {
        y: offsetY
        width: parent.width
        height: parent.height - offsetY
        contentHeight: column.height

        PullDownMenu {
            visible: codeItem.canDelete
            MenuItem {
                //: Context menu item
                //% "Delete"
                text: qsTrId("history-menu-delete")
                onClicked: codeItem.deleteEntry()
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: codeItem.focus = true
        }

        Column {
            id: column

            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            height: childrenRect.height

            PageHeader {
                id: pageHeader

                title: BarcodeUtils.barcodeFormatName(codeItem.format)
                description: HistoryModel.formatTimestamp(codeItem.timestamp)
            }

            TextArea {
                id: textArea

                width: parent.width
                readOnly: false
                wrapMode: TextEdit.Wrap
                softwareInputPanelEnabled: false
            }

            Button {
                id: button

                readonly property bool isNeeded: text.length > 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (dgCert.valid) {
                        //: Button text
                        //% "COVID Certificate"
                        return qsTrId("button-eu_covid_cert")
                    } else if (isLink) {
                        //: Button text
                        //% "Open link"
                        return qsTrId("button-open_link")
                    } else if (isUrl) {
                        //: Button text
                        //% "Open URL"
                        return qsTrId("button-open_url")
                    } else if (haveContact) {
                        //: Button text
                        //% "Contact card"
                        return qsTrId("button-contact_card")
                    } else if (isVEvent) {
                        //: Button text
                        //% "Add to calendar"
                        return qsTrId("button-add_to_calendar")
                    } else if (receiptFetcher.state === ReceiptFetcher.StateChecking) {
                        return holdOffTimer.running ?
                            //: Button text
                            //% "Fetching..."
                            qsTrId("button-fetching_receipt") :
                            //: Button label (cancel network operation)
                            //% "Cancel"
                            qsTrId("button-cancel_fetching")
                    } else if (receiptFetcher.state !== ReceiptFetcher.StateIdle) {
                        //: Button text
                        //% "Fetch receipt"
                        return qsTrId("button-fetch_receipt")
                    } else {
                        return ""
                    }
                }
                visible: isNeeded
                enabled: !holdOffTimer.running
                onClicked: {
                    // Take focus away from the edit field
                    button.forceActiveFocus()
                    if (dgCert.valid) {
                        pageStack.push("CovidPage.qml", {
                            allowedOrientations: codeItem.allowedOrientations,
                            text: dgCert.text
                        })
                    } else if (isUrl) {
                        console.log("opening", codeItem.text)
                        Qt.openUrlExternally(codeItem.text)
                        holdOffTimer.restart()
                    } else if (isVEvent) {
                        // This actually creates a temporary file
                        calendarEvent.content = Utils.calendarText(normalizedText)
                        console.log("importing", calendarEvent.url)
                        Qt.openUrlExternally(calendarEvent.url)
                        holdOffTimer.restart()
                    } else if (haveContact) {
                        pageStack.push("VCardPage.qml", {
                            allowedOrientations: codeItem.allowedOrientations,
                            contact: vcard.contact(),
                        }).saveContact.connect(function() {
                           pageStack.pop()
                           codeItem.vcard.importContact()
                        })
                    } else if (receiptFetcher.state === ReceiptFetcher.StateChecking) {
                        receiptFetcher.cancel()
                    } else {
                        // Fetch Receipt
                        holdOffTimer.restart()
                        receiptFetcher.fetch()
                    }
                }
                Timer {
                    id: holdOffTimer

                    interval: 2000
                }
            }

            Item {
                readonly property bool isChecking: receiptFetcher.state === ReceiptFetcher.StateChecking
                readonly property bool isError: receiptFetcher.state === ReceiptFetcher.StateFailure

                visible: height > 0
                height: (isChecking || isError) ? Theme.itemSizeSmall : (button.isNeeded > 0) ? Theme.paddingLarge : 0
                width: parent.width

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.paddingMedium
                    visible: opacity > 0
                    opacity: parent.isChecking ? 1 : 0

                    BusyIndicator {
                        running: parent.opacity != 0
                        size: BusyIndicatorSize.ExtraSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeSmall
                        truncationMode: TruncationMode.Fade
                        color: Theme.highlightColor
                        //: Progress label
                        //% "Contacting %1..."
                        text: qsTrId("text-fetch_contacting").arg(receiptFetcher.host)
                    }
                    Behavior on opacity { FadeAnimation {} }
                }

                Label {
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    verticalAlignment: Text.AlignVCenter
                    color: Theme.highlightColor
                    visible: opacity > 0
                    opacity: parent.isError ? 1 : 0
                    text: {
                        switch (receiptFetcher.error) {
                        case ReceiptFetcher.ErrorNotFound:
                            //: Status label
                            //% "Receipt not found"
                            return qsTrId("text-receipt_not_found")
                        case ReceiptFetcher.ErrorNetwork:
                            //: Status label
                            //% "Network error"
                            return qsTrId("text-network_error")
                        }
                        return ""
                    }
                    Behavior on opacity { FadeAnimation {} }
                }

                Behavior on height { SmoothedAnimation { duration: 100 } }
            }

            Item {
                width: parent.width
                height: receiptView.item ? (receiptView.item.height + Theme.paddingLarge) : 0
                visible: receiptView.active

                Loader {
                    id: receiptView

                    width: parent.width
                    source: receiptFetcher.state === ReceiptFetcher.StateSuccess ? "../components/HtmlView.qml" : ""
                    onStatusChanged: {
                        if (status == Loader.Ready) {
                            item.htmlBody = receiptFetcher.receipt
                        }
                    }
                }
            }

            SilicaFlickable {
                id: imageFlickable

                visible: image.status === Image.Ready
                width: image.implicitWidth
                height: image.implicitHeight
                contentWidth: imagePinchArea.width
                contentHeight: imagePinchArea.height
                anchors.horizontalCenter: parent.horizontalCenter
                flickableDirection: Flickable.HorizontalAndVerticalFlick
                quickScrollEnabled: false
                clip: true

                PinchArea {
                    id: imagePinchArea

                    width:  Math.max(image.width * image.scale, imageFlickable.width)
                    height: Math.max(image.height * image.scale, imageFlickable.height)

                    property int centerX
                    property int centerY
                    property real prevScale: 1

                    pinch {
                        target: image
                        minimumScale: 1
                        maximumScale: 4
                    }

                    onPinchStarted: prevScale = image.scale
                    onPinchUpdated: {
                        centerX = pinch.center.x
                        centerY = pinch.center.y
                        imageFlickable.returnToBounds()
                    }

                    Connections {
                        target: imagePinchArea.pinch.active ? image : null
                        onScaleChanged: {
                            var newWidth = image.width * image.scale
                            var newHeight = image.height * image.scale
                            var oldWidth = image.width * imagePinchArea.prevScale
                            var oldHeight = image.height * imagePinchArea.prevScale
                            var widthDifference = newWidth - oldWidth
                            var heightDifference = newHeight - oldHeight

                            if (oldWidth > imageFlickable.width || newWidth > imageFlickable.width) {
                                imageFlickable.contentX += imagePinchArea.centerX / newWidth * widthDifference
                            }
                            if (oldHeight > imageFlickable.height || newHeight > imageFlickable.height) {
                                imageFlickable.contentY += imagePinchArea.centerY / newHeight * heightDifference
                            }
                            imagePinchArea.prevScale = image.scale
                        }
                    }

                    Image {
                        id: image

                        anchors.centerIn: parent
                        source: (hasImage && recordId.length && AppSettings.saveImages) ?
                            ("image://scanner/saved/" + (codeItem.isPortrait ? "portrait/" : "landscape/") + recordId) : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                    }


                    // Reset the zoom on double click with an animation
                    MouseArea {
                        anchors.fill: parent

                        enabled: image.scale !== 1
                        onClicked: {
                            // doubleClick never arrives on Sailfish OS 2.x
                            if (doubleClickTimer.running) {
                                doubleClickTimer.stop()
                                reset()
                            } else {
                                doubleClickTimer.start()
                            }
                        }

                        onDoubleClicked: {
                            doubleClickTimer.stop()
                            reset()
                        }

                        Timer {
                            id: doubleClickTimer

                            interval: 200
                        }

                        function reset() {
                            if (!resetAnimation.running) {
                                imageScaleAnimation.from = image.scale
                                flickableContentXAnimation.from = imageFlickable.contentX
                                flickableContentYAnimation.from = imageFlickable.contentY
                                resetAnimation.start()
                            }
                        }

                        ParallelAnimation {
                            id: resetAnimation

                            alwaysRunToEnd: true

                            readonly property int _duration: 200

                            NumberAnimation {
                                id: imageScaleAnimation

                                target: image
                                property: "scale"
                                easing.type: Easing.InOutQuad
                                duration: resetAnimation._duration
                                to: 1
                            }

                            NumberAnimation {
                                id: flickableContentXAnimation

                                target: imageFlickable
                                property: "contentX"
                                easing.type: Easing.InOutQuad
                                duration: resetAnimation._duration
                                to: 0
                            }

                            NumberAnimation {
                                id: flickableContentYAnimation

                                target: imageFlickable
                                property: "contentY"
                                easing.type: Easing.InOutQuad
                                duration: resetAnimation._duration
                                to: 0
                            }
                        }
                    }
                }

                ScrollDecorator { flickable: imageFlickable }
            }

            Item {
                visible: image.visible
                height: Theme.paddingLarge
                width: 1
            }
        }

        VerticalScrollDecorator { }
    }
}
