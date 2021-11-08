/*
The MIT License (MIT)

Copyright (c) 2018-2020 Slava Monich

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

#include "Decoder.h"

#include "HarbourDebug.h"

#include <QAtomicInt>

#include <zbar/ImageScanner.h>
#include <zbar/Image.h>
#include <zbar/Symbol.h>
#include <zbar/include/zbar.h>

// ==========================================================================
// Decoder::Result::Private
// ==========================================================================

class Decoder::Result::Private {
public:
    Private(QString aText, QList<QPointF> aPoints,
            zbar::zbar_symbol_type_t aFormat, QString formatName);

public:
    QAtomicInt iRef;
    QString iText;
    QList<QPointF> iPoints;
    zbar::zbar_symbol_type_t iFormat;
    QString iFormatName;
};

Decoder::Result::Private::Private(QString aText, QList<QPointF> aPoints,
                                  zbar::zbar_symbol_type_t aFormat, QString formatName) :
    iRef(1), iText(aText), iPoints(aPoints), iFormat(aFormat),
    iFormatName(formatName)
{
}

// ==========================================================================
// Decoder::Result
// ==========================================================================

Decoder::Result::Result(QString aText, QList<QPointF> aPoints,
                        zbar::zbar_symbol_type_t aFormat, QString formatName) :
    iPrivate(new Private(aText, aPoints, aFormat, formatName))
{
}

Decoder::Result::Result(const Result& aResult) :
    iPrivate(aResult.iPrivate)
{
    if (iPrivate) {
        iPrivate->iRef.ref();
    }
}

Decoder::Result::Result() :
    iPrivate(NULL)
{
}

Decoder::Result::~Result()
{
    if (iPrivate && !iPrivate->iRef.deref()) {
        delete iPrivate;
    }
}

Decoder::Result& Decoder::Result::operator = (const Result& aResult)
{
    if (iPrivate != aResult.iPrivate) {
        if (iPrivate && !iPrivate->iRef.deref()) {
            delete iPrivate;
        }
        iPrivate = aResult.iPrivate;
        if (iPrivate) {
            iPrivate->iRef.ref();
        }
    }
    return *this;
}

bool Decoder::Result::isValid() const
{
    return iPrivate != NULL;
}

QString Decoder::Result::getText() const
{
    return iPrivate ? iPrivate->iText : QString();
}

QList<QPointF> Decoder::Result::getPoints() const
{
    return iPrivate ? iPrivate->iPoints : QList<QPointF>();
}

zbar::zbar_symbol_type_t Decoder::Result::getFormat() const
{
    return iPrivate ? iPrivate->iFormat : zbar::zbar_symbol_type_t::ZBAR_NONE;
}

QString Decoder::Result::getFormatName() const
{
    return iPrivate ? iPrivate->iFormatName : QString();
}

// ==========================================================================
// Decoder::Private
// ==========================================================================

class Decoder::Private {
public:
    Private();
    ~Private();

public:
    zbar::ImageScanner* iReader;
};

Decoder::Private::Private() :
    iReader(new zbar::ImageScanner)
{
    iReader->set_config(zbar::ZBAR_NONE, zbar::ZBAR_CFG_ENABLE, 1);
}

Decoder::Private::~Private()
{
    delete iReader;
}


// ==========================================================================
// Decoder
// ==========================================================================

Decoder::Decoder() : iPrivate(new Private)
{
}

Decoder::~Decoder()
{
    delete iPrivate;
}

Decoder::Result Decoder::decode(zbar::QZBarImage bitmap)
{
    zbar::Image tmp = bitmap.convert(*(long *)"Y800");
    iPrivate->iReader->scan(tmp);
    bitmap.set_symbols(tmp.get_symbols());

    auto symbols = tmp.get_symbols();
    for (auto symbol_it = symbols.symbol_begin(); symbol_it != symbols.symbol_end(); ++symbol_it) {
        auto symbol = *symbol_it;
        QList<QPointF> points;
        for (auto i = symbol.point_begin(); i != symbol.point_end(); ++i) {
            auto point = *i;
            points.append(QPointF(point.x, point.y));
        }

        const std::string& text = symbol.get_data();
        return Result(QString::fromStdString(text), points,
                      symbol.get_type(), QString::fromStdString(symbol.get_type_name()));
    }

    return Result();
}
