/*
The MIT License (MIT)

Copyright (c) 2026 Slava Monich

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

#include "BarcodeImageGrabber.h"

#include "HarbourDebug.h"

#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>

// ==========================================================================
// BarcodeImageGrabber::Private
// ==========================================================================

class BarcodeImageGrabber::Private
{
public:
    Private();

    void tryGrab(BarcodeImageGrabber*);

public:
    QQuickItem* iViewFinderItem;
    QRect iViewFinderRect;
    bool iNeedGrab;
    bool iCanGrab;
    bool iGrabbing;
};

BarcodeImageGrabber::Private::Private() :
    iViewFinderItem(Q_NULLPTR),
    iNeedGrab(false),
    iCanGrab(true),
    iGrabbing(false)
{}

void
BarcodeImageGrabber::Private::tryGrab(
    BarcodeImageGrabber* aGrabber)
{
    if (iNeedGrab && iCanGrab && !iGrabbing && iViewFinderItem) {
        QQuickWindow* window = iViewFinderItem->window();

        if (window) {
            HDEBUG("grabbing image");
            iGrabbing = true;
            Q_EMIT aGrabber->grabbingChanged();

            QImage image = window->grabWindow();

            iGrabbing = false;
            Q_EMIT aGrabber->grabbingChanged();

            if (!image.isNull()) {
                HDEBUG("grabbed" << image);
                iNeedGrab = false;
                Q_EMIT aGrabber->imageGrabbed(image, iViewFinderRect);
            }
        }
    }
}

// ==========================================================================
// BarcodeImageGrabber
// ==========================================================================

BarcodeImageGrabber::BarcodeImageGrabber(
    QObject* aParent) :
    QObject(aParent),
    iPrivate(new Private)
{
    HDEBUG("created");
}

BarcodeImageGrabber::~BarcodeImageGrabber()
{
    delete iPrivate;
    HDEBUG("destroyed");
}

QObject*
BarcodeImageGrabber::viewFinderItem() const
{
    return iPrivate->iViewFinderItem;
}

void
BarcodeImageGrabber::setViewFinderItem(
    QObject* aItem)
{
    QQuickItem* item = qobject_cast<QQuickItem*>(aItem);

    if (iPrivate->iViewFinderItem != item) {
        iPrivate->iViewFinderItem = item;
        Q_EMIT viewFinderItemChanged();
        iPrivate->tryGrab(this);
    }
}

QRect
BarcodeImageGrabber::viewFinderRect() const
{
    return iPrivate->iViewFinderRect;
}

void
BarcodeImageGrabber::setViewFinderRect(
    QRect aRect)
{
    if (iPrivate->iViewFinderRect != aRect) {
        iPrivate->iViewFinderRect = aRect;
        Q_EMIT viewFinderRectChanged();
    }
}

bool
BarcodeImageGrabber::canGrab() const
{
    return iPrivate->iCanGrab;
}

void
BarcodeImageGrabber::setCanGrab(
    bool aCanGrab)
{
    if (iPrivate->iCanGrab != aCanGrab) {
        iPrivate->iCanGrab = aCanGrab;
        Q_EMIT canGrabChanged();
        iPrivate->tryGrab(this);
    }
}

bool
BarcodeImageGrabber::grabbing() const
{
    return iPrivate->iGrabbing;
}

void
BarcodeImageGrabber::requestImage()
{
    iPrivate->iNeedGrab = true;
    iPrivate->tryGrab(this);
}
