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
// Recovery certificate
//
// Recovery group, if present, MUST contain exactly 1 (one) entry
// describing exactly one recovery statement. All elements of the
// recovery group are mandatory, empty values are not supported.

Column {
    width: parent.width

    property var contents: parent.contents

    SectionHeader {
        //: Section header
        //% "Recovery certificate"
        text: qsTrId("dgcert-recovery-header")
    }

    DetailItem {
        //: Detail label (test group)
        //% "Disease or agent"
        label: qsTrId("dgcert-recovery-tg")
        value: DGCert.diseaseDisplayName(contents.tg)
    }

    DetailItem {
        //: Detail label (test group)
        //% "Date of the first positive test"
        label: qsTrId("dgcert-recovery-fr")
        value: contents.fr
    }

    DetailItem {
        //: Detail label (test group)
        //% "Country where the test was carried out"
        label: qsTrId("dgcert-recovery-co")
        value: contents.co
    }

    DetailItem {
        //: Detail label (test group)
        //% "Certificate issuer"
        label: qsTrId("dgcert-recovery-is")
        value: contents.is
    }

    DetailItem {
        //: Detail label (test group)
        //% "Certificate valid from"
        label: qsTrId("dgcert-recovery-df")
        value: contents.df
    }

    DetailItem {
        //: Detail label (test group)
        //% "Certificate valid until"
        label: qsTrId("dgcert-recovery-du")
        value: contents.du
    }

    DetailItem {
        //: Detail label (test group)
        //% "Unique certificate identifier"
        label: qsTrId("dgcert-recovery-ci")
        value: contents.ci
    }
}
