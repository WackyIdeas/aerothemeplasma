/*
 * SPDX-FileCopyrightText: 2018 Friedrich W. H. Kossebau <kossebau@kde.org>
 * SPDX-FileCopyrightText: 2022 Ismael Asensio <isma.af@gmail.com>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.kcmutils as KCM

Item {
    id: root

    property var cfg_watermarks
    property alias cfg_watermarkVisible: watermarkVisible.checked

    property Window watermarkConfigure: null

    component CustomGroupBox: GroupBox {
        id: gbox
        label: Label {
            id: lbl
            x: gbox.leftPadding + 2
            y: lbl.implicitHeight/2-gbox.bottomPadding-1
            width: lbl.implicitWidth
            text: gbox.title
            elide: Text.ElideRight
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -2
                anchors.rightMargin: -2
                color: "white"
                z: -1
            }
        }
        background: Rectangle {
            y: gbox.topPadding - gbox.bottomPadding*2
            width: parent.width
            height: parent.height - gbox.topPadding + gbox.bottomPadding*2
            color: "transparent"
            border.color: "#d5dfe5"
            radius: 3
        }
    }

    ListModel {
        id: presets

        ListElement { text: "Windows 10" }
        ListElement { text: "Windows 8.1" }
        ListElement { text: "Windows 8" }
        ListElement { text: "Windows 7" }
        ListElement { text: "Windows Vista" }
        ListElement { text: "AeroThemePlasma" }
    }

    Item {
        id: watermarkManager

        property var watermarks
        property int count: 0

        function setWatermark(index: int, text: string, bold: bool, color: string, horizontalAlignment: int) {
            watermarks[index].text = text;
            watermarks[index].bold = bold;
            watermarks[index].color = color;
            watermarks[index].horizontalAlignment = horizontalAlignment;
            save();
        }

        function addWatermark(index: int, text: string, bold: bool, color: string, horizontalAlignment: int) {
            var watermark = {
                "text":text,
                "bold":bold,
                "color":color,
                "horizontalAlignment":horizontalAlignment
            };
            watermarks.push(watermark);
            repeater_watermarks.selected_delegate = watermarks.length - 1;
            save();
        }

        function deleteWatermark(index: int) {
            watermarks.splice(index, 1);
            repeater_watermarks.selected_delegate--;
            repeater_watermarks.selected_delegate--;
            save();
        }

        function moveUp(index: int) {
            if(index !== 0) {
                var object = watermarks[index];

                watermarks.splice(index, 1);
                watermarks.splice(index-1, 0, object);
            }

            save();
        }

        function newWatermark() {
            var component = Qt.createComponent("WatermarkConfigure.qml");

            watermarkConfigure = component.createObject(root, { purpose: "new" });
            watermarkConfigure.done.connect(watermarkManager.addWatermark);
            watermarkConfigure.show();
        }

        function modify(index: int) {
            var watermark = watermarkManager.watermarks[repeater_watermarks.selected_delegate];
            var component = Qt.createComponent("WatermarkConfigure.qml");

            watermarkConfigure = component.createObject(root, {
                index: repeater_watermarks.selected_delegate,
                purpose: "modify",
                text: watermark.text,
                bold: watermark.bold,
                color: watermark.color,
                horizontalAlignment: watermark.horizontalAlignment
            });
            watermarkConfigure.done.connect(watermarkManager.setWatermark);
            watermarkConfigure.show();
        }

        function moveDown(index: int) {
            if(index < count) {
                var object = watermarks[index];

                watermarks.splice(index, 1);
                watermarks.splice(index+1, 0, object);
            }

            save();
        }

        function remove(index: int) {
            watermarks.splice(index, 1);
            repeater_watermarks.selected_delegate--;
            save();
        }

        function clear() {
            watermarks.splice(0, count);
            save();
        }

        function save() {
            repeater_watermarks.model = null;
            root.cfg_watermarks = JSON.stringify(watermarks);
            count = watermarks.length;
            repeater_watermarks.model = count;
        }

        function loadPreset(preset: int) {
            clear();
            switch(preset) {
                case 0: {
                    addWatermark(0, "Windows 10", false, "FFFFFF", 2);
                    addWatermark(0, "Build 22H2", false, "FFFFFF", 2);
                    break;
                }
                case 1: {
                    addWatermark(0, "Windows 8.1", false, "FFFFFF", 2);
                    addWatermark(0, "Build 9600", false, "FFFFFF", 2);
                    break;
                }
                case 2: {
                    addWatermark(0, "Windows 8", false, "FFFFFF", 2);
                    addWatermark(0, "Build 9200", false, "FFFFFF", 2);
                    break;
                }
                case 3: {
                    addWatermark(0, "Windows 7", false, "FFFFFF", 2);
                    addWatermark(0, "Build 7601", false, "FFFFFF", 2);
                    break;
                }
                case 4: {
                    addWatermark(0, "Windows Vista(TM)", false, "FFFFFF", 2);
                    addWatermark(0, "Build 6003", false, "FFFFFF", 2);
                    break;
                }
                case 5: {
                    addWatermark(0, "AeroThemePlasma", false, "FFFFFF", 2);
                    addWatermark(0, "Build 6.5.0", false, "FFFFFF", 2);
                    break;
                }
            }
        }


        Component.onCompleted: {
            watermarks = JSON.parse(Plasmoid.configuration.watermarks);
            count = watermarks.length;
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Kirigami.Units.gridUnit*4
        anchors.rightMargin: Kirigami.Units.gridUnit*4

        CheckBox {
            id: watermarkVisible
            text: i18n("Enabled")
        }

        CustomGroupBox {
            Layout.fillWidth: true

            title: i18n("Presets")
            enabled: watermarkVisible.checked

            RowLayout {
                anchors.fill: parent

                Button {
                    Layout.alignment: Qt.AlignTop

                    text: i18n("Load")
                    onClicked: {
                        watermarkManager.loadPreset(repeater_presets.selected_delegate)
                        repeater_presets.selected_delegate = -1
                    }
                    enabled: repeater_presets.selected_delegate !== -1 && watermarkVisible.checked
                }

                Item {
                    Layout.alignment: Qt.AlignTop

                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 1
                    Layout.minimumHeight: 22
                    Layout.preferredHeight: list_presets.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1

                        border.width: 1
                        border.color: "lightgray"
                    }

                    ColumnLayout {
                        id: list_presets

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top

                        spacing: 0

                        Repeater {
                            id: repeater_presets

                            property int selected_delegate: -1

                            model: presets
                            delegate: Item {
                                id: delegate

                                required property var model
                                required property int index

                                property bool selected: repeater_presets.selected_delegate == index
                                property bool hovered: ma.containsMouse

                                Layout.fillWidth: true
                                Layout.preferredHeight: 22

                                enabled: watermarkVisible.checked
                                opacity: enabled ? 1.0 : 0.5

                                Rectangle {
                                    anchors.fill: parent

                                    color: "#3399FF"

                                    visible: (delegate.hovered || delegate.selected) && delegate.enabled
                                    opacity: delegate.selected ? 1.0 : 0.5
                                }

                                Text {
                                    anchors.fill: parent

                                    verticalAlignment: Text.AlignVCenter
                                    text: model.text
                                    leftPadding: 3
                                    rightPadding: 3
                                }

                                MouseArea {
                                    id: ma

                                    anchors.fill: parent

                                    hoverEnabled: true
                                    enabled: delegate.enabled
                                    onPressed: repeater_presets.selected_delegate = delegate.index;
                                    onDoubleClicked: {
                                        watermarkManager.loadPreset(model.index);
                                        repeater_presets.selected_delegate = -1;
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }

        CustomGroupBox {
            Layout.fillWidth: true

            title: i18n("Watermarks")
            enabled: watermarkVisible.checked

            RowLayout {
                anchors.fill: parent

                ColumnLayout {
                    id: control_column

                    Layout.alignment: Qt.AlignTop

                    uniformCellSizes: true
                    spacing: 4

                    Button {
                        Layout.fillWidth: true

                        text: i18n("New")
                        onClicked: watermarkManager.newWatermark();
                        enabled: watermarkVisible.checked
                    }

                    Button {
                        Layout.fillWidth: true

                        text: i18n("Clear")
                        onClicked: watermarkManager.clear();
                        enabled: watermarkVisible.checked
                    }

                    Item {  }

                    Button {
                        Layout.fillWidth: true

                        text: i18n("Remove")
                        onClicked: watermarkManager.remove(repeater_watermarks.selected_delegate)
                        enabled: repeater_watermarks.selected_delegate !== -1 && watermarkVisible.checked
                    }

                    Button {
                        Layout.fillWidth: true

                        text: i18n("Modify")
                        onClicked: watermarkManager.modify(repeater_watermarks.selected_delegate)
                        enabled: repeater_watermarks.selected_delegate !== -1 && watermarkVisible.checked
                    }

                    Button {
                        Layout.fillWidth: true

                        text: i18n("Up")
                        onClicked: {
                            watermarkManager.moveUp(repeater_watermarks.selected_delegate);
                            repeater_watermarks.selected_delegate--;
                        }
                        enabled: repeater_watermarks.selected_delegate !== -1 && watermarkVisible.checked
                    }
                    Button {
                        Layout.fillWidth: true

                        text: i18n("Down")
                        onClicked: {
                            watermarkManager.moveDown(repeater_watermarks.selected_delegate);
                            repeater_watermarks.selected_delegate++;
                        }
                        enabled: repeater_watermarks.selected_delegate !== -1 && watermarkVisible.checked
                    }
                }

                Item {
                    Layout.alignment: Qt.AlignTop

                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 1
                    Layout.preferredHeight: control_column.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1

                        border.width: 1
                        border.color: "lightgray"
                    }

                    ScrollView {
                        anchors.fill: parent

                        ColumnLayout {
                            id: list_watermarks

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top

                            spacing: 0

                            Repeater {
                                id: repeater_watermarks

                                property int selected_delegate: -1

                                model: watermarkManager.count
                                delegate: Item {
                                    id: delegate

                                    required property int index

                                    property bool selected: repeater_watermarks.selected_delegate == index
                                    property bool hovered: ma.containsMouse

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 22

                                    enabled: watermarkVisible.checked
                                    opacity: enabled ? 1.0 : 0.5

                                    Rectangle {
                                        anchors.fill: parent

                                        color: "#3399FF"

                                        visible: delegate.hovered || delegate.selected
                                        opacity: delegate.selected ? 1.0 : 0.5
                                    }

                                    RowLayout {
                                        id: row

                                        anchors.fill: parent
                                        anchors.leftMargin: 3
                                        anchors.rightMargin: 3

                                        Rectangle {
                                            Layout.alignment: Qt.AlignVCenter

                                            Layout.preferredWidth: 16
                                            Layout.preferredHeight: 16

                                            color: "#" + watermarkManager.watermarks[delegate.index].color

                                            border.width: 1
                                            border.color: "gray"
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignVCenter

                                            Layout.fillWidth: true
                                            Layout.fillHeight: true

                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                            text: watermarkManager.watermarks[delegate.index].text
                                            font.bold: watermarkManager.watermarks[delegate.index].bold
                                            horizontalAlignment: {
                                                switch(watermarkManager.watermarks[delegate.index].horizontalAlignment) {
                                                    case 0:
                                                        return Text.AlignLeft;
                                                    case 1:
                                                        return Text.AlignHCenter;
                                                    case 2:
                                                        return Text.AlignRight;
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: ma

                                        anchors.fill: parent

                                        hoverEnabled: true
                                        enabled: delegate.enabled
                                        onPressed: repeater_watermarks.selected_delegate = delegate.index;
                                        onDoubleClicked: {
                                            repeater_watermarks.selected_delegate = delegate.index;
                                            watermarkManager.modify(repeater_watermarks.selected_delegate);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
