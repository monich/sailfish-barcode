/*
The MIT License (MIT)

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

#include "Decoder.h"
#include "ImageSource.h"

#include "HarbourDebug.h"

#include <QAtomicInt>

#include <zxing/MultiFormatReader.h>
#include <zxing/Binarizer.h>
#include <zxing/BinaryBitmap.h>
#include <zxing/common/GlobalHistogramBinarizer.h>

// ==========================================================================
// Decoder::Result::Private
// ==========================================================================

class Decoder::Result::Private {
public:
    Private(QString aText, QList<QPointF> aPoints, zxing::BarcodeFormat::Value aFormat);

public:
    QAtomicInt iRef;
    QString iText;
    QList<QPointF> iPoints;
    zxing::BarcodeFormat::Value iFormat;
    QString iFormatName;
};

Decoder::Result::Private::Private(QString aText, QList<QPointF> aPoints,
    zxing::BarcodeFormat::Value aFormat) :
    iRef(1), iText(aText), iPoints(aPoints), iFormat(aFormat),
    iFormatName(QLatin1String(zxing::BarcodeFormat::barcodeFormatNames[aFormat]))
{
}

// ==========================================================================
// Decoder::Result
// ==========================================================================

Decoder::Result::Result(QString aText, QList<QPointF> aPoints,
    zxing::BarcodeFormat aFormat) :
    iPrivate(new Private(aText, aPoints, aFormat))
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

zxing::BarcodeFormat::Value Decoder::Result::getFormat() const
{
    return iPrivate ? iPrivate->iFormat : zxing::BarcodeFormat::NONE;
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

    zxing::Ref<zxing::Result> decode(zxing::Ref<zxing::LuminanceSource> aSource);

public:
    zxing::MultiFormatReader* iReader;
    zxing::DecodeHints iHints;
};

Decoder::Private::Private() :
    iReader(new zxing::MultiFormatReader),
    iHints(zxing::DecodeHints::DEFAULT_HINT)
{
}

Decoder::Private::~Private()
{
    delete iReader;
}

zxing::Ref<zxing::Result> Decoder::Private::decode(zxing::Ref<zxing::LuminanceSource> aSource)
{
    zxing::Ref<zxing::Binarizer> binarizer(new zxing::GlobalHistogramBinarizer(aSource));
    zxing::Ref<zxing::BinaryBitmap> bitmap(new zxing::BinaryBitmap(binarizer));
    return iReader->decode(bitmap, iHints);
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

Decoder::Result Decoder::decode(QImage aImage)
{
    zxing::Ref<zxing::LuminanceSource> source(new ImageSource(aImage));
    return decode(source);
}

Decoder::Result Decoder::decode(zxing::Ref<zxing::LuminanceSource> aSource)
{
    try {
        zxing::Ref<zxing::Result> result(iPrivate->decode(aSource));

        QList<QPointF> points;
        zxing::ArrayRef<zxing::Ref<zxing::ResultPoint> > found(result->getResultPoints());
        for (int i = 0; i < found->size(); i++) {
            const zxing::ResultPoint& point(*(found[i]));
            points.append(QPointF(point.getX(), point.getY()));
        }

        const std::string& text = result->getText()->getText();
        return Result(QString::fromUtf8(text.c_str(), text.length()), points,
            result->getBarcodeFormat());
    } catch (zxing::Exception& e) {
        HDEBUG("Exception:" << e.what());
        return Result();
    }
}

void Decoder::setHints(const zxing::DecodeHints& aHints)
{
    iPrivate->iHints = aHints;
}
