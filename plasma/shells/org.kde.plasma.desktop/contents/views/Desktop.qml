/*
    SPDX-FileCopyrightText: 2012 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2014 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Effects
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC
import org.kde.kwindowsystem 1.0
import org.kde.plasma.activityswitcher as ActivitySwitcher
import "../activitymanager"
import "../explorer"
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root

    property Item containment

    property QtObject widgetExplorer

    Connections {
        target: ActivitySwitcher.Backend
        function onShouldShowSwitcherChanged() {
            if (ActivitySwitcher.Backend.shouldShowSwitcher) {
                if (sidePanelStack.state != "activityManager") {
                    root.toggleActivityManager();
                }

            } else {
                if (sidePanelStack.state == "activityManager") {
                    root.toggleActivityManager();
                }

            }
        }
    }

    function toggleWidgetExplorer(containment) {

        if (sidePanelStack.state == "widgetExplorer") {
            sidePanelStack.state = "closed";
        } else {
            sidePanelStack.state = "widgetExplorer";
            sidePanelStack.setSource(Qt.resolvedUrl("../explorer/WidgetExplorer.qml"), {"containment": containment, "sidePanel": sidePanel});
        }
    }

    function toggleActivityManager() {
        if (sidePanelStack.state == "activityManager") {
            sidePanelStack.state = "closed";
        } else {
            sidePanelStack.state = "activityManager";
            sidePanelStack.setSource(Qt.resolvedUrl("../activitymanager/ActivityManager.qml"), {"rootItem": root});
        }
    }


    readonly property rect editModeRect: {
        if (!containment) {
            return Qt.rect(0,0,0,0);
        }
        let screenRect = containment.plasmoid.availableScreenRect;
        let panelConfigRect = Qt.rect(0,0,0,0);

        if (containment.plasmoid.corona.panelBeingConfigured
            && containment.plasmoid.corona.panelBeingConfigured.screenToFollow === desktop.screenToFollow) {
            panelConfigRect = containment.plasmoid.corona.panelBeingConfigured.relativeConfigRect;
        }

        if (panelConfigRect.width <= 0) {
            ; // Do nothing
        } else if (panelConfigRect.x > width - (panelConfigRect.x + panelConfigRect.width)) {
            screenRect = Qt.rect(screenRect.x, screenRect.y, panelConfigRect.x - screenRect.x, screenRect.height);
        } else {
            const diff = Math.max(0, panelConfigRect.x + panelConfigRect.width - screenRect.x);
            screenRect = Qt.rect(Math.max(screenRect.x, panelConfigRect.x + panelConfigRect.width), screenRect.y, screenRect.width - diff, screenRect.height);
        }

        /*if (sidePanel.visible) {
            if (Qt.application.layoutDirection === Qt.RightToLeft) {
                screenRect = Qt.rect(screenRect.x, screenRect.y, screenRect.width - sidePanel.width, screenRect.height);
            } else {
                screenRect = Qt.rect(screenRect.x + sidePanel.width, screenRect.y, screenRect.width - sidePanel.width, screenRect.height);
            }
        }*/
        return screenRect;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: containment.plasmoid.corona.editMode = false
    }

    MouseArea {
        id: containmentParent
        x: editModeLoader.active ? editModeLoader.item.centerX - width / 2 : 0
        y: editModeLoader.active ? editModeLoader.item.centerY - height / 2 : 0
        width: root.width
        height: root.height
        readonly property real extraScale: desktop.configuredPanel || sidePanel.visible ? 0.95 : 0.9
        property real scaleFactor: Math.min(editModeRect.width/root.width, editModeRect.height/root.height) * extraScale
        scale: containment?.plasmoid.corona.editMode ? scaleFactor : 1
    }

    Loader {
        id: editModeLoader
        anchors.fill: parent
        sourceComponent: DesktopEditMode {}
        active: containment?.plasmoid.corona.editMode || editModeUiTimer.running
        Timer {
            id: editModeUiTimer
            property bool editMode: containment?.plasmoid.corona.editMode || false
            onEditModeChanged: restart()
            interval: Kirigami.Units.longDuration
        }
    }

    Loader {
        id: wallpaperColors

        active: root.containment && root.containment.wallpaper && desktop.usedInAccentColor
        asynchronous: true

        sourceComponent: Kirigami.ImageColors {
            id: imageColors
            source: root.containment.wallpaper

            readonly property color backgroundColor: Kirigami.Theme.backgroundColor
            readonly property color textColor: Kirigami.Theme.textColor

            // Ignore the initial dominant color
            onPaletteChanged: {
                if (!Qt.colorEqual(root.containment.wallpaper.accentColor, "transparent")) {
                    desktop.accentColor = root.containment.wallpaper.accentColor;
                }
                if (this.palette.length === 0) {
                    desktop.accentColor = "transparent";
                } else {
                    desktop.accentColor = this.dominant;
                }
            }

            Kirigami.Theme.inherit: false
            Kirigami.Theme.backgroundColor: backgroundColor
            Kirigami.Theme.textColor: textColor

            onBackgroundColorChanged: Qt.callLater(update)
            onTextColorChanged: Qt.callLater(update)

            property Connections repaintConnection: Connections {
                target: root.containment.wallpaper
                function onAccentColorChanged() {
                    if (Qt.colorEqual(root.containment.wallpaper.accentColor, "transparent")) {
                        imageColors.update();
                    } else {
                        imageColors.paletteChanged();
                    }
                }
            }
        }
    }

    Timer {
        id: pendingUninstallTimer
        // keeps track of the applets the user wants to uninstall
        property var applets: []
        function uninstall() {
            for (var i = 0, length = applets.length; i < length; ++i) {
                widgetExplorer.uninstall(applets[i])
            }
            applets = []

            if (sidePanelStack.state !== "widgetExplorer" && widgetExplorer) {
                widgetExplorer.destroy()
                widgetExplorer = null
            }
        }

        interval: 60000 // one minute
        onTriggered: uninstall()
    }

    Window {
        id: sidePanel

        title: "plasmashell_explorer"

        property bool outputOnly: false

        flags:  Qt.WA_TranslucentBackground | (outputOnly ? Qt.WindowTransparentForInput : Qt.Widget)
        color:  "#00000000"

        property int previousWidth: 0
        property int previousHeight: 0
        onMinimumWidthChanged: {
            if(sidePanelStack.item)
                previousWidth = minimumWidth;
        }
        onMinimumHeightChanged: {
            if(sidePanelStack.item)
                previousHeight = minimumHeight;
        }

        minimumWidth: sidePanelStack.item ? sidePanelStack.item.implicitWidth : previousWidth
        maximumWidth: minimumWidth

        minimumHeight: sidePanelStack.item ? sidePanelStack.item.implicitHeight : previousHeight
        maximumHeight: minimumHeight


        onVisibleChanged: {
            if (!visible) {
                // If was called from a panel, open the panel config
                if (sidePanelStack.item && sidePanelStack.item.containment
                    && sidePanelStack.item.containment != containment.plasmoid
                    && !sidePanelStack.item.containment.userConfiguring
                ) {
                    Qt.callLater(sidePanelStack.item.containment.internalAction("configure").trigger);
                }
                sidePanelStack.state = "closed";
                ActivitySwitcher.Backend.shouldShowSwitcher = false;
            }
        }

        Loader {
            id: sidePanelStack
            asynchronous: true
            width: item ? item.implicitWidth : 0
            height: item ? item.implicitHeight : 320

            //height: 325 // accurate value is actually 349 but nobody has to know
            state: "closed"

            LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
            LayoutMirroring.childrenInherit: true

            onLoaded: {
                // sidePanel.PopupPlasmaWindow("", "")
                if (sidePanelStack.item) {
                    item.closed.connect(function(){sidePanelStack.state = "closed";});

                    if (sidePanelStack.state == "activityManager") {
                        sidePanelStack.item.showSwitcherOnly =
                            ActivitySwitcher.Backend.shouldShowSwitcher
                        sidePanelStack.item.forceActiveFocus();
                    } else if (sidePanelStack.state == "widgetExplorer"){
                        sidePanel.opacity = Qt.binding(function() { return sidePanelStack.item ? sidePanelStack.item.opacity : 1 })
                        sidePanel.outputOnly = Qt.binding(function() { return sidePanelStack.item && sidePanelStack.item.outputOnly })
                    }
                }
                sidePanel.visible = true;
                if (KWindowSystem.isPlatformX11) {
                    KX11Extras.forceActiveWindow(sidePanel);
                }
            }
            onStateChanged: {
                if (sidePanelStack.state == "closed") {
                    sidePanel.visible = false;
                    sidePanelStack.source = ""; //unload all elements
                }
            }
        }
    }

    Connections {
        target: containment?.plasmoid ?? null
        function onAvailableScreenRectChanged() {
            if (sidePanel.visible) {
                sidePanel.requestActivate();
            }
        }
    }


    onContainmentChanged: {
        if (containment == null) {
            return;
        }

        containment.parent = containmentParent

        if (switchAnim.running) {
            //If the animation was still running, stop it and reset
            //everything so that a consistent state can be kept
            switchAnim.running = false;
            internal.newContainment.visible = false;
            internal.oldContainment.visible = false;
            internal.oldContainment = null;
        }

        internal.newContainment = containment;
        containment.visible = true;

        if (internal.oldContainment != null && internal.oldContainment != containment) {
            switchAnim.running = true;
        } else {
            containment.anchors.left = containmentParent.left;
            containment.anchors.top = containmentParent.top;
            containment.anchors.right = containmentParent.right;
            containment.anchors.bottom = containmentParent.bottom;
            if (internal.oldContainment) {
                internal.oldContainment.visible = false;
            }
            internal.oldContainment = containment;
        }
    }

    //some properties that shouldn't be accessible from elsewhere
    QtObject {
        id: internal;

        property Item oldContainment: null;
        property Item newContainment: null;
    }

    SequentialAnimation {
        id: switchAnim
        ScriptAction {
            script: {
                if (sidePanelStack.state == "activityManager") {
                    sidePanel.close();
                    sidePanel.show();
                    root.toggleActivityManager();
                }

                if (containment) {
                    containment.z = 1;
                    containment.x = root.width;
                }
                if (internal.oldContainment) {
                    internal.oldContainment.z = 0;
                    internal.oldContainment.x = 0;
                }
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: internal.oldContainment
                properties: "x"
                to: internal.newContainment != null ? -root.width : 0
                duration: Kirigami.Units.veryLongDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: internal.newContainment
                properties: "x"
                to: 0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }
        ScriptAction {
            script: {
                if (internal.oldContainment) {
                    internal.oldContainment.visible = false;
                }
                if (containment) {
                    internal.oldContainment = containment;
                }
            }
        }
    }

    Loader {
        id: previewBannerLoader
        readonly property point pos: root.containment?.plasmoid.availableScreenRegion,
            active ? root.containment.adjustToAvailableScreenRegion(
                root.containment.width + root.containment.x - item.width - Kirigami.Units.largeSpacing,
                root.containment.height + root.containment.y - item.height - Kirigami.Units.largeSpacing,
                item.width + Kirigami.Units.largeSpacing,
                item.height + Kirigami.Units.largeSpacing)
            : Qt.point(0, 0)
        x: pos.x
        y: pos.y
        z: Number(root.containment?.z) + 1
        active: root.containment && Boolean(desktop.showPreviewBanner)
        visible: active
        source: "PreviewBanner.qml"
    }
}
