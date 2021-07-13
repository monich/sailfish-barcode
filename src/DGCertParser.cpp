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

#include "DGCertParser.h"

#include "HarbourBase45.h"
#include "HarbourDebug.h"

#include <zlib.h>

// ==========================================================================
// DGCertParser::Private
// ==========================================================================

class DGCertParser::Private
{
public:

    struct Data {
        const uchar* ptr;
        const uchar* end;
    };

    typedef bool (*StringReader)(Data* aData, qint64 aCount, QString* aText);

    // See RFC 7049 (2.1. Major Types)
    enum ItemType {
        InvalidItem = -1,
        UnsignedInt = 0,
        NegativeInt = 1,
        ByteString = 2,
        TextString = 3,
        ArrayItem = 4,
        MapItem = 5,
        TagItem = 6
    };

    enum {
        ValueUint8 = 24,
        ValueUint16 = 25,
        ValueUint32 = 26,
        ValueUint64 = 27
    };

    // Technical Specifications for Digital Green Certificates
    // Volume 1
    // 3.3.1 CWT Structure Overview
    // ...
    // • Issuer (iss, claim key 1, optional, ISO 3166-1 alpha-2 of issuer)
    // • Issued At (iat, claim key 6)
    // • Expiration Time (exp, claim key 4)
    // • Health Certificate (hcert, claim key -260
    //   - Digital Green Certificate v1 (eu_dgc_v1, claim key 1)

    // Technical Specifications for Digital Green Certificates
    // Volume 3
    // 2.6.3 Common Payload Values
    // ...
    // +========================================================+
    // | Key  | Name  | Type | Description                      |
    // +========================================================+
    // | 1    | iss   | bstr | Issuer of the DGC                |
    // | 6    | iat   | bstr | Issuing Date of the DGC          |
    // | 4    | exp   | bstr | Expiring Date of the DGC         |
    // | -260 | hcert | map  | Payload of the DGC (Vac,Tst,Rec) |
    // +========================================================+
    //
    // Payload format:
    //
    // Technical Specifications for EU Digital COVID Certificates
    // JSON Schema Specification
    //
    // Common structures and general requirements
    //
    // "JSON": {
    //   "ver": <version information>,
    //   "nam": {
    //     <person name information>
    //   },
    //   "dob": <date of birth>,
    //   "v" or "t" or "r": [
    //       {<vaccination dose or test or recovery information, one entry>}
    //     ]
    //   }
    //

    enum PayloadKeys {
        KEY_ISS = 1,
        KEY_IAT = 6,
        KEY_EXP = 4,
        KEY_HCERT = -260,
        KEY_HCERT_EU_DGC_V1 = 1
    };

    static const QString V1_PREFIX;

    static bool skipItem(Data* aData);
    static bool skipItems(Data* aData, qint64 aCount);
    static bool skipBytes(Data* aData, qint64 aCount);
    static bool readValueU8(Data* aData, quint8* aValue);
    static bool readValueU16(Data* aData, quint16* aValue);
    static bool readValueU32(Data* aData, quint32* aValue);
    static bool readValueU64(Data* aData, quint64* aValue);
    static bool readValue(Data* aData, uchar aInfo, qint64* aValue);
    static ItemType readItem(Data* aData, qint64* aValue, bool aSkipTag = true);
    static bool readBytes(Data* aData, qint64 aCount, QByteArray* aBytes);
    static bool readUtf8(Data* aData, qint64 aCount, QString* aText);
    static bool readLatin1(Data* aData, qint64 aCount, QString* aText);
    static bool readStringItem(Data* aData, StringReader aReader, QString* aText, bool aCanSkip = true);
    static QVariant readVariant(Data* aData);
    static bool parsePayload(Data* aData, Payload* aPayload);
    static bool parseCOSE(Data* aData, Payload* aPayload);
    static bool parseV1(const QByteArray& aBinary, Payload* aPayload);
    static QByteArray uncompress(const QByteArray& aCompressed);
};

const QString DGCertParser::Private::V1_PREFIX("HC1:");

inline bool DGCertParser::Private::skipBytes(Data* aData, qint64 aCount)
{
    return readBytes(aData, aCount, Q_NULLPTR);
}

bool DGCertParser::Private::skipItem(Data* aData)
{
    qint64 value;

    switch (readItem(aData, &value)) {
    case UnsignedInt:
    case NegativeInt:
        return true;
    case ByteString:
    case TextString:
        return skipBytes(aData, value);
    case MapItem:
        return skipItems(aData, 2 * value);
    case ArrayItem:
        return skipItems(aData, value);
    default:
        HDEBUG("Unsupported item");
        return false;
    }
}

bool DGCertParser::Private::skipItems(Data* aData, qint64 aCount)
{
    if (aCount >= 0) {
        for (qint64 i = 0; i < aCount; i++) {
            if (!skipItem(aData)) {
                return false;
            }
        }
        return true;
    }
    return false;
}

bool DGCertParser::Private::readValueU8(Data* aData, quint8* aValue)
{
    if (aData->ptr < aData->end) {
        *aValue = aData->ptr[0];
        aData->ptr++;
        return true;
    }
    return false;
}

bool DGCertParser::Private::readValueU16(Data* aData, quint16* aValue)
{
    if (aData->ptr + 1 < aData->end) {
        *aValue = (((quint16)aData->ptr[0]) << 8) | aData->ptr[1];
        aData->ptr += 2;
        return true;
    }
    return false;
}

bool DGCertParser::Private::readValueU32(Data* aData, quint32* aValue)
{
    if (aData->ptr + 3 < aData->end) {
        *aValue = ((((((((quint32)aData->ptr[0]) << 8) |
            aData->ptr[1]) << 8) | aData->ptr[2]) << 8) |
            aData->ptr[3]);
        aData->ptr += 4;
        return true;
    }
    return false;
}

bool DGCertParser::Private::readValueU64(Data* aData, quint64* aValue)
{
    if (aData->ptr + 3 < aData->end) {
        *aValue = ((((((((((((((((quint64)aData->ptr[0]) << 8) |
            aData->ptr[1]) << 8) | aData->ptr[2]) << 8) |
            aData->ptr[3]) << 8) | aData->ptr[4]) << 8) |
            aData->ptr[5]) << 8) | aData->ptr[6]) << 8) |
            aData->ptr[7]);
        aData->ptr += 4;
        return true;
    }
    return false;
}

bool DGCertParser::Private::readValue(Data* aData, uchar aInfo, qint64* aValue)
{
    if (aInfo < ValueUint8) {
        *aValue = aInfo;
        return true;
    } else {
        quint8 u8;
        quint16 u16;
        quint32 u32;

        switch (aInfo) {
        case ValueUint8:
            if (readValueU8(aData, &u8)) {
                *aValue = u8;
                return true;
            }
            break;
        case ValueUint16:
            if (readValueU16(aData, &u16)) {
                *aValue = u16;
                return true;
            }
            break;
        case ValueUint32:
            if (readValueU32(aData, &u32)) {
                *aValue = u32;
                return true;
            }
            break;
        case ValueUint64:
            return readValueU64(aData, (quint64*)aValue);
        }
    }
    return false;
}

DGCertParser::Private::ItemType
DGCertParser::Private::readItem(Data* aData, qint64* aValue, bool aSkipTag)
{
    if (aData->ptr < aData->end) {
        // RFC 7049
        // Concise Binary Object Representation (CBOR)
        // 2. Specification of the CBOR Encoding
        //
        // ...
        // The initial byte of each data item contains both information about
        // the major type (the high-order 3 bits, described in Section 2.1)
        // and additional information (the low-order 5 bits). When the value
        // of the additional information is less than 24, it is directly used
        // as a small unsigned integer. When it is 24 to 27, the additional
        // bytes for a variable-length integer immediately follow; the values
        // 24 to 27 of the additional information specify that its length is
        // a 1-, 2-, 4-, or 8-byte unsigned integer, respectively. Additional
        // information value 31 is used for indefinite-length items, described
        // in Section 2.2. Additional information values 28 to 30 are reserved
        // for future expansion.
        qint64 value;
        const uchar initialByte = *aData->ptr++;
        ItemType majorType = (ItemType)(initialByte >> 5);
        const uchar info = (initialByte & 0x1f);

        switch (majorType) {
        case TagItem:
            if (aSkipTag) {
                if (readValue(aData, info, &value)) {
                    HDEBUG("Skipping tag" << value);
                    majorType = readItem(aData, &value, false);
                    if (majorType != TagItem && majorType != InvalidItem) {
                        *aValue = value;
                        return majorType;
                    }
                }
            }
            break;
        case UnsignedInt:
        case ByteString:
        case TextString:
        case ArrayItem:
        case MapItem:
            // Watch for overflow
            if (readValue(aData, info, &value) && value >= 0) {
                *aValue = value;
                return majorType;
            }
            break;
        case NegativeInt:
            // Watch for overflow
            if (readValue(aData, info, &value) && value >= 0) {
                *aValue = (qint64)(-1) - value;
                return majorType;
            }
            break;
        default:
            break;
        }
    }
    return InvalidItem;
}

bool DGCertParser::Private::readUtf8(Data* aData, qint64 aCount, QString* aText)
{
    if (aCount >= 0 && (qint64)(aData->end - aData->ptr) >= aCount) {
        if (aText) {
            *aText = QString::fromUtf8((char*)aData->ptr, aCount);
        }
        aData->ptr += aCount;
        return true;
    }
    return false;
}

bool DGCertParser::Private::readLatin1(Data* aData, qint64 aCount, QString* aText)
{
    if (aCount >= 0 && (qint64)(aData->end - aData->ptr) >= aCount) {
        if (aText) {
            *aText = QString::fromLatin1((char*)aData->ptr, aCount);
        }
        aData->ptr += aCount;
        return true;
    }
    return false;
}

bool DGCertParser::Private::readStringItem(Data* aData, StringReader aReader, QString* aText, bool aCanSkip)
{
    qint64 len;

    switch (readItem(aData, &len)) {
    case TextString:
        return aReader(aData, len, aText);
    case InvalidItem:
        break;
    default:
        if (aCanSkip) {
            if (aText) {
                aText->clear();
            }
            return skipItem(aData);
        }
        break;
    }
    return false;
}

bool DGCertParser::Private::readBytes(Data* aData, qint64 aCount, QByteArray* aBytes)
{
    if (aCount >= 0 && (qint64)(aData->end - aData->ptr) >= aCount) {
        if (aBytes) {
            *aBytes = QByteArray((char*)aData->ptr, aCount);
        }
        aData->ptr += aCount;
        return true;
    }
    return false;
}

QVariant DGCertParser::Private::readVariant(Data* aData)
{
    QVariant out;
    if (aData->ptr < aData->end) {
        qint64 value;
        QString text;
        QByteArray bytes;
        const uchar initialByte = *aData->ptr++;
        const ItemType majorType = (ItemType)(initialByte >> 5);
        const uchar info = (initialByte & 0x1f);

        switch (majorType) {
        case TagItem:
            if (readValue(aData, info, &value)) {
                HDEBUG("Skipping tag" << value);
                out = readItem(aData, &value, false);
                if (out.isValid()) {
                    return out;
                }
            }
            break;
        case UnsignedInt:
            if (info < ValueUint8) {
                return QVariant((uint)info);
            } else {
                quint8 u8;
                quint16 u16;
                quint32 u32;
                quint64 u64;

                switch (info) {
                case ValueUint8:
                    if (readValueU8(aData, &u8)) {
                        return QVariant((uint)u8);
                    }
                    break;
                case ValueUint16:
                    if (readValueU16(aData, &u16)) {
                        return QVariant((uint)u16);
                    }
                    break;
                case ValueUint32:
                    if (readValueU32(aData, &u32)) {
                        return QVariant((uint)u32);
                    }
                    break;
                case ValueUint64:
                    if (readValueU64(aData, &u64)) {
                        return QVariant((uint)u64);
                    }
                    break;
                }
            }
            break;
        case NegativeInt:
            if (info < ValueUint8) {
                return QVariant((-1) - (int)info);
            } else {
                quint8 u8;
                quint16 u16;
                quint32 u32;
                quint64 u64;

                switch (info) {
                case ValueUint8:
                    if (readValueU8(aData, &u8)) {
                        return QVariant((-1) - (int)u8);
                    }
                    break;
                case ValueUint16:
                    if (readValueU16(aData, &u16)) {
                        return QVariant((-1) - (int)u16);
                    }
                    break;
                case ValueUint32:
                    if (readValueU32(aData, &u32)) {
                        return QVariant((-1) - (int)u32);
                    }
                    break;
                case ValueUint64:
                    if (readValueU64(aData, &u64)) {
                        return QVariant((qint64)(-1) - u64);
                    }
                    break;
                }
            }
            break;
        case ByteString:
            if (readValue(aData, info, &value) &&
                readBytes(aData, value, &bytes)) {
                return QVariant(bytes);
            }
            break;
        case TextString:
            if (readValue(aData, info, &value) &&
                readUtf8(aData, value, &text)) {
                return QVariant(text);
            }
            break;
        case ArrayItem:
            if (readValue(aData, info, &value) && value >= 0) {
                QVariantList array;

                for (qint64 i = 0; i < value; i++) {
                    QVariant entry = readVariant(aData);

                    if (entry.isValid()) {
                        array.append(entry);
                    } else {
                        return QVariant();
                    }
                }
                return QVariant(array);
            }
            break;
        case MapItem:
            if (readValue(aData, info, &value) && value >= 0) {
                QVariantMap map;

                for (qint64 i = 0; i < value; i++) {
                    QString key;

                    if (readStringItem(aData, readLatin1, &key, false)) {
                        QVariant entry = readVariant(aData);

                        if (entry.isValid()) {
                            map.insert(key, entry);
                            continue;
                        }
                    }
                    return QVariant();
                }
                return QVariant(map);
            }
            break;
        default:
            break;
        }
    }
    return QVariant();
}

bool DGCertParser::Private::parsePayload(Data* aData, Payload* aPayload)
{
    // Technical Specifications for Digital Green Certificates
    // Volume 3
    // 2.6.3 Common Payload Values
    //
    // +========================================================+
    // | Key  | Name  | Type | Description                      |
    // +========================================================+
    // | 1    | iss   | bstr | Issuer of the DGC                |
    // | 6    | iat   | bstr | Issuing Date of the DGC          |
    // | 4    | exp   | bstr | Expiring Date of the DGC         |
    // | -260 | hcert | map  | Payload of the DGC (Vac,Tst,Rec) |
    // +========================================================+
    ItemType type;
    qint64 n;

    if ((type = readItem(aData, &n)) == MapItem && n >= 4) {
        for (qint64 i = 0; i < n; i++) {
            qint64 key, value;
            QString text;

            type = readItem(aData, &key);
            if (type != UnsignedInt && type != NegativeInt) {
                skipItem(aData);
                continue;
            }
            switch (key) {
            case KEY_ISS:
                if ((type = readItem(aData, &value)) != TextString ||
                    !readLatin1(aData, value, &text)) {
                    HDEBUG("Failed to parse ISS entry");
                    return false;
                }
                HDEBUG("Issuer:" << text);
                if (aPayload) {
                    aPayload->iIssuer = text;
                }
                break;
            case KEY_IAT:
                if ((type = readItem(aData, &value)) != UnsignedInt) {
                    HDEBUG("Unexpected IAT valued type");
                    return false;
                }
                if (aPayload) {
                    aPayload->iIssueDate = QDateTime::fromTime_t(value);
                    HDEBUG("Issuing Date:" << aPayload->iIssueDate);
                } else {
                    HDEBUG("Issuing Date:" << QDateTime::fromTime_t(value));
                }
                break;
            case KEY_EXP:
                if ((type = readItem(aData, &value)) != UnsignedInt) {
                    HDEBUG("Unexpected EXP valued type");
                    return false;
                }
                if (aPayload) {
                    aPayload->iExpirationDate = QDateTime::fromTime_t(value);
                    HDEBUG("Expiring Date:" << aPayload->iExpirationDate);
                } else {
                    HDEBUG("Expiring Date:" << QDateTime::fromTime_t(value));
                }
                break;
            case KEY_HCERT:
                if ((type = readItem(aData, &value)) != MapItem) {
                    HDEBUG("Unexpected EXP valued type");
                    return false;
                } else {
                    const qint64 k = value;
                    qint64 hcertKey;

                    HDEBUG("HCERT map size" << k);
                    for (qint64 j = 0; j < k; j++) {
                        type = readItem(aData, &hcertKey);
                        if (type == UnsignedInt &&
                            hcertKey == KEY_HCERT_EU_DGC_V1) {
                            HDEBUG("EU DGC v1" << QByteArray((char*)
                                aData->ptr, aData->end - aData->ptr).toHex());
                            QVariant var = readVariant(aData);
                            if (var.isValid()) {
                                if (aPayload) {
                                    aPayload->iHCert = var.toMap();
                                    HDEBUG("EU_DGC_V1" << aPayload->iHCert);
                                } else {
                                    HDEBUG("EU_DGC_V1" << var.toMap());
                                }
                            } else {
                                HDEBUG("Failed to parse EU_DGC_V1");
                                return false;
                            }
                        } else {
                            skipItem(aData);
                        }
                    }
                }
                break;
            default:
                HDEBUG("Unknown payload key" << key);
                skipItem(aData);
                break;
            }
        }
        return true;
    }
    return false;
}

bool DGCertParser::Private::parseCOSE(Data* aData, Payload* aPayload)
{
    qint64 value;
    ItemType type = readItem(aData, &value);

    if (type == ArrayItem && value >= 4 &&
        // draft-ietf-cose-rfc8152bis-struct-15
        // Basic COSE Structure
        // 1. The protected header parameters, encoded and wrapped in a bstr.
       (type = readItem(aData, &value)) == ByteString &&
        skipBytes(aData, value) &&
        // 2. The unprotected header parameters as a map.
        (type = readItem(aData, &value)) == MapItem &&
        skipItems(aData, 2 * value) &&
        // 3. The content of the message
        (type = readItem(aData, &value)) == ByteString &&
        (qint64)(aData->end - aData->ptr) >= value) {
        Data data;

        data.ptr = aData->ptr;
        data.end = aData->ptr + value;
        HDEBUG("Payload" << QByteArray((char*)aData->ptr, value).toHex());
        return parsePayload(&data, aPayload);
    }
    return false;
}

bool DGCertParser::Private::parseV1(const QByteArray& aBinary, Payload* aPayload)
{
    if (!aBinary.isEmpty()) {
        Private::Data data;

        data.ptr = (uchar*) aBinary.constData();
        data.end = data.ptr + aBinary.size();
        if (parseCOSE(&data, aPayload)) {
            return true;
        }
    }
    return false;
}

QByteArray DGCertParser::Private::uncompress(const QByteArray& aCompressed)
{
    QByteArray out;

    if (!aCompressed.isEmpty()) {
        z_stream unzip;

        memset(&unzip, 0, sizeof(unzip));
        unzip.next_in = (Bytef*)aCompressed.constData();
        int zerr = inflateInit2(&unzip, MAX_WBITS);
        if (zerr == Z_OK) {
            const uint chunk = 0x200;
            out.resize(chunk);
            unzip.next_out = (Bytef*)out.data();
            unzip.avail_in = aCompressed.size();
            unzip.avail_out = chunk;
            HDEBUG("Compressed size" << aCompressed.size());
            while (unzip.avail_out > 0 && zerr == Z_OK) {
                zerr = inflate(&unzip, Z_NO_FLUSH);
                if (zerr == Z_OK && unzip.avail_out < chunk) {
                    // Data may get relocated, update next_out too
                    out.resize(out.size() + chunk);
                    unzip.next_out = (Bytef*)out.data() + unzip.total_out;
                    unzip.avail_out += chunk;
                }
            }
            if (zerr == Z_STREAM_END) {
                out.resize(unzip.next_out - (Bytef*)out.data());
                HDEBUG("Uncompressed size" << out.size());
            } else {
                out.clear();
            }
            inflateEnd(&unzip);
        }
    }
    return out;
}

// ==========================================================================
// DGCertParser
// ==========================================================================

bool DGCertParser::mayBeValid(const QString& aBase45)
{
    // Quick check, may be done on the main thread
    return aBase45.startsWith(Private::V1_PREFIX);
}

bool DGCertParser::parse(const QString& aBase45, Payload* aPayload, int* aFormatVersion)
{
    bool result = false;
    int formatVersion = 0;

    if (aBase45.startsWith(Private::V1_PREFIX)) {
        formatVersion = 1;
        const QString base45(aBase45.mid(Private::V1_PREFIX.length()));
        const QByteArray compressed(HarbourBase45::fromBase45(base45));
        if (!compressed.isEmpty()) {
            HDEBUG("Decoded" << compressed.size() << "bytes of compressed data" << compressed.toHex());
            result = parseV1(compressed, aPayload);
        }
    }
    if (aFormatVersion) {
        *aFormatVersion = result ? formatVersion : 0;
    }
    return result;
}

bool DGCertParser::parseV1(const QByteArray& aCompressedBinary, Payload* aPayload)
{
    if (!aCompressedBinary.isEmpty()) {
        const QByteArray uncompressed(Private::uncompress(aCompressedBinary));
        if (!uncompressed.isEmpty()) {
            HDEBUG("Uncompressed" << uncompressed.size() << "bytes of raw data" << uncompressed.toHex());
            return Private::parseV1(uncompressed, aPayload);
        }
    }
    return false;
}

// Thread pool shared by DGCertModel and DGCertRecognizer
QSharedPointer<QThreadPool> DGCertParser::threadPool()
{
    static QWeakPointer<QThreadPool> sharedPool;
    QSharedPointer<QThreadPool> pool = sharedPool;
    if (pool.isNull()) {
        pool = QSharedPointer<QThreadPool>::create();
        pool->setMaxThreadCount(2); // 2 threads shoud be enough
        sharedPool = pool;
    }
    return pool;
}
