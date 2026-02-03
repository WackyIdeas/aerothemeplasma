/*
    SPDX-FileCopyrightText: 2018 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components as PlasmaComponents3
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import QtQuick.Effects

// This top-level item is an opaque background that goes behind the colored
// background, for contrast. It's not an Item since that it would be square,
// and not round, as required here
KSvg.SvgItem {
    id: badgeRect

    property int number: 0
    property color badgeColor: "black"

    implicitWidth: Kirigami.Units.iconSizes.small//Math.max(height, Math.round(label.contentWidth)) // Add some padding around.
    implicitHeight: Kirigami.Units.iconSizes.small//implicitWidth

    svg: badgeRing
    elementId: "ring"

    KSvg.SvgItem {
        id: badgeGradient
        svg: badgeRing
        elementId: "gradient"
        z: -1
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: badgeRect.badgeColor
            brightness: {
                if(badgeRect.badgeColor.hslLightness < 0.5) return 0.75;
                if(badgeRect.badgeColor.hslLightness > 0.7) { return 0.15; }
                return 0.25
            }
        }
    }

    // Number
    PlasmaComponents3.Label {
        id: label
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        width: height
        height: Math.min(Kirigami.Units.gridUnit * 2, Math.round(parent.height)-2)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.VerticalFit
        font.pointSize: 1024
        font.letterSpacing: -1
        minimumPointSize: 5
        text: {
            if (badgeRect.number < 0) {
                return i18nc("Invalid number of new messages, overlay, keep short", "—");
            } else if (badgeRect.number > 9) {
                return i18nc("Over 9 new messages, overlay, keep short", "9+");
            } else {
                return badgeRect.number.toLocaleString(Qt.locale(), 'f', 0);
            }
        }
        textFormat: Text.PlainText
    }
}
