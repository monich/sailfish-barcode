/*
The MIT License (MIT)

Copyright (c) 2021-2022 Slava Monich

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

.pragma library

// Value Sets for Digital Green Certificates
// Version 1.11
// 2022-09-14

var diseaseDisplayNames = {
    "840539006" : "COVID-19"
}

var vaccineTypeDisplayNames = {
    "1119305005": "SARS-CoV-2 antigen vaccine",
    "1119349007": "SARS-CoV-2 mRNA vaccine",
    "J07BX03": "COVID-19 vaccine",
    "1162643001": "SARS-CoV-2 recombinant spike protein antigen vaccine",
    "1157024006": "Inactivated whole SARS-CoV-2 antigen vaccine",
    "29061000087103": "COVID-19 non-replicating viral vector vaccine"
}

var vaccineProductDisplayNames = {
    "EU/1/20/1528": "Comirnaty (Pfizer/BioNTech)",
    "EU/1/20/1507": "COVID-19 Vaccine Moderna",
    "EU/1/21/1529": "Vaxzevria (AstraZeneca)",
    "EU/1/20/1525": "COVID-19 Vaccine Janssen",
    "CVnCoV": "CVnCoV (CureVac)",
    "NVX-CoV2373": "NVX-CoV2373 (Novavax)",
    "Sputnik-V": "Sputnik V (Gam-COVID-Vac)",
    "Convidecia": "Convidecia (PakVac)",
    "EpiVacCorona": "EpiVacCorona (Aurora-CoV)",
    "BBIBP-CorV": "BBIBP-CorV (Sinopharm)",
    "Inactivated-SARS-CoV-2-Vero-Cell": "Inactivated SARS‑CoV‑2 (Sinopharm)",
    "CoronaVac": "CoronaVac (Sinovac)",
    "Covaxin": "Covaxin (Bharat Biotech)",
    "Covid-19-recombinant": "Covid-19 (recombinant)",
    "Sputnik-Light": "Sputnik Light",
    "MVC-COV1901": "MVC COVID-19 vaccine",
    "EU/1/21/1618": "Nuvaxovid",
    "Sputnik-M": "Sputnik M",
    "Covid-19-adsorvida-inativada": "Vacina adsorvida covid-19 (inativada)",
    "Soberana-02": "Soberana 02",
    "Soberana-Plus": "Soberana Plus",
    "EU/1/21/1624": "COVID-19 Vaccine Valneva"
}

var vaccineManufacturerDisplayNames = {
    "ORG-100001699": "AstraZeneca AB",
    "ORG-100030215": "Biontech Manufacturing GmbH",
    "ORG-100001417": "Janssen-Cilag International",
    "ORG-100031184": "Moderna Biotech Spain S.L.",
    "ORG-100006270": "Curevac AG",
    "ORG-100013793": "CanSino Biologics",
    "ORG-100020693": "China Sinopharm International Corp. - Beijing location",
    "ORG-100010771": "Sinopharm Weiqida Europe Pharmaceutical s.r.o. - Prague location",
    "ORG-100024420": "Sinopharm Zhijun (Shenzhen) Pharmaceutical Co. Ltd. - Shenzhen location",
    "ORG-100032020": "Novavax CZ AS",
    "Gamaleya-Research-Institute": "Gamaleya Research Institute",
    "Vector-Institute": "Vector Institute",
    "Sinovac-Biotech": "Sinovac Biotech",
    "Bharat-Biotech": "Bharat Biotech",
    "ORG-100001981": "Serum Institute Of India Private Limited",
    "ORG-100007893": "R-Pharm CJSC",
    "Chumakov-Federal-Scientific-Center": "Chumakov Federal Scientific Center for Research and Development of Immune-and-Biological Products",
    "ORG-100023050": "Gulf Pharmaceutical Industries",
    "CIGB": "Center for Genetic Engineering and Biotechnology (CIGB)",
    "Sinopharm-WIBP": "Sinopharm - Wuhan Institute of Biological Products",
    "ORG-100033914": "Medigen Vaccine Biologics Corporation",
    "ORG-100000788": "Sanofi Pasteur",
    "ORG-100036422": "Valneva France",
    "Instituto-Butantan": "Instituto Butantan",
    "NVSI": "National Vaccine and Serum Institute, China",
    "Yisheng-Biopharma": "Yisheng Biopharma",
    "ORG-100026614": "Sinocelltech Ltd.",
    "ORG-100008549": "Medicago Inc.",
    "Finlay-Institute": "Finlay Institute of Vaccines"
}

// Result of the test
var testResultDisplayNames = {
    //: Test result
    //% "Not detected"
    "260415000": qsTrId("dgcert-test_result-not_detected"),
    //: Test result
    //% "Detected"
    "260373001": qsTrId("dgcert-test_result-detected")
}

// 2- and 3-letter country codes for the EU member states
var euCountryCodes = [
    "AT", "AUT", // Austria
    "BE", "BEL", // Belgium
    "BG", "BGR", // Bulgaria
    "HR", "HRV", // Croatia
    "CY", "CYP", // Cyprus
    "CZ", "CZE", // Czech Republic
    "DK", "DNK", // Denmark
    "EE", "EST", // Estonia
    "FI", "FIN", // Finland
    "FR", "FRA", // France
    "DE", "DEU", // Germany
    "GR", "GRC", // Greece
    "HU", "HUN", // Hungary
    "IE", "IRL", // Ireland
    "IT", "ITA", // Italy
    "LV", "LVA", // Latvia
    "LT", "LTU", // Lithuania
    "LU", "LUX", // Luxembourg
    "MT", "MLT", // Malta
    "NL", "NLD", // Netherlands
    "PL", "POL", // Poland
    "PT", "PRT", // Portugal
    "RO", "ROU", // Romania
    "SK", "SVK", // Slovakia
    "SI", "SVN", // Slovenia
    "ES", "ESP", // Spain
    "SE", "SWE"  // Sweden
]

function dateString(date) {
    return date.toLocaleDateString(Qt.locale(), "yyyy-MM-dd")
}

function timeString(date) {
    return date.toLocaleTimeString(Qt.locale(), "hh:mm")
}

function dateTimeString(date) {
    return dateString(date) + " " + timeString(date)
}

function diseaseDisplayName(code) {
    var name = diseaseDisplayNames[code]
    return name ? name : code
}

function vaccineTypeDisplayName(code) {
    var name = vaccineTypeDisplayNames[code]
    return name ? name : code
}

function vaccineProductDisplayName(code) {
    var name = vaccineProductDisplayNames[code]
    return name ? name : code
}

function vaccineManufacturerDisplayName(code) {
    var name = vaccineManufacturerDisplayNames[code]
    return name ? name : code
}

function testResultDisplayName(code) {
    var name = testResultDisplayNames[code]
    return name ? name : code
}

function isEUCountryCode(country) {
    var uppercased = country.toUpperCase()
    return euCountryCodes.indexOf(uppercased) >= 0 ||
        uppercased === "CH" || uppercased === "CHE" || // Switzerland
        uppercased === "NO" || uppercased === "NOR"    // Norway
}
