/*
    SPDX-FileCopyrightText: 2010 Marco Martin <notmart@gmail.com>
    SPDX-FileCopyrightText: 2016 Jan Grulich <jgrulich@redhat.com>
    SPDX-FileCopyrightText: 2020 George Vogiatzis <gvgeo@protonmail.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg

/**
 * Ignores the theme's listItem margins, and uses custom highlight(pressed) area.
 * Could break some themes but the majority look fine.
 * Also includes a separator to be used in sections.
 */
MouseArea {
    id: listItem

    property bool checked: false
    property bool separator: false
    property rect highlightRect: Qt.rect(0, 0, width, height)
    property alias separatorText: sepText

    width: parent.width
    opacity: separatorText.text !== i18n("Connected")

    // Sections have spacing above but not below. Will use 2 of them below.
    height: separator ? (separatorText.text === i18n("Connected") ? 0 : Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing) : parent.height
    hoverEnabled: true

    Rectangle {
        id: separatorLine
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: Kirigami.Units.smallSpacing
        }
        width: parent.width
        visible: separator
        height: 1
        color: "#b1b1b1"
    }
    Text {
        id: sepText
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.leftMargin: Kirigami.Units.largeSpacing+2
        //text: i18n("Wireless Network Connection")
        color: "#40555a"
        verticalAlignment: Text.AlignVCenter
        //leftPadding: 10

        visible: separator
    }


    KSvg.FrameSvgItem {
        id: background
        imagePath: "widgets/listitem"
        prefix: "normal"
        anchors.fill: parent
        visible: separator ? false : true
    }

}
