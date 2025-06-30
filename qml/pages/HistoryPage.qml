/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2025 Slava Monich

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
import org.nemomobile.notifications 1.0
import harbour.barcode 1.0

import "../js/Utils.js" as Utils
import "../components"

Page {
    property int _myStackDepth

    allowedOrientations: window.allowedOrientations

    onStatusChanged: {
        if (status === PageStatus.Active) {
            _myStackDepth = pageStack.depth
        } else if (status === PageStatus.Inactive) {
            // We also end up here after TextPage gets pushed
            if (pageStack.depth < _myStackDepth) {
                // It's us getting popped
                HistoryModel.commitChanges()
                header.loseFocus()
            }
        }
    }

    onIsPortraitChanged: {
        historyList.positionViewAtIndex(historyList.currentIndex, ListView.Visible)
        // Otherwise width is changing with a delay, causing visible layout changes:
        width = isPortrait ? Screen.width : Screen.height
    }

    Notification {
        id: clipboardNotification

        expireTimeout: 2000
        Component.onCompleted: {
            if ("icon" in clipboardNotification) {
                clipboardNotification.icon = "icon-s-clipboard"
            }
        }
    }

    SilicaFlickable {
        id: flickable

        anchors.fill: parent
        contentHeight: content.height

        onContentYChanged: {
            if (contentY >= header.height) {
                header.loseFocus()
            }
        }

        PullDownMenu {
            visible: historyList.model.count > 0
            MenuItem {
                //: Pulley menu item
                //% "Clear"
                text: qsTrId("history-menu-clear")
                onClicked: {
                    //: Remorse popup text
                    //% "Deleting all codes"
                    remorsePopup.execute(qsTrId("history-remorse-deleting_all"), function() {
                        HistoryModel.removeAll()
                        header.searchText = ""
                    })
                }
            }
            MenuItem {
                //: Pulley menu item
                //% "Select"
                text: qsTrId("history-menu-select")
                onClicked: {
                    historyList.model.clearSelection()
                    var page = pageStack.push("SelectPage.qml", { model: historyList.model })
                    page.copySelected.connect(function() {
                        pageStack.pop()
                        var values = historyList.model.selectedValues("value")
                        var n = values.length
                        if (n > 0) {
                            var concat = ""
                            for (var i = 0; i < n; i++) {
                                if (i > 0) concat += "\n"
                                concat += values[i]
                            }
                            Clipboard.text = concat
                            clipboardNotification.previewBody = (n === 1) ?
                                //: Notification text (single code selected)
                                //% "Selected code copied to clipboard"
                                qsTrId("history-code_copied-notification") :
                                //: Notification text (multiple codes selected)
                                //% "Selected codes copied to clipboard"
                                qsTrId("history-codes_copied-notification")
                            clipboardNotification.publish()
                        }
                    })
                    page.deleteSelected.connect(function() {
                        pageStack.pop()
                        var n = historyList.model.selectionCount
                        if (n > 0) {
                            remorsePopup.execute((n === 1) ?
                                //: Remorse popup text (single code selected)
                                //% "Deleting selected code"
                                qsTrId("history-remorse-deleting_selected_code") :
                                //: Remorse popup text (multiple codes selected)
                                //% "Deleting selected codes"
                                qsTrId("history-remorse-deleting_selected_codes"), function() {
                                HistoryModel.removeMany(historyList.model.selectedValues("id"))
                            })
                        }
                    })
                }
            }
        }

        RemorsePopup {
            id: remorsePopup
        }

        ViewPlaceholder {
            enabled: !HistoryModel.count
            text: HistoryModel.isEmpty ?
                //: Placeholder text
                //% "The history is empty"
                qsTrId("history-empty") :
                //: Placeholder text
                //% "The search text is not found"
                qsTrId("history-nothing_found")
        }

        Column {
            id: content

            width: parent.width

            SearchHeader {
                id: header

                width: parent.width
                badgeText: (HistoryModel.count && !searchText.length) ? HistoryModel.count : ""
                searchVisible: !HistoryModel.isEmpty

                //: History page title
                //% "History"
                title: qsTrId("history-title")

                onSearchTextChanged: HistoryModel.filterString = searchText
            }

            ListView {
                id: historyList

                width: parent.width
                height: contentHeight
                interactive: false
                model: HarbourSelectionListModel { sourceModel: HistoryModel }

                delegate: HistoryItem {
                    id: delegate

                    value: Theme.highlightText(model.value, header.searchText, Theme.highlightColor)
                    timestamp: model.timestamp
                    format: model.format
                    enabled: !model.selected || !remorsePopup.visible
                    opacity: enabled ? 1 : 0.2

                    readonly property int modelIndex: index

                    function deleteItem() {
                        //: Remorse popup text
                        //% "Deleting"
                        remorseAction(qsTrId("history-menu-delete_remorse"), function() {
                            HistoryModel.removeAt(modelIndex)
                        })
                    }

                    onClicked: {
                        var list = historyList
                        var stack = pageStack
                        var codePage = stack.push("CodePage.qml", {
                            model: historyList.model,
                            currentIndex: model.index
                        })
                        codePage.deleteItemAt.connect(function(index) {
                            list.positionViewAtIndex(index, ListView.Visible)
                            list.currentIndex = index
                            stack.pop()
                            list.currentItem.deleteItem()
                        })
                        codePage.requestIndex.connect(function(index) {
                            list.positionViewAtIndex(index, ListView.Visible)
                        })
                    }

                    ListView.onRemove: RemoveAnimation { target: delegate }

                    menu: Component {
                        ContextMenu {
                            container: flickable

                            onHeightChanged: {
                                // Make sure we are staying inside the screen area
                                var bottom = parent.mapToItem(flickable, x, y).y + height
                                if (bottom > flickable.height) {
                                    flickable.contentY += bottom - flickable.height
                                }
                            }

                            MenuItem {
                                //: Context menu item
                                //% "Delete"
                                text: qsTrId("history-menu-delete")
                                onClicked: delegate.deleteItem()
                            }
                            MenuItem {
                                //: Context menu item
                                //% "Copy to clipboard"
                                text: qsTrId("history-menu-copy")
                                onClicked: Clipboard.text = HistoryModel.getValue(delegate.modelIndex)
                            }
                        }
                    }
                }
            }
        }

        VerticalScrollDecorator { }
    }
}
