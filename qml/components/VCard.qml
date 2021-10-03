/*
The MIT License (MIT)

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
import org.nemomobile.notifications 1.0
import org.nemomobile.dbus 2.0
//import org.nemomobile.contacts 1.0
import harbour.barcode 1.0

Item {
    id: vcard
    visible: false

    property alias count: model.count
    property alias content: file.content

    function importContact() {
        var url
        if (SystemInfo.osVersionCompare("4.0") >= 0) {
            // Newer Contacts app can't access /tmp
            importFile.content = file.content
            url = importFile.url
        } else {
            // Didn't have to litter ~/Downloads in earlier versions of Sailfish OS
            url = file.url
        }

        contactsDbusIface.call("importContactFile", ["" + url],
            function(result) {
                //: Pop-up notification
                //% "Contact saved"
                notification.previewBody = qsTrId("contact-notification-saved")
                notification.publish()
            },
            function(error, message) {
                console.log(error)
                // org.freedesktop.DBus.Error.ServiceUnknown convers both D-Bus API break
                // and sandboxing. The rest (e.g. org.freedesktop.DBus.Error.NoReply) is
                // considerd to be a success
                if (error === "org.freedesktop.DBus.Error.ServiceUnknown") {
                    if (ProcessState.jailedApp) {
                        //: Pop-up notification
                        //% "Failed to save the contact (blocked by sandboxing?)"
                        notification.previewBody = qsTrId("contact-notification-failed_jailed")
                    } else {
                        //: Pop-up notification
                        //% "Failed to save the contact"
                        notification.previewBody = qsTrId("contact-notification-failed")
                    }
                } else {
                    //: Pop-up notification
                    //% "Contact saved (or at least we tried)"
                    notification.previewBody = qsTrId("contact-notification-maybe_saved")
                }
                notification.publish()
            })
    }

    function contact() {
        return model.getPerson(0)
    }

    PeopleVCardModel {
        id: model
        source: file.fileName
    }

    DBusInterface {
        id: contactsDbusIface
        service: "com.jolla.contacts.ui"
        path: "/com/jolla/contacts/ui"
        iface: "com.jolla.contacts.ui"
    }

    Notification {
        id: notification
        expireTimeout: 2000
    }

    TemporaryFile {
        id: file

        location: TemporaryFile.Tmp
        fileTemplate: "barcodeXXXXXX.vcf"
    }

    TemporaryFile {
        id: importFile

        location: TemporaryFile.Downloads
        fileTemplate: "barcodeXXXXXX.vcf"
    }
}
