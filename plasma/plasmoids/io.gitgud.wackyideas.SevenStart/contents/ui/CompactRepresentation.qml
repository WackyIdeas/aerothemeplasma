/***************************************************************************
 *   Copyright (C) 2013-2014 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kwindowsystem 1.0

import org.kde.kirigami as Kirigami

Item {
    id: root

    Layout.minimumHeight: floatingOrbPanel.scaledHeight / 3;
    Layout.maximumHeight: floatingOrbPanel.scaledHeight / 3;
    Layout.minimumWidth: floatingOrbPanel.scaledWidth;
    Layout.maximumWidth: floatingOrbPanel.scaledWidth;
    //Layout.preferredWidth: 56;
    //Layout.preferredHeight: floatingOrbPanel.scaledHeight / 3;
    width: Layout.maximumWidth
    height: Layout.maximumHeight
    property bool compositing: false

    Binding {
        target: kicker
        property: "Layout.minimumHeight"
        value: root.Layout.minimumHeight
    }

    Binding {
        target: kicker
        property: "Layout.maximumHeight"
        value: root.Layout.maximumHeight
    }

    Binding {
        target: kicker
        property: "Layout.minimumWidth"
        value: root.Layout.minimumWidth
    }
    Binding {
        target: kicker
        property: "Layout.maximumWidth"
        value: root.Layout.maximumWidth
    }

    property QtObject contextMenu: null
    property QtObject dashWindow: null
    readonly property bool editMode: Plasmoid.containment.corona.editMode
    readonly property bool inPanel: (Plasmoid.location == PlasmaCore.Types.TopEdge || Plasmoid.location == PlasmaCore.Types.RightEdge || Plasmoid.location == PlasmaCore.Types.BottomEdge || Plasmoid.location == PlasmaCore.Types.LeftEdge)
    property bool menuShown: dashWindow.visible
    property QtObject orb: null
    property alias orbTimer: orbTimer
    readonly property var screenGeometry: Plasmoid.screenGeometry

    // Should the orb be rendered in its own dialog window so that it can stick out of the panel?
    readonly property bool stickOutOrb: (Plasmoid.location == PlasmaCore.Types.TopEdge || Plasmoid.location == PlasmaCore.Types.BottomEdge) && Plasmoid.configuration.stickOutOrb && kicker.height <= 30 && !editMode
    readonly property bool useCustomButtonImage: (Plasmoid.configuration.useCustomButtonImage)
    readonly property bool vertical: (Plasmoid.formFactor == PlasmaCore.Types.Vertical)
    readonly property bool enableShadow: (Plasmoid.configuration.enableShadow)

    onEnableShadowChanged: {
        //Plasmoid.enableShadow(Plasmoid.configuration.enableShadow);
        if(dashWindow) {
            dashWindow.firstTimeShadowSetup = false;
        }
    }


    // If the url is empty (default value), then use the fallback url. Otherwise, return the url path relative to
    // the location of the source code.
    function getResolvedUrl(url, fallback) {

        if (url.toString() === "" || !Plasmoid.fileExists(url)) {
            return Qt.resolvedUrl(fallback);
        }
        return url;
    }
    function positionOrb() {
        var pos = kicker.mapToGlobal(floatingOrbPanel.x, floatingOrbPanel.y);
        pos.y -= 5;
        if(Plasmoid.configuration.offsetFloatingOrb) {
            pos.y += 3;
        }
        orb.width = floatingOrbPanel.scaledWidth
        orb.height = floatingOrbPanel.scaledHeight / 3;
        if(orb.height === 30) {
            pos.y += 2;
        }

        orb.x = pos.x;
        orb.y = pos.y;
    }
    function showMenu() {
        dashWindow.visible = !dashWindow.visible;
        dashWindow.showingAllPrograms = false;
        maskTimer.start();
        if(KWindowSystem.isPlatformX11) Plasmoid.setActiveWin(dashWindow);
        Plasmoid.setDialogAppearance(dashWindow, dashWindow.dialogBackgroundTexture.mask);
        dashWindow.m_searchField.focus = true;
        orb.raise();

    }
    function updateSizeHints() {
        return;
        /*if (useCustomButtonImage) {
            if (vertical) {
                var scaledHeight = Math.floor(parent.width * (floatingOrbPanel.buttonIcon.height / floatingOrbPanel.buttonIcon.width));
                root.Layout.minimumHeight = scaledHeight;
                root.Layout.maximumHeight = scaledHeight;
                root.Layout.minimumWidth = Kirigami.Units.iconSizes.small;
                root.Layout.maximumWidth = inPanel ? Kirigami.Units.iconSizes.medium : -1;
            } else {
                var scaledWidth = Math.floor(parent.height * (floatingOrbPanel.buttonIcon.width / floatingOrbPanel.buttonIcon.height));
                root.Layout.minimumWidth = scaledWidth;
                root.Layout.maximumWidth = scaledWidth;
                root.Layout.minimumHeight = Kirigami.Units.iconSizes.small;
                root.Layout.maximumHeight = inPanel ? Kirigami.Units.iconSizes.medium : -1;
            }
        } else {
            root.Layout.minimumWidth = Kirigami.Units.iconSizes.small;
            root.Layout.maximumWidth = inPanel ? Kirigami.Units.iconSizes.medium : -1;
            root.Layout.minimumHeight = Kirigami.Units.iconSizes.small;
            root.Layout.maximumHeight = inPanel ? Kirigami.Units.iconSizes.medium : -1;
        }
        if (stickOutOrb && orb) {
            root.Layout.minimumWidth = orb.width + panelSvg.margins.right * (compositing ? 0 : 1);
            root.Layout.maximumWidth = orb.width + panelSvg.margins.right * (compositing ? 0 : 1);
            root.Layout.minimumHeight = orb.height;
            root.Layout.maximumHeight = orb.height;
        }*/
    }

    //kicker.status: PlasmaCore.Types.PassiveStatus
    //Plasmoid.status: dashWindow && dashWindow.visible ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.PassiveStatus
    //clip: true

    Component.onCompleted: {
        dashWindow = Qt.createQmlObject("MenuRepresentation {}", kicker);
        orb = Qt.createQmlObject("StartOrb {}", kicker);

        maskTimer.start();
        orbTimer.start();
        Plasmoid.activated.connect(function () {
            console.log("hi");
            showMenu();
        });
    }
    onCompositingChanged: {
        updateSizeHints();
        positionOrb();
        compositingFix.start();
    }
    onHeightChanged: updateSizeHints()

    onStickOutOrbChanged: {
        updateSizeHints();
        positionOrb();
    }
    onWidthChanged: updateSizeHints()

    Connections {
        target: Plasmoid.configuration
        function onCustomButtonImageChanged() {
            positionOrb();
        }
        function onOrbWidthChanged() {
            positionOrb();
        }
    }
    Connections {
        function onScreenChanged() {
            orbTimer.start();
        }
        function onScreenGeometryChanged() {
            orbTimer.start();
        }

        target: kicker
    }

    /*
     * Three IconItems are used in order to achieve the same look and feel as Windows 7's
     * orbs. When the menu is closed, hovering over the orb results in the hovered icon
     * gradually appearing into view, and clicking on the orb causes an instant change in
     * visibility, where the normal and hovered icons are invisible, and the pressed icon
     * is visible.
     *
     * When they're bounded by the panel, these icons will by default try to fill up as
     * much space as they can in the compact representation while preserving their aspect
     * ratio.
     */


    FloatingOrb {
        id: floatingOrbPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        objectName: "innerorb"
        opacity: (!stickOutOrb)

    }

    // Handles all mouse events for the popup orb
    MouseArea {
        id: mouseAreaCompositingOff

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true

        onPressed: mouse => {
            if(mouse.button === Qt.LeftButton)
                showMenu();
            else
                mouse.accepted = false;
        }
        z: 99
    }

    // I hate this

    // So the only way I could reasonably think of to make this work is running the function
    // with a delay.
    Timer {
        id: compositingFix

        interval: 150

        onTriggered: {
            if (!compositing) {
                Plasmoid.setTransparentWindow();
            }
        }
    }

    // Even worse, this just makes things even more unsophisticated. If someone has a better
    // way of solving this, I would love to know.
    Timer {
        id: orbTimer

        interval: 15

        onTriggered: {

            Plasmoid.setOrb(orb);
            // Currently hardcoded, will make it configurable soon, when it's been properly tested and hopefully slightly refactored.
            Plasmoid.setMask(Qt.resolvedUrl("./orbs/mask.png"), false);
            Plasmoid.setDashWindow(dashWindow, dashWindow.dialogBackgroundTexture.mask, dashWindow.dialogBackgroundTexture.imagePath);
            updateSizeHints();
            positionOrb();
        }
    }

    Timer {
        id: maskTimer
        interval: 25
        onTriggered: {
            Plasmoid.setDialogAppearance(dashWindow, dashWindow.dialogBackgroundTexture.mask);
        }
    }
}
