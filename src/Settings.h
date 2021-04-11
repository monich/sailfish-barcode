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

#ifndef BARCODE_SETTINGS_H
#define BARCODE_SETTINGS_H

#include <QObject>
#include <QString>

#include <QtQml>

// Old keys (the ones that may need to be imported from the database)

#define KEY_SOUND                   "sound"
#define KEY_DIGITAL_ZOOM            "digital_zoom"
#define KEY_SCAN_DURATION           "scan_duration"
#define KEY_RESULT_VIEW_DURATION    "result_view_duration"
#define KEY_MARKER_COLOR            "marker_color"
#define KEY_HISTORY_SIZE            "history_size"
#define KEY_SCAN_ON_START           "scan_on_start"

class Settings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool sound READ sound WRITE setSound NOTIFY soundChanged)
    Q_PROPERTY(bool buzzOnScan READ buzzOnScan WRITE setBuzzOnScan NOTIFY buzzOnScanChanged)
    Q_PROPERTY(int digitalZoom READ digitalZoom WRITE setDigitalZoom NOTIFY digitalZoomChanged)
    Q_PROPERTY(int maxDigitalZoom READ maxDigitalZoom WRITE setMaxDigitalZoom NOTIFY maxDigitalZoomChanged)
    Q_PROPERTY(int scanDuration READ scanDuration WRITE setScanDuration NOTIFY scanDurationChanged)
    Q_PROPERTY(int resultViewDuration READ resultViewDuration WRITE setResultViewDuration NOTIFY resultViewDurationChanged)
    Q_PROPERTY(QString markerColor READ markerColor WRITE setMarkerColor NOTIFY markerColorChanged)
    Q_PROPERTY(int historySize READ historySize WRITE setHistorySize NOTIFY historySizeChanged)
    Q_PROPERTY(bool scanOnStart READ scanOnStart WRITE setScanOnStart NOTIFY scanOnStartChanged)
    Q_PROPERTY(bool saveImages READ saveImages WRITE setSaveImages NOTIFY saveImagesChanged)
    Q_PROPERTY(bool volumeZoom READ volumeZoom WRITE setVolumeZoom NOTIFY volumeZoomChanged)
    Q_PROPERTY(bool wideMode READ wideMode WRITE setWideMode NOTIFY wideModeChanged)
    Q_PROPERTY(Orientation orientation READ orientation WRITE setOrientation NOTIFY orientationChanged)
    Q_ENUMS(Orientation)
    Q_ENUMS(Constants)

public:
    enum Orientation {
        OrientationPrimary,
        OrientationPortrait,
        OrientationPortraitAny,
        OrientationLandscape,
        OrientationLandscapeAny,
        OrientationAny
    };

    enum Constants {
        MaximumHintCount = 2
    };

    explicit Settings(QObject* aParent = Q_NULLPTR);
    ~Settings();

    Q_INVOKABLE static QString hintKey(QString aHintName);

    bool sound() const;
    void setSound(bool aValue);

    bool buzzOnScan() const;
    void setBuzzOnScan(bool aValue);

    int digitalZoom() const;
    void setDigitalZoom(int aValue);

    int maxDigitalZoom() const;
    void setMaxDigitalZoom(int aValue);

    int scanDuration() const;
    void setScanDuration(int aValue);

    int resultViewDuration() const;
    void setResultViewDuration(int aValue);

    QString markerColor() const;
    void setMarkerColor(QString aValue);

    int historySize() const;
    void setHistorySize(int aValue);

    bool scanOnStart() const;
    void setScanOnStart(bool aValue);

    bool saveImages() const;
    void setSaveImages(bool aValue);

    bool volumeZoom() const;
    void setVolumeZoom(bool aValue);

    bool wideMode() const;
    void setWideMode(bool aValue);

    Orientation orientation() const;
    void setOrientation(Orientation aValue);

Q_SIGNALS:
    void soundChanged();
    void buzzOnScanChanged();
    void digitalZoomChanged();
    void maxDigitalZoomChanged();
    void scanDurationChanged();
    void resultViewDurationChanged();
    void markerColorChanged();
    void historySizeChanged();
    void scanOnStartChanged();
    void saveImagesChanged();
    void volumeZoomChanged();
    void wideModeChanged();
    void orientationChanged();

private:
    class Private;
    Private* iPrivate;
};

QML_DECLARE_TYPE(Settings)

#endif // BARCODE_SETTINGS_H
