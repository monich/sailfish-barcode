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

#ifndef DGCERT_MODEL_H
#define DGCERT_MODEL_H

#include <QString>
#include <QDateTime>
#include <QVariantMap>
#include <QAbstractListModel>

/*
 * Technical Specifications for Digital Green Certificates
 * https://ec.europa.eu/health/ehealth/covid-19_en
 */
class DGCertModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString text READ getText WRITE setText NOTIFY textChanged)
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
    Q_PROPERTY(int formatVersion READ getFormatVersion NOTIFY formatVersionChanged)
    Q_PROPERTY(QString issuer READ getIssuer NOTIFY issuerChanged)
    Q_PROPERTY(QDateTime issueDate READ getIssueDate NOTIFY issueDateChanged)
    Q_PROPERTY(QDateTime expirationDate READ getExpirationDate NOTIFY expirationDateChanged)
    Q_PROPERTY(QString schemaVersion READ getSchemaVersion NOTIFY schemaVersionChanged)
    Q_PROPERTY(QVariantMap personName READ getPersonName NOTIFY personNameChanged)
    Q_PROPERTY(QString birthday READ getBirthday NOTIFY birthdayChanged)
    Q_ENUMS(CertificateType)

public:
    class Task;
    class Group;

    enum CertificateType {
        UnknownType,
        VaccinationCertificate,
        RecoveryCertificate,
        TestCertificate
    };

    DGCertModel(QObject* aParent = Q_NULLPTR);
    ~DGCertModel();

    QString getText() const;
    void setText(QString aText);

    bool isValid() const;
    int getFormatVersion() const;
    QString getIssuer() const;
    QDateTime getIssueDate() const;
    QDateTime getExpirationDate() const;
    QString getSchemaVersion() const;
    QVariantMap getPersonName() const;
    QString getBirthday() const;

    // QAbstractItemModel
    QHash<int,QByteArray> roleNames() const Q_DECL_OVERRIDE;
    int rowCount(const QModelIndex& aParent = QModelIndex()) const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex& aIndex, int aRole) const Q_DECL_OVERRIDE;

Q_SIGNALS:
    void textChanged();
    void validChanged();
    void formatVersionChanged();
    void issuerChanged();
    void issueDateChanged();
    void expirationDateChanged();
    void schemaVersionChanged();
    void personNameChanged();
    void birthdayChanged();

private:
    class Private;
    Private* iPrivate;
};

#endif // DGCERT_MODEL_H
