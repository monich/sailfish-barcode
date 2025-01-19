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

.pragma library
.import harbour.barcode 1.0 as App

var frontCameraId
var backCameraId

function isVcard(text) {
    if (text.length > 11 && text.substring(0,11) === "BEGIN:VCARD") {
        var c = text.charAt(11)
        return c === '\r' || c === '\n'
    }
    return false
}

function isVevent(text) {
    if (text.length > 12) {
        var c
        if (text.substring(0,12) === "BEGIN:VEVENT") {
            c = text.charAt(12)
            if (c === '\r' || c === '\n') {
                return true
            }
        }
        if (text.length > 15) {
            if (text.substring(0,15) === "BEGIN:VCALENDAR") {
                c = text.charAt(15)
                if (c === '\r' || c === '\n') {
                    return true
                }
            }
        }
    }
    return false
}

function isUrl(text) {
    return App.BarcodeUtils.urlScheme(text).length > 0
}

function isLink(text) {
    var scheme = App.BarcodeUtils.urlScheme(text)
    return scheme === "http" || scheme === "https"
}

function isText(text) {
    return !isLink(text);
}

function calendarText(text) {
    return (text.substring(0,12) === "BEGIN:VEVENT") ?
        ("BEGIN:VCALENDAR\nVERSION:1.0\n" + text + "\nEND:VCALENDAR") :
        text
}

function removeLineBreak(text) {
    return text.replace(/(\r|\n)+/g, ' ')
}

function convertLineBreaks(text) {
    return text.replace(/\r\n/g, '\n').replace(/\r/g, '\n')
}

function getValueText(value) {
    if (isLink(value)) {
        return value
    } else {
        return removeLineBreak(value)
    }
}
