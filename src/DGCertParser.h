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

#ifndef DGCERT_PARSER_H
#define DGCERT_PARSER_H

#include <QString>
#include <QDateTime>
#include <QByteArray>
#include <QVariantMap>
#include <QThreadPool>
#include <QSharedPointer>

// Serialization scheme:
// JSON => CBOR => COSE => Compression => Base45
class DGCertParser
{
    class Private;

public:
    class Payload {
    public:
        QString iIssuer;
        QDateTime iIssueDate;
        QDateTime iExpirationDate;
        QVariantMap iHCert;
    };

    static bool mayBeValid(const QString& aBase45);
    static bool parse(const QString& aBase45, Payload* aPayload = Q_NULLPTR, int* aFormatVersion = Q_NULLPTR);
    static bool parseV1(const QByteArray& aCompressedBinary, Payload* aPayload = Q_NULLPTR);
    static QSharedPointer<QThreadPool> threadPool();
};

#endif // DGCERT_PARSER_H
