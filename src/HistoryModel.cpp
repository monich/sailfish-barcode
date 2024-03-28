/*
The MIT License (MIT)

 Copyright (c) 2018-2024 Slava Monich

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

#include "HistoryModel.h"
#include "HistoryImageProvider.h"
#include "Database.h"

#include "HarbourDebug.h"
#include "HarbourTask.h"

#include <QDirIterator>
#include <QThreadPool>
#include <QFileInfo>
#include <QImage>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRecord>
#include <QSqlTableModel>

#include <limits.h>

// ==========================================================================
// HistoryModel::CleanupTask
// Removes image files not associated with any rows in the database
// ==========================================================================

class HistoryModel::CleanupTask :
    public HarbourTask
{
    Q_OBJECT

public:
    CleanupTask(QThreadPool*, QStringList);
    void performTask() Q_DECL_OVERRIDE;

public:
    QStringList iList;
    bool iHaveImages;
};

HistoryModel::CleanupTask::CleanupTask(
    QThreadPool* aPool,
    QStringList aList) :
    HarbourTask(aPool),
    iList(aList),
    iHaveImages(false)
{
}

void
HistoryModel::CleanupTask::performTask()
{
    QDirIterator it(Database::imageDir().path(), QDir::Files);
    while (it.hasNext()) {
        it.next();
        const QString name(it.fileName());
        if (name.endsWith(HistoryImageProvider::IMAGE_EXT)) {
            const QString base(name.left(name.length() -
                HistoryImageProvider::IMAGE_EXT.length()));
            const int pos = iList.indexOf(base);
            if (pos >= 0) {
                iList.removeAt(pos);
                iHaveImages = true;
            } else {
                const QString path(it.filePath());
                HDEBUG("deleting" << base << qPrintable(path));
                if (!QFile::remove(path)) {
                    HWARN("Failed to delete" << qPrintable(path));
                }
            }
        }
    }
    HDEBUG("done");
}

// ==========================================================================
// HistoryModel::SaveTask
// ==========================================================================

class HistoryModel::SaveTask :
    public HarbourTask
{
    Q_OBJECT

public:
    SaveTask(QThreadPool*, QImage, QString);
    void performTask() Q_DECL_OVERRIDE;

public:
    const QImage iImage;
    const QString iId;
    const QString iName;
};

HistoryModel::SaveTask::SaveTask(
    QThreadPool* aPool,
    QImage aImage,
    QString aId) :
    HarbourTask(aPool),
    iImage(aImage),
    iId(aId),
    iName(aId + HistoryImageProvider::IMAGE_EXT)
{
}

void
HistoryModel::SaveTask::performTask()
{
    QDir dir(Database::imageDir());
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    const QString path(dir.filePath(iName));
    HDEBUG(qPrintable(path));
    if (!iImage.save(path)) {
        HWARN("Fails to save" << qPrintable(path));
    }
    HDEBUG("done");
}

// ==========================================================================
// HistoryModel::PurgeTask
// ==========================================================================

class HistoryModel::PurgeTask :
    public QRunnable
{
public:
    void run() Q_DECL_OVERRIDE;
};

void
HistoryModel::PurgeTask::run()
{
    QDirIterator it(Database::imageDir().path(), QDir::Files);
    while (it.hasNext()) {
        it.next();
        const QString name(it.fileName());
        if (name.endsWith(HistoryImageProvider::IMAGE_EXT)) {
            bool ok = false;
            const QString base(name.left(name.length() -
                HistoryImageProvider::IMAGE_EXT.length()));
            base.toInt(&ok);
            if (ok) {
                const QString path(it.filePath());
                HDEBUG("deleting" << base << qPrintable(path));
                if (!QFile::remove(path)) {
                    HWARN("Failed to delete" << qPrintable(path));
                }
            }
        }
    }
    HDEBUG("done");
}

// ==========================================================================
// HistoryModel::Private
// ==========================================================================

class HistoryModel::Private :
    public QSqlTableModel
{
    Q_OBJECT

public:
    enum {
        FIELD_ID,
        FIELD_VALUE,
        FIELD_TIMESTAMP, // DB_SORT_COLUMN (see below)
        FIELD_FORMAT,
        NUM_FIELDS
    };

    // Order of first NUM_FIELDS roles must match the order of fields:
    enum {
        FirstRole = Qt::UserRole,
        IdRole = FirstRole,
        ValueRole,
        TimestampRole,
        FormatRole,
        HasImageRole,
        LastRole = HasImageRole
    };

    static const int DB_SORT_COLUMN = FIELD_TIMESTAMP;
    static const QString DB_TABLE;
    static const QString DB_FIELD[NUM_FIELDS];
    static const QString HAS_IMAGE;

#define DB_FIELD_ID DB_FIELD[HistoryModel::Private::FIELD_ID]
#define DB_FIELD_VALUE DB_FIELD[HistoryModel::Private::FIELD_VALUE]
#define DB_FIELD_TIMESTAMP DB_FIELD[HistoryModel::Private::FIELD_TIMESTAMP]
#define DB_FIELD_FORMAT DB_FIELD[HistoryModel::Private::FIELD_FORMAT]

    enum TriState { No, Maybe, Yes };

    Private(HistoryModel*);
    ~Private();

    HistoryModel* historyModel() const;
    QVariant valueAt(int, int) const;
    bool isEmpty() const;
    bool imageFileExistsAt(int) const;
    bool removeExtraRows(int aReserve = 0);
    void commitChanges();
    void cleanupFiles();

    QHash<int,QByteArray> roleNames() const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex&, int) const Q_DECL_OVERRIDE;

private Q_SLOTS:
    void onSaveDone();
    void onCleanupDone();

public:
    QThreadPool* iThreadPool;
    TriState iHaveImages;
    QString iFilterString;
    bool iSaveImages;
    int iMaxCount;
    int iLastKnownCount;
    bool iLastKnownEmpty;
    int iFieldIndex[NUM_FIELDS];
};

const QString HistoryModel::Private::DB_TABLE(QLatin1String(HISTORY_TABLE));
const QString HistoryModel::Private::DB_FIELD[] = {
    QLatin1String(HISTORY_FIELD_ID),
    QLatin1String(HISTORY_FIELD_VALUE),
    QLatin1String(HISTORY_FIELD_TIMESTAMP),
    QLatin1String(HISTORY_FIELD_FORMAT)
};
const QString HistoryModel::Private::HAS_IMAGE("hasImage");

HistoryModel::Private::Private(
    HistoryModel* aPublicModel) :
    QSqlTableModel(aPublicModel, Database::database()),
    iThreadPool(new QThreadPool(this)),
    iHaveImages(Maybe),
    iSaveImages(true),
    iMaxCount(INT_MAX),
    iLastKnownCount(0)
{
    iThreadPool->setMaxThreadCount(1);
    for (int i = 0; i < NUM_FIELDS; i++) iFieldIndex[i] = -1;
    QSqlDatabase db = database();
    if (db.open()) {
        HDEBUG("database opened");
        setTable(DB_TABLE);
        select();
        for (int i = 0; i < NUM_FIELDS; i++) {
            const QString name(DB_FIELD[i]);
            iFieldIndex[i] = fieldIndex(name);
            HDEBUG(iFieldIndex[i] << name);
        }
    } else {
        HWARN(db.lastError());
    }
    const int sortColumn = iFieldIndex[DB_SORT_COLUMN];
    if (sortColumn >= 0) {
        HDEBUG("sort column" << sortColumn);
        setSort(sortColumn, Qt::DescendingOrder);
        sort(sortColumn, Qt::DescendingOrder);
    }
    setEditStrategy(QSqlTableModel::OnManualSubmit);
    iLastKnownEmpty = !rowCount(); // Nothing is dirty at startup
    // At startup we assume that images are being saved
    cleanupFiles();
}

HistoryModel::Private::~Private()
{
    if (isDirty()) {
        commitChanges();
        cleanupFiles();
    }
    iThreadPool->waitForDone();
}

HistoryModel*
HistoryModel::Private::historyModel() const
{
    return qobject_cast<HistoryModel*>(QObject::parent());
}

QHash<int,QByteArray>
HistoryModel::Private::roleNames() const
{
    QHash<int,QByteArray> roles;
    for (int i = 0; i < NUM_FIELDS; i++) {
        roles.insert(FirstRole + i, DB_FIELD[i].toUtf8());
    }
    roles.insert(HasImageRole, HAS_IMAGE.toLatin1());
    return roles;
}

bool
HistoryModel::Private::isEmpty() const
{
    const int n = rowCount();
    for (int i = 0; i < n; i++) {
        if (!isDirty(index(i, 0))) {
            return false;
        }
    }
    return true;
}

bool
HistoryModel::Private::imageFileExistsAt(
    int aRow) const
{
    bool ok;
    int id = valueAt(aRow, FIELD_ID).toInt(&ok);
    if (ok) {
        const QString path(Database::imageDir().
            filePath(QString::number(id) + HistoryImageProvider::IMAGE_EXT));
        if (QFile::exists(path)) {
            HDEBUG(path << "exists");
            return true;
        }
    }
    return false;
}

QVariant
HistoryModel::Private::data(
    const QModelIndex& aIndex,
    int aRole) const
{
    if (aRole >= FirstRole) {
        const int i = aRole - FirstRole;
        const int row = aIndex.row();
        if (i < NUM_FIELDS) {
            int column = iFieldIndex[i];
            if (column >= 0) {
                return QSqlTableModel::data(index(row, column));
            }
        } else if (aRole == HasImageRole) {
            return QVariant::fromValue(iSaveImages && imageFileExistsAt(row));
        }
        return QVariant();
    } else {
        return QSqlTableModel::data(aIndex, aRole);
    }
}

QVariant
HistoryModel::Private::valueAt(
    int aRow,
    int aField) const
{
    if (aField >= 0 && aField < NUM_FIELDS) {
        const int column = iFieldIndex[aField];
        if (column >= 0) {
            return QSqlTableModel::data(index(aRow, column));
        }
    }
    return QVariant();
}

bool
HistoryModel::Private::removeExtraRows(
    int aReserve)
{
    if (iMaxCount > 0) {
        HistoryModel* filter = historyModel();
        const int max = qMax(iMaxCount - aReserve, 0);
        const int n = filter->rowCount();
        if (n > max) {
            for (int i = n; i > max; i--) {
                const int row = i - 1;
                QModelIndex index = filter->mapToSource(filter->index(row, 0));
                HDEBUG("Removing row" << row << "(" << index.row() << ")");
                removeRow(index.row());
            }
            return true;
        }
    }
    return false;
}

void
HistoryModel::Private::commitChanges()
{
    if (isDirty()) {
        QSqlDatabase db = database();
        db.transaction();
        HDEBUG("Commiting changes");
        if (submitAll()) {
            db.commit();
        } else {
            HWARN(db.lastError());
            db.rollback();
        }
    }
}

void
HistoryModel::Private::cleanupFiles()
{
    QSqlQuery query(database());
    query.prepare("SELECT " HISTORY_FIELD_ID " FROM " HISTORY_TABLE);
    if (query.exec()) {
        QStringList ids;
        while (query.next()) {
            ids.append(query.value(0).toString());
        }
        // Submit the cleanup task
        HDEBUG("ids:" << ids);
        (new CleanupTask(iThreadPool, ids))->
            submit(this, SLOT(onCleanupDone()));
    } else {
        HWARN(query.lastError());
    }
}

void
HistoryModel::Private::onSaveDone()
{
    SaveTask* task = qobject_cast<SaveTask*>(sender());
    HASSERT(task);
    if (task) {
        if (HistoryImageProvider::instance()) {
            HistoryImageProvider::instance()->dropFromCache(task->iId);
        }
        task->release();
    }
}

void
HistoryModel::Private::onCleanupDone()
{
    CleanupTask* task = qobject_cast<CleanupTask*>(sender());
    HASSERT(task);
    if (task) {
        if (iHaveImages == Maybe) {
            if (task->iHaveImages) {
                HDEBUG("we do have some images");
                iHaveImages = Yes;
            } else {
                HDEBUG("there are no saved images");
                iHaveImages = No;
            }
        }
        task->release();
    }
}

// ==========================================================================
// HistoryModel
// ==========================================================================

HistoryModel::HistoryModel(
    QObject* aParent) :
    QSortFilterProxyModel(aParent),
    iPrivate(new Private(this))
{
    setDynamicSortFilter(true);
    setFilterRole(Private::ValueRole);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    setSourceModel(iPrivate);
    iPrivate->iLastKnownCount = rowCount();
    connect(iPrivate, SIGNAL(rowsInserted(QModelIndex,int,int)), SIGNAL(totalCountChanged()));
    connect(iPrivate, SIGNAL(rowsRemoved(QModelIndex,int,int)), SIGNAL(totalCountChanged()));
    connect(iPrivate, SIGNAL(modelReset()), SIGNAL(totalCountChanged()));
    connect(this, SIGNAL(rowsInserted(QModelIndex,int,int)), SLOT(updateCount()));
    connect(this, SIGNAL(rowsRemoved(QModelIndex,int,int)), SLOT(updateCount()));
    connect(this, SIGNAL(modelReset()), SLOT(updateCount()));
}

// Callback for qmlRegisterSingletonType<HistoryModel>
QObject*
HistoryModel::createSingleton(
    QQmlEngine*,
    QJSEngine*)
{
    return new HistoryModel();
}

bool
HistoryModel::filterAcceptsRow(
    int aSourceRow,
    const QModelIndex& aParent) const
{
    return QSortFilterProxyModel::filterAcceptsRow(aSourceRow, aParent) &&
        !iPrivate->isDirty(iPrivate->index(aSourceRow, 0, aParent));
}

void
HistoryModel::updateCount()
{
    const int count = rowCount();
    const bool empty = iPrivate->isEmpty();
    const bool emptyChanged = empty != iPrivate->iLastKnownEmpty;

    if (emptyChanged) {
        HDEBUG("empty" << iPrivate->iLastKnownEmpty << "=>" << empty);
        iPrivate->iLastKnownEmpty = empty;
    }
    if (iPrivate->iLastKnownCount != count) {
        HDEBUG(iPrivate->iLastKnownCount << "=>" << count);
        iPrivate->iLastKnownCount = count;
        Q_EMIT countChanged();
    }
    if (emptyChanged) {
        Q_EMIT isEmptyChanged();
    }
}

int
HistoryModel::totalCount() const
{
    return iPrivate->rowCount();
}

int
HistoryModel::maxCount() const
{
    return iPrivate->iMaxCount;
}

void
HistoryModel::setMaxCount(
    int aValue)
{
    if (iPrivate->iMaxCount != aValue) {
        iPrivate->iMaxCount = aValue;
        HDEBUG(aValue);
        if (iPrivate->removeExtraRows()) {
            invalidateFilter();
            commitChanges();
            iPrivate->cleanupFiles();
        }
        Q_EMIT maxCountChanged();
    }
}

bool
HistoryModel::isEmpty() const
{
    return iPrivate->iLastKnownEmpty;
}

bool
HistoryModel::hasImages() const
{
    return iPrivate->iHaveImages != Private::No;
}

bool
HistoryModel::saveImages() const
{
    return iPrivate->iSaveImages;
}

void
HistoryModel::setSaveImages(
    bool aValue)
{
    if (iPrivate->iSaveImages != aValue) {
        HDEBUG(aValue);
        if (!aValue) {
            if (HistoryImageProvider::instance()) {
                HistoryImageProvider::instance()->clearCache();
            }
            // Collect the rows that are about to change
            // (keeping iSaveImages false)
            QVector<int> rows;
            const int totalCount = rowCount();
            if (totalCount > 0) {
                rows.reserve(totalCount);
                for (int i = 0; i < totalCount; i++) {
                    if (data(index(i, 0), Private::HasImageRole).toBool()) {
                        rows.append(i);
                    }
                }
            }

            // Update the flag
            iPrivate->iSaveImages = aValue;

            // Emit dataChanged for changed rows
            const int changedCount = rows.count();
            if (changedCount > 0) {
                const QVector<int> role(1, Private::HasImageRole);
                for (int i = 0; i < changedCount; i++) {
                    const QModelIndex modelIndex(index(rows.at(i), 0));
                    Q_EMIT dataChanged(modelIndex, modelIndex, role);
                }
            }

            // Actually delete all files on a separate thread
            iPrivate->iThreadPool->start(new PurgeTask);
            // And assume that we don't have images anymore
            if (iPrivate->iHaveImages != Private::No) {
                iPrivate->iHaveImages = Private::No;
                Q_EMIT hasImagesChanged();
            }
        } else {
            iPrivate->iSaveImages = aValue;
        }
        Q_EMIT saveImagesChanged();
    }
}

QString
HistoryModel::filterString() const
{
    return iPrivate->iFilterString;
}

void
HistoryModel::setFilterString(
    QString aPattern)
{
    if (iPrivate->iFilterString != aPattern) {
        iPrivate->iFilterString = aPattern;
        HDEBUG(aPattern);
        setFilterFixedString(aPattern);
        Q_EMIT filterStringChanged();
    }
}

QString
HistoryModel::getValue(
    int aRow)
{
    return data(index(aRow, Private::FIELD_VALUE)).toString();
}

int
HistoryModel::insert(
    QImage aImage,
    QString aText,
    QString aFormat)
{
    int id = 0;
    QString timestamp(QDateTime::currentDateTime().toString(Qt::ISODate));
    HDEBUG(aText << aFormat << timestamp << aImage);
    QSqlRecord record(iPrivate->database().record(Private::DB_TABLE));
    record.setValue(Private::DB_FIELD_VALUE, aText);
    record.setValue(Private::DB_FIELD_TIMESTAMP, timestamp);
    record.setValue(Private::DB_FIELD_FORMAT, aFormat);
    if (iPrivate->removeExtraRows(1)) {
        invalidateFilter();
        commitChanges();
    }
    const int row = 0;
    if (iPrivate->insertRecord(row, record)) {
        invalidateFilter();
        // Just commit the changes, no need for cleanup:
        iPrivate->commitChanges();
        id = iPrivate->valueAt(row, Private::FIELD_ID).toInt();
        HDEBUG(id << iPrivate->record(row));
        if (id && iPrivate->iSaveImages) {
            // Save the image on a separate thread. While we are saving
            // it, the image will remain cached by HistoryImageProvider.
            // It will be removed from the cache by Private::onSaveDone()
            HistoryImageProvider* ip = HistoryImageProvider::instance();
            const QString idString(QString::number(id));
            if (ip && ip->cacheImage(idString, aImage)) {
                (new SaveTask(iPrivate->iThreadPool, aImage, idString))->
                    submit(iPrivate, SLOT(onSaveDone()));
            }
            // Assume that we do have images now
            const bool hadImages = hasImages();
            iPrivate->iHaveImages = Private::Yes;
            if (!hadImages) {
                Q_EMIT hasImagesChanged();
            }
        }
    }
    return id;
}

void
HistoryModel::remove(
    int aRecordId)
{
    const int count = rowCount();
    for (int row = 0; row < count; row++) {
        bool ok;
        const int id = data(index(row, 0), Private::IdRole).toInt(&ok);
        if (ok && id == aRecordId) {
            HDEBUG("removing record" << aRecordId << "at" << row);
            removeRows(row, 1);
            invalidateFilter();
            return;
        }
    }
    HDEBUG("record" << aRecordId << "not found");
}

void
HistoryModel::removeAt(
    int aRow)
{
    HDEBUG(aRow << iPrivate->valueAt(aRow, Private::FIELD_ID).toString());
    removeRows(aRow, 1);
    invalidateFilter();
}

void
HistoryModel::removeAll()
{
    HDEBUG("clearing history");
    if (!iPrivate->isEmpty()) {
        iPrivate->removeRows(0, iPrivate->rowCount());
        invalidateFilter();
    }
}

void
HistoryModel::removeMany(
    QVariantList aIds)
{
    QList<int> rows;
    QVariantList ids(aIds);

    // Collect the list of rows
    rows.reserve(ids.count());
    const int count = rowCount();
    for (int row = 0; row < count && !ids.isEmpty(); row++) {
        const QVariant var(data(index(row, 0), Private::IdRole));
        if (ids.removeOne(var)) {
            rows.append(row);
        }
    }

    // Sort the rows
    qSort(rows);
    HDEBUG("ids" << aIds);
    HDEBUG("rows" << rows);

    // Remove the rows starting from the end of the list
    int start = -1, end = -1, removed = 0;
    for (int i = rows.count() - 1; i >= 0; i--) {
        const int row = rows.at(i);
        if (start < 0) {
            start = end = row;
        } else if (row == start - 1) {
            start = row;
        } else {
            const int n = end - start + 1;
            HDEBUG("Removing" << n << "row(s)" << start << ".." << end);
            removeRows(start, n);
            removed += n;
            start = end = row;
        }
    }
    if (start >= 0) {
        const int n = end - start + 1;
        HDEBUG("Removing" << n << "row(s)" << start << ".." << end);
        removeRows(start, n);
        removed += n;
    }
    if (removed > 0) {
        invalidateFilter();
    }
}

void
HistoryModel::commitChanges()
{
    iPrivate->commitChanges();
    if (iPrivate->iSaveImages) {
        iPrivate->cleanupFiles();
    }
}

QString
HistoryModel::formatTimestamp(
    QString aTimestamp)
{
    static const QString format("dd.MM.yyyy  hh:mm:ss");
    return QDateTime::fromString(aTimestamp, Qt::ISODate).toString(format);
}

#include "HistoryModel.moc"
