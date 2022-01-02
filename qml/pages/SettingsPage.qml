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

Page {
    id: settingsPage

    allowedOrientations: window.allowedOrientations

    readonly property bool landscapeLayout: (width > height && Screen.sizeCategory > Screen.Small) || Screen.sizeCategory > Screen.Medium

    readonly property var colors: [
        "#FF0080", "#FF0000", "#FF8000", "#FFFF00",
        "#00FF00", "#8000FF", "#00FFFF", "#0000FF"
    ]

    property int currentColor: getColorFromSettings()


    function getColorFromSettings() {
        var savedColor = AppSettings.markerColor
        for	(var i = 0; i < colors.length; i++) {
            if (savedColor === colors[i]) {
                return i
            }
        }
        return 0
    }

    function applyOrientation() {
        var item = orientationComboBox.currentItem
        if (item) {
            AppSettings.orientation = orientationInvertSwitch.checked ? item.invertable : item.primary
        }
    }

    function updateOrientation() {
        var value = AppSettings.orientation
        var n = orientationMenu.children.length
        for (var i = 0; i < n; i++) {
            var item = orientationMenu.children[i]
            if (item.isMenuItem && (value === item.primary || value === item.invertable)) {
                orientationComboBox.currentIndex = item.index
                orientationInvertSwitch.enabled = (item.primary !== item.invertable)
                if (orientationInvertSwitch.enabled) {
                    orientationInvertSwitch.checked = (value === item.invertable)
                } else {
                    orientationInvertSwitch.checked = item.canInvert
                }
                return
            }
        }
        orientationComboBox.currentIndex = orientationMenu.defaultIndex
        orientationInvertSwitch.checked = false
        orientationInvertSwitch.enabled = false
    }

    Component.onCompleted: updateOrientation()

    Connections {
        target: AppSettings
        onOrientationChanged: settingsPage.updateOrientation()
    }

    Loader {
        id: buzzLoader

        active: AppSettings.buzzOnScan
        source: "../components/Buzz.qml"
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width

            //: Setting page title and menu item
            //% "Settings"
            PageHeader { title: qsTrId("settings-title") }

            //: Section header
            //% "Barcode formats"
            SectionHeader { text: qsTrId("settings-formats-section") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x*2
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                //: Section description
                //% "Disabling the formats that you don't need speeds up the decoding and reduces the risk of incorrect recognition of the barcode type."
                text: qsTrId("settings-formats-description")
            }

            Grid {
                id: formatsGrid

                width: parent.width
                columns: landscapeLayout ? 4 : 2

                readonly property real columnWidth: Math.floor(width/columns)
                readonly property int portraitColumns: Math.max(1, Math.min(2, width/Theme.itemSizeHuge))
                readonly property int landscapeColumns: Math.max(2, Math.min(4, width/Theme.itemSizeHuge))

                Repeater {
                    model: BarcodeFormatModel { hints: AppSettings.decodingHints }
                    delegate: TextSwitch {
                        text: model.name
                        width: formatsGrid.columnWidth
                        automaticCheck: false
                        checked: model.enabled
                        onClicked: {
                            if (checked) {
                                AppSettings.clearDecodingHint(model.hint)
                            } else {
                                AppSettings.setDecodingHint(model.hint)
                            }
                        }
                    }
                }
            }

            //: Section header
            //% "Display"
            SectionHeader { text: qsTrId("settings-display-section") }

            Grid {
                width: parent.width
                columns: landscapeLayout ? 2 : 1

                readonly property real columnWidth: width/columns

                ComboBox {
                    id: orientationComboBox

                    //: Combo box label
                    //% "Orientation"
                    label: qsTrId("settings-display-orientation-label")
                    width: parent.columnWidth
                    value: currentItem ? currentItem.text : ""
                    menu: ContextMenu {
                        id: orientationMenu

                        readonly property int defaultIndex: 0
                        x: 0
                        width: orientationComboBox.width
                        MenuItem {
                            //: Combo box value for primary orientation
                            //% "Primary"
                            text: qsTrId("settings-display-orientation-primary")
                            readonly property int index: 0
                            readonly property int primary: Settings.OrientationPrimary
                            readonly property int invertable: primary
                            readonly property bool canInvert: false
                            readonly property bool isMenuItem: true
                        }
                        MenuItem {
                            //: Combo box value for portrait orientation
                            //% "Portrait"
                            text: qsTrId("settings-display-orientation-portrait")
                            readonly property int index: 1
                            readonly property int primary: Settings.OrientationPortrait
                            readonly property int invertable: Settings.OrientationPortraitAny
                            readonly property bool canInvert: true
                            readonly property bool isMenuItem: true
                        }
                        MenuItem {
                            //: Combo box value for landscape orientation
                            //% "Landscape"
                            text: qsTrId("settings-display-orientation-landscape")
                            readonly property int index: 2
                            readonly property int primary: Settings.OrientationLandscape
                            readonly property int invertable: Settings.OrientationLandscapeAny
                            readonly property bool canInvert: true
                            readonly property bool isMenuItem: true
                        }
                        MenuItem {
                            //: Combo box value for dynamic orientation
                            //% "Dynamic"
                            text: qsTrId("settings-display-orientation-dynamic")
                            readonly property int index: 3
                            readonly property int primary: Settings.OrientationAny
                            readonly property int invertable: primary
                            readonly property bool canInvert: true
                            readonly property bool isMenuItem: true
                        }
                        onActivated: {
                            orientationComboBox.currentIndex = index
                            settingsPage.applyOrientation()
                        }
                    }
                }

                TextSwitch {
                    id: orientationInvertSwitch

                    //: Text switch label
                    //% "Allow inverted orientation"
                    text: qsTrId("settings-display-orientation-allow_inverted")
                    //: Text switch description
                    //% "If enabled, allows both primary and inverted landscape or portrait orientation."
                    description: qsTrId("settings-display-orientation-allow_inverted-description")
                    width: parent.columnWidth
                    onClicked: settingsPage.applyOrientation()
                }
            }

            //: Section header
            //% "Scan"
            SectionHeader { text: qsTrId("settings-scan-section") }

            Grid {
                width: parent.width
                columns: landscapeLayout ? 2 : 1

                readonly property real columnWidth: width/columns

                IconTextSwitch {
                    checked: AppSettings.sound
                    //: Switch button text
                    //% "Detection sound"
                    text: qsTrId("settings-sound-label")
                    icon.source: landscapeLayout ? "" : "image://theme/icon-m-speaker"
                    width: parent.columnWidth
                    automaticCheck: false
                    onClicked: AppSettings.sound = !checked
                }

                IconTextSwitch {
                    checked: AppSettings.buzzOnScan
                    //: Switch button text
                    //% "Vibrate on detection"
                    text: qsTrId("settings-vibration-label")
                    icon.source: landscapeLayout ? "" : "image://theme/icon-m-vibration"
                    width: parent.columnWidth
                    automaticCheck: false
                    onClicked: {
                        AppSettings.buzzOnScan = !checked
                        if (buzzLoader.item) {
                            buzzLoader.item.start()
                        }
                    }
                }

                IconTextSwitch {
                    checked: AppSettings.scanOnStart
                    //: Switch button text
                    //% "Scan on start"
                    text: qsTrId("settings-autoscan-label")
                    icon.source: landscapeLayout ? "" : "image://theme/icon-m-play"
                    width: parent.columnWidth
                    automaticCheck: false
                    onClicked: AppSettings.scanOnStart = !checked
                }

                IconTextSwitch {
                    checked: AppSettings.volumeZoom
                    //: Switch button text
                    //% "Zoom with volume keys"
                    text: qsTrId("settings-volume_zoom-label")
                    icon.source: landscapeLayout ? "" : "image://theme/icon-m-transfer"
                    width: parent.columnWidth
                    automaticCheck: false
                    onClicked: AppSettings.volumeZoom = !checked
                }
            }

            IconTextSwitch {
                id: saveImagesSwitch

                checked: AppSettings.saveImages
                //: Switch button text
                //% "Save barcode images"
                text: qsTrId("settings-save_images-label")
                icon.source: landscapeLayout ? "" : "image://theme/icon-m-camera"
                width: parent.width
                automaticCheck: false
                busy: picturesConfirmButtons.visible
                onClicked: {
                    if (checked) {
                        if (picturesConfirmButtons.visible) {
                            // Cancel the previous click
                            picturesConfirmButtons.visible = false
                            description = ""
                        } else if (HistoryModel.hasImages) {
                            //: Switch button description (explanation)
                            //% "This will delete all previously saved barcode images."
                            description = qsTrId("settings-save_images-description")
                            picturesConfirmButtons.visible = true
                        } else {
                            // No need to confirm
                            AppSettings.saveImages = false
                        }
                    } else {
                        AppSettings.saveImages = true
                    }
                }
                onCheckedChanged: {
                    picturesConfirmButtons.visible = false
                    description = ""
                }
            }

            Row {
                id: picturesConfirmButtons

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                spacing: Theme.paddingMedium
                visible: false

                Button {
                    width: Math.round((parent.width - parent.spacing) / 2)
                    //: Button label (confirm deletion of image files)
                    //% "Confirm delete"
                    text: qsTrId("settings-save_images-confirm_delete")
                    onClicked: AppSettings.saveImages = false
                }

                Button {
                    width: Math.round((parent.width - parent.spacing) / 2)
                    //: Button label
                    //% "Cancel"
                    text: qsTrId("settings-history-cancel")
                    onClicked: {
                        saveImagesSwitch.description = ""
                        picturesConfirmButtons.visible = false
                    }
                }
            }

            //: Section header
            //% "History"
            SectionHeader { text: qsTrId("settings-history-section") }

            Slider {
                id: historySizeSlider

                readonly property int currentCount: HistoryModel.count

                width: parent.width
                minimumValue: 0
                maximumValue: 200
                value: AppSettings.historySize
                stepSize: 10
                //: Slider label
                //% "Max history size (saved values: %1)"
                label: qsTrId("settings-history-slider_label").arg(currentCount)
                valueText: value === 0 ?
                    //: Generic slider value
                    //% "deactivated"
                    qsTrId("settings-value-deactivated") :
                    //: History slider value
                    //% "%1 item(s)"
                    qsTrId("settings-history-slider_value",value).arg(value)
                onSliderValueChanged: {
                    if (value < currentCount) {
                        historyConfirmButtons.visible = true
                    } else {
                        historyConfirmButtons.visible = false
                        AppSettings.historySize = value
                    }
                }
            }

            Row {
                id: historyConfirmButtons

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                spacing: Theme.paddingMedium
                visible: false

                Button {
                    width: Math.round((parent.width - parent.spacing) / 2)
                    //: Button label
                    //% "Confirm resize"
                    text: qsTrId("settings-history-confirm_resize")
                    onClicked: {
                        AppSettings.historySize = historySizeSlider.value
                        historyConfirmButtons.visible = false
                    }
                }

                Button {
                    width: Math.round((parent.width - parent.spacing) / 2)
                    //: Button label
                    //% "Cancel"
                    text: qsTrId("settings-history-cancel")
                    onClicked: {
                        historySizeSlider.value = AppSettings.historySize
                        historyConfirmButtons.visible = false
                    }
                }
            }

            //: Section header
            //% "Marker"
            SectionHeader { text: qsTrId("settings-marker-section") }

            Grid {
                id: colorSelector

                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                columns: settingsPage.isPortrait ? 4 : 8

                Repeater {
                    model: colors

                    Item {
                        width: parent.width/colorSelector.columns
                        height: parent.width/colorSelector.columns

                        Rectangle {
                            property real adjustment: (index == currentColor) ? 0 :
                                colorSelectorBackground.down ? (2 * Theme.paddingMedium) :
                                (2 * Theme.paddingLarge)

                            width: parent.width - adjustment
                            height: parent.height - adjustment
                            radius: Theme.paddingLarge
                            color: colors[index]
                            anchors.centerIn: parent

                            Behavior on adjustment { SmoothedAnimation { duration: 100 } }
                        }

                        MouseArea {
                            id: colorSelectorBackground

                            readonly property bool down: pressed && containsMouse
                            anchors.fill: parent
                            onClicked: {
                                currentColor = index
                                AppSettings.markerColor = colors[index]
                            }
                        }
                    }
                }
            }

            Slider {
                width: parent.width
                minimumValue: 0
                maximumValue: 15
                value: AppSettings.resultViewDuration
                stepSize: 1
                //: Slider label
                //% "Mark detected code"
                label: qsTrId("settings-marker-slider_label")
                valueText: value === 0 ?
                    //: Generic slider value
                    //% "deactivated"
                    qsTrId("settings-value-deactivated") :
                    //: Marker slider value
                    //% "%1 second(s)"
                    qsTrId("settings-marker-slider_value",value).arg(value)
                onSliderValueChanged: AppSettings.resultViewDuration = value
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }
        }
    }
}
