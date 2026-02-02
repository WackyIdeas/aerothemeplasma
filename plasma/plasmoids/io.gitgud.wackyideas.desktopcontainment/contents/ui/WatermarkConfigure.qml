import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

Window {
    id: root

    property string purpose
    property int index

    property string text: "New watermark"
    property bool bold: false
    property string color: "FFFFFF"
    property int horizontalAlignment: 2

    signal done(int index, string text, bool bold, string color, int horizontalAlignment)
    onDone: destroy();

    minimumWidth: width
    minimumHeight: height
    width: 418
    height: column.height < 1 ? 1 : column.height
    maximumWidth: width
    maximumHeight: height

    title: i18n("Desktop")

    FontMetrics { id: systemFont; font: color.font }

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right

        spacing: 0

        Rectangle {
            id: topContents

            Layout.preferredWidth: parent.width
            Layout.preferredHeight: row.implicitHeight + 24

            color: "white"

            RowLayout {
                id: row

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12

                spacing: 8

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignTop

                    implicitWidth: 32
                    implicitHeight: 32

                    source: "plasma"
                }

                ColumnLayout {
                    Text {
                        Layout.fillWidth: true

                        text: root.purpose == "new" ? i18n("Create a new watermark") : i18n("Modify an existing watermark")
                        color: "#003399"
                        font.pointSize: 11
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text { Layout.fillWidth: true; text: i18n("Text:") }

                        QQC2.TextField { id: text; Layout.fillWidth: true; text: root.text }
                    }

                    QQC2.CheckBox {
                        id: bold

                        text: i18n("Use bold text")
                        checked: root.bold
                    }

                    RowLayout {
                        Text {
                            Layout.fillWidth: true

                            text: i18n("Color (HEX):")
                        }

                        Text {
                            text: "#"
                        }
                        QQC2.TextField {
                            id: color

                            Layout.minimumWidth: Math.round(systemFont.maximumCharacterWidth)*6
                            Layout.maximumWidth: Math.round(systemFont.maximumCharacterWidth)*6

                            validator: RegularExpressionValidator { regularExpression: /[0-9A-Fa-f]+/ }
                            maximumLength: 6
                            text: root.color
                            color: "black"
                        }
                    }

                    RowLayout {
                        Text {
                            Layout.fillWidth: true

                            text: i18n("Horizontal alignment:")
                        }

                        QQC2.ComboBox {
                            id: horizontalAlignment

                            currentIndex: root.horizontalAlignment
                            model: [
                                "Left",
                                "Center",
                                "Right"
                            ]
                        }
                    }
                }
            }
        }

        Rectangle { Layout.preferredWidth: parent.width; Layout.preferredHeight: 1; color: "#dfdfdf" }

        Rectangle {
            Layout.preferredWidth: parent.width
            Layout.preferredHeight: 40

            color: "#f0f0f0"

            RowLayout {
                anchors.fill: parent
                anchors.rightMargin: 11

                spacing: 8

                Item { Layout.fillWidth: true }

                QQC2.Button {
                    text: i18n("OK")
                    onClicked: root.done(root.index, text.text, bold.checked, color.text, horizontalAlignment.currentIndex);
                }
                QQC2.Button {
                    text: i18n("Cancel")
                    onClicked: root.destroy();
                }
            }
        }
    }
}
