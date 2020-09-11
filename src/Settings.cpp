/*
The MIT License (MIT)

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

#include "Settings.h"

#include <MGConfItem>

#define DCONF_PATH                      "/apps/harbour-barcode/"

// New keys (the ones that have only been in dconf)
#define KEY_BUZZ_ON_SCAN               "buzz_on_scan"
#define KEY_SAVE_IMAGES                "save_images"
#define KEY_WIDE_MODE                  "wide_mode"
#define KEY_ORIENTATION                "orientation"
#define KEY_MAX_DIGITAL_ZOOM           "max_digital_zoom"

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
#define DEFAULT_WIDE_MODE               false
#define DEFAULT_ORIENTATION             (Settings::OrientationAny)

// ==========================================================================
// Settings::Private
// ==========================================================================

class Settings::Private {
public:
    Private(Settings* aSettings);

    static const QString HINTS_ROOT;

public:
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
    MGConfItem* iWideMode;
    MGConfItem* iOrientation;
};

const QString Settings::Private::HINTS_ROOT(DCONF_PATH "hints/");

Settings::Private::Private(Settings* aSettings) :
    iSound(new MGConfItem(DCONF_PATH KEY_SOUND, aSettings)),
    iBuzzOnScan(new MGConfItem(DCONF_PATH KEY_BUZZ_ON_SCAN, aSettings)),
    iDigitalZoom(new MGConfItem(DCONF_PATH KEY_DIGITAL_ZOOM, aSettings)),
    iMaxDigitalZoom(new MGConfItem(DCONF_PATH KEY_MAX_DIGITAL_ZOOM, aSettings)),
    iScanDuration(new MGConfItem(DCONF_PATH KEY_SCAN_DURATION, aSettings)),
    iResultViewDuration(new MGConfItem(DCONF_PATH KEY_RESULT_VIEW_DURATION, aSettings)),
    iMarkerColor(new MGConfItem(DCONF_PATH KEY_MARKER_COLOR, aSettings)),
    iHistorySize(new MGConfItem(DCONF_PATH KEY_HISTORY_SIZE, aSettings)),
    iScanOnStart(new MGConfItem(DCONF_PATH KEY_SCAN_ON_START, aSettings)),
    iSaveImages(new MGConfItem(DCONF_PATH KEY_SAVE_IMAGES, aSettings)),
    iWideMode(new MGConfItem(DCONF_PATH KEY_WIDE_MODE, aSettings)),
    iOrientation(new MGConfItem(DCONF_PATH KEY_ORIENTATION, aSettings))
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
    connect(iWideMode, SIGNAL(valueChanged()), aSettings, SIGNAL(wideModeChanged()));
    connect(iOrientation, SIGNAL(valueChanged()), aSettings, SIGNAL(orientationChanged()));
}

// ==========================================================================
// Settings
// ==========================================================================

Settings::Settings(QObject* aParent) :
    QObject(aParent),
    iPrivate(new Private(this))
{
}

Settings::~Settings()
{
    delete iPrivate;
}

QString Settings::hintKey(QString aHintName)
{
    return Private::HINTS_ROOT + aHintName;
}

bool Settings::sound() const
{
    return iPrivate->iSound->value(DEFAULT_SOUND).toBool();
}

void Settings::setSound(bool aValue)
{
    iPrivate->iSound->set(aValue);
}

bool Settings::buzzOnScan() const
{
    return iPrivate->iBuzzOnScan->value(DEFAULT_BUZZ_ON_SCAN).toBool();
}

void Settings::setBuzzOnScan(bool aValue)
{
    iPrivate->iBuzzOnScan->set(aValue);
}

int Settings::digitalZoom() const
{
    return iPrivate->iDigitalZoom->value(DEFAULT_DIGITAL_ZOOM).toInt();
}

void Settings::setDigitalZoom(int aValue)
{
    iPrivate->iDigitalZoom->set(aValue);
}

int Settings::maxDigitalZoom() const
{
    return iPrivate->iMaxDigitalZoom->value(DEFAULT_MAX_DIGITAL_ZOOM).toInt();
}

void Settings::setMaxDigitalZoom(int aValue)
{
    iPrivate->iMaxDigitalZoom->set(aValue);
}

int Settings::scanDuration() const
{
    return iPrivate->iScanDuration->value(DEFAULT_SCAN_DURATION).toInt();
}

void Settings::setScanDuration(int aValue)
{
    iPrivate->iScanDuration->set(aValue);
}

int Settings::resultViewDuration() const
{
    return iPrivate->iResultViewDuration->value(DEFAULT_RESULT_VIEW_DURATION).toInt();
}

void Settings::setResultViewDuration(int aValue)
{
    iPrivate->iResultViewDuration->set(aValue);
}

QString Settings::markerColor() const
{
    return iPrivate->iMarkerColor->value(DEFAULT_MARKER_COLOR).toString();
}

void Settings::setMarkerColor(QString aValue)
{
    iPrivate->iMarkerColor->set(aValue);
}

int Settings::historySize() const
{
    return iPrivate->iHistorySize->value(DEFAULT_HISTORY_SIZE).toInt();
}

void Settings::setHistorySize(int aValue)
{
    iPrivate->iHistorySize->set(aValue);
}

bool Settings::scanOnStart() const
{
    return iPrivate->iScanOnStart->value(DEFAULT_SCAN_ON_START).toBool();
}

void Settings::setScanOnStart(bool aValue)
{
    iPrivate->iScanOnStart->set(aValue);
}

bool Settings::saveImages() const
{
    return iPrivate->iSaveImages->value(DEFAULT_SAVE_IMAGES).toBool();
}

void Settings::setSaveImages(bool aValue)
{
    iPrivate->iSaveImages->set(aValue);
}

bool Settings::wideMode() const
{
    return iPrivate->iWideMode->value(DEFAULT_WIDE_MODE).toBool();
}

void Settings::setWideMode(bool aValue)
{
    iPrivate->iWideMode->set(aValue);
}

Settings::Orientation Settings::orientation() const
{
    return (Orientation)iPrivate->iOrientation->value((int)DEFAULT_ORIENTATION).toInt();
}

void Settings::setOrientation(Orientation aValue)
{
    iPrivate->iOrientation->set((int)aValue);
}
