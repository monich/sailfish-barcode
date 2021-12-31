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

#include "ImageSource.h"

#include <zxing/common/GlobalHistogramBinarizer.h>

class ImageSource::Private {
public:
    static QImage gray(const QImage& aImage);
    static bool isGray(const QImage& aImage);
    static const QVector<QRgb> grayColorTable();
    static const QVector<QRgb> gGrayColorTable;
};

const QVector<QRgb> ImageSource::Private::gGrayColorTable(ImageSource::Private::grayColorTable());

const QVector<QRgb> ImageSource::Private::grayColorTable()
{
    QVector<QRgb> colors;
    colors.reserve(256);
    for (int i = 0; i < 256; i++) {
        colors.append(qRgb(i, i, i));
    }
    return colors;
}

bool ImageSource::Private::isGray(const QImage& aImage)
{
    if (aImage.format() == QImage::Format_Indexed8) {
        const int n = gGrayColorTable.count();
        if (aImage.colorCount() == n) {
            const QVector<QRgb> ct = aImage.colorTable();
            const QRgb* data1 = ct.constData();
            const QRgb* data2 = gGrayColorTable.constData();
            // Most of the time pointers would match
            if (data1 == data2 || !memcmp(data1, data2, sizeof(QRgb)*n)) {
                return true;
            }
        }
    }
    return false;
}

QImage ImageSource::Private::gray(const QImage& aImage)
{
    if (isGray(aImage) || aImage.isNull()) {
        return aImage;
    } else if (aImage.depth() != 32) {
        return gray(aImage.convertToFormat(QImage::Format_RGB32));
    } else {
        const int w = aImage.width();
        const int h =  aImage.height();
        QImage gray(w, h, QImage::Format_Indexed8);
        gray.setColorTable(gGrayColorTable);

        const uchar* idata = aImage.constBits();
        const uint istride = aImage.bytesPerLine();
        uchar* odata = gray.bits();
        const uint ostride = gray.bytesPerLine();

        for (int y = 0; y < h; y++, idata += istride, odata += ostride) {
            uchar* dest = odata;
            const QRgb* src = (const QRgb*)idata;
            for (int x = 0; x < w; x++) {
                const QRgb rgb = *src++;
                // *dest++ = qGray(rgb);
                // This is significantly faster than gGray() but is
                // just as good for our purposes:
                *dest++ = (uchar)((((rgb & 0x00ff0000) >> 16) +
                    ((rgb & 0x0000ff00) >> 8) +
                    (rgb & 0xff))/3);
            }
        }
        return gray;
    }
}

ImageSource::ImageSource(const QImage& aImage) :
    zxing::LuminanceSource(aImage.width(), aImage.height()),
    iImage(Private::gray(aImage))
{
}

ImageSource::~ImageSource()
{
}

zxing::ArrayRef<zxing::byte> ImageSource::getRow(int aY, zxing::ArrayRef<zxing::byte> aRow) const
{
    const int width = getWidth();
    if (aRow->size() != width) {
        aRow.reset(zxing::ArrayRef<zxing::byte>(width));
    }
    memcpy(&aRow[0], getGrayRow(aY), width);
    return aRow;
}

zxing::ArrayRef<zxing::byte> ImageSource::getMatrix() const
{
    const int width = getWidth();
    const int height =  getHeight();
    zxing::ArrayRef<zxing::byte> matrix(width*height);
    zxing::byte* m = &matrix[0];

    for (int y = 0; y < height; y++) {
        memcpy(m, getGrayRow(y), width);
        m += width;
    }

    return matrix;
}

const zxing::byte* ImageSource::getGrayRow(int aY) const
{
    return iImage.constBits() + aY * iImage.bytesPerLine();
}

// Strictly for debugging
QImage ImageSource::bwImage()
{
    zxing::GlobalHistogramBinarizer binarizer(zxing::Ref<zxing::LuminanceSource>(this));
    try {
        zxing::Ref<zxing::BitMatrix> matrix = binarizer.getBlackMatrix();
        const int w = iImage.width();
        const int h =  iImage.height();
        QImage img(w, h, QImage::Format_Mono);
        QVector<QRgb> colors;
        colors.append(qRgb(255, 255, 255));
        colors.append(qRgb(0, 0, 0));
        img.setColorTable(colors);
        for (int y = 0; y < h; y ++) {
            zxing::Ref<zxing::BitArray> row = matrix->getRow(y, zxing::Ref<zxing::BitArray>());
            uchar* ptr = img.scanLine(y);
            for (int x = 0; x < w; ) {
                uchar b = 0;
                for (int i = 0; i < 8; i++, x++) {
                    b = (b << 1) | ((uchar) row->get(x));
                }
                *ptr++ = b;
            }
        }
        return img;
    } catch (std::exception&) {
        // GlobalHistogramBinarizer::getBlackMatrix() has thrown up
        return QImage();
    }
}
