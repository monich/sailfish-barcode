/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2022 Slava Monich

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

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.barcode 1.0

import "../components"
import "../harbour"

Page {
    id: aboutPage

    allowedOrientations: window.allowedOrientations

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: aboutColumn.height

        Column {
            id: aboutColumn

            width: parent.width
            height: childrenRect.height

            PageHeader {
                // No need to translate this one
                title: "CodeReader"
            }

            Image {
                readonly property int size: Theme.itemSizeHuge
                source: "img/harbour-barcode.svg"
                anchors.horizontalCenter: parent.horizontalCenter
                sourceSize: Qt.size(size, size)
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            LabelText {
                //: About page text
                //% "This app demonstrates a bar code reader for Sailfish OS. We hope it is useful for other projects. CodeReader is open source and licensed under the MIT License."
                text: qsTrId("about-description")
            }

            LabelText {
                //: About page label
                //% "Version"
                label: qsTrId("about-version-label")
                text: AppVersion
            }

            LabelText {
                //: About page label
                //% "Authors"
                label: qsTrId("about-author-labels")
                text: "Steffen\u00A0Förster, Slava\u00A0Monich"
            }

            LabelText {
                //: About page label
                //% "Contributors"
                label: qsTrId("about-contributors-label")
                //: About page text
                //% "%1 and others."
                text: qsTrId("about-contributors-text").arg("Diego\u00A0Russo, Åke\u00A0Engelbrektson, Dominik\u00A0Chrástecký, Miklós\u00A0Márton, Hauke\u00A0Schade")
            }

            ListItem {
                id: clickableUrl

                contentHeight: labelUrl.height
                height: contentHeight + (menuOpen ? openUrlMenu.height : 0)
                width: parent.width

                LabelText {
                    id: labelUrl
                    //: About page label
                    //% "Source code"
                    label: qsTrId("about-source_code-label")
                    text: "https://github.com/monich/sailfish-barcode"
                    //: About page description for source code URL
                    //% "You can also file issues and bug reports there."
                    description: qsTrId("about-source_code-description")
                    color: clickableUrl.highlighted ? Theme.highlightColor : Theme.primaryColor
                    separator: false // It's below the menu
                }
                onClicked: Qt.openUrlExternally(labelUrl.text);
                menu: ContextMenu {
                    id: openUrlMenu
                    MenuItem {
                        //: Button text
                        //% "Open link"
                        text: qsTrId("button-open_link")
                        onClicked: Qt.openUrlExternally(labelUrl.text);
                    }
                }
            }

            Separator {
                width:parent.width
                color: Theme.highlightColor
                horizontalAlignment: Qt.AlignHCenter
            }

            LabelText {
                //: About page label
                //% "References"
                label: qsTrId("about-references-label")
                //: About page text
                //% "This project uses code and ideas of other projects, see README.md on Github."
                text: qsTrId("about-references-text")
            }

            LabelText {
                //: About page label
                //% "Supported 1D/2D bar codes"
                label: qsTrId("about-supported_codes-label")
                separator: false
            }

            Grid {
                id: grid

                readonly property int cellWidth: Math.floor((width - spacing * (columns - 1))/columns)
                readonly property int cellHeight: Math.floor(cellWidth * 5 / 8)

                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                spacing: Theme.paddingLarge
                columns: Math.max(Math.floor((width + spacing)/(Theme.itemSizeExtraLarge + spacing)), 1)

                Repeater {
                    model: BarcodeFormatModel { }
                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            color: "white"
                            anchors.fill: parent
                        }

                        HarbourHighlightIcon {
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                top: parent.top
                                topMargin: Theme.paddingSmall
                                bottom: formatName.top
                            }
                            width: parent.width - 2 * Theme.paddingSmall
                            source: "img/sample-" + model.sample + ".svg"
                            highlightColor: "black"
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            verticalAlignment: Image.AlignTop
                            horizontalAlignment: Image.AlignHCenter
                            smooth: true
                        }

                        Text {
                            id: formatName

                            text: model.name
                            font.pixelSize: Theme.fontSizeTiny
                            color: "black"
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                bottom: parent.bottom
                            }
                        }
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }
        }

        VerticalScrollDecorator { }
    }
}
