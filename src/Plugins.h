/*
The MIT License (MIT)

Copyright (c) 2020 Slava Monich

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

#ifndef BARCODE_PLUGINS_H
#define BARCODE_PLUGINS_H

// Certain plugins are not allowed in harbour apps, can't be used
// directly, have to be loaded in a weird way

class QQmlEngine;

class Plugins {
    class Gallery;      // QtDocGallery
    class Contacts;     // org.nemomobile.contacts
    class Thumbnailer;  // org.nemomobile.thumbnailer
public:
    static void registerTypes(QQmlEngine* aEngine, const char* aModule, int v1, int v2);
};

#endif // BARCODE_PLUGINS_H
