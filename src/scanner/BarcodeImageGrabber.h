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

#ifndef BARCODE_IMAGE_GRABBER_H
#define BARCODE_IMAGE_GRABBER_H

#include <QtCore/QObject>
#include <QtCore/QRect>
#include <QtGui/QImage>

class BarcodeImageGrabber :
    public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject* viewFinderItem READ viewFinderItem WRITE setViewFinderItem NOTIFY viewFinderItemChanged)
    Q_PROPERTY(QRect viewFinderRect READ viewFinderRect WRITE setViewFinderRect NOTIFY viewFinderRectChanged)
    Q_PROPERTY(bool canGrab READ canGrab WRITE setCanGrab NOTIFY canGrabChanged)
    Q_PROPERTY(bool grabbing READ grabbing NOTIFY grabbingChanged)

public:
    BarcodeImageGrabber(QObject* aParent = Q_NULLPTR);
    ~BarcodeImageGrabber();

    QObject* viewFinderItem() const;
    void setViewFinderItem(QObject*);

    QRect viewFinderRect() const;
    void setViewFinderRect(QRect);

    bool canGrab() const;
    void setCanGrab(bool);

    bool grabbing() const;

public Q_SLOTS:
    void requestImage();

Q_SIGNALS:
    void viewFinderItemChanged();
    void viewFinderRectChanged();
    void canGrabChanged();
    void grabbingChanged();
    void imageGrabbed(QImage image, QRect viewPort);

private:
    class Private;
    Private* iPrivate;
};

#endif // BARCODE_IMAGE_GRABBER_H
