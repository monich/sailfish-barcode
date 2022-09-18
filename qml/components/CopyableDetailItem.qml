import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: thisItem

    contentHeight: detailItem.height
    height: contentHeight + (copyMenu ? copyMenu.height : 0)
    width: parent.width

    property alias label: detailItem.label
    property alias value: detailItem.value
    property alias leftMargin: detailItem.leftMargin

    menu: ContextMenu {
        id: copyMenu

        x: detailItem.width/2
        width: detailItem.width/2

        MenuItem {
            //: Context menu item
            //% "Copy to clipboard"
            text: qsTrId("history-menu-copy")
            onClicked: Clipboard.text = detailItem.value
        }
    }

    DetailItem {
        id: detailItem
    }
}
