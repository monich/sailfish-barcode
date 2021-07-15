/*
The MIT License (MIT)

Copyright (c) 2021 Slava Monich

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

import "../components"
import "../js/DGCert.js" as DGCert

Page {
    id: thisPage

    property alias text: certModel.text

    DGCertModel {
        id: certModel
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: parent.width

            PageHeader {
                //: Page header
                //% "EU Digital COVID Certificate"
                title: qsTrId("dgcert-page_header")
                //: Page description
                //% "Schema version %1"
                description: qsTrId("dgcert-schema_version").arg(certModel.schemaVersion)
            }

            VerticalGap { }

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "img/eu-flag.svg"
                sourceSize.width: Theme.itemSizeHuge

                Label {
                    id: euIssuerCountryCode

                    readonly property int defaultSize: parent.height / 3
                    visible: DGCert.isEUCountryCode(certModel.issuer)
                    text: certModel.issuer
                    anchors.centerIn: parent
                    minimumPixelSize: Theme.fontSizeSmall
                    fontSizeMode: Text.Fit
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    width: defaultSize
                    color: "white"
                    font {
                        family: Theme.fontFamilyHeading
                        bold: true
                    }
                }
            }

            VerticalGap { }

            // The actual contents is shown when model is ready.
            // That usually happens well before the page push animation
            // is finished
            Column {
                width: parent.width
                opacity: certModel.valid ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { FadeAnimation { } }

                DetailItem {
                    //: Detail label (common field)
                    //% "Issuer"
                    label: qsTrId("dgcert-common-issuer")
                    value: certModel.issuer
                    visible: !euIssuerCountryCode.visible
                }

                DetailItem {
                    //: Detail label (common field)
                    //% "Issue date"
                    label: qsTrId("dgcert-common-issue_date")
                    value: DGCert.dateTimeString(certModel.issueDate)
                }

                DetailItem {
                    //: Detail label (common field)
                    //% "Expiration date"
                    label: qsTrId("dgcert-common-expiration_date")
                    value: DGCert.dateTimeString(certModel.expirationDate)
                }

                VerticalGap { }

                Separator {
                    width:parent.width
                    color: Theme.highlightColor
                    horizontalAlignment: Qt.AlignHCenter
                }

                VerticalGap { }

                DetailItem {
                    //: Detail label (personal details)
                    //% "Name"
                    label: qsTrId("dgcert-personal-name")
                    value: certModel.personName.gn + " " + certModel.personName.fn
                }

                DetailItem {
                    //: Detail label (personal details)
                    //% "Standardized name"
                    label: qsTrId("dgcert-personal-standardized_name")
                    value: certModel.personName.gnt + " " + certModel.personName.fnt
                }

                DetailItem {
                    //: Detail label (personal details)
                    //% "Date of birth"
                    label: qsTrId("dgcert-personal-date_of_birth")
                    value: certModel.birthday
                }

                SilicaListView {
                    id: groupList

                    width: parent.width
                    orientation: ListView.Horizontal
                    snapMode: ListView.SnapOneItem
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    flickDeceleration: maximumFlickVelocity
                    height: contentItem.childrenRect.height
                    interactive: count > 0
                    model: certModel

                    // There's usually only one item in this list
                    delegate: Loader {
                        property var contents: model.contents
                        width: groupList.width
                        source: (model.type === DGCertModel.VaccinationCertificate) ? "../components/CovidVaccinationInfo.qml" :
                            (model.type === DGCertModel.RecoveryCertificate) ? "../components/CovidRecoveryInfo.qml" :
                            (model.type === DGCertModel.TestCertificate) ? "../components/CovidTestInfo.qml" : null
                    }
                }

                VerticalGap { }

                Separator {
                    width:parent.width
                    color: Theme.highlightColor
                    horizontalAlignment: Qt.AlignHCenter
                }

                VerticalGap { }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - x * 2
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                    //: Disclaimer
                    //% "The signature is not checked and therefore the validity of the certificate is not guaranteed."
                    text: qsTrId("dgcert-signature_disclaimer")
                }

                VerticalGap { }
            }
        }

        VerticalScrollDecorator { }
    }
}
