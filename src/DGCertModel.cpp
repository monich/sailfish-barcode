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

#include "DGCertModel.h"
#include "DGCertParser.h"

#include "HarbourTask.h"
#include "HarbourDebug.h"

#include <QThreadPool>
#include <QSharedPointer>
#include <QDateTime>

// ==========================================================================
// DGCertModel::Task
//
// Attempts to decode a Digital Green Certificate. It's typically not a big
// task but it often happens at the moment when page transition animation is
// running, so it better be done on a separate thread.
// ==========================================================================

class DGCertModel::Task : public HarbourTask
{
    Q_OBJECT

public:
    Task(QThreadPool* aPool,  const QString& aText);

    void performTask() Q_DECL_OVERRIDE;

public:
    const QString iText;
    DGCertParser::Payload iPayload;
    bool iValid;
    int iFormatVersion;
};

DGCertModel::Task::Task(QThreadPool* aPool, const QString& aText) :
    HarbourTask(aPool),
    iText(aText),
    iValid(false),
    iFormatVersion(0)
{
}

void DGCertModel::Task::performTask()
{
    iValid = DGCertParser::parse(iText, &iPayload, &iFormatVersion);
}

// ==========================================================================
// DGCertModel::Group
// ==========================================================================

class DGCertModel::Group
{
public:
    typedef QList<Group> List;

    enum Role {
        TypeRole = Qt::UserRole,
        ContentsRole
    };

    Group(CertificateType aType, const QVariantMap aContents) :
        iType(aType), iContents(aContents) {}

public:
    CertificateType iType;
    QVariantMap iContents;
};

// ==========================================================================
// DGCertModel::Private
// ==========================================================================

class DGCertModel::Private : public QObject
{
    Q_OBJECT

public:
    Private(QObject* aParent);
    ~Private();

    DGCertModel* parentObject() const;
    void setText(QString aText);
    void resetParsedData();

    static QVariantMap firstMapInArray(const QVariant aMap, const QString aKey);

public Q_SLOTS:
    void onTaskDone();

public:
    QSharedPointer<QThreadPool> iThreadPool;
    Task* iTask;
    bool iValid;
    int iFormatVersion;
    QString iIssuer;
    QDateTime iIssueDate;
    QDateTime iExpirationDate;
    QString iSchemaVersion;
    QVariantMap iPersonName;
    QString iBirthday;
    Group::List iGroups;
    QString iText;
};

DGCertModel::Private::Private(QObject* aParent) :
    QObject(aParent),
    iThreadPool(DGCertParser::threadPool()),
    iTask(Q_NULLPTR),
    iValid(false),
    iFormatVersion(0)
{
}

DGCertModel::Private::~Private()
{
    if (iTask) iTask->release();
}

inline DGCertModel* DGCertModel::Private::parentObject() const
{
    return qobject_cast<DGCertModel*>(parent());
}

void DGCertModel::Private::setText(QString aText)
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

QVariantMap DGCertModel::Private::firstMapInArray(const QVariant aMap, const QString aKey)
{
    const QVariantList list(aMap.toMap().value(aKey).toList());
    return list.isEmpty() ? QVariantMap() : list.first().toMap();
}

void DGCertModel::Private::onTaskDone()
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

        bool issuerChanged = false;
        if (iIssuer != task->iPayload.iIssuer) {
            iIssuer = task->iPayload.iIssuer;
            issuerChanged = true;
        }

        bool issueDateChanged = false;
        if (iIssueDate != task->iPayload.iIssueDate) {
            iIssueDate = task->iPayload.iIssueDate;
            issueDateChanged = true;
        }

        bool expirationDateChanged = false;
        if (iExpirationDate != task->iPayload.iExpirationDate) {
            iExpirationDate = task->iPayload.iExpirationDate;
            expirationDateChanged = true;
        }

        const QVariantMap hcert(task->iPayload.iHCert);
        bool schemaVersionChanged = false;
        static const QString SCHEMA_VERSION_KEY("ver");
        const QString schemaVersion(hcert.value(SCHEMA_VERSION_KEY).toString());
        if (iSchemaVersion != schemaVersion) {
            iSchemaVersion = schemaVersion;
            schemaVersionChanged = true;
        }

        bool birthdayChanged = false;
        static const QString BIRTHDAY_KEY("dob");
        const QString birthday(hcert.value(BIRTHDAY_KEY).toString());
        if (iBirthday != birthday) {
            iBirthday = birthday;
            birthdayChanged = true;
        }

        // Assume this one always changes
        static const QString PERSON_NAME_KEY("nam");
        iPersonName = hcert.value(PERSON_NAME_KEY).toMap();

        DGCertModel* model = parentObject();

        static const QString VACCINATION_ENTRY("v");
        static const QString RECOVERY_ENTRY("r");
        static const QString TEST_ENTRY("t");
        model->beginResetModel();
        iGroups.clear();
        const QVariantMap v(firstMapInArray(hcert, VACCINATION_ENTRY));
        if (!v.isEmpty()) {
            HDEBUG("v =>" << v);
            iGroups.append(Group(VaccinationCertificate, v));
        }
        const QVariantMap r(firstMapInArray(hcert, RECOVERY_ENTRY));
        if (!r.isEmpty()) {
            HDEBUG("r =>" << r);
            iGroups.append(Group(RecoveryCertificate, r));
        }
        const QVariantMap t(firstMapInArray(hcert, TEST_ENTRY));
        if (!t.isEmpty()) {
            HDEBUG("t =>" << t);
            iGroups.append(Group(TestCertificate, t));
        }
        model->endResetModel();

        if (validChanged && !task->iValid) {
            Q_EMIT model->validChanged();
        }
        if (formatVersionChanged) {
            Q_EMIT model->formatVersionChanged();
        }
        if (issuerChanged) {
            Q_EMIT model->issuerChanged();
        }
        if (issueDateChanged) {
            Q_EMIT model->issueDateChanged();
        }
        if (expirationDateChanged) {
            Q_EMIT model->expirationDateChanged();
        }
        if (schemaVersionChanged) {
            Q_EMIT model->schemaVersionChanged();
        }
        if (birthdayChanged) {
            Q_EMIT model->birthdayChanged();
        }
        Q_EMIT model->personNameChanged();
        if (validChanged && task->iValid) {
            Q_EMIT model->validChanged();
        }
        task->release();
    }
}

void DGCertModel::Private::resetParsedData()
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

    bool schemaVersionChanged = false;
    if (!iSchemaVersion.isEmpty()) {
        iSchemaVersion.clear();
        schemaVersionChanged = true;
    }

    bool issuerChanged = false;
    if (!iIssuer.isEmpty()) {
        iIssuer.clear();
        issuerChanged = true;
    }

    bool issueDateChanged = false;
    if (iIssueDate.isValid()) {
        iIssueDate = QDateTime();
        issueDateChanged = true;
    }

    bool expirationDateChanged = false;
    if (iExpirationDate.isValid()) {
        iExpirationDate = QDateTime();
        expirationDateChanged = true;
    }

    bool personNameChanged = false;
    if (!iPersonName.isEmpty()) {
        iPersonName.clear();
        personNameChanged = true;
    }

    bool birthdayChanged = false;
    if (!iBirthday.isEmpty()) {
        iBirthday.clear();
        birthdayChanged = true;
    }

    DGCertModel* model = parentObject();

    if (!iGroups.isEmpty()) {
        model->beginResetModel();
        iGroups.clear();
        model->endResetModel();
    }
    if (validChanged) {
        Q_EMIT model->validChanged();
    }
    if (formatVersionChanged) {
        Q_EMIT model->formatVersionChanged();
    }
    if (issuerChanged) {
        Q_EMIT model->issuerChanged();
    }
    if (issueDateChanged) {
        Q_EMIT model->issueDateChanged();
    }
    if (expirationDateChanged) {
        Q_EMIT model->expirationDateChanged();
    }
    if (schemaVersionChanged) {
        Q_EMIT model->schemaVersionChanged();
    }
    if (personNameChanged) {
        Q_EMIT model->personNameChanged();
    }
    if (birthdayChanged) {
        Q_EMIT model->birthdayChanged();
    }
}

// ==========================================================================
// DGCertModel
// ==========================================================================

DGCertModel::DGCertModel(QObject* aParent) :
    QAbstractListModel(aParent),
    iPrivate(new Private(this))
{
}

DGCertModel::~DGCertModel()
{
    delete iPrivate;
}

QString DGCertModel::getText() const
{
    return iPrivate->iText;
}

void DGCertModel::setText(QString aText)
{
    iPrivate->setText(aText);
}

bool DGCertModel::isValid() const
{
    return iPrivate->iValid;
}

int DGCertModel::getFormatVersion() const
{
    return iPrivate->iFormatVersion;
}

QString DGCertModel::getIssuer() const
{
    return iPrivate->iIssuer;
}

QDateTime DGCertModel::getIssueDate() const
{
    return iPrivate->iIssueDate;
}

QDateTime DGCertModel::getExpirationDate() const
{
    return iPrivate->iExpirationDate;
}

QString DGCertModel::getSchemaVersion() const
{
    return iPrivate->iSchemaVersion;
}

QString DGCertModel::getBirthday() const
{
    return iPrivate->iBirthday;
}

QVariantMap DGCertModel::getPersonName() const
{
    return iPrivate->iPersonName;
}

QHash<int,QByteArray> DGCertModel::roleNames() const
{
    QHash<int,QByteArray> roles;
    roles.insert(Group::TypeRole, "type");
    roles.insert(Group::ContentsRole, "contents");
    return roles;
}

int DGCertModel::rowCount(const QModelIndex& aParent) const
{
    return iPrivate->iGroups.count();
}

QVariant DGCertModel::data(const QModelIndex& aIndex, int aRole) const
{
    const int row = aIndex.row();
    if (row >=0 && row < iPrivate->iGroups.count()) {
        const Group& group(iPrivate->iGroups.at(row));
        switch ((Group::Role)aRole) {
        case Group::TypeRole: return group.iType;
        case Group::ContentsRole: return group.iContents;
        }
    }
    return QVariant();
}

#include "DGCertModel.moc"
