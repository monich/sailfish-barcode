/*
The MIT License (MIT)

Copyright (c) 2019-2020 Slava Monich

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
    id: historyPage

    allowedOrientations: window.allowedOrientations

    property alias model: historyList.model
    property Item hint

    signal copySelected()
    signal deleteSelected()

    function showHint(text) {
        if (!hint) {
            hint = hintComponent.createObject(historyPage)
        }
        hint.text = text
        hint.opacity = 1.0
    }

    function hideHint() {
        if (hint) {
            hint.opacity = 0.0
        }
    }

    Component {
        id: hintComponent

        Hint { }
    }

    SilicaListView {
        id: historyList

        width: parent.width
        clip: true
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: toolPanel.top
        }

        header: PageHeader {
            id: header

            //: Selection page title
            //% "Select codes"
            title: qsTrId("select-title")

            HarbourBadge {
                anchors {
                    right: header.extraContent.right
                    rightMargin: Theme.paddingLarge
                    verticalCenter: header.extraContent.verticalCenter
                }
                maxWidth: header.extraContent.width - anchors.rightMargin
                text: model.count ? model.count : ""
            }
        }

        delegate: HistoryItem {
            value: model.value
            timestamp: model.timestamp
            format: model.format
            selected: model.selected
            onClicked: model.selected = !model.selected
        }

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                id: selectAllMenuItem

                //: Pulley menu item
                //% "Select all"
                text: qsTrId("select-menu-all")
                enabled: model.selectionCount < model.count
                onEnabledChanged: if (!pullDownMenu.active) visible = enabled
                onClicked: model.selectAll()
            }

            MenuItem {
                id: selectNoneMenuItem

                //: Pulley menu item
                //% "Select none"
                text: qsTrId("select-menu-none")
                enabled: model.selectionCount > 0
                onEnabledChanged: if (!pullDownMenu.active) visible = enabled
                onClicked: model.clearSelection()
            }

            Component.onCompleted: updateMenuItems()
            onActiveChanged: updateMenuItems()

            function updateMenuItems() {
                if (!active) {
                    selectNoneMenuItem.visible = selectNoneMenuItem.enabled
                    selectAllMenuItem.visible = selectAllMenuItem.enabled
                }
            }
        }

        VerticalScrollDecorator { }
    }

    ToolPanel {
        id: toolPanel

        active: model.selectionCount > 0
        //: Hint label
        //% "Delete selected codes"
        deleteHint: qsTrId("hint-delete_selected_codes")
        //: Hint label
        //% "Copy selected codes to clipboard"
        copyHint: qsTrId("hint-copy_selected_codes")

        onCopySelected: historyPage.copySelected()
        onDeleteSelected: historyPage.deleteSelected()
        onShowHint: historyPage.showHint(text)
        onHideHint: historyPage.hideHint()
    }
}
