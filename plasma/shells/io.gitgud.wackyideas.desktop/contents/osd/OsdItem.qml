/*
    SPDX-FileCopyrightText: 2014 Martin Klapetek <mklapetek@kde.org>
    SPDX-FileCopyrightText: 2019 Kai Uwe Broulik <kde@broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

import Qt5Compat.GraphicalEffects

RowLayout {
    id: root

    // OSD Timeout in msecs - how long it will stay on the screen
    property int timeout: 1800
    // This is either a text or a number, if showingProgress is set to true,
    // the number will be used as a value for the progress bar
    property var osdValue
    // Maximum percent value
    property int osdMaxValue: 100
    // Icon name to display
    property string icon
    // Set to true if the value is meant for progress bar,
    // false for displaying the value as normal text
    property bool showingProgress: false

    function formatPercent(number) {
        return i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Percentage value", "%1%", number);
    }

    spacing: Kirigami.Units.largeSpacing

    Layout.preferredWidth: Math.max(Math.min(Screen.desktopAvailableWidth / 2, implicitWidth), Kirigami.Units.gridUnit * 15)
    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
    Layout.minimumWidth: Layout.preferredWidth
    Layout.minimumHeight: Layout.preferredHeight
    Layout.maximumWidth: Layout.preferredWidth
    Layout.maximumHeight: Layout.preferredHeight
    width: Layout.preferredWidth
    height: Layout.preferredHeight

    Kirigami.Icon {
        id: iconItem
        Layout.leftMargin: Kirigami.Units.smallSpacing // Left end spacing
        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
        Layout.alignment: Qt.AlignVCenter
        source: root.icon
        visible: valid
    }

    PlasmaComponents3.ProgressBar {
        id: progressBar
        Layout.leftMargin: iconItem.valid ? 0 : Kirigami.Units.smallSpacing // Left end spacing
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        // So it never exceeds the minimum popup size
        Layout.minimumWidth: 0
        Layout.rightMargin: Kirigami.Units.smallSpacing
        visible: root.showingProgress
        from: 0
        to: root.osdMaxValue
        value: Number(root.osdValue)
    }

    // Get the width of a three-digit number so we can size the label
    // to the maximum width to avoid the progress bad resizing itself
    TextMetrics {
        id: widestLabelSize
        text: formatPercent(root.osdMaxValue)
        font: percentageLabel.font
    }

    // Numerical display of progress bar value
    Item {

        visible: root.showingProgress
        Layout.rightMargin: Kirigami.Units.smallSpacing // Right end spacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2 // Right end spacing
        Layout.fillHeight: true
        Layout.preferredWidth: Math.ceil(widestLabelSize.advanceWidth)
        Layout.alignment: Qt.AlignVCenter
    PlasmaExtras.Heading {
        id: percentageLabel
        level: 3
        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: formatPercent(progressBar.value)
        textFormat: Text.PlainText
        wrapMode: Text.NoWrap
        //font.family: "Segoe UI Light"

        renderType: Text.NativeRendering
        font.hintingPreference: Font.PreferFullHinting
        font.kerning: false

        //color: "black"
        // Display a subtle visual indication that the volume might be
        // dangerously high
        // ------------------------------------------------
        // Keep this in sync with the copies in plasma-pa:ListItemBase.qml
        // and plasma-pa:VolumeSlider.qml
        color: {
            if (progressBar.value <= 100) {
                return "black"
            } else {
                return Qt.darker(Kirigami.Theme.negativeTextColor, 1.5);
            }
        }
    }

    Glow {
        anchors.fill: percentageLabel
        radius: 15
        samples: 31
        color: "#77ffffff"
        spread: 0.60
        source: percentageLabel
        cached: true
        visible: percentageLabel.visible
    }
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: iconItem.valid ? 0 : Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2 // Right end spacing
        Layout.alignment: Qt.AlignVCenter
        visible: !root.showingProgress
        PlasmaExtras.Heading {
            id: headingText
            anchors.fill: parent
            level: 3
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            text: !root.showingProgress && root.osdValue ? root.osdValue : ""
            //font.family: "Segoe UI Light"
            renderType: Text.NativeRendering
            font.hintingPreference: Font.PreferFullHinting
            font.kerning: false
            color: "black"
        }
        Glow {
            anchors.fill: headingText
            radius: 15
            samples: 31
            color: "#77ffffff"
            spread: 0.60
            source: headingText
            cached: true
            visible: headingText.visible
        }
    }


}
