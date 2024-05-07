/*
The MIT License (MIT)

Copyright (c) 2020-2024 Slava Monich

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

#ifndef BARCODE_UTILS_H
#define BARCODE_UTILS_H

#include <QObject>

class QQmlEngine;
class QJSEngine;

class BarcodeUtils :
    public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString mediaKeyQml READ mediaKeyQml CONSTANT)
    Q_PROPERTY(QString permissionsQml READ permissionsQml CONSTANT)
    Q_PROPERTY(QString peopleVCardModelQml READ peopleVCardModelQml CONSTANT)

public:
    BarcodeUtils(QObject* aParent = Q_NULLPTR);

    // Callback for qmlRegisterSingletonType<BarcodeUtils>
    static QObject* createSingleton(QQmlEngine*, QJSEngine*);

    static QString documentGalleryModelQml();
    static QString thumbnailQml();
    static QString mediaKeyQml();
    static QString permissionsQml();
    static QString peopleVCardModelQml();

    Q_INVOKABLE static QString urlScheme(QString);
    Q_INVOKABLE static QString barcodeFormatName(QString);
};

#endif // BARCODE_UTILS_H
