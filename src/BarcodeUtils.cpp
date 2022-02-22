/*
The MIT License (MIT)

Copyright (c) 2020-2022 Slava Monich

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

#include "BarcodeUtils.h"
#include "BarcodeFormatModel.h"

#include "HarbourBase45.h"

// import Sailfish.Silica 1.0;import QtDocGallery 5.0;DocumentGalleryModel{
//   rootType:DocumentGallery.Image;properties:["url","mimeType","orientation"];sortProperties:["-lastModified"];
//   filter:GalleryStartsWithFilter{property:"filePath";value:StandardPaths.music;negated:true}}
static const char documentGalleryModelBase45[] =
    "YEDS9E5LE+347ECUVD+EDU7DNOAXVDGPC634Y$5:M7Q$D04ESUEHDAET8ZOCAECTV"
    "DALEA34Y$57M7U3E1%E1$CMVEAECTVDALENZ96VC6WD0LE24EPUAI9ELG7U3E1%E1"
    "$CMVEAECTVDALEE%5B$D93D6N70LEI9E5LEQEDNPEKNB6%E7UD3Q5J$DF$DPUAI9E"
    "IE4+F4*KE1$C3WEBWE-3EMF49N704EVVE0LEI9E5LEQEDNPEKNBIX5HECSVEV3ERE"
    "DQEDTTCHZBR.C:VD5$COG7AECTVDALEYOAGECLWEC2BAWEP+8:VD5$CARF0LEI9E5"
    "LETEFVF4XEDG CIECI7DCN7AEC%$E G73WE0/DGECUUCIEC99D5*57%EOED4N7* C"
    "IEC  COH76LEG$CZ2";

// import Sailfish.Media 1.0;MediaKey{}
static const char mediaKeyBase45[] =
    "YEDS9E5LE+347ECUVD+EDU7DDZ9AVCOCCZ96H46DZ9AVCMDCC$CNRF";

// import org.nemomobile.policy 1.0;Permissions{
//   autoRelease:true;applicationClass:"camera";
//   Resource{type:Resource.ScaleButton;optional:true}}
static const char permissionsBase45[] =
    "YEDS9E5LEN44$KE6*50$C+3ET3EXEDRZCS9EXVD+PC634Y$5JM75$CJ$DZQE EDF/"
    "D+QF8%ED3E: CX CLQEOH76LE+ZCEECP9EOEDIEC EDC.DPVDZQEWF7GPCF$DVKEX"
    "E4XIAVQE6%EKPCERF%FF*ZCXIAVQE6%EKPCO%5GPCTVD3I8MWE-3E5N7X9E ED..D"
    "VUDKWE%$E+%F";

// import org.nemomobile.thumbnailer 1.0;Thumbnail{
//   readonly property int errorStatus:Thumbnail.Error;anchors.fill:parent}
static const char thumbnailBase45[] =
    "YEDS9E5LEN44$KE6*50$C+3ET3EXEDRZCAWE1%E/JC7ECTVDBJEZ96H468UA1%E/J"
    "C7EC6WDZKE2EC-3E4WDO440LEI9E5LE3EFZEDSUE5$C0LEHKE3WENWENPE8UA1%E/"
    "JC7ECJUD3Z80LE%JECECNPC04EBPER.C VDKH7GEC1$CVWE";

// import org.nemomobile.contacts 1.0;PeopleVCardModel{}
static const char peopleVCardModelBase45[] =
    "YEDS9E5LEN44$KE6*50$C+3ET3EXEDRZCUPCG/D1ECLWE634Y$5JM72$CP9EM CEN"
    "8YKENZ96VC6WDZ2";

BarcodeUtils::BarcodeUtils(QObject* aParent) :
    QObject(aParent)
{
}

// Callback for qmlRegisterSingletonType<BarcodeUtils>
QObject* BarcodeUtils::createSingleton(QQmlEngine*, QJSEngine*)
{
    return new BarcodeUtils();
}

QString BarcodeUtils::documentGalleryModelQml()
{
    return HarbourBase45::fromBase45(QString::fromLatin1(documentGalleryModelBase45));
}

QString BarcodeUtils::thumbnailQml()
{
    return HarbourBase45::fromBase45(QString::fromLatin1(thumbnailBase45));
}

QString BarcodeUtils::mediaKeyQml()
{
    return HarbourBase45::fromBase45(QString::fromLatin1(mediaKeyBase45));
}

QString BarcodeUtils::permissionsQml()
{
    return HarbourBase45::fromBase45(QString::fromLatin1(permissionsBase45));
}

QString BarcodeUtils::peopleVCardModelQml()
{
    return HarbourBase45::fromBase45(QString::fromLatin1(peopleVCardModelBase45));
}

QString BarcodeUtils::urlScheme(QString aText)
{
    return (!aText.isEmpty() &&
        aText.indexOf('\r') < 0 &&
        aText.indexOf('\n') < 0) ?
        QUrl(aText, QUrl::StrictMode).scheme() :
        QString();
}

const QString BarcodeUtils::barcodeFormatName(QString aIdent)
{
    return BarcodeFormatModel::formatName(aIdent);
}
