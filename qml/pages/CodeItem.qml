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
import harbour.barcode 1.0

import "../js/Utils.js" as Utils

Item {
    id: codeItem

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
    readonly property bool haveEvent: !!calendarEvent.fileName
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
            var component = Qt.createComponent("VCard.qml");
            if (component.status === Component.Ready) {
                vcard = component.createObject(codeItem, {
                    content: meCardConverter.vcard ? meCardConverter.vcard : normalizedText
                })
            }
        }
    }

    MeCardConverter {
        id: meCardConverter

        mecard: normalizedText
        onVcardChanged: updateVcard()
    }

    TemporaryFile {
        id: calendarEvent

        content: isVEvent ? Utils.calendarText(normalizedText) : ""
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

                title: Utils.barcodeFormat(codeItem.format)
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
                    if (isLink) {
                        //: Button text
                        //% "Open link"
                        return qsTrId("text-open_link")
                    } else if (isUrl) {
                        //: Button text
                        //% "Open URL"
                        return qsTrId("text-open_url")
                    } else if (haveContact) {
                        //: Button text
                        //% "Contact card"
                        return qsTrId("text-contact_card")
                    } else if (haveEvent) {
                        //: Button text
                        //% "Add to calendar"
                        return qsTrId("text-add_to_calendar")
                    } else if (receiptFetcher.state === ReceiptFetcher.StateChecking) {
                        return holdOffTimer.running ?
                            //: Button text
                            //% "Fetching..."
                            qsTrId("text-fetching_receipt") :
                            //: Button label (cancel network operation)
                            //% "Cancel"
                            qsTrId("text-cancel_fetching")
                    } else if (receiptFetcher.state !== ReceiptFetcher.StateIdle) {
                        //: Button text
                        //% "Fetch receipt"
                        return qsTrId("text-fetch_receipt")
                    } else {
                        return ""
                    }
                }
                visible: isNeeded
                enabled: !holdOffTimer.running
                onClicked: {
                    if (isUrl) {
                        console.log("opening", codeItem.text)
                        Qt.openUrlExternally(codeItem.text)
                        holdOffTimer.restart()
                    } else if (haveEvent) {
                        console.log("importing", calendarEvent.url)
                        Qt.openUrlExternally(calendarEvent.url)
                        holdOffTimer.restart()
                    } else if (haveContact) {
                        // Workaround for Sailfish.Contacts not being allowed in harbour apps
                        var page = Qt.createQmlObject("import QtQuick 2.0;import Sailfish.Silica 1.0;import Sailfish.Contacts 1.0; \
    Page { id: page; signal saveContact(); property alias contact: card.contact; property alias saveText: saveMenu.text; \
    ContactCard { id: card; PullDownMenu { MenuItem { id: saveMenu; onClicked: page.saveContact(); }}}}",
                            codeItem, "ContactPage")
                        pageStack.push(page, {
                            allowedOrientations: window.allowedOrientations,
                            contact: codeItem.vcard.contact(),
                            //: Pulley menu item (saves contact)
                            //% "Save"
                            saveText: qsTrId("contact-menu-save")
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

            Image {
                id: image

                readonly property bool isPortrait: sourceSize.height > sourceSize.width
                readonly property bool rotate: image.isPortrait !== codeItem.isPortrait

                anchors.horizontalCenter: parent.horizontalCenter
                source: (hasImage && recordId.length && AppSettings.saveImages) ?
                    ("image://scanner/saved/" + (codeItem.isPortrait ? "portrait/" : "landscape/") + recordId) : ""
                visible: status === Image.Ready
                asynchronous: true
                cache: false
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
