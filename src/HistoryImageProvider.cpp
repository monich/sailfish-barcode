/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
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

#include "HistoryImageProvider.h"
#include "Database.h"
#include "HarbourDebug.h"

#include <QHash>
#include <QMutex>

// ==========================================================================
// HistoryImageProvider::Private
// ==========================================================================

class HistoryImageProvider::Private {
public:
    Private() {}
    ~Private() {}

    static const QString SAVED;
    static const QString PORTRAIT;
    static const QString LANDSCAPE;

    static HistoryImageProvider* gInstance;

public:
    QMutex iMutex;
    QHash<QString,QImage> iCache;
};

const QString HistoryImageProvider::Private::SAVED("saved/");
const QString HistoryImageProvider::Private::PORTRAIT("portrait/");
const QString HistoryImageProvider::Private::LANDSCAPE("landscape/");

HistoryImageProvider* HistoryImageProvider::Private::gInstance = NULL;

// ==========================================================================
// HistoryImageProvider
// ==========================================================================

const QString HistoryImageProvider::IMAGE_EXT(".jpg");

HistoryImageProvider::HistoryImageProvider() :
    QQuickImageProvider(Image),
    iPrivate(new Private)
{
    if (!Private::gInstance) {
        Private::gInstance = this;
    }
}

HistoryImageProvider::~HistoryImageProvider()
{
    delete iPrivate;
    if (Private::gInstance == this) {
        Private::gInstance = Q_NULLPTR;
    }
}

HistoryImageProvider* HistoryImageProvider::instance()
{
    return Private::gInstance;
}

QImage HistoryImageProvider::requestImage(const QString& aId, QSize* aSize, const QSize&)
{
    QImage img;
    // We are expecting either "saved/portrait/id" or "saved/landscape/id"
    if (aId.startsWith(Private::SAVED)) {
        // "saved/" prefix is there
        QString recId;
        bool portrait = true;
        const QString imageId(aId.mid(Private::SAVED.length()));
        if (imageId.startsWith(Private::PORTRAIT)) {
            // "saved/portrait/" prefix
            recId = imageId.mid(Private::PORTRAIT.length());
        } else if (imageId.startsWith(Private::LANDSCAPE)) {
            // "saved/landscape/id" prefix
            recId = imageId.mid(Private::LANDSCAPE.length());
            portrait = false;
        }
        if (!recId.isEmpty()) {
            iPrivate->iMutex.lock();
            img = iPrivate->iCache.value(imageId);
            iPrivate->iMutex.unlock();
            if (img.isNull()) {
                const QString path(Database::imageDir().path() +
                    QDir::separator() + recId + IMAGE_EXT);
                if (QFile::exists(path)) {
                    if (img.load(path)) {
                        HDEBUG(aId << "=>" << qPrintable(path) << img.size());
                    } else {
                        HWARN("Failed to load " << qPrintable(path));
                    }
                } else {
                    HDEBUG(qPrintable(path) << "not found");
                }
            } else {
                HDEBUG(recId << "cached");
            }
            // Rotate the image is necessary
            if (!img.isNull()) {
                if ((img.height() > img.width()) != portrait) {
                    img = img.transformed(QTransform().
                        translate(img.width()/2.0, img.height()/2.0).
                        rotate(-90));
                }
                HDEBUG(img);
            }
        } else {
            HWARN("Invalid history image id" << recId);
        }
    } else {
        HWARN("Invalid history image URL" << aId);
    }

    if (!img.isNull() && aSize) {
        *aSize = img.size();
    }

    return img;
}

bool HistoryImageProvider::cacheImage(QString aImageId, QImage aImage)
{
    if (!aImageId.isEmpty() && !aImage.isNull()) {
        iPrivate->iMutex.lock();
        iPrivate->iCache.insert(aImageId, aImage);
        HDEBUG(aImageId);
        iPrivate->iMutex.unlock();
        return true;
    } else {
        return false;
    }
}

void HistoryImageProvider::dropFromCache(QString aImageId)
{
    iPrivate->iMutex.lock();
    if (iPrivate->iCache.remove(aImageId)) {
        HDEBUG(aImageId);
    }
    iPrivate->iMutex.unlock();
}

void HistoryImageProvider::clearCache()
{
    iPrivate->iMutex.lock();
    iPrivate->iCache.clear();
    iPrivate->iMutex.unlock();
}
