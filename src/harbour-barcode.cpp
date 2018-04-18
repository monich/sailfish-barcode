/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018 Slava Monich

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
#include <QGuiApplication>
#include <QQuickView>
#include <QtQml>

#include "scanner/AutoBarcodeScanner.h"
#include "scanner/CaptureImageProvider.h"

#include "DebugLog.h"

#ifndef APP_VERSION
#  define ""
#endif

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    qmlRegisterType<AutoBarcodeScanner>("harbour.barcode.AutoBarcodeScanner", 1, 0, "AutoBarcodeScanner");

    bool torchSupported = false;

    // Parse Qt version to find out what's supported and what's not
    const char* qver = qVersion();
    DLOG("Qt version" << qver);
    if (qver) {
        const QStringList s(QString(qver).split('.'));
        if (s.size() >= 3) {
            int v = QT_VERSION_CHECK(s[0].toInt(), s[1].toInt(), s[2].toInt());
            if (v >= QT_VERSION_CHECK(5,6,0)) {
                torchSupported = true;
                DLOG("Torch supported");
            }
        }
    }

    view->engine()->addImageProvider("scanner", new CaptureImageProvider());
    view->rootContext()->setContextProperty("AppVersion", APP_VERSION);
    view->rootContext()->setContextProperty("TorchSupported", torchSupported);
    view->setSource(SailfishApp::pathTo("qml/harbour-barcode.qml"));
    view->setTitle("CodeReader");
    view->showFullScreen();
    return app->exec();
}
