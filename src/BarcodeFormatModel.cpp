/*
The MIT License (MIT)

Copyright (c) 2022 Slava Monich

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

#include "BarcodeFormatModel.h"

#include <zxing/BarcodeFormat.h>
#include <zxing/DecodeHints.h>

#include "HarbourDebug.h"

// Bits that are not really being used:
// MAXICODE
// UPC_EAN_EXTENSION
// RSS_14
// RSS_EXPANDED
#define ALL_FORMATS(f) \
    f(QR_CODE,"qrcode","QR Code") \
    f(AZTEC,"aztec","Aztec") \
    f(DATA_MATRIX,"datamatrix","Data Matrix") \
    f(PDF_417,"pdf417","PDF417") \
    f(CODABAR,"codabar","Codabar") \
    f(CODE_39,"code39","Code 39") \
    f(CODE_93,"code93","Code 93") \
    f(CODE_128,"code128","Code 128") \
    f(EAN_8,"ean8","EAN-8") \
    f(EAN_13,"ean13","EAN-13") \
    f(UPC_A,"upca","UPC-A") \
    f(UPC_E,"upce","UPC-E") \
    f(ITF,"itf14","ITF-14")

// ==========================================================================
// BarcodeFormatModel::Private
// ==========================================================================

class BarcodeFormatModel::Private
{
public:
    struct Format {
        uint hint;
        const QString ident;
        const QString sample;
        const QString name;
    };

    enum Role {
        HintRole = Qt::UserRole,
        EnabledRole,
        IdentifierRole,
        SampleRole,
        NameRole
    };

    static const Format FORMATS[];
    static const int FORMAT_COUNT;

    Private() : iHints(zxing::DecodeHints::DEFAULT_HINT.getHints()) { }

public:
    zxing::DecodeHintType iHints;
};

const BarcodeFormatModel::Private::Format BarcodeFormatModel::Private::FORMATS[] = {
    #define FORMAT_(ID,sample,name) { zxing::DecodeHints::ID##_HINT, \
    QString(QLatin1String(zxing::BarcodeFormat::barcodeFormatNames[zxing::BarcodeFormat::ID])), \
    QString(QLatin1String(sample)),QString(QLatin1String(name))},
    ALL_FORMATS(FORMAT_)
    #undef FORMAT_
};

const int BarcodeFormatModel::Private::FORMAT_COUNT =
    sizeof(BarcodeFormatModel::Private::FORMATS)/
    sizeof(BarcodeFormatModel::Private::FORMATS[0]);

// ==========================================================================
// BarcodeFormatModel
// ==========================================================================

BarcodeFormatModel::BarcodeFormatModel(QObject* aParent) :
    QAbstractListModel(aParent),
    iPrivate(new Private)
{
}

BarcodeFormatModel::~BarcodeFormatModel()
{
    delete iPrivate;
}

const QString BarcodeFormatModel::formatName(QString aIdent)
{
    for (int i = 0; i < Private::FORMAT_COUNT; i++) {
        const Private::Format* format = Private::FORMATS + i;
        if (aIdent == format->ident) {
            return format->name;
        }
    }
    return QString();
}

QHash<int,QByteArray> BarcodeFormatModel::roleNames() const
{
    QHash<int,QByteArray> roles;
    roles.insert(Private::HintRole, "hint");
    roles.insert(Private::EnabledRole, "enabled");
    roles.insert(Private::IdentifierRole, "identifier");
    roles.insert(Private::SampleRole, "sample");
    roles.insert(Private::NameRole, "name");
    return roles;
}

int BarcodeFormatModel::rowCount(const QModelIndex& aParent) const
{
    return Private::FORMAT_COUNT;
}

QVariant BarcodeFormatModel::data(const QModelIndex& aIndex, int aRole) const
{
    const int row = aIndex.row();
    if (row >=0 && row < Private::FORMAT_COUNT) {
        const Private::Format* format = Private::FORMATS + row;
        switch ((Private::Role)aRole) {
        case Private::HintRole: return format->hint;
        case Private::EnabledRole: return (iPrivate->iHints & format->hint) != 0;
        case Private::IdentifierRole: return format->ident;
        case Private::SampleRole: return format->sample;
        case Private::NameRole: return format->name;
        }
    }
    return QVariant();
}

uint BarcodeFormatModel::getHints() const
{
    return iPrivate->iHints;
}

void BarcodeFormatModel::setHints(uint aHints)
{
    HDEBUG(hex << aHints);
    if (iPrivate->iHints != aHints) {
        const uint oldHints = iPrivate->iHints;
        iPrivate->iHints = aHints;
        const QVector<int> role(1, Private::EnabledRole);
        for (int row = 0; row < Private::FORMAT_COUNT; row++) {
            const Private::Format* format = Private::FORMATS + row;
            if ((oldHints & format->hint) != (aHints & format->hint)) {
                const QModelIndex modelIndex(index(row));
                Q_EMIT dataChanged(modelIndex, modelIndex, role);
            }
        }
        Q_EMIT hintsChanged();
    }
}
