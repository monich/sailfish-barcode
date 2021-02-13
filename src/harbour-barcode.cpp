/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
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

#include <sailfishapp.h>
#include <QTranslator>
#include <QCameraExposure>
#include <QGuiApplication>
#include <QQuickView>
#include <QOpenGLContext>
#include <QOffscreenSurface>
#include <QtQml>

#include <MGConfItem>

#include "scanner/BarcodeScanner.h"

#include "HarbourDebug.h"
#include "HarbourDisplayBlanking.h"
#include "HarbourSelectionListModel.h"
#include "HarbourSingleImageProvider.h"
#include "HarbourTemporaryFile.h"
#include "HarbourSystemInfo.h"

#include "BarcodeUtils.h"
#include "Plugins.h"
#include "Database.h"
#include "HistoryImageProvider.h"
#include "HistoryModel.h"
#include "MeCardConverter.h"
#include "OfdReceiptFetcher.h"
#include "Settings.h"

#ifndef APP_VERSION
#  define ""
#endif

#define CAMERA_DCONF_KEY(name) "/apps/jolla-camera/primary/image/" name

static void register_types(QQmlEngine* engine, const char* uri, int v1, int v2)
{
    Plugins::registerTypes(engine, uri, v1, v2);
    qmlRegisterType<HarbourSelectionListModel>(uri, v1, v2, "HarbourSelectionListModel");
    qmlRegisterType<HarbourSingleImageProvider>(uri, v1, v2, "SingleImageProvider");
    qmlRegisterType<HarbourDisplayBlanking>(uri, v1, v2, "DisplayBlanking");
    qmlRegisterType<HarbourTemporaryFile>(uri, v1, v2, "TemporaryFile");
    qmlRegisterSingletonType<HarbourSystemInfo>(uri, v1, v2, "SystemInfo", HarbourSystemInfo::createSingleton);
    qmlRegisterType<BarcodeScanner>(uri, v1, v2, "BarcodeScanner");
    qmlRegisterType<OfdReceiptFetcher>(uri, v1, v2, "ReceiptFetcher");
    qmlRegisterType<MeCardConverter>(uri, v1, v2, "MeCardConverter");
    qmlRegisterUncreatableType<Settings>(uri, v1, v2, "Settings", "Use AppSettings context property");
    qmlRegisterSingletonType<HistoryModel>(uri, v1, v2, "HistoryModel", HistoryModel::createSingleton);
    qmlRegisterSingletonType<BarcodeUtils>(uri, v1, v2, "BarcodeUtils", BarcodeUtils::createSingleton);
}

static QSize toSize(QVariant var)
{
    // e.g. "1920x1080"
    if (var.isValid()) {
        QStringList values(var.toString().split('x'));
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
    return QSize();
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    bool torchSupported = false;

    // Parse Qt version to find out what's supported and what's not
    const char* qver = qVersion();
    HDEBUG("Qt version" << qver);
    if (qver) {
        const QStringList s(QString(qver).split('.'));
        if (s.size() >= 3) {
            int v = QT_VERSION_CHECK(s[0].toInt(), s[1].toInt(), s[2].toInt());
            if (v >= QT_VERSION_CHECK(5,6,0)) {
                // If flash is not supported at all, this key contains [2]
                // at least on the most recent versions of Sailfish OS
                QString flashValuesKey(CAMERA_DCONF_KEY("flashValues"));
                MGConfItem flashValuesConf(flashValuesKey);
                QVariantList flashValues(flashValuesConf.value().toList());
                if (flashValues.size() == 1 &&
                    flashValues.at(0).toInt() == QCameraExposure::FlashOff) {
                    HDEBUG("Flash disabled by" << qPrintable(flashValuesKey));
                } else {
                    torchSupported = true;
                    HDEBUG("Torch supported");
                }
            }
        }
    }

    // Available 4/3 and 16/9 resolutions
    QString key_4_3(CAMERA_DCONF_KEY("viewfinderResolution_4_3"));
    QString key_16_9(CAMERA_DCONF_KEY("viewfinderResolution_16_9"));
    QSize res_4_3(toSize(MGConfItem(key_4_3).value()));
    QSize res_16_9(toSize(MGConfItem(key_16_9).value()));
    HDEBUG("Resolutions" << res_4_3 << res_16_9);

    QLocale locale;
    QTranslator* translator = new QTranslator(app.data());
    QString transDir = SailfishApp::pathTo("translations").toLocalFile();
    QString transFile("harbour-barcode");
    if (translator->load(locale, transFile, "-", transDir) ||
        translator->load(transFile, transDir)) {
        app->installTranslator(translator);
    } else {
        HWARN("Failed to load translator for" << locale);
        delete translator;
    }

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    QQmlEngine* engine = view->engine();
    register_types(engine, "harbour.barcode", 1, 0);
    engine->addImageProvider("scanner", new HistoryImageProvider);

    Settings* settings = new Settings(app.data());
    Database::initialize(engine, settings);

    QQmlContext* root = view->rootContext();
    root->setContextProperty("AppVersion", APP_VERSION);
    root->setContextProperty("AppSettings", settings);
    root->setContextProperty("TorchSupported", torchSupported);
    if (res_4_3.isValid()) {
        root->setContextProperty("ViewfinderResolution_4_3", res_4_3);
    }
    if (res_16_9.isValid()) {
        root->setContextProperty("ViewfinderResolution_16_9", res_16_9);
    }

    QOpenGLContext ctx;
    int maxTextureSize = 0;
    if (ctx.create()) {
        GLint maxSize = 0;
        QOffscreenSurface surface;
        surface.setFormat( ctx.format() );
        surface.create();
        ctx.makeCurrent(&surface);
        glEnable(GL_TEXTURE_2D);
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxSize);
        if (maxSize > 0) {
            maxTextureSize = maxSize;
        }
        ctx.doneCurrent();
        surface.destroy();
    }
    HDEBUG("Max texture size" << maxTextureSize);
    root->setContextProperty("MaxTextureSize", maxTextureSize);

    view->setSource(SailfishApp::pathTo("qml/harbour-barcode.qml"));
    view->setTitle("CodeReader");
    view->showFullScreen();
    return app->exec();
}
