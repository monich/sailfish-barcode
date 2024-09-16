/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2024 Slava Monich

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

#ifndef BARCODESCANNER_H
#define BARCODESCANNER_H

#include <QtCore/QObject>
#include <QtCore/QRect>
#include <QtCore/QVariantMap>
#include <QtGui/QImage>

class BarcodeScanner :
    public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject* viewFinderItem READ viewFinderItem WRITE setViewFinderItem NOTIFY viewFinderItemChanged)
    Q_PROPERTY(QRect viewFinderRect READ viewFinderRect WRITE setViewFinderRect NOTIFY viewFinderRectChanged)
    Q_PROPERTY(QString markerColor READ markerColor WRITE setMarkerColor NOTIFY markerColorChanged)
    Q_PROPERTY(int rotation READ rotation WRITE setRotation NOTIFY rotationChanged)
    Q_PROPERTY(ScanState scanState READ scanState NOTIFY scanStateChanged)
    Q_PROPERTY(bool canGrab READ canGrab WRITE setCanGrab NOTIFY canGrabChanged)
    Q_PROPERTY(bool grabbing READ grabbing NOTIFY grabbingChanged)
    Q_PROPERTY(bool inverted READ inverted WRITE setInverted NOTIFY invertedChanged)
    Q_PROPERTY(bool mirrored READ mirrored WRITE setMirrored NOTIFY mirroredChanged)
    Q_PROPERTY(uint decodingHints READ decodingHints WRITE setDecodingHints NOTIFY decodingHintsChanged)
    Q_ENUMS(ScanState)

public:
    enum ScanState {
        Idle,
        Scanning,
        Aborting,
        TimedOut
    };

    BarcodeScanner(QObject* aParent = Q_NULLPTR);
    virtual ~BarcodeScanner();

    Q_INVOKABLE void startScanning(int);
    Q_INVOKABLE void stopScanning();

    QObject* viewFinderItem() const;
    void setViewFinderItem(QObject*);

    QRect viewFinderRect() const;
    void setViewFinderRect(QRect);

    QString markerColor() const;
    void setMarkerColor(QString);

    int rotation() const;
    void setRotation(int);

    ScanState scanState() const;

    bool canGrab() const;
    void setCanGrab(bool);

    bool grabbing() const;

    bool inverted() const;
    void setInverted(bool);

    bool mirrored() const;
    void setMirrored(bool);

    uint decodingHints() const;
    void setDecodingHints(uint);

Q_SIGNALS:
    void decodingFinished(QImage image, QVariantMap result);
    void viewFinderItemChanged();
    void viewFinderRectChanged();
    void markerColorChanged();
    void rotationChanged();
    void scanStateChanged();
    void canGrabChanged();
    void grabbingChanged();
    void invertedChanged();
    void mirroredChanged();
    void decodingHintsChanged();

private:
    class Private;
    Private* iPrivate;
};

#endif // BARCODESCANNER_H
