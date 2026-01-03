/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2026 Slava Monich

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

#include "scanner/BarcodeImageGrabber.h"
#include "scanner/BarcodeScanner.h"

#include "HarbourDebug.h"
#include "HarbourDisplayBlanking.h"
#include "HarbourProcessState.h"
#include "HarbourSelectionListModel.h"
#include "HarbourSingleImageProvider.h"
#include "HarbourTemporaryFile.h"
#include "HarbourSystemInfo.h"

#include "BarcodeFormatModel.h"
#include "BarcodeUtils.h"
#include "Database.h"
#include "DGCertModel.h"
#include "DGCertRecognizer.h"
#include "HistoryImageProvider.h"
#include "HistoryModel.h"
#include "MeCardConverter.h"
#include "Settings.h"

#ifndef APP_VERSION
#  define ""
#endif

#define CAMERA_DCONF_KEY(name) "/apps/jolla-camera/primary/image/" name

#define REGISTER_TYPE(uri, v1, v2, Class) \
    qmlRegisterType<Class>(uri, v1, v2, #Class)
#define REGISTER_SINGLETON_TYPE(uri, v1, v2, Class) \
    qmlRegisterSingletonType<Class>(uri, v1, v2, #Class, \
    Class::createSingleton)
#define REGISTER_UNCREATABLE_TYPE(uri, v1, v2, Class) \
    qmlRegisterUncreatableType<Class>(uri, v1, v2, #Class, \
    QString())

static void register_types(QQmlEngine* engine, const char* uri, int v1, int v2)
{
    qmlRegisterType<HarbourSingleImageProvider>(uri, v1, v2, "SingleImageProvider");
    qmlRegisterType<HarbourDisplayBlanking>(uri, v1, v2, "DisplayBlanking");
    qmlRegisterType<HarbourTemporaryFile>(uri, v1, v2, "TemporaryFile");
    qmlRegisterSingletonType<HarbourSystemInfo>(uri, v1, v2, "SystemInfo", HarbourSystemInfo::createSingleton);
    qmlRegisterSingletonType<HarbourProcessState>(uri, v1, v2, "ProcessState", HarbourProcessState::createSingleton);
    REGISTER_TYPE(uri, v1, v2, HarbourSelectionListModel);
    REGISTER_TYPE(uri, v1, v2, BarcodeFormatModel);
    REGISTER_TYPE(uri, v1, v2, BarcodeImageGrabber);
    REGISTER_TYPE(uri, v1, v2, BarcodeScanner);
    REGISTER_TYPE(uri, v1, v2, DGCertModel);
    REGISTER_TYPE(uri, v1, v2, DGCertRecognizer);
    REGISTER_TYPE(uri, v1, v2, MeCardConverter);
    REGISTER_SINGLETON_TYPE(uri, v1, v2, HistoryModel);
    REGISTER_SINGLETON_TYPE(uri, v1, v2, BarcodeUtils);
    REGISTER_UNCREATABLE_TYPE(uri, v1, v2, Settings);
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    bool torchSupported = false;

    const char* qver = qVersion();
    HDEBUG("Qt version" << qver);

    if (qgetenv("HARBOUR_BARCODE_ENABLE_TORCH").toInt() > 0 ||
        MGConfItem(SETTINGS_DCONF_PATH_("enableTorch")).value().toBool()) {
        torchSupported = true;
        HDEBUG("Torch support is enabled");
    } else if (qver) {
        // Figure out what's supported and what's not
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
                } else if (flashValues.isEmpty()) {
                    // If this DConf key is missing, assume that the torch
                    // mode is not supported
                    HDEBUG("DConf entry" << qPrintable(flashValuesKey) <<
                        "is missing, disabling the torch");
                } else {
                    torchSupported = true;
                    HDEBUG("Torch supported");
                }
            }
        }
    }

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
