/*
The MIT License (MIT)

Copyright (c) 2022 Slava Monich

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

#ifndef BARCODE_FORMAT_MODEL_H
#define BARCODE_FORMAT_MODEL_H

#include <QAbstractListModel>

class BarcodeFormatModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(uint hints READ getHints WRITE setHints NOTIFY hintsChanged)

public:
    BarcodeFormatModel(QObject* aParent = Q_NULLPTR);
    ~BarcodeFormatModel();

    static const QString formatName(QString aIdent);

    uint getHints() const;
    void setHints(uint aHints);

    // QAbstractItemModel
    QHash<int,QByteArray> roleNames() const Q_DECL_OVERRIDE;
    int rowCount(const QModelIndex& aParent = QModelIndex()) const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex& aIndex, int aRole) const Q_DECL_OVERRIDE;

Q_SIGNALS:
    void hintsChanged();

private:
    class Private;
    Private* iPrivate;
};


#endif // BARCODE_FORMAT_MODEL_H
