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
// Test certificate

Column {
    width: parent.width

    property var contents: parent.contents

    SectionHeader {
        //: Section header
        //% "Test certificate"
        text: qsTrId("dgcert-test-header")
    }

    DetailItem {
        //: Detail label (test group)
        //% "Disease or agent"
        label: qsTrId("dgcert-test-tg")
        value: DGCert.diseaseDisplayName(contents.tg)
    }

    DetailItem {
        //: Detail label (test group)
        //% "The type of test"
        label: qsTrId("dgcert-test-tt")
        value: contents.tt
    }

    DetailItem {
        //: Detail label (test group)
        //% "Test name"
        label: qsTrId("dgcert-test-nm")
        value: visible ? contents.nm : ""
        visible: 'nm' in contents // Optional
    }

    DetailItem {
        //: Detail label (test group)
        //% "Test device identifier"
        label: qsTrId("dgcert-test-ma")
        value: visible ? contents.ma : ""
        visible: 'ma' in contents // Optional
    }

    DetailItem {
        //: Detail label (test group)
        //% "Date and time of the sample"
        label: qsTrId("dgcert-test-sc")
        value: DGCert.dateTimeString(new Date(contents.sc))
    }

    DetailItem {
        //: Detail label (test group)
        //% "Result of the test"
        label: qsTrId("dgcert-test-tr")
        value: DGCert.testResultDisplayName(contents.tr)
    }

    DetailItem {
        //: Detail label (test group)
        //% "Testing centre or facility"
        label: qsTrId("dgcert-test-tc")
        value: contents.tc
    }

    DetailItem {
        //: Detail label (test group)
        //% "Country where the test was carried out"
        label: qsTrId("dgcert-test-co")
        value: contents.co
    }

    DetailItem {
        //: Detail label (test group)
        //% "Certificate issuer"
        label: qsTrId("dgcert-test-is")
        value: contents.is
    }

    DetailItem {
        //: Detail label (test group)
        //% "Unique certificate identifier"
        label: qsTrId("dgcert-test-ci")
        value: contents.ci
    }
}
