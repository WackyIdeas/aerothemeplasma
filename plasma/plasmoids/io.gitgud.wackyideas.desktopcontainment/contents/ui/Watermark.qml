import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid

ColumnLayout {
    spacing: 0

    opacity: Plasmoid.configuration.watermarkVisible
    z: -1

    Item {
        id: watermarkManager

        property var watermarks
        property int count: 0

        function load() {
            watermarks = JSON.parse(Plasmoid.configuration.watermarks);
            count = watermarks.length;
        }

        Connections {
            target: Plasmoid.configuration

            function onWatermarksChanged() {
                watermarkManager.load();
            }
        }

        Component.onCompleted: load()
    }

    Repeater {
        model: watermarkManager.count
        delegate: Text {
            id: delegate

            required property int index

            Layout.fillWidth: true

            text: watermarkManager.watermarks[index].text
            font.bold: watermarkManager.watermarks[index].bold
            color: "#" + watermarkManager.watermarks[index].color
            wrapMode: Text.WordWrap
            horizontalAlignment: {
                switch(watermarkManager.watermarks[index].horizontalAlignment) {
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
}
