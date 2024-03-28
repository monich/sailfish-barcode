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

#ifndef BARCODE_HISTORY_MODEL_H
#define BARCODE_HISTORY_MODEL_H

#include <QtQml>
#include <QImage>
#include <QSortFilterProxyModel>

#define HISTORY_TABLE           "history"
#define HISTORY_FIELD_ID        "id"
#define HISTORY_FIELD_VALUE     "value"
#define HISTORY_FIELD_TIMESTAMP "timestamp"
#define HISTORY_FIELD_FORMAT    "format"

class HistoryModel :
    public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(int maxCount READ maxCount WRITE setMaxCount NOTIFY maxCountChanged)
    Q_PROPERTY(bool saveImages READ saveImages WRITE setSaveImages NOTIFY saveImagesChanged)
    Q_PROPERTY(bool hasImages READ hasImages NOTIFY hasImagesChanged)
    Q_PROPERTY(bool isEmpty READ isEmpty NOTIFY isEmptyChanged)
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)

public:
    HistoryModel(QObject* aParent = Q_NULLPTR);

    int totalCount() const;

    int maxCount() const;
    void setMaxCount(int aValue);

    bool isEmpty() const;
    bool hasImages() const;
    bool saveImages() const;
    void setSaveImages(bool aValue);

    QString filterString() const;
    void setFilterString(QString);

    Q_INVOKABLE QString getValue(int);
    Q_INVOKABLE int insert(QImage, QString, QString);
    Q_INVOKABLE void remove(int);
    Q_INVOKABLE void removeAt(int);
    Q_INVOKABLE void removeAll();
    Q_INVOKABLE void removeMany(QVariantList);
    Q_INVOKABLE void commitChanges();

    // Utilities
    Q_INVOKABLE static QString formatTimestamp(QString);

    // Callback for qmlRegisterSingletonType<HistoryModel>
    static QObject* createSingleton(QQmlEngine*, QJSEngine*);

protected:
    bool filterAcceptsRow(int, const QModelIndex&) const;

private Q_SLOTS:
    void updateCount();

Q_SIGNALS:
    void countChanged();
    void totalCountChanged();
    void maxCountChanged();
    void saveImagesChanged();
    void hasImagesChanged();
    void isEmptyChanged();
    void filterStringChanged();

private:
    class Private;
    class SaveTask;
    class CleanupTask;
    class PurgeTask;
    Private* iPrivate;
};

QML_DECLARE_TYPE(HistoryModel)

#endif // BARCODE_HISTORY_MODEL_H
