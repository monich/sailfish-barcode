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

#include "BarcodeScanner.h"
#include "ImageSource.h"
#include "Decoder.h"

#include "HarbourDebug.h"

#include <QtConcurrent>
#include <QQuickWindow>
#include <QQuickItem>
#include <QPainter>
#include <QBrush>

#ifdef HARBOUR_DEBUG
#include <QStandardPaths>
static const QDir debugImageDir(QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/codereader");
static void saveDebugImage(const QImage& aImage, const QString& aFileName)
{
    if (!aImage.isNull()) {
        QString path = debugImageDir.filePath(aFileName);
        if (aImage.save(path)) {
            HDEBUG("image saved:" << qPrintable(path));
        }
    }
}
#else
#  define saveDebugImage(image,fileName) ((void)0)
#endif

// ==========================================================================
// BarcodeScanner::Private
// ==========================================================================

class BarcodeScanner::Private : public QObject {
    Q_OBJECT
public:
    Private(BarcodeScanner* aParent);
    ~Private();

    BarcodeScanner* scanner();

    bool setViewFinderRect(const QRect& aRect);
    bool setViewFinderItem(QObject* aValue);
    bool setMarkerColor(QString aValue);
    bool setRotation(int aDegrees);
    void startScanning(int aTimeout);
    void stopScanning();
    void grabImage();
    void decodingThread();
    void updateScanState();

Q_SIGNALS:
    void needImage();
    void decodingDone(QImage image, Decoder::Result result);

public Q_SLOTS:
    void onScanningTimeout();
    void onDecodingDone(QImage aImage, Decoder::Result aResult);
    void onGrabImage();

public:
    bool iCanGrab;
    bool iGrabbing;
    bool iScanning;
    bool iNeedImage;
    bool iAbortScan;
    bool iTimedOut;
    int iRotation;
    ScanState iLastKnownState;

    QImage iCaptureImage;
    QQuickItem* iViewFinderItem;
    QTimer* iScanTimeout;

    QMutex iDecodingMutex;
    QWaitCondition iDecodingEvent;
    QFuture<void> iDecodingFuture;

    QRect iViewFinderRect;
    QColor iMarkerColor;
};

BarcodeScanner::Private::Private(BarcodeScanner* aParent) :
    QObject(aParent),
    iCanGrab(true),
    iGrabbing(false),
    iScanning(false),
    iNeedImage(false),
    iAbortScan(false),
    iTimedOut(false),
    iRotation(0),
    iLastKnownState(Idle),
    iViewFinderItem(NULL),
    iScanTimeout(new QTimer(this)),
    iMarkerColor(QColor(0, 255, 0)) // default green
{
    iScanTimeout->setSingleShot(true);
    connect(iScanTimeout, SIGNAL(timeout()), SLOT(onScanningTimeout()));

    // Handled on the main thread
    qRegisterMetaType<Decoder::Result>();
    connect(this, SIGNAL(decodingDone(QImage,Decoder::Result)),
        SLOT(onDecodingDone(QImage,Decoder::Result)),
        Qt::QueuedConnection);

    // Forward needImage emitted by the decoding thread
    connect(this, SIGNAL(needImage()), SLOT(onGrabImage()),
        Qt::QueuedConnection);
}

BarcodeScanner::Private::~Private()
{
    stopScanning();
    iDecodingFuture.waitForFinished();
}

inline BarcodeScanner* BarcodeScanner::Private::scanner()
{
    return qobject_cast<BarcodeScanner*>(parent());
}

bool BarcodeScanner::Private::setViewFinderRect(const QRect& aRect)
{
    if (iViewFinderRect != aRect) {
        // iViewFinderRect is accessed by decodingThread() thread
        iDecodingMutex.lock();
        iViewFinderRect = aRect;
        iDecodingMutex.unlock();
        return true;
    }
    return false;
}

bool BarcodeScanner::Private::setViewFinderItem(QObject* aItem)
{
    QQuickItem* item = qobject_cast<QQuickItem*>(aItem);
    if (iViewFinderItem != item) {
        iViewFinderItem = item;
        return true;
    }
    return false;
}

bool BarcodeScanner::Private::setMarkerColor(QString aValue)
{
    if (QColor::isValidColor(aValue)) {
        QColor color(aValue);
        if (iMarkerColor != color) {
            iMarkerColor = color;
            return true;
        }
    }
    return false;
}

bool BarcodeScanner::Private::setRotation(int aDegrees)
{
    if (iRotation != aDegrees) {
        iDecodingMutex.lock();
        iRotation = aDegrees;
        iDecodingMutex.unlock();
        return true;
    }
    return false;
}

void BarcodeScanner::Private::startScanning(int aTimeout)
{
    if (!iScanning) {
        iScanning = true;
        iAbortScan = false;
        iTimedOut = false;
        if (aTimeout) {
            HDEBUG("timeout" << aTimeout);
            iScanTimeout->start(aTimeout);
        } else {
            HDEBUG("no timeout");
        }
        iCaptureImage = QImage();
        iDecodingFuture = QtConcurrent::run(this, &Private::decodingThread);
        updateScanState();
    }
}

void BarcodeScanner::Private::stopScanning()
{
    // stopping a running scanning process
    iDecodingMutex.lock();
    if (iScanning) {
        HDEBUG("aborting");
        iAbortScan = true;
        iDecodingEvent.wakeAll();
    }
    iDecodingMutex.unlock();
    updateScanState();
}

void BarcodeScanner::Private::grabImage()
{
    QQuickWindow* window = iViewFinderItem->window();
    if (window) {
        BarcodeScanner* parent = scanner();
        HDEBUG("grabbing image");
        iNeedImage = false;
        iGrabbing = true;
        Q_EMIT parent->grabbingChanged();
        QImage image = window->grabWindow();
        iGrabbing = false;
        Q_EMIT parent->grabbingChanged();
        if (!image.isNull() && iScanning) {
            HDEBUG(image);
            iDecodingMutex.lock();
            iCaptureImage = image;
            iDecodingEvent.wakeAll();
            iDecodingMutex.unlock();
        }
    }
}

void BarcodeScanner::Private::onGrabImage()
{
    if (iViewFinderItem && iScanning) {
        if (iCanGrab) {
            grabImage();
        } else {
            HDEBUG("not right now");
            iNeedImage = true;
        }
    }
}

void BarcodeScanner::Private::decodingThread()
{
    HDEBUG("decodingThread() is called from " << QThread::currentThread());

    Decoder decoder;
    Decoder::Result result;
    QImage image;
    qreal scale = 1;
    bool rotated = false;
    int scaledWidth = 0;

    const int maxSize = 800;

    iDecodingMutex.lock();
    while (!iAbortScan && !result.isValid()) {
        emit needImage();
        int rotation;
        QRect viewFinderRect;
        while (iCaptureImage.isNull() && !iAbortScan) {
            iDecodingEvent.wait(&iDecodingMutex);
        }
        if (iAbortScan) {
            image = QImage();
        } else {
            image = iCaptureImage;
            iCaptureImage = QImage();
        }
        viewFinderRect = iViewFinderRect;
        rotation = iRotation;
        iDecodingMutex.unlock();

        if (!image.isNull()) {
#if HARBOUR_DEBUG
            QTime time(QTime::currentTime());
#endif
            saveDebugImage(image, "debug_screenshot.bmp");

            // Crop the image - we only need the viewfinder area
            // Grabbed image is always in portrait orientation
            rotation %= 360;
            switch (rotation) {
            default:
                HDEBUG("Invalid rotation angle" << rotation);
            case 0:
                image = image.copy(viewFinderRect);
                break;
            case 90:
                {
                    QRect cropRect(image.width() - viewFinderRect.bottom(),
                        viewFinderRect.left(), viewFinderRect.height(),
                        viewFinderRect.width());
                    image = image.copy(cropRect).transformed(QTransform().
                        translate(cropRect.width()/2, cropRect.height()/2).
                        rotate(-90));
                }
                break;
            case 180:
                {
                    QRect cropRect(image.width() - viewFinderRect.right(),
                        image.height() - viewFinderRect.bottom(),
                        viewFinderRect.width(), viewFinderRect.height());
                    image = image.copy(cropRect).transformed(QTransform().
                        translate(cropRect.width()/2, cropRect.height()/2).
                        rotate(180));
                }
                break;
            case 270:
                {
                    QRect cropRect(viewFinderRect.top(),
                        image.height() - viewFinderRect.right(),
                        viewFinderRect.height(), viewFinderRect.width());
                    image = image.copy(cropRect).transformed(QTransform().
                        translate(cropRect.width()/2, cropRect.height()/2).
                        rotate(90));
                }
                break;
            }

            HDEBUG("extracted" << image);
            saveDebugImage(image, "debug_cropped.bmp");

#if HARBOUR_DEBUG
            // In debug build, ~/Pictures/codereader/debug_input.bmp gets
            // processed instead of the actual captured and cropped image,
            // if such file exists. Normally it doesn't exist. If you need
            // to debug decoding of the same image, you would do something
            // like this:
            //
            // $ mkdir ~/Pictures/codereader
            //
            // try debuging the image, abort/finish the decoding the then
            //
            // $ cd ~/Pictures/codereader
            // $ cp debug_cropped.bmp debug_input.bmp
            //
            // And then whenever you start capture this file will be picked
            // up instead of the actual input.
            //
            if (debugImageDir.exists()) {
                QImage debugImage;
                QString filePath = debugImageDir.filePath("debug_input.bmp");
                if (debugImage.load(filePath)) {
                    HDEBUG("LOADED" << qPrintable(filePath));
                    image = debugImage;
                }
            }
#endif // HARBOUR_DEBUG

            QImage scaledImage;
            if (image.width() > maxSize || image.height() > maxSize) {
                Qt::TransformationMode mode = Qt::SmoothTransformation;
                if (image.height() > image.width()) {
                    scaledImage = image.scaledToHeight(maxSize, mode);
                    scale = image.height()/(qreal)maxSize;
                    HDEBUG("scaled to height" << scale << scaledImage);
                } else {
                    scaledImage = image.scaledToWidth(maxSize, mode);
                    scale = image.width()/(qreal)maxSize;
                    HDEBUG("scaled to width" << scale << scaledImage);
                }
                saveDebugImage(scaledImage, "debug_scaled.bmp");
            } else {
                scaledImage = image;
                scale = 1;
            }

            // Ref takes ownership of ImageSource:
            ImageSource* source = new ImageSource(scaledImage);
            zxing::Ref<zxing::LuminanceSource> sourceRef(source);

#if HARBOUR_DEBUG
            // These are expensive, check if directory exists before
            // generating debug images (esp. the black & white one,
            // which is purely for debugging)
            if (debugImageDir.exists()) {
                saveDebugImage(source->grayscaleImage(), "debug_grayscale.bmp");
                saveDebugImage(source->bwImage(), "debug_bw.bmp");
            }
#endif // HARBOUR_DEBUG

            HDEBUG("decoding screenshot ...");
            result = decoder.decode(sourceRef);

            if (!result.isValid()) {
                // try the other orientation for 1D bar code
                QTransform transform;
                transform.rotate(90);
                scaledImage = scaledImage.transformed(transform);
                saveDebugImage(scaledImage, "debug_rotated.bmp");
                HDEBUG("decoding rotated screenshot ...");
                result = decoder.decode(scaledImage);
                // We need scaled width for rotating the points back
                scaledWidth = scaledImage.width();
                rotated = true;
            } else {
                rotated = false;
            }
            HDEBUG("decoding took" << time.elapsed() << "ms");
        }
        iDecodingMutex.lock();
    }
    iDecodingMutex.unlock();

    if (result.isValid()) {
        HDEBUG("decoding succeeded:" << result.getText() << result.getPoints());
        if (scale > 1 || rotated) {
            // The image could be a) scaled and b) rotated. Convert
            // points to the original coordinate system
            QList<QPointF> points = result.getPoints();
            const int n = points.size();
            for (int i = 0; i < n; i++) {
                QPointF p(points.at(i));
                if (rotated) {
                    const qreal x = p.rx();
                    p.setX(p.ry());
                    p.setY(scaledWidth - x);
                }
                p *= scale;
                HDEBUG(points[i] << "=>" << p);
                points[i] = p;
            }
            result = Decoder::Result(result.getText(), points, result.getFormat());
        }
    } else {
        HDEBUG("nothing was decoded");
        image = QImage();
    }
    Q_EMIT decodingDone(image, result);
}

void BarcodeScanner::Private::onDecodingDone(QImage aImage, Decoder::Result aResult)
{
    HDEBUG(aResult.getText());
    if (!aImage.isNull()) {
        const QList<QPointF> points(aResult.getPoints());
        HDEBUG("image:" << aImage);
        HDEBUG("points:" << points);
        HDEBUG("format:" << aResult.getFormat() << aResult.getFormatName());
        if (!points.isEmpty()) {
            QPainter painter(&aImage);
            painter.setPen(iMarkerColor);
            QBrush markerBrush(iMarkerColor);
            for (int i = 0; i < points.size(); i++) {
                const QPoint p(points.at(i).toPoint());
                painter.fillRect(QRect(p.x()-3, p.y()-15, 6, 30), markerBrush);
                painter.fillRect(QRect(p.x()-15, p.y()-3, 30, 6), markerBrush);
            }
            painter.end();
            saveDebugImage(aImage, "debug_marks.bmp");
        }

        // Scanning could succeed even AFTER it has timed out.
        // We still count that as a success.
        iTimedOut = false;
    }

    iCaptureImage = QImage();
    iScanTimeout->stop();
    iScanning = false;
    iNeedImage = false;

    QVariantMap result;
    result.insert("ok", QVariant::fromValue(aResult.isValid()));
    result.insert("text", QVariant::fromValue(aResult.getText()));
    result.insert("format", QVariant::fromValue(aResult.getFormatName()));
    Q_EMIT scanner()->decodingFinished(aImage, result);
    updateScanState();
}

void BarcodeScanner::Private::onScanningTimeout()
{
    iDecodingMutex.lock();
    iAbortScan = true;
    iTimedOut = true;
    HDEBUG("decoding aborted by timeout");
    iDecodingEvent.wakeAll();
    iDecodingMutex.unlock();
    updateScanState();
}

void BarcodeScanner::Private::updateScanState()
{
    const ScanState state = iScanning ?
        (iAbortScan ? Aborting : Scanning) :
        (iTimedOut ? TimedOut : Idle);
    if (iLastKnownState != state) {
        HDEBUG("state" << iLastKnownState << "->" << state);
        iLastKnownState = state;
        Q_EMIT scanner()->scanStateChanged();
    }
}

// ==========================================================================
// BarcodeScanner
// ==========================================================================

BarcodeScanner::BarcodeScanner(QObject* parent) :
    QObject(parent),
    iPrivate(new Private(this))
{
    HDEBUG("created");
}

BarcodeScanner::~BarcodeScanner()
{
    HDEBUG("destroyed");
}

const QRect& BarcodeScanner::viewFinderRect() const
{
    return iPrivate->iViewFinderRect;
}

void BarcodeScanner::setViewFinderRect(const QRect& aRect)
{
    if (iPrivate->setViewFinderRect(aRect)) {
        HDEBUG(aRect);
    }
}

QObject* BarcodeScanner::viewFinderItem() const
{
    return iPrivate->iViewFinderItem;
}

void BarcodeScanner::setViewFinderItem(QObject* aItem)
{
    if (iPrivate->setViewFinderItem(aItem)) {
        Q_EMIT viewFinderItemChanged();
    }
}

QString BarcodeScanner::markerColor() const
{
    return iPrivate->iMarkerColor.name();
}

void BarcodeScanner::setMarkerColor(QString aValue)
{
    if (iPrivate->setMarkerColor(aValue)) {
        HDEBUG(aValue);
        Q_EMIT markerColorChanged();
    }
}

int BarcodeScanner::rotation() const
{
    return iPrivate->iRotation;
}

void BarcodeScanner::setRotation(int aDegrees)
{
    if (iPrivate->setRotation(aDegrees)) {
        HDEBUG(aDegrees);
        Q_EMIT rotationChanged();
    }
}

void BarcodeScanner::startScanning(int aTimeout)
{
    iPrivate->startScanning(aTimeout);
}

void BarcodeScanner::stopScanning()
{
    iPrivate->stopScanning();
}

BarcodeScanner::ScanState BarcodeScanner::scanState() const
{
    return iPrivate->iLastKnownState;
}

bool BarcodeScanner::canGrab() const
{
    return iPrivate->iCanGrab;
}

void BarcodeScanner::setCanGrab(bool aCanGrab)
{
    if (iPrivate->iCanGrab != aCanGrab) {
        iPrivate->iCanGrab = aCanGrab;
        HDEBUG(iPrivate->iCanGrab);
        Q_EMIT canGrabChanged();
        if (iPrivate->iCanGrab &&
            iPrivate->iScanning &&
            iPrivate->iNeedImage) {
            iPrivate->grabImage();
        }
    }
}

bool BarcodeScanner::grabbing() const
{
    return iPrivate->iGrabbing;
}

#include "BarcodeScanner.moc"
