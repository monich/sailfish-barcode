NAME = barcode
PREFIX = harbour
TARGET = $${PREFIX}-$${NAME}

CONFIG += sailfishapp link_pkgconfig
PKGCONFIG += sailfishapp mlite5 glib-2.0 zlib

QT += multimedia concurrent sql network

LIBS += -ldl

isEmpty(VERSION) {
    VERSION = 1.0.44
    message("VERSION is unset, assuming $$VERSION")
}

QMAKE_CXXFLAGS += -Wno-unused-parameter
QMAKE_CFLAGS += -Wno-implicit-fallthrough

DEFINES += \
  APP_VERSION=\\\"$$VERSION\\\" \
  NO_ICONV

INCLUDEPATH += \
    src \
    src/zbar/include/ \
    src/zbar/zbar/ \
    src/zbar-config/ \
    harbour-lib/include

CONFIG(debug, debug|release) {
    DEFINES += HARBOUR_DEBUG=1
}

SOURCES += \
    src/BarcodeUtils.cpp \
    src/Database.cpp \
    src/DGCertModel.cpp \
    src/DGCertParser.cpp \
    src/DGCertRecognizer.cpp \
    src/harbour-barcode.cpp \
    src/HistoryImageProvider.cpp \
    src/HistoryModel.cpp \
    src/MeCardConverter.cpp \
    src/OfdReceiptFetcher.cpp \
    src/Plugins.cpp \
    src/Settings.cpp \
    src/scanner/BarcodeScanner.cpp \
    src/scanner/Decoder.cpp

HEADERS += \
    src/BarcodeUtils.h \
    src/Database.h \
    src/DGCertModel.h \
    src/DGCertParser.h \
    src/DGCertRecognizer.h \
    src/HistoryImageProvider.h \
    src/HistoryModel.h \
    src/MeCardConverter.h \
    src/OfdReceiptFetcher.h \
    src/Plugins.h \
    src/Settings.h \
    src/scanner/BarcodeScanner.h \
    src/scanner/Decoder.h

OTHER_FILES += \
    qml/cover/CoverPage.qml \
    rpm/harbour-barcode.spec \
    translations/*.ts \
    icons/*.svg \
    README.md \
    harbour-barcode.desktop \
    qml/harbour-barcode.qml \
    qml/components/*.qml \
    qml/components/img/*.svg \
    qml/cover/*.svg \
    qml/pages/img/*.png \
    qml/pages/img/*.svg \
    qml/pages/*.qml \
    qml/js/*.js

# harbour-lib

HARBOUR_LIB_DIR = harbour-lib
HARBOUR_LIB_INCLUDE = $${HARBOUR_LIB_DIR}/include
HARBOUR_LIB_SRC = $${HARBOUR_LIB_DIR}/src
HARBOUR_LIB_QML = $${HARBOUR_LIB_DIR}/qml

SOURCES += \
    $${HARBOUR_LIB_SRC}/HarbourBase45.cpp \
    $${HARBOUR_LIB_SRC}/HarbourDisplayBlanking.cpp \
    $${HARBOUR_LIB_SRC}/HarbourMce.cpp \
    $${HARBOUR_LIB_SRC}/HarbourMediaPlugin.cpp \
    $${HARBOUR_LIB_SRC}/HarbourPluginLoader.cpp \
    $${HARBOUR_LIB_SRC}/HarbourPolicyPlugin.cpp \
    $${HARBOUR_LIB_SRC}/HarbourProcessState.cpp \
    $${HARBOUR_LIB_SRC}/HarbourSelectionListModel.cpp \
    $${HARBOUR_LIB_SRC}/HarbourSingleImageProvider.cpp \
    $${HARBOUR_LIB_SRC}/HarbourSystem.cpp \
    $${HARBOUR_LIB_SRC}/HarbourSystemInfo.cpp \
    $${HARBOUR_LIB_SRC}/HarbourTask.cpp \
    $${HARBOUR_LIB_SRC}/HarbourTemporaryFile.cpp

HEADERS += \
    $${HARBOUR_LIB_INCLUDE}/HarbourBase45.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourDebug.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourDisplayBlanking.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourMediaPlugin.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourPluginLoader.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourPolicyPlugin.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourProcessState.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourSelectionListModel.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourSingleImageProvider.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourSystem.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourSystemInfo.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourTask.h \
    $${HARBOUR_LIB_INCLUDE}/HarbourTemporaryFile.h \
    $${HARBOUR_LIB_SRC}/HarbourMce.h

HARBOUR_QML_COMPONENTS = \
    $${HARBOUR_LIB_QML}/HarbourBadge.qml \
    $${HARBOUR_LIB_QML}/HarbourFitLabel.qml \
    $${HARBOUR_LIB_QML}/HarbourHighlightIcon.qml \
    $${HARBOUR_LIB_QML}/HarbourHintIconButton.qml \
    $${HARBOUR_LIB_QML}/HarbourHorizontalSwipeHint.qml

OTHER_FILES += $${HARBOUR_QML_COMPONENTS}

qml_components.files = $${HARBOUR_QML_COMPONENTS}
qml_components.path = /usr/share/$${TARGET}/qml/harbour
INSTALLS += qml_components

# zbar

SOURCES += \
    src/zbar/zbar/convert.c \
    src/zbar/zbar/video.c \
    src/zbar/zbar/video/null.c \
    src/zbar/zbar/sqcode.c \
    src/zbar/zbar/symbol.c \
    src/zbar/zbar/image.c \
    src/zbar/zbar/error.c \
    src/zbar/zbar/refcnt.c \
    src/zbar/zbar/img_scanner.c \
    src/zbar/zbar/misc.c \
    src/zbar/zbar/scanner.c \
    src/zbar/zbar/decoder.c \
    src/zbar/zbar/qrcode/binarize.c \
    src/zbar/zbar/qrcode/qrdec.c \
    src/zbar/zbar/qrcode/bch15_5.c \
    src/zbar/zbar/qrcode/isaac.c \
    src/zbar/zbar/qrcode/qrdectxt.c \
    src/zbar/zbar/qrcode/util.c \
    src/zbar/zbar/qrcode/rs.c \
    src/zbar/zbar/config.c \
    src/zbar/zbar/decoder/code39.c \
    src/zbar/zbar/decoder/databar.c \
    src/zbar/zbar/decoder/qr_finder.c \
    src/zbar/zbar/decoder/code128.c \
    src/zbar/zbar/decoder/i25.c \
    src/zbar/zbar/decoder/ean.c \
    src/zbar/zbar/decoder/codabar.c \
    src/zbar/zbar/decoder/sq_finder.c \
    src/zbar/zbar/decoder/code93.c

HEADERS += \
    src/zbar-config/config.h \
    src/zbar/zbar/decoder.h \
    src/zbar/zbar/misc.h \
    src/zbar/zbar/mutex.h \
    src/zbar/zbar/img_scanner.h \
    src/zbar/zbar/window.h \
    src/zbar/zbar/debug.h \
    src/zbar/zbar/refcnt.h \
    src/zbar/zbar/image.h \
    src/zbar/zbar/error.h \
    src/zbar/zbar/thread.h \
    src/zbar/zbar/sqcode.h \
    src/zbar/zbar/symbol.h \
    src/zbar/zbar/qrcode/bch15_5.h \
    src/zbar/zbar/qrcode/rs.h \
    src/zbar/zbar/qrcode/util.h \
    src/zbar/zbar/qrcode/isaac.h \
    src/zbar/zbar/qrcode/qrdec.h \
    src/zbar/zbar/qrcode/binarize.h \
    src/zbar/zbar/event.h \
    src/zbar/zbar/timer.h \
    src/zbar/zbar/processor/posix.h \
    src/zbar/zbar/decoder/sq_finder.h \
    src/zbar/zbar/decoder/ean.h \
    src/zbar/zbar/decoder/codabar.h \
    src/zbar/zbar/decoder/code93.h \
    src/zbar/zbar/decoder/code39.h \
    src/zbar/zbar/decoder/code128.h \
    src/zbar/zbar/decoder/i25.h \
    src/zbar/zbar/decoder/qr_finder.h \
    src/zbar/zbar/decoder/databar.h \
    src/zbar/zbar/qrcode.h \
    src/zbar/include/zbar/Decoder.h \
    src/zbar/include/zbar/Scanner.h \
    src/zbar/include/zbar/Symbol.h \
    src/zbar/include/zbar/Exception.h \
    src/zbar/include/zbar/Window.h \
    src/zbar/include/zbar/Image.h \
    src/zbar/include/zbar/ImageScanner.h \
    src/zbar/include/zbar.h


# libmc

LIBMC_LIB_DIR = libmc
LIBMC_LIB_INCLUDE = $${LIBMC_LIB_DIR}/include
LIBMC_LIB_SRC = $${LIBMC_LIB_DIR}/src

INCLUDEPATH += $${LIBMC_LIB_INCLUDE}

SOURCES += \
    $${LIBMC_LIB_SRC}/mc_block.c \
    $${LIBMC_LIB_SRC}/mc_mecard.c \
    $${LIBMC_LIB_SRC}/mc_record.c

HEADERS += \
    $${LIBMC_LIB_INCLUDE}/mc_mecard.h \
    $${LIBMC_LIB_INCLUDE}/mc_record.h \
    $${LIBMC_LIB_INCLUDE}/mc_types.h

# Icons
ICON_SIZES = 86 108 128 172 256
for(s, ICON_SIZES) {
    icon_target = icon$${s}
    icon_dir = icons/$${s}x$${s}
    $${icon_target}.files = $${icon_dir}/$${TARGET}.png
    $${icon_target}.path = /usr/share/icons/hicolor/$${s}x$${s}/apps
    INSTALLS += $${icon_target}
}

app_icon.files = icons/harbour-barcode.svg
app_icon.path = /usr/share/$${TARGET}/qml/pages/img/
INSTALLS += app_icon

# Translations
TRANSLATION_IDBASED=-idbased
TRANSLATIONS_PATH = /usr/share/$${TARGET}/translations
TRANSLATION_SOURCES = \
  $${_PRO_FILE_PWD_}/qml

defineTest(addTrFile) {
    rel = translations/$${1}
    OTHER_FILES += $${rel}.ts
    export(OTHER_FILES)

    in = $${_PRO_FILE_PWD_}/$$rel
    out = $${OUT_PWD}/$$rel

    s = $$replace(1,-,_)
    lupdate_target = lupdate_$$s
    qm_target = qm_$$s

    $${lupdate_target}.commands = lupdate -noobsolete -locations none $${TRANSLATION_SOURCES} -ts \"$${in}.ts\" && \
        mkdir -p \"$${OUT_PWD}/translations\" &&  [ \"$${in}.ts\" != \"$${out}.ts\" ] && \
        cp -af \"$${in}.ts\" \"$${out}.ts\" || :

    $${qm_target}.path = $$TRANSLATIONS_PATH
    $${qm_target}.depends = $${lupdate_target}
    $${qm_target}.commands = lrelease $$TRANSLATION_IDBASED \"$${out}.ts\" && \
        $(INSTALL_FILE) \"$${out}.qm\" $(INSTALL_ROOT)$${TRANSLATIONS_PATH}/

    QMAKE_EXTRA_TARGETS += $${lupdate_target} $${qm_target}
    INSTALLS += $${qm_target}

    export($${lupdate_target}.commands)
    export($${qm_target}.path)
    export($${qm_target}.depends)
    export($${qm_target}.commands)
    export(QMAKE_EXTRA_TARGETS)
    export(INSTALLS)
}

LANGUAGES = cs da de es fr hu it pl pt ru sk sv zh_CN zh_TW

addTrFile($${TARGET})
for(l, LANGUAGES) {
    addTrFile($${TARGET}-$$l)
}

qm.path = $$TRANSLATIONS_PATH
qm.CONFIG += no_check_exist
INSTALLS += qm
