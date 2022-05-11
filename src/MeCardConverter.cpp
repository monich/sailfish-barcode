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

#include "mc_mecard.h"

#include "MeCardConverter.h"

#include "HarbourTask.h"
#include "HarbourDebug.h"

#include <QThreadPool>
#include <QSharedPointer>

// ==========================================================================
// MeCardConverter::Task
//
// Parses MECARD and generates VCARD on a worker thread. It's typically
// not a big task but it often happens at the moment when page transition
// animation is running, so it better be done on a separate thread.
// ==========================================================================

class MeCardConverter::Task : public HarbourTask {
    Q_OBJECT

public:
    Task(QThreadPool* aPool, QString aMeCard);

    void performTask() Q_DECL_OVERRIDE;

    static void encodeValue(QByteArray* aBuf, const char* aValue);
    static void encodeValues(QByteArray* aBuf, const char* aTag, const McStr* aValues);
    static void concatValues(QByteArray* aBuf, const char* aTag, const McStr* aValues, char aSeparator);

public:
    QString iMeCard;
    QString iVCard;
};

MeCardConverter::Task::Task(QThreadPool* aPool, QString aMeCard) :
    HarbourTask(aPool),
    iMeCard(aMeCard)
{
}

void MeCardConverter::Task::performTask()
{
    const QByteArray text(iMeCard.toUtf8());
    MeCard* mecard = mecard_parse(text.constData());
    if (mecard) {
        // All strings produced by libmc are UTF-8
        QByteArray utf8("BEGIN:VCARD\nVERSION:3.0\n");
        concatValues(&utf8, "N", mecard->n, ';');
        encodeValues(&utf8, "TEL", mecard->tel);
        encodeValues(&utf8, "EMAIL", mecard->email);
        encodeValues(&utf8, "ORG", mecard->org);
        encodeValues(&utf8, "BDAY", mecard->bday);
        if (mecard->adr) {
            // ADR is slightly special
            utf8.append("ADR;TYPE=POSTAL:;;");
            const McStr* ptr = mecard->adr;
            while (*ptr) {
                encodeValue(&utf8, *ptr++);
                if (*ptr) {
                    utf8.append(',');
                    if (**ptr != ' ') {
                        utf8.append(' ');
                    }
                }
            }
            utf8.append('\n');
        }
        concatValues(&utf8, "NOTE", mecard->note, ',');
        encodeValues(&utf8, "URL", mecard->url);
        concatValues(&utf8, "NICKNAME", mecard->nickname, ',');
        utf8.append("END:VCARD");
        iVCard = QString::fromUtf8(utf8);
        mecard_free(mecard);
    }
}

void MeCardConverter::Task::encodeValue(QByteArray* aBuf,
    const char* aValue)
{
    while (*aValue) {
        const char c = *aValue++;
        if (c == '\n') {
            aBuf->append("\\n");
        } else {
            switch (c) {
            case '\\':
            case ';':
            case ',':
                aBuf->append('\\');
                break;
            }
            aBuf->append(c);
        }
    }
}

void MeCardConverter::Task::encodeValues(QByteArray* aBuf,
    const char* aTag, const McStr* aValues)
{
    if (aValues) {
        while (*aValues) {
            aBuf->append(aTag);
            aBuf->append(':');
            encodeValue(aBuf, *aValues++);
            aBuf->append('\n');
        }
    }
}

void MeCardConverter::Task::concatValues(QByteArray* aBuf,
    const char* aTag, const McStr* aValues, char aSeparator)
{
    if (aValues) {
        aBuf->append(aTag);
        aBuf->append(':');
        while (*aValues) {
            encodeValue(aBuf, *aValues++);
            if (*aValues) {
                aBuf->append(aSeparator);
            }
        }
        aBuf->append('\n');
    }
}

// ==========================================================================
// MeCardConverter::Private
// ==========================================================================

class MeCardConverter::Private : public QObject {
    Q_OBJECT

public:
    Private(QObject* aParent);
    ~Private();

    static QSharedPointer<QThreadPool> threadPool();
    MeCardConverter* parentObject() const;
    void setMecard(QString aMeCard);

public Q_SLOTS:
    void onTaskDone();

public:
    QSharedPointer<QThreadPool> iThreadPool;
    Task* iTask;
    QString iMeCard;
    QString iVCard;
};

MeCardConverter::Private::Private(QObject* aParent) :
    QObject(aParent),
    iThreadPool(threadPool()),
    iTask(Q_NULLPTR)
{
}

MeCardConverter::Private::~Private()
{
    if (iTask) iTask->release();
}

QSharedPointer<QThreadPool> MeCardConverter::Private::threadPool()
{
    static QWeakPointer<QThreadPool> sharedPool;
    QSharedPointer<QThreadPool> pool = sharedPool;
    if (pool.isNull()) {
        pool = QSharedPointer<QThreadPool>::create();
        pool->setMaxThreadCount(2); // 2 threads shoud be enough
        sharedPool = pool;
    }
    return pool;
}

inline MeCardConverter* MeCardConverter::Private::parentObject() const
{
    return qobject_cast<MeCardConverter*>(parent());
}

void MeCardConverter::Private::setMecard(QString aMeCard)
{
    if (iMeCard != aMeCard) {
        iMeCard = aMeCard;
        HDEBUG(aMeCard);
        if (iTask) iTask->release();
        iTask = new Task(iThreadPool.data(), aMeCard);
        iTask->submit(this, SLOT(onTaskDone()));
        Q_EMIT parentObject()->mecardChanged();
    }
}

void MeCardConverter::Private::onTaskDone()
{
    if (sender() == iTask) {
        const QString vcard(iTask->iVCard);
        iTask->release();
        iTask = NULL;
        if (iVCard != vcard) {
            iVCard = vcard;
            Q_EMIT parentObject()->vcardChanged();
        }
    }
}

// ==========================================================================
// MeCardConverter
// ==========================================================================

MeCardConverter::MeCardConverter(QObject* aParent) :
    QObject(aParent),
    iPrivate(new Private(this))
{
}

MeCardConverter::~MeCardConverter()
{
    delete iPrivate;
}

QString MeCardConverter::vcard() const
{
    return iPrivate->iVCard;
}

QString MeCardConverter::mecard() const
{
    return iPrivate->iMeCard;
}

void MeCardConverter::setMecard(QString aMeCard)
{
    iPrivate->setMecard(aMeCard);
}

#include "MeCardConverter.moc"
