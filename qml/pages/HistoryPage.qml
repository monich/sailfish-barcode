/*
The MIT License (MIT)

Copyright (c) 2014 Steffen Förster
Copyright (c) 2018-2020 Slava Monich

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
import "../harbour"

Page {
    id: historyPage

    allowedOrientations: window.allowedOrientations

    property int myStackDepth

    readonly property bool empty: HistoryModel.count === 0

    onStatusChanged: {
        if (status === PageStatus.Active) {
            myStackDepth = pageStack.depth
        } else if (status === PageStatus.Inactive) {
            // We also end up here after TextPage gets pushed
            if (pageStack.depth < myStackDepth) {
                // It's us getting popped
                HistoryModel.commitChanges()
            }
        }
    }

    onIsPortraitChanged: historyList.positionViewAtIndex(historyList.currentIndex, ListView.Visible)

    Notification {
        id: clipboardNotification

        expireTimeout: 2000
        Component.onCompleted: {
            if ("icon" in clipboardNotification) {
                clipboardNotification.icon = "icon-s-clipboard"
            }
        }
    }

    SilicaListView {
        id: historyList

        anchors.fill: parent

        header: PageHeader {
            id: header

            //: History page title
            //% "History"
            title: qsTrId("history-title")

            HarbourBadge {
                id: badge
                anchors {
                    right: header.extraContent.right
                    rightMargin: Theme.paddingLarge
                    verticalCenter: header.extraContent.verticalCenter
                }
                maxWidth: header.extraContent.width - anchors.rightMargin
                text: HistoryModel.count ? HistoryModel.count : ""
            }
        }

        model: HarbourSelectionListModel { sourceModel: HistoryModel }

        delegate: HistoryItem {
            id: delegate

            value: model.value
            timestamp: model.timestamp
            format: model.format
            enabled: !model.selected || !remorsePopup.visible
            opacity: enabled ? 1 : 0.2

            readonly property int modelIndex: index

            function deleteItem() {
                var item = delegate
                var remorse = remorseComponent.createObject(null)
                remorse.z = delegate.z + 1
                //: Remorse popup text
                //% "Deleting"
                remorse.execute(delegate, qsTrId("history-menu-delete_remorse"),
                    function() {
                        HistoryModel.remove(item.modelIndex)
                        remorse.destroy()
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
                    id: contextMenu

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

        PullDownMenu {
            visible: !historyPage.empty
            MenuItem {
                //: Pulley menu item
                //% "Clear"
                text: qsTrId("history-menu-clear")
                onClicked: {
                    //: Remorse popup text
                    //% "Deleting all codes"
                    remorsePopup.execute(qsTrId("history-remorse-deleting_all"),
                        function() { HistoryModel.removeAll() })
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
                        var n = historyList.model.selectionCount
                        if (n > 0) {
                            Clipboard.text = HistoryModel.concatenateCodes(historyList.model.selectedRows, '\n')
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
                                HistoryModel.removeMany(historyList.model.selectedRows)
                            })
                        }
                    })
                }
            }
        }

        Component {
            id: remorseComponent

            RemorseItem { }
        }

        RemorsePopup {
            id: remorsePopup
        }

        VerticalScrollDecorator { }

        ViewPlaceholder {
            id: placeHolder

            enabled: historyPage.empty
            //: Placeholder text
            //% "History is empty"
            text: qsTrId("history-empty")
        }
    }
}
