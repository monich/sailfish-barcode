/*
The MIT License (MIT)

Copyright (c) 2018 Slava Monich

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

#ifndef BARCODE_DECODER_H
#define BARCODE_DECODER_H

#include <QImage>
#include <QPoint>
#include <QString>
#include <QMetaType>

#include <zbar/QZBarImage.h>
#include <zbar/Symbol.h>

class Decoder {
    Q_DISABLE_COPY(Decoder)

public:
    class Result;

    Decoder();
    ~Decoder();

    Result decode(zbar::QZBarImage aImage);

private:
    class Private;
    Private* iPrivate;
};

class Decoder::Result {
friend class Decoder;

public:
    Result(QString aText, QList<QPointF> aPoints, zbar::zbar_symbol_type_t aFormat, QString formatName);
    Result(const Result& aResult);
    Result();
    ~Result();

    Result& operator = (const Result& aResult);

    bool isValid() const;
    QString getText() const;
    QList<QPointF> getPoints() const;
    zbar::zbar_symbol_type_t getFormat() const;
    QString getFormatName() const;

private:
    class Private;
    Private* iPrivate;
};

Q_DECLARE_METATYPE(Decoder::Result)

#endif // BARCODE_DECODER_H
