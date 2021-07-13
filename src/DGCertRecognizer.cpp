/*
The MIT License (MIT)

Copyright (c) 2021 Slava Monich

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

#include "DGCertRecognizer.h"
#include "DGCertParser.h"

#include "HarbourTask.h"
#include "HarbourDebug.h"

#include <QThreadPool>
#include <QSharedPointer>
#include <QDateTime>

// ==========================================================================
// DGCertRecognizer::Task
//
// Attempts to decode a Digital Green Certificate. It's typically not a big
// task but it often happens at the moment when page transition animation is
// running, so it better be done on a separate thread.
// ==========================================================================

class DGCertRecognizer::Task : public HarbourTask
{
    Q_OBJECT

public:
    Task(QThreadPool* aPool, const QString& aText);

    void performTask() Q_DECL_OVERRIDE;

public:
    const QString iText;
    bool iValid;
    int iFormatVersion;
};

DGCertRecognizer::Task::Task(QThreadPool* aPool, const QString& aText) :
    HarbourTask(aPool),
    iText(aText),
    iValid(false),
    iFormatVersion(0)
{
}

void DGCertRecognizer::Task::performTask()
{
    iValid = DGCertParser::parse(iText, Q_NULLPTR, &iFormatVersion);
}

// ==========================================================================
// DGCertRecognizer::Private
// ==========================================================================

class DGCertRecognizer::Private : public QObject
{
    Q_OBJECT

public:
    Private(QObject* aParent);
    ~Private();

    DGCertRecognizer* parentObject() const;
    void setText(QString aMeCard);
    void resetParsedData();

public Q_SLOTS:
    void onTaskDone();

public:
    QSharedPointer<QThreadPool> iThreadPool;
    Task* iTask;
    bool iValid;
    int iFormatVersion;
    QString iText;
};

DGCertRecognizer::Private::Private(QObject* aParent) :
    QObject(aParent),
    iThreadPool(DGCertParser::threadPool()),
    iTask(Q_NULLPTR),
    iValid(false),
    iFormatVersion(0)
{
}

DGCertRecognizer::Private::~Private()
{
    if (iTask) iTask->release();
}


inline DGCertRecognizer* DGCertRecognizer::Private::parentObject() const
{
    return qobject_cast<DGCertRecognizer*>(parent());
}

void DGCertRecognizer::Private::setText(QString aText)
{
    if (iText != aText) {
        iText = aText;
        HDEBUG(aText);
        if (iTask) iTask->release();
        if (DGCertParser::mayBeValid(iText)) {
            iTask = new Task(iThreadPool.data(), aText);
            iTask->submit(this, SLOT(onTaskDone()));
        } else {
            iTask = Q_NULLPTR;
            resetParsedData();
        }
        Q_EMIT parentObject()->textChanged();
    }
}

void DGCertRecognizer::Private::onTaskDone()
{
    if (sender() == iTask) {
        Task* task = iTask;
        iTask = Q_NULLPTR;

        bool validChanged = false;
        if (iValid != task->iValid) {
            iValid = task->iValid;
            validChanged = true;
        }

        bool formatVersionChanged = false;
        if (iFormatVersion != task->iFormatVersion) {
            iFormatVersion = task->iFormatVersion;
            formatVersionChanged = true;
        }

        DGCertRecognizer* model = parentObject();

        if (validChanged && !task->iValid) {
            Q_EMIT model->validChanged();
        }
        if (formatVersionChanged) {
            Q_EMIT model->formatVersionChanged();
        }
        if (validChanged && task->iValid) {
            Q_EMIT model->validChanged();
        }
        task->release();
    }
}

void DGCertRecognizer::Private::resetParsedData()
{
    bool validChanged = false;
    if (iValid) {
        iValid = false;
        validChanged = true;
    }

    bool formatVersionChanged = false;
    if (iFormatVersion != 0) {
        iFormatVersion = 0;
        formatVersionChanged = true;
    }

    DGCertRecognizer* model = parentObject();

    if (validChanged) {
        Q_EMIT model->validChanged();
    }
    if (formatVersionChanged) {
        Q_EMIT model->formatVersionChanged();
    }
}

// ==========================================================================
// DGCertRecognizer
// ==========================================================================

DGCertRecognizer::DGCertRecognizer(QObject* aParent) :
    QObject(aParent),
    iPrivate(new Private(this))
{
}

DGCertRecognizer::~DGCertRecognizer()
{
    delete iPrivate;
}

QString DGCertRecognizer::getText() const
{
    return iPrivate->iText;
}

void DGCertRecognizer::setText(QString aText)
{
    iPrivate->setText(aText);
}

bool DGCertRecognizer::isValid() const
{
    return iPrivate->iValid;
}

int DGCertRecognizer::getFormatVersion() const
{
    return iPrivate->iFormatVersion;
}

#include "DGCertRecognizer.moc"
