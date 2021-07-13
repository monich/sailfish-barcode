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

import "../js/DGCert.js" as DGCert

// Technical Specifications for EU Digital COVID Certificates
// JSON Schema Specification
// Schema version: 1.3.0
// 2021-06-09
//
// Vaccination certificate
//
// Vaccination group, if present, MUST contain exactly 1 (one) entry
// describing exactly one vaccination event. All elements of the
// vaccination group are mandatory, empty values are not supported.

Column {
    width: parent.width

    property var contents: parent.contents

    SectionHeader {
        //: Section header
        //% "Vaccination certificate"
        text: qsTrId("dgcert-vaccination-header")
    }

    DetailItem {
        //: Detail label (vaccination group)
        //% "Disease or agent targeted"
        label: qsTrId("dgcert-vaccination-tg")
        value: DGCert.diseaseDisplayName(contents.tg)
    }

    DetailItem {
        //: Detail label (vaccination group)
        //% "Type of the vaccine"
        label: qsTrId("dgcert-vaccination-vp")
        value: DGCert.vaccineTypeDisplayName(contents.vp)
    }

    DetailItem {
        //: Detail label (vaccination group)
        //% "Vaccine product"
        label: qsTrId("dgcert-vaccination-mp")
        value: DGCert.vaccineProductDisplayName(contents.mp)
    }

    DetailItem {
        //: Detail label (vaccination group)
        //% "Vaccine manufacturer"
        label: qsTrId("dgcert-vaccination-ma")
        value: DGCert.vaccineManufacturerDisplayName(contents.ma)
    }

    DetailItem {
        //: Detail label (vaccination group)
        //% "Number of doses"
        label: qsTrId("dgcert-vaccination-dn_sd")
        value: contents.dn + "/" + contents.sd
    }

    DetailItem {
        //: Detail label (vaccination group)
        //% "Date of vaccination"
        label: qsTrId("dgcert-vaccination-dt")
        value: contents.dt
    }

    DetailItem {
        //: Detail label (vaccination group)
        //% "Country of vaccination"
        label: qsTrId("dgcert-vaccination-co")
        value: contents.co
    }

    DetailItem {
        //: Detail label (vaccination group)
        //% "Certificate issuer"
        label: qsTrId("dgcert-vaccination-is")
        value: contents.is
    }

    DetailItem {
        //: Detail label (vaccination group)
        //% "Unique certificate identifier"
        label: qsTrId("dgcert-vaccination-ci")
        value: contents.ci
    }
}
