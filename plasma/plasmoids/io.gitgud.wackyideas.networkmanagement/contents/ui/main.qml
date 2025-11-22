/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.2
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.networkmanager as NMQt
import QtQuick.Layouts 1.1
import org.kde.kcmutils as KCMUtils
import org.kde.config as KConfig

PlasmoidItem {
    id: mainWindow

    property alias windowManager: wm
    property alias networkStatus: networkStatus
    Item {
        id: wm
        property var windowObjects: {}
        function getWindow(name) {
            if(typeof windowObjects === "undefined")
                windowObjects = {};
            return windowObjects[name];
        }
        function addWindow(uuid, state, type, name, model, devicePath, index) {
            if(typeof windowObjects === "undefined")
                windowObjects = {};

            var winComponent = Qt.createComponent("DetailsWindow.qml", mainWindow);
            if(winComponent.status === Component.Error) {
                console.log("Error loading component:", winComponent.errorString());
                return null;
            }
            var winObj = winComponent.createObject(winComponent, { uuid: uuid, connectionState: state, type: type, networkName: name, connectionModel: model, devicePath: devicePath});
            if(winObj == null) {
                console.log("Error loading object");
                return null;
            }
            winObj.tabBar.currentIndex = index;
            //winObj.transientParent = null;

            windowObjects[name+uuid] = winObj;
            Qt.callLater(() => { windowObjects[name+uuid].show(); });
            return windowObjects[name+uuid];
        }
        function removeWindow(name) {
            delete windowObjects[name];
        }

    }


    property PlasmaNM.NetworkModel connectionModel: null
    property alias nmhandler: handler
    readonly property string kcm: "kcm_networkmanagement"
    readonly property bool kcmAuthorized: KConfig.KAuthorized.authorizeControlModule("kcm_networkmanagement")
    readonly property bool delayModelUpdates: fullRepresentationItem !== null
        && fullRepresentationItem.connectionModel !== null
        && fullRepresentationItem.connectionModel.delayModelUpdates
    readonly property bool airplaneModeAvailable: availableDevices.modemDeviceAvailable || availableDevices.wirelessDeviceAvailable
    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)
    property alias planeModeSwitchAction: planeAction

    Plasmoid.title: "Open Network and Sharing Center"
    toolTipMainText: i18n("Networks")
    toolTipSubText: {
        const activeConnections = networkStatus.activeConnections;

        if (!airplaneModeAvailable) {
            return activeConnections;
        }

        if (PlasmaNM.Configuration.airplaneModeEnabled) {
            return i18nc("@info:tooltip", "Middle-click to turn off Airplane Mode");
        } else {
            const hint = i18nc("@info:tooltip", "Middle-click to turn on Airplane Mode");
            return activeConnections ? `${activeConnections}\n${hint}` : hint;
        }
    }

    Plasmoid.busy: connectionIconProvider.connecting
    Plasmoid.icon: inPanel ? connectionIconProvider.connectionIcon + "-symbolic" : connectionIconProvider.connectionTooltipIcon
    switchWidth: Kirigami.Units.iconSizes.small * 10
    switchHeight: Kirigami.Units.iconSizes.small * 10

    // Only exists because the default CompactRepresentation doesn't expose
    // a middle-click action.
    // TODO remove once it gains that feature.
    compactRepresentation: CompactRepresentation {
        airplaneModeAvailable: mainWindow.airplaneModeAvailable
        iconName: Plasmoid.icon
    }
    fullRepresentation: PopupDialog {
        id: dialogItem
        nmHandler: handler
        nmStatus: networkStatus
        readonly property int flyoutIntendedWidth: 16 * 17
        Layout.minimumWidth: 16 * 10
        Layout.minimumHeight: 131
        Layout.preferredHeight: dialogItem.implicitHeight
        anchors.fill: parent
        anchors.topMargin: -Kirigami.Units.smallSpacing
        focus: true
    }
    //property var detailsWindow: null

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Enable Wi-Fi")
            icon.name: "network-wireless-on"
            priority: PlasmaCore.Action.LowPriority
            checkable: true
            checked: enabledConnections.wirelessEnabled
            visible: enabledConnections.wirelessHwEnabled
                        && availableDevices.wirelessDeviceAvailable
                        && !PlasmaNM.Configuration.airplaneModeEnabled
            onTriggered: checked => {handler.enableWireless(checked)}
        },
        PlasmaCore.Action {
            text: i18n("Enable Mobile Network")
            icon.name: "network-mobile-on"
            priority: PlasmaCore.Action.LowPriority
            checkable: true
            checked: enabledConnections.wwanEnabled
            visible: enabledConnections.wwanHwEnabled
                        && availableDevices.modemDeviceAvailable
                        && !PlasmaNM.Configuration.airplaneModeEnabled
            onTriggered: checked => {handler.enableWwan(checked)}
        },
        PlasmaCore.Action {
            id: planeAction
            text: i18n("Enable Airplane Mode")
            icon.name: "network-flightmode-on"
            priority: PlasmaCore.Action.LowPriority
            checkable: true
            checked: PlasmaNM.Configuration.airplaneModeEnabled
            visible: mainWindow.airplaneModeAvailable
            onTriggered: checked => {
                handler.enableAirplaneMode(checked)
                PlasmaNM.Configuration.airplaneModeEnabled = checked
            }
        },
        PlasmaCore.Action {
            id: hotspotAction
            text: i18n("Hotspot")
            priority: PlasmaCore.Action.LowPriority
            checkable: true
            checked: handler.hotspotActive
            visible: handler.hotspotSupported

            onTriggered: checked => {
                if (PlasmaNM.Configuration.hotspotConnectionPath) {
                    handler.stopHotspot();
                } else {
                    handler.createHotspot();
                }
            }

            Component.onCompleted: {
                checked = PlasmaNM.Configuration.hotspotConnectionPath
            }

        },
        PlasmaCore.Action {
            text: i18n("Open Network Login Page…")
            icon.name: "network-manager"
            priority: PlasmaCore.Action.LowPriority
            visible: networkStatus.connectivity === NMQt.NetworkManager.Portal

            onTriggered: Qt.openUrlExternally(networkStatus.networkCheckUrl)
        }
    ]

    PlasmaCore.Action {
        id: configureAction
        text: i18n("&Configure Network Connections…")
        icon.name: "configure"
        visible: kcmAuthorized
        shortcut: "alt+d, s"
        onTriggered: KCMUtils.KCMLauncher.openSystemSettings(kcm)
    }

    Component.onCompleted: {
        plasmoid.setInternalAction("configure", configureAction);
    }

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

    PlasmaNM.AvailableDevices {
        id: availableDevices
    }

    PlasmaNM.NetworkStatus {
        id: networkStatus
    }

    PlasmaNM.ConnectionIcon {
        id: connectionIconProvider
        connectivity: networkStatus.connectivity
    }

    PlasmaNM.Handler {
        id: handler
    }

    Timer {
        id: scanTimer
        interval: 10200
        repeat: true
        running: mainWindow.expanded && !PlasmaNM.Configuration.airplaneModeEnabled && !mainWindow.delayModelUpdates

        onTriggered: handler.requestScan()
    }
}
