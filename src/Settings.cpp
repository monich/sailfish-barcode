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

#include "Settings.h"

#include "HarbourDebug.h"

#include <zxing/DecodeHints.h>

#include <MGConfItem>

#define DCONF_PATH_(x)                 SETTINGS_DCONF_PATH_(x)

// New keys (the ones that have only been in dconf)
#define KEY_BUZZ_ON_SCAN               "buzz_on_scan"
#define KEY_SAVE_IMAGES                "save_images"
#define KEY_WIDE_MODE                  "wide_mode"
#define KEY_ORIENTATION                "orientation"
#define KEY_MAX_DIGITAL_ZOOM           "max_digital_zoom"
#define KEY_VOLUME_ZOOM                "volume_zoom"
#define KEY_DECODING_HINTS             "decoding_hints"
#define KEY_RESOLUTION_4_3             "resolution_4_3"  // Width is stored
#define KEY_RESOLUTION_16_9            "resolution_16_9" // Width is stored

#define DEFAULT_SOUND                   false
#define DEFAULT_BUZZ_ON_SCAN            true
#define DEFAULT_DIGITAL_ZOOM            3
#define DEFAULT_MAX_DIGITAL_ZOOM        10
#define DEFAULT_SCAN_DURATION           20
#define DEFAULT_RESULT_VIEW_DURATION    2
#define DEFAULT_MARKER_COLOR            "#00FF00"
#define DEFAULT_HISTORY_SIZE            50
#define DEFAULT_SCAN_ON_START           false
#define DEFAULT_SAVE_IMAGES             true
#define DEFAULT_VOLUME_ZOOM             true
#define DEFAULT_WIDE_MODE               false
#define DEFAULT_DECODING_HINTS          zxing::DecodeHints::DEFAULT_HINT.getHints()
#define DEFAULT_ORIENTATION             Settings::OrientationAny

// Camera configuration (got removed at some point)
#define CAMERA_DCONF_PATH_(x)           "/apps/jolla-camera/primary/image/" x
#define CAMERA_DCONF_RESOLUTION_4_3     CAMERA_DCONF_PATH_("viewfinderResolution_4_3")
#define CAMERA_DCONF_RESOLUTION_16_9    CAMERA_DCONF_PATH_("viewfinderResolution_16_9")

// ==========================================================================
// Settings::Private
// ==========================================================================

class Settings::Private {
public:
    Private(Settings* aSettings);

    static const QString HINTS_ROOT;

    static QSize toSize(const QVariant);
    static QSize size_4_3(int);
    static QSize size_16_9(int);

    QSize resolution_4_3();
    QSize resolution_16_9();

public:
    const int iDefaultResolution_4_3;
    const int iDefaultResolution_16_9;
    MGConfItem* iSound;
    MGConfItem* iBuzzOnScan;
    MGConfItem* iDigitalZoom;
    MGConfItem* iMaxDigitalZoom;
    MGConfItem* iScanDuration;
    MGConfItem* iResultViewDuration;
    MGConfItem* iMarkerColor;
    MGConfItem* iHistorySize;
    MGConfItem* iScanOnStart;
    MGConfItem* iSaveImages;
    MGConfItem* iVolumeZoom;
    MGConfItem* iWideMode;
    MGConfItem* iDecodingHints;
    MGConfItem* iOrientation;
    MGConfItem* iResolution_4_3;
    MGConfItem* iResolution_16_9;
};

const QString Settings::Private::HINTS_ROOT(DCONF_PATH_("hints/"));

Settings::Private::Private(
    Settings* aSettings) :
    iDefaultResolution_4_3(toSize(MGConfItem(CAMERA_DCONF_RESOLUTION_4_3).value()).width()),
    iDefaultResolution_16_9(toSize(MGConfItem(CAMERA_DCONF_RESOLUTION_16_9).value()).width()),
    iSound(new MGConfItem(DCONF_PATH_(KEY_SOUND), aSettings)),
    iBuzzOnScan(new MGConfItem(DCONF_PATH_(KEY_BUZZ_ON_SCAN), aSettings)),
    iDigitalZoom(new MGConfItem(DCONF_PATH_(KEY_DIGITAL_ZOOM), aSettings)),
    iMaxDigitalZoom(new MGConfItem(DCONF_PATH_(KEY_MAX_DIGITAL_ZOOM), aSettings)),
    iScanDuration(new MGConfItem(DCONF_PATH_(KEY_SCAN_DURATION), aSettings)),
    iResultViewDuration(new MGConfItem(DCONF_PATH_(KEY_RESULT_VIEW_DURATION), aSettings)),
    iMarkerColor(new MGConfItem(DCONF_PATH_(KEY_MARKER_COLOR), aSettings)),
    iHistorySize(new MGConfItem(DCONF_PATH_(KEY_HISTORY_SIZE), aSettings)),
    iScanOnStart(new MGConfItem(DCONF_PATH_(KEY_SCAN_ON_START), aSettings)),
    iSaveImages(new MGConfItem(DCONF_PATH_(KEY_SAVE_IMAGES), aSettings)),
    iVolumeZoom(new MGConfItem(DCONF_PATH_(KEY_VOLUME_ZOOM), aSettings)),
    iWideMode(new MGConfItem(DCONF_PATH_(KEY_WIDE_MODE), aSettings)),
    iDecodingHints(new MGConfItem(DCONF_PATH_(KEY_DECODING_HINTS), aSettings)),
    iOrientation(new MGConfItem(DCONF_PATH_(KEY_ORIENTATION), aSettings)),
    iResolution_4_3(new MGConfItem(DCONF_PATH_(KEY_RESOLUTION_4_3), aSettings)),
    iResolution_16_9(new MGConfItem(DCONF_PATH_(KEY_RESOLUTION_16_9), aSettings))
{
    connect(iSound, SIGNAL(valueChanged()), aSettings, SIGNAL(soundChanged()));
    connect(iBuzzOnScan, SIGNAL(valueChanged()), aSettings, SIGNAL(buzzOnScanChanged()));
    connect(iDigitalZoom, SIGNAL(valueChanged()), aSettings, SIGNAL(digitalZoomChanged()));
    connect(iMaxDigitalZoom, SIGNAL(valueChanged()), aSettings, SIGNAL(maxDigitalZoomChanged()));
    connect(iScanDuration, SIGNAL(valueChanged()), aSettings, SIGNAL(scanDurationChanged()));
    connect(iResultViewDuration, SIGNAL(valueChanged()), aSettings, SIGNAL(resultViewDurationChanged()));
    connect(iMarkerColor, SIGNAL(valueChanged()), aSettings, SIGNAL(markerColorChanged()));
    connect(iHistorySize, SIGNAL(valueChanged()), aSettings, SIGNAL(historySizeChanged()));
    connect(iScanOnStart, SIGNAL(valueChanged()), aSettings, SIGNAL(scanOnStartChanged()));
    connect(iSaveImages, SIGNAL(valueChanged()), aSettings, SIGNAL(saveImagesChanged()));
    connect(iVolumeZoom, SIGNAL(valueChanged()), aSettings, SIGNAL(volumeZoomChanged()));
    connect(iWideMode, SIGNAL(valueChanged()), aSettings, SIGNAL(wideModeChanged()));
    connect(iDecodingHints, SIGNAL(valueChanged()), aSettings, SIGNAL(decodingHintsChanged()));
    connect(iOrientation, SIGNAL(valueChanged()), aSettings, SIGNAL(orientationChanged()));
    connect(iResolution_4_3, SIGNAL(valueChanged()), aSettings, SIGNAL(wideResolutionChanged()));
    connect(iResolution_16_9, SIGNAL(valueChanged()), aSettings, SIGNAL(narrowResolutionChanged()));
    HDEBUG("Default 4:3 resolution" << size_4_3(iDefaultResolution_4_3));
    HDEBUG("Default 16:9 resolution" << size_16_9(iDefaultResolution_16_9));
}

QSize
Settings::Private::toSize(
    const QVariant aVariant)
{
    // e.g. "1920x1080"
    if (aVariant.isValid()) {
        const QStringList values(aVariant.toString().split('x'));
        if (values.count() == 2) {
            bool ok = false;
            int width = values.at(0).toInt(&ok);
            if (ok && width > 0) {
                int height = values.at(1).toInt(&ok);
                if (ok && height > 0) {
                    return QSize(width, height);
                }
            }
        }
    }
    return QSize(0, 0);
}

QSize
Settings::Private::size_4_3(
    int aWidth)
{
    return QSize(aWidth, aWidth * 3 / 4);
}

QSize
Settings::Private::size_16_9(
    int aWidth)
{
    return QSize(aWidth, aWidth * 9 / 16);
}

QSize
Settings::Private::resolution_4_3()
{
    return size_4_3(qMax(iResolution_4_3->value(iDefaultResolution_4_3).toInt(), 0));
}

QSize
Settings::Private::resolution_16_9()
{
    return size_16_9(qMax(iResolution_16_9->value(iDefaultResolution_16_9).toInt(), 0));
}

// ==========================================================================
// Settings
// ==========================================================================

Settings::Settings(
    QObject* aParent) :
    QObject(aParent),
    iPrivate(new Private(this))
{
}

Settings::~Settings()
{
    delete iPrivate;
}

QString
Settings::hintKey(
    QString aHintName)
{
    return Private::HINTS_ROOT + aHintName;
}

bool
Settings::sound() const
{
    return iPrivate->iSound->value(DEFAULT_SOUND).toBool();
}

void
Settings::setSound(
    bool aValue)
{
    iPrivate->iSound->set(aValue);
}

bool
Settings::buzzOnScan() const
{
    return iPrivate->iBuzzOnScan->value(DEFAULT_BUZZ_ON_SCAN).toBool();
}

void
Settings::setBuzzOnScan(
    bool aValue)
{
    iPrivate->iBuzzOnScan->set(aValue);
}

int
Settings::digitalZoom() const
{
    return iPrivate->iDigitalZoom->value(DEFAULT_DIGITAL_ZOOM).toInt();
}

void
Settings::setDigitalZoom(
    int aValue)
{
    iPrivate->iDigitalZoom->set(aValue);
}

int
Settings::maxDigitalZoom() const
{
    return iPrivate->iMaxDigitalZoom->value(DEFAULT_MAX_DIGITAL_ZOOM).toInt();
}

void
Settings::setMaxDigitalZoom(
    int aValue)
{
    iPrivate->iMaxDigitalZoom->set(aValue);
}

int
Settings::scanDuration() const
{
    return iPrivate->iScanDuration->value(DEFAULT_SCAN_DURATION).toInt();
}

void
Settings::setScanDuration(
    int aValue)
{
    iPrivate->iScanDuration->set(aValue);
}

int
Settings::resultViewDuration() const
{
    return iPrivate->iResultViewDuration->value(DEFAULT_RESULT_VIEW_DURATION).toInt();
}

void
Settings::setResultViewDuration(
    int aValue)
{
    iPrivate->iResultViewDuration->set(aValue);
}

QString
Settings::markerColor() const
{
    return iPrivate->iMarkerColor->value(DEFAULT_MARKER_COLOR).toString();
}

void
Settings::setMarkerColor(
    const QString aValue)
{
    iPrivate->iMarkerColor->set(aValue);
}

int
Settings::historySize() const
{
    return iPrivate->iHistorySize->value(DEFAULT_HISTORY_SIZE).toInt();
}

void
Settings::setHistorySize(
    int aValue)
{
    iPrivate->iHistorySize->set(aValue);
}

bool
Settings::scanOnStart() const
{
    return iPrivate->iScanOnStart->value(DEFAULT_SCAN_ON_START).toBool();
}

void
Settings::setScanOnStart(
    bool aValue)
{
    iPrivate->iScanOnStart->set(aValue);
}

bool
Settings::saveImages() const
{
    return iPrivate->iSaveImages->value(DEFAULT_SAVE_IMAGES).toBool();
}

void
Settings::setSaveImages(
    bool aValue)
{
    iPrivate->iSaveImages->set(aValue);
}

bool
Settings::volumeZoom() const
{
    return iPrivate->iVolumeZoom->value(DEFAULT_VOLUME_ZOOM).toBool();
}

void
Settings::setVolumeZoom(
    bool aValue)
{
    iPrivate->iVolumeZoom->set(aValue);
}

bool
Settings::wideMode() const
{
    return iPrivate->iWideMode->value(DEFAULT_WIDE_MODE).toBool();
}

void
Settings::setWideMode(
    bool aValue)
{
    iPrivate->iWideMode->set(aValue);
}

uint
Settings::decodingHints() const
{
    return iPrivate->iDecodingHints->value(DEFAULT_DECODING_HINTS).toUInt();
}

void
Settings::setDecodingHints(
    uint aValue)
{
    iPrivate->iDecodingHints->set(aValue);
}

void
Settings::setDecodingHint(
    uint aValue)
{
    const uint hints = decodingHints();
    if ((hints & aValue) != aValue) {
        iPrivate->iDecodingHints->set(hints | aValue);
    }
}

void
Settings::clearDecodingHint(
    uint aValue)
{
    const uint hints = decodingHints();
    if ((hints & aValue) != 0) {
        iPrivate->iDecodingHints->set(hints & ~aValue);
    }
}

Settings::Orientation
Settings::orientation() const
{
    return (Orientation)iPrivate->iOrientation->value((int)DEFAULT_ORIENTATION).toInt();
}

void
Settings::setOrientation(
    Orientation aValue)
{
    iPrivate->iOrientation->set((int)aValue);
}

qreal
Settings::wideRatio() const
{
    return 4./3;
}

QSize
Settings::wideResolution() const
{
    return iPrivate->resolution_4_3();
}

void
Settings::setWideResolution(
    QSize aSize)
{
    HDEBUG(aSize);
    iPrivate->iResolution_4_3->set(aSize.width());
}

qreal
Settings::narrowRatio() const
{
    return 16./9;
}

QSize
Settings::narrowResolution() const
{
    return iPrivate->resolution_16_9();
}

void
Settings::setNarrowResolution(
    QSize aSize)
{
    HDEBUG(aSize);
    iPrivate->iResolution_16_9->set(aSize.width());
}
