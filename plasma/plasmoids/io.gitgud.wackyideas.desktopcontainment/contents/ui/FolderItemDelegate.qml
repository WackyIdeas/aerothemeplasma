/*
    SPDX-FileCopyrightText: 2014-2015 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents

import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.kquickcontrolsaddons 2.0

Item {
    id: main

    property int index:          model.index
    property string name:        model.blank ? "" : model.display
    property string nameWrapped: model.blank ? "" : model.displayWrapped
    property bool blank:         model.blank
    property bool selected:      model.blank ? false : model.selected
    property bool isDir:           loader.item ? loader.item.isDir : false
    property QtObject popupDialog: loader.item ? loader.item.popupDialog    : null
    property Item iconArea:        loader.item ? loader.item.iconArea       : null
    property Item label:           loader.item ? loader.item.label          : null
    property Item labelArea:       loader.item ? loader.item.labelArea      : null
    property Item actionsOverlay:  loader.item ? loader.item.actionsOverlay : null
    property Item hoverArea:       loader.item ? loader.item.hoverArea      : null
    property Item frame:           loader.item ? loader.item.frame          : null
    property Item toolTip:         loader.item ? loader.item.toolTip        : null
    property bool shouldShowToolTip: false
    Accessible.name: name
    Accessible.role: Accessible.Canvas


    // This MouseArea exists to intercept press and hold; preventing edit mode
    // from being triggered when pressing and holding on an icon (if there is one).
    MouseArea {
        anchors.fill: parent
        visible: !main.blank
    }

    function openPopup() {
        if (isDir) {
            loader.item.openPopup();
        }
    }

    function closePopup() {
        if (popupDialog) {
            popupDialog.requestDestroy();
            loader.item.popupDialog = null;
        }
    }

    Loader {
        id: loader

        // On the desktop we pad our cellSize to avoid a gap at the right/bottom of the screen.
        // The padding per item is quite small and causes the delegate to be positioned on fractional pixels
        // leading to blurry rendering. The Loader is offset to account for this.
        x: -main.x % 1
        y: -main.y % 1
        width: parent.width
        height: parent.height

        visible: status === Loader.Ready

        active: !model.blank

        sourceComponent: delegateImplementation

        asynchronous: true
    }

    function updateDragImage() {
        if (selected && !blank) {
            loader.grabToImage(result => {
                dir.addItemDragImage(positioner.map(index), main.x + loader.x, main.y + loader.y, loader.width, loader.height, result.image);
            });
        }
    }
    Component {
        id: delegateImplementation

        Item {
            id: impl

            anchors.fill: parent

            property bool blank: model.blank
            property bool selected: model.blank ? false : model.selected
            property bool isDir: model.blank ? false : model.isDir
            property bool hovered: (main.GridView.view.hoveredItem === main)
            property QtObject popupDialog: null
            property Item iconArea: icon
            property Item label: label
            property Item labelArea: label
            property Item actionsOverlay: actions
            property Item hoverArea: toolTip
            property Item frame: frameLoader
            property Item toolTip: toolTip
            property Item selectionButton: null
            property Item popupButton: null

            readonly property bool iconAndLabelsShouldlookSelected: impl.hovered

            // When a drop happens, a new item is created, and is set to selected
            // grabToImagebefore it gets the final width, making grabToImage fail because it's still 0x0
            onSelectedChanged: {
                Qt.callLater(updateDragImage)
                if(selected && (!toolTip.containsMouse) && main.shouldShowToolTip) {
                    toolTipTimer.start();
                    main.shouldShowToolTip = false;
                } else {
                    toolTipTimer.stop();
                    toolTip.hideImmediately();
                }
            }
            function updateDragImage() {
                if (selected && !blank) {
                    frameLoader.grabToImage(result => {
                        dir.addItemDragImage(positioner.map(index), main.x + frameLoader.x, main.y + frameLoader.y, frameLoader.width, frameLoader.height, result.image);
                    });
                }
            }

            Connections {
                target: model

                function onSelectedChanged() {
                    if (dir.usedByContainment && model.selected) {
                        gridView.currentIndex = model.index;
                    }
                }
            }

            onHoveredChanged: {
                if (hovered) {
                    // In list view, it behaves more like a menu, and menus always activate their items on a single click
                    if (Plasmoid.configuration.selectionMarkers && (Qt.styleHints.singleClickActivation || root.useListViewMode)) {
                        selectionButton = selectionButtonComponent.createObject(actions);
                    }

                    if (model.isDir) {
                        if (!main.GridView.view.isRootView || root.containsDrag) {
                            hoverActivateTimer.restart();
                        }

                        if (Plasmoid.configuration.popups && !root.useListViewMode) {
                            popupButton = popupButtonComponent.createObject(actions);
                        }
                    }
                } else if (!hovered) {
                    if (popupDialog != null) {
                        closePopup();
                    }

                    if (selectionButton) {
                        selectionButton.destroy();
                        selectionButton = null;
                    }

                    if (popupButton) {
                        popupButton.destroy();
                        popupButton = null;
                    }
                }
            }

            function openPopup() {
                if (folderViewDialogComponent.status === Component.Ready) {
                    impl.popupDialog = folderViewDialogComponent.createObject(impl);
                    impl.popupDialog.visualParent = icon;
                    impl.popupDialog.url = model.linkDestinationUrl;
                    impl.popupDialog.visible = true;
                }
            }

            Timer {
                id: toolTipTimer
                interval: 700
                onTriggered: {
                    toolTip.updateToolTip();
                    toolTip.showToolTip();
                }
            }

            Loader {
                id: frameLoader

                x: 0//root.useListViewMode ? 0 : Kirigami.Units.smallSpacing
                y: root.useListViewMode ? 0 : Kirigami.Units.smallSpacing

                property Item iconShadow: null
                property string prefix: ""

                sourceComponent: frameComponent
                active: impl.iconAndLabelsShouldlookSelected || model.selected
                asynchronous: true

                width: parent.width

                height: root.useListViewMode
                                ? parent.height
                                // the smallSpacings are for padding
                                : icon.height + (Kirigami.Units.iconSizes.small * label.lineCount) + (Kirigami.Units.smallSpacing * 3)

                Kirigami.Icon {
                    id: iconHighlight

                    z: 3

                    states: [
                        State { // icon view
                            when: !root.useListViewMode

                            AnchorChanges {
                                target: iconHighlight
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        },
                        State { // list view
                            when: root.useListViewMode

                            AnchorChanges {
                                target: iconHighlight
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    ]

                    anchors {
                        topMargin: Kirigami.Units.smallSpacing
                        leftMargin: Kirigami.Units.smallSpacing
                    }

                    width: root.useListViewMode ? main.GridView.view.iconSize : (parent.width - 2 * Kirigami.Units.smallSpacing)
                    height: main.GridView.view.iconSize

                    isMask: true
                    color: "#c2e7ed"

                    opacity: 0.5

                    animated: false

                    source: model.decoration
                    visible: model.selected && Plasmoid.configuration.selectionStyle
                }
                Kirigami.Icon {
                    id: icon

                    z: 2

                    states: [
                        State { // icon view
                            when: !root.useListViewMode

                            AnchorChanges {
                                target: icon
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        },
                        State { // list view
                            when: root.useListViewMode

                            AnchorChanges {
                                target: icon
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    ]

                    anchors {
                        topMargin: Kirigami.Units.smallSpacing
                        leftMargin: Kirigami.Units.smallSpacing
                    }

                    width: root.useListViewMode ? main.GridView.view.iconSize : (parent.width - 2 * Kirigami.Units.smallSpacing)
                    height: main.GridView.view.iconSize

                    opacity: {
                        if (root.useListViewMode && selectionButton) {
                            return 0.3;
                        }

                        if (model.isHidden) {
                            return 0.6;
                        }

                        return 1.0;
                    }

                    animated: false

                    source: model.decoration
                }
                PlasmaComponents.Label {
                    id: label

                    renderType: Text.NativeRendering
                    font.hintingPreference: Font.PreferFullHinting
                    z: 2 // So it's always above the highlight effect
                    font.kerning: Screen.devicePixelRatio == 1.0

                    Timer {
                        id: hidpi_hack
                        interval: 50
                        onTriggered: {
                            front.anchors.rightMargin += 1;
                            front.anchors.rightMargin -= 1;
                            behind.anchors.rightMargin += 1;
                            behind.anchors.rightMargin -= 1;

                        }
                    }
                    // Hacks to improve font rendering to increase contrast and text brightness
                    // This is done to get darker subpixel rendering, closer to ClearType
                    PlasmaComponents.Label {
                        id: behind
                        z: -1
                        anchors.fill: parent
                        anchors.rightMargin: 1
                        anchors.leftMargin: -1
                        color: model.selected && Plasmoid.configuration.selectionStyle ? "black" : "#F9000000"
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: Screen.devicePixelRatio == 1.0
                        text: parent.text
                        elide: Text.ElideRight
                        maximumLineCount: parent.maximumLineCount
                        wrapMode: (maximumLineCount === 1) ? Text.NoWrap : Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        visible: Plasmoid.configuration.textShadows
                    }
                    PlasmaComponents.Label {
                        id: front
                        z: -2
                        anchors.fill: parent
                        anchors.rightMargin: 0
                        color: model.selected && Plasmoid.configuration.selectionStyle ? "black" : "#ffffffff"
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferFullHinting
                        font.kerning: Screen.devicePixelRatio == 1.0
                        text: parent.text
                        elide: Text.ElideRight
                        maximumLineCount: parent.maximumLineCount
                        wrapMode: (maximumLineCount === 1) ? Text.NoWrap : Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        visible: Plasmoid.configuration.textShadows
                    }

                    states: [
                        State { // icon view
                            when: !root.useListViewMode

                            PropertyChanges {
                                target: label
                                anchors.topMargin: Kirigami.Units.smallSpacing
                                // Ffs
                                width: Math.floor((parent.width - Kirigami.Units.smallSpacing + (Screen.devicePixelRatio != 1.0) * 2 * Screen.devicePixelRatio) * Screen.devicePixelRatio) / Screen.devicePixelRatio
                                maximumLineCount: Plasmoid.configuration.textLines
                                horizontalAlignment: Text.AlignHCenter
                            }
                            AnchorChanges {
                                target: label
                                anchors.top: icon.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            AnchorChanges {
                                target: behind
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                            }
                            AnchorChanges {
                                target: front
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                            }
                            PropertyChanges {
                                target: behind
                                anchors.rightMargin: 1
                                anchors.leftMargin: -1
                            }
                            StateChangeScript {
                                script: {
                                    hidpi_hack.start();
                                }
                            }
                        },
                        State { // list view
                            when: root.useListViewMode

                            AnchorChanges {
                                target: label
                                anchors.left: icon.right
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            PropertyChanges {
                                target: label
                                anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                                anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                                width: parent.width - icon.width - (Kirigami.Units.smallSpacing * 4)
                                maximumLineCount: 1
                                horizontalAlignment: Text.AlignLeft
                            }
                        }
                    ]

                    color: {
                        if (Plasmoid.isContainment) {
                            if (model.selected && Plasmoid.configuration.selectionStyle) {
                                return "gray"
                            } else return "white"
                        }

                        return Kirigami.Theme.textColor;

                    }
                    opacity: model.isHidden ? 0.6 : 1

                    text: main.nameWrapped
                    elide: Text.ElideRight
                    wrapMode: (maximumLineCount === 1) ? Text.NoWrap : Text.Wrap
                    horizontalAlignment: Text.AlignHCenter

                    TextMetrics {
                        id: textMetrics

                        text: main.nameWrapped
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: textMetrics.advanceWidth + Kirigami.Units.smallSpacing
                        height: parent.height
                        color: "#c2e7ed"
                        visible: model.selected && Plasmoid.configuration.selectionStyle
                        z: -1
                    }

                    layer.enabled: true
                    layer.effect: DropShadow {
                        anchors.fill: label

                        z: 1

                        horizontalOffset: 1
                        verticalOffset: 1

                        radius: 4.0
                        samples: radius * 2
                        spread: 0.38

                        color: Plasmoid.configuration.textShadows ? (model.selected && Plasmoid.configuration.selectionStyle ? "transparent" : "#c8080808") : "transparent"

                        opacity: (model.isHidden ? 0.6 : 1)

                        source: label

                        visible: (Plasmoid.isContainment && (!editor || editor.targetItem !== main))
                    }
                }

                Component {
                    id: frameComponent

                    KSvg.FrameSvgItem {
                        imagePath: "widgets/viewitem"
                        visible: this === frameLoader.item && !Plasmoid.configuration.selectionStyle
                        property bool hovered: impl.iconAndLabelsShouldlookSelected
                        property bool pressed: model.selected
                        prefix: {
                            if(hovered && pressed) return "selected+hover";
                            if(hovered) return "hover";
                            if(pressed) return "selected";
                            return "normal";
                        }
                    }
                }

                Component {
                    id: selectionButtonComponent

                    FolderItemActionButton {
                        element: model.selected ? "remove" : "add"

                        onClicked: {
                            dir.toggleSelected(positioner.map(index));
                            main.GridView.view.currentIndex = index;
                        }
                    }
                }

                Component {
                    id: popupButtonComponent

                    FolderItemActionButton {
                        visible: main.GridView.view.isRootView && (popupDialog == null)

                        element: "open"

                        onClicked: {
                            dir.setSelected(positioner.map(index));
                            main.GridView.view.currentIndex = index;
                            openPopup();
                        }
                    }
                }

                Component {
                    id: iconShadowComponent

                    DropShadow {
                        anchors.fill: icon

                        z: 1

                        verticalOffset: 1

                        radius: 5.0
                        samples: radius * 2 + 1
                        spread: 0.05

                        color: "black"

                        opacity: model.isHidden ? 0.3 : 0.6
                        visible: Plasmoid.configuration.iconShadows
                        source: icon
                    }
                }

            }

            PlasmaCore.ToolTipArea {
                id: toolTip

                active: (Plasmoid.configuration.toolTips || label.truncated)
                && popupDialog === null
                && !model.blank
                interactive: false
                location: {
                    if(toolTip.containsMouse) {
                        return PlasmaCore.Types.Floating | PlasmaCore.Types.Desktop
                    } else {
                        return root.useListViewMode ? (Plasmoid.location === PlasmaCore.Types.LeftEdge ? PlasmaCore.Types.LeftEdge : PlasmaCore.Types.RightEdge) : Plasmoid.location
                    }
                }
                z: 999
                function updateToolTip() {
                    if (toolTip.active && !model.blank) {

                        toolTip.textFormat = Text.RichText;
                        toolTip.mainText = model.display;

                        if (model.size !== undefined) {
                            toolTip.subText = model.type + "<br>" + "Size: " + model.size;
                        } else {
                            toolTip.subText = model.type;
                        }
                    }

                }
                MouseArea {
                    id: toolTipMA
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: {
                        if (containsMouse) {
                            toolTip.updateToolTip();
                            main.GridView.view.hoveredItem = main;
                        } else if(!containsMouse && main.GridView.view.hoveredItem === main) {
                            toolTip.hideImmediately();
                        }
                    }
                }

                states: [
                    State { // icon view
                        when: !root.useListViewMode

                        PropertyChanges {
                            target: toolTip
                            x: frameLoader.x
                            y: frameLoader.y
                            width: frameLoader.width
                            height: frameLoader.height
                        }
                    },
                    State { // list view
                        when: root.useListViewMode

                        AnchorChanges {
                            target: toolTip
                            anchors.horizontalCenter: undefined
                        }

                        PropertyChanges {
                            target: toolTip
                            x: frameLoader.x
                            y: frameLoader.y
                            width: frameLoader.width
                            height: frameLoader.height
                        }
                    }
                ]
            }


            Column {
                id: actions

                visible: {
                    if (main.GridView.view.isRootView && root.containsDrag) {
                        return false;
                    }

                    if (!main.GridView.view.isRootView && main.GridView.view.dialog && main.GridView.view.dialog.containsDrag) {
                        return false;
                    }

                    if (popupDialog) {
                        return false;
                    }

                    return true;
                }

                anchors {
                    left: frameLoader.left
                    top: frameLoader.top
                    leftMargin: root.useListViewMode ? (icon.x + (icon.width / 2)) - (width / 2) : 0
                    topMargin: root.useListViewMode ? (icon.y + (icon.height / 2)) - (height / 2) : 0
                }

                width: implicitWidth
                height: implicitHeight
            }

            Component.onCompleted: {
                if (Plasmoid.isContainment && main.GridView.view.isRootView && root.GraphicsInfo.api === GraphicsInfo.OpenGL) {
                    frameLoader.iconShadow = iconShadowComponent.createObject(frameLoader);
                }
            }
        }
    }
}
