/*
The MIT License (MIT)

Copyright (c) 2022 Slava Monich

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

import "../components"
import "../harbour"

Page {
    id: thisPage

    property var contact

    signal saveContact()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingSmall

        PullDownMenu {
            MenuItem {
                //: Pulley menu item (saves contact)
                //% "Save contact"
                text: qsTrId("contact-menu-save_contact")
                onClicked: thisPage.saveContact()
            }
        }

        DetailItem {
            id: detailItemSample
            visible: false
            label: " "
            value: " "
        }

        Column {
            id: content

            width: parent.width

            readonly property int detailIconSize: detailItemSample.height - 2 * Theme.paddingSmall
            readonly property int detailLeftMargin: Theme.horizontalPageMargin + detailIconSize + Theme.paddingLarge

            PageHeader {
                title: !contact ? "" :
                    contact.displayLabel ? contact.displayLabel :
                    contact.primaryName ? contact.primaryName :
                    contact.secondaryName ? contact.secondaryName :
                    contact.companyName ? contact.companyName :
                    //: Default page title (contact page)
                    //% "Contact"
                    qsTrId("contact-title-default")
                description: (!contact || contact.companyName === title) ? "" : contact.companyName
            }

            Image {
                id: contactImage

                readonly property bool available: status === Image.Ready
                property int itemSize: Math.round(Screen.width/3)

                anchors.horizontalCenter: parent.horizontalCenter
                width: itemSize
                height: itemSize
                sourceSize: Qt.size(itemSize, itemSize)
                fillMode: Image.PreserveAspectCrop
                source: !contact ? "" : contact.avatarUrl
                visible: available
                cache: false
                clip: true
            }

            VerticalGap {
                visible: contactImage.visible
            }

            CopyableDetailItem {
                id: primaryName

                label: secondaryName.visible ?
                    //: Contact detail label
                    //% "Primary name"
                    qsTrId("contact-detail-primary_name") :
                    //: Contact detail label
                    //% "Name"
                    qsTrId("contact-detail-name")
                value: contact.primaryName
                visible: !!value
                leftMargin: content.detailLeftMargin
            }

            CopyableDetailItem {
                id: secondaryName

                label: primaryName.visible ?
                    //: Contact detail label
                    //% "Secondary name"
                    qsTrId("contact-detail-secondary_name") :
                    //: Contact detail label
                    //% "Name"
                    qsTrId("contact-detail-name")
                value: contact.secondaryName
                visible: !!value
                leftMargin: content.detailLeftMargin
            }

            VerticalGap {
                visible: primaryName.visible || secondaryName.visible
            }

            Separator {
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Qt.AlignHCenter
                visible: (primaryName.visible ||
                    secondaryName.visible) && phoneDetails.count
            }

            Repeater {
                id: phoneDetails

                model: !contact ? [] : contact.removeDuplicatePhoneNumbers(contact.phoneDetails)

                CopyableDetailItem {
                    //: Contact detail label
                    //% "Phone"
                    label: index ? "" : qsTrId("contact-detail-phone")
                    value: modelData.number
                    visible: !!value || !index
                    leftMargin: content.detailLeftMargin

                    HarbourHighlightIcon {
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingSmall
                        visible: !index
                        source: visible ? "img/contact-phone.svg" : ""
                        sourceSize.height: content.detailIconSize
                    }
                }
            }

            Separator {
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Qt.AlignHCenter
                visible: (primaryName.visible ||
                    secondaryName.visible ||
                    phoneDetails.count) && emailDetails.count
            }

            Repeater {
                id: emailDetails

                model: !contact ? [] : contact.removeDuplicateEmailAddresses(contact.emailDetails)

                CopyableDetailItem {
                    //: Contact detail label
                    //% "E-mail"
                    label: index ? "" : qsTrId("contact-detail-email")
                    value: modelData.address
                    visible: !!value || !index
                    leftMargin: content.detailLeftMargin

                    HarbourHighlightIcon {
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingSmall
                        visible: !index
                        source: visible ? "img/contact-email.svg" : ""
                        sourceSize.height: content.detailIconSize
                    }
                }
            }

            Separator {
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Qt.AlignHCenter
                visible: (primaryName.visible ||
                    secondaryName.visible ||
                    phoneDetails.count ||
                    emailDetails.count) && addressDetails.count
            }

            Repeater {
                id: addressDetails

                model: !contact ? [] : contact.addressDetails

                CopyableDetailItem {
                    //: Contact detail label
                    //% "Address"
                    label: index ? "" : qsTrId("contact-detail-address")
                    value: modelData.address
                    visible: !!value || !index
                    leftMargin: content.detailLeftMargin

                    HarbourHighlightIcon {
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingSmall
                        visible: !index
                        source: visible ? "img/contact-address.svg" : ""
                        sourceSize.height: content.detailIconSize
                    }
                }
            }

            Separator {
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Qt.AlignHCenter
                visible: (primaryName.visible ||
                    secondaryName.visible ||
                    phoneDetails.count ||
                    emailDetails.count ||
                    addressDetails.count) && websiteDetails.count
            }

            Repeater {
                id: websiteDetails

                model: !contact ? [] : contact.websiteDetails

                CopyableDetailItem {
                    //: Contact detail label
                    //% "Website"
                    label: index ? "" : qsTrId("contact-detail-website")
                    value: modelData.url
                    visible: !!value || !index
                    leftMargin: content.detailLeftMargin

                    HarbourHighlightIcon {
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingSmall
                        visible: !index
                        source: visible ? "img/contact-website.svg" : ""
                        sourceSize.height: content.detailIconSize
                    }
                }
            }

            Separator {
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Qt.AlignHCenter
                visible: (primaryName.visible ||
                    secondaryName.visible ||
                    phoneDetails.count ||
                    emailDetails.count ||
                    addressDetails.count ||
                    websiteDetails.count) && birthdayDetail.visible
            }

            CopyableDetailItem {
                id: birthdayDetail

                readonly property var birthdayDetail: !contact ? undefined : contact.birthdayDetail
                //: Contact detail label
                //% "Birthday"
                label: qsTrId("contact-detail-birthday")
                value: isNaN(birthdayDetail.date) ? "" : Qt.formatDate(birthdayDetail.date)
                visible: !!value
                leftMargin: content.detailLeftMargin

                HarbourHighlightIcon {
                    x: Theme.horizontalPageMargin
                    y: Theme.paddingSmall
                    visible: parent.visible
                    source: visible ? "img/contact-date.svg" : ""
                    sourceSize.height: content.detailIconSize
                }
            }

            Separator {
                width: parent.width
                color: Theme.highlightColor
                horizontalAlignment: Qt.AlignHCenter
                visible: (primaryName.visible ||
                    secondaryName.visible ||
                    phoneDetails.count ||
                    emailDetails.count ||
                    addressDetails.count ||
                    websiteDetails.count ||
                    birthdayDetail.visible) && noteDetails.count
            }

            Repeater {
                id: noteDetails

                model: !contact ? [] : contact.noteDetails

                CopyableDetailItem {
                    //: Contact detail label
                    //% "Note"
                    label: index ? "" : qsTrId("contact-detail-note")
                    value: modelData.note
                    visible: !!value || !index
                    leftMargin: content.detailLeftMargin

                    HarbourHighlightIcon {
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingSmall
                        visible: !index
                        source: visible ? "img/contact-note.svg" : ""
                        sourceSize.height: content.detailIconSize
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
