/*
    SPDX-FileCopyrightText: 2012-2013 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.private.taskmanager as TaskManagerApplet
import org.kde.plasma.plasmoid 2.0
import Qt5Compat.GraphicalEffects

import "code/layoutmetrics.js" as LayoutMetrics
import "code/tools.js" as TaskTools

PlasmaCore.ToolTipArea {
    id: task

    // BEGIN TOOLTIP CODE
    property real attentionAnimOpacity: attentionFrame.opacity > 0 ? 1 : attentionGlow.opacity
    property Item taskThumbnail: tasksRoot.taskThumbnail

    active: !jumpListOpen
    mainItem: showPreviews ? taskThumbnail : null
    mainText: showPreviews ? "" : model.display
    location: Plasmoid.location
    backgroundHints: showPreviews ? "StandardBackground" : "SolidBackground"
    interactive: showPreviews
    windowTitle: showPreviews ? "seventasks-tooltip" : ""

    onContainsMouseChanged: (containsMouse) => {
        if(tasksRoot.toolTipOpen && !showPreviews) {
            task.hideImmediately();
            tasksRoot.toolTipOpen = false;
        }
        if(tasksRoot.pinnedToolTipOpen && showPreviews) {
            task.hideImmediately();
            tasksRoot.pinnedToolTipOpen = false;
        }
    }
    onToolTipVisibleChanged: (toolTipVisible) => {
        if(!toolTipVisible) {
            tasksRoot.toolTipOpen = false;
            tasksRoot.pinnedToolTipOpen = false;
        }
    }
    onAboutToShow: {
        updateToolTipBindings();
        if(showPreviews) tasksRoot.toolTipOpen = true;
        if(!showPreviews) tasksRoot.pinnedToolTipOpen = true;
    }

    function updateToolTipBindings() {
        taskThumbnail.parentTask = Qt.binding(() => task);

        taskThumbnail.demandsAttention = Qt.binding(() => model.IsDemandingAttention);
        taskThumbnail.minimized = Qt.binding(() => model.IsMinimized);
        taskThumbnail.display = Qt.binding(() => model.display);
        taskThumbnail.icon = Qt.binding(() => model.decoration);
        taskThumbnail.active = Qt.binding(() => model.IsActive);
        taskThumbnail.startup = Qt.binding(() => model.IsStartup)
        taskThumbnail.windows = Qt.binding(() => model.WinIdList);
        taskThumbnail.modelIndex = Qt.binding(() => task.modelIndex());
        taskThumbnail.taskIndex = Qt.binding(() => model.index);
        taskThumbnail.pidParent = Qt.binding(() => model.AppPid);
        taskThumbnail.launcherUrl = Qt.binding(() => model.LauncherUrlWithoutIcon);
        taskThumbnail.isGroupParent = Qt.binding(() => model.IsGroupParent);
        taskThumbnail.taskHovered = Qt.binding(() => dragArea.containsMouse);
    }
    // END TOOLTIP CODE

    activeFocusOnTab: true

    // To achieve a bottom to top layout, the task manager is rotated by 180 degrees(see main.qml).
    // This makes the tasks mirrored, so we mirror them again to fix that.
    rotation: Plasmoid.configuration.reverseMode && Plasmoid.formFactor === PlasmaCore.Types.Vertical ? 180 : 0

    implicitHeight: LayoutMetrics.preferredTaskHeight();
    implicitWidth: {
        if(tasksRoot.vertical) {
            return tasksRoot.width;
        } else {
            if(tasksRoot.iconsOnly || model.IsLauncher || model.IsStartup) {
                return LayoutMetrics.preferredMinLauncherWidth();
            } else {
                var minWidth = LayoutMetrics.preferredMinWidth();
                var maxWidth = LayoutMetrics.preferredMaxWidth();


                var taskCount = taskList.contentItem.visibleChildren.length;
                if(taskCount <= 1) taskCount = taskList.count
                if(taskCount < 0) taskCount = 0;
                var launcherCount = tasksModel.logicalLauncherCount;
                if(launcherCount === 0) launcherCount = 1;
                var currentWidth = Math.floor((taskList.width - (LayoutMetrics.preferredMinLauncherWidth()+16) * (launcherCount)) / (taskList.count - tasksModel.logicalLauncherCount));
                return Math.min(maxWidth, Math.max(minWidth, currentWidth));
            }
        }
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }

    SequentialAnimation {
        id: addLabelsAnimation
        NumberAnimation { target: task; properties: "opacity"; to: 1; duration: 200; easing.type: Easing.OutQuad }
        PropertyAction { target: task; property: "visible"; value: true }
        PropertyAction { target: task; property: "state"; value: "" }
    }
    SequentialAnimation {
        id: removeLabelsAnimation
        NumberAnimation { target: task; properties: "width"; to: 0; duration: 200; easing.type: Easing.OutQuad }
        PropertyAction { target: task; property: "ListView.delayRemove"; value: false }
    }
    SequentialAnimation {
        id: removeIconsAnimation
        NumberAnimation { target: task; properties: "opacity"; to: 0; duration: 200; easing.type: Easing.OutQuad }
        PropertyAction { target: task; property: "ListView.delayRemove"; value: false }
    }

    required property var model
    required property int index
    required property Item tasksRoot

    readonly property int pid: model.AppPid
    readonly property string appName: model.AppName
    readonly property string appId: model.AppId.replace(/\.desktop/, '')
    readonly property bool isIcon: tasksRoot.iconsOnly || model.IsLauncher
    property bool isLauncher: model.IsLauncher
    property bool isWindow: model.IsWindow
    property int childCount: model.ChildCount
    property int previousChildCount: 0
    property alias labelText: label.text
    property alias mouseArea: dragArea
    property QtObject contextMenu: null
    property QtObject jumpList: null // Pointer to the reimplemented context menu.
    property bool jumpListOpen: jumpList !== null
    property bool wasActive: false

    property bool showPreviews: Plasmoid.configuration.showPreviews && !model.IsLauncher && model.IsWindow

    onJumpListOpenChanged: {
        if(jumpList !== null) {
            Qt.callLater(() => { Plasmoid.setMouseGrab(true, jumpList); } );
        } else {
            task.wasActive = false;
        }
        if(jumpListOpen) {
            task.hideImmediately();
            tasksRoot.toolTipOpen = false;
            tasksRoot.pinnedToolTipOpen = false;
        }
    }
    readonly property bool smartLauncherEnabled: !model.IsStartup
    property QtObject smartLauncherItem: null
    property Item audioStreamIcon: null
    property var audioStreams: []
    property bool delayAudioStreamIndicator: false
    property bool completed: false
    readonly property bool hasAudioStream: audioStreams.length > 0
    readonly property bool playing: hasAudioStream && audioStreams.some(function (item) {
        return !item.corked
    })
    readonly property bool muted: hasAudioStream && audioStreams.every(function (item) {
        return item.muted
    })

    readonly property bool highlighted: dragArea.containsMouse
        || (task.contextMenu && task.contextMenu.status === PlasmaExtras.Menu.Open)
        || (task.jumpList)
        //|| tasksRoot.toolTipOpen && taskThumbnail?.taskIndex == model.index

    readonly property bool animateLabel: (!model.IsStartup && !model.IsLauncher) && !tasksRoot.iconsOnly
    readonly property bool shouldHideOnRemoval: model.IsStartup || model.IsLauncher
    ListView.onRemove: {
            if (tasksRoot.containsMouse && index != tasksModel.count &&
                task.model.WinIdList.length > 0 &&
                taskClosedWithMouseMiddleButton.indexOf(item.winIdList[0]) > -1) {
                tasksRoot.needLayoutRefresh = true;
            }
            taskClosedWithMouseMiddleButton = [];
            if(shouldHideOnRemoval) {
                taskList.add = null;
                taskList.resetAddTransition.start();
            }
            if(animateLabel) { // Closing animation for tasks with labels
                taskList.displaced = null;
                ListView.delayRemove = true;
                taskList.resetTransition.start();
                removeLabelsAnimation.start();
            }
    }
    ListView.onAdd: {
        if(model.IsStartup && !taskInLauncherList(appId)) {
            task.implicitWidth = 0;
            task.visible = false;
        }
        if(shouldHideOnRemoval) {
            taskList.add = null;
            taskList.resetAddTransition.start();
        }
        if(animateLabel) {
            task.visible = false;
            task.state = "animateLabels";
            addLabelsAnimation.start();
        }
        layoutDelay.start()
    }
    states: [
        State {
            name: "animateLabels"
            PropertyChanges { target: task; implicitWidth: 0 }
        }
    ]

    property alias leftTapHandler: leftTapHandler

    Accessible.name: model.display
    Accessible.description: {
        if (!model.display) {
            return "";
        }

        if (model.IsLauncher) {
            return i18nc("@info:usagetip %1 application name", "Launch %1", model.display)
        }

        let smartLauncherDescription = "";

        if (model.IsGroupParent) {
            switch (Plasmoid.configuration.groupedTaskVisualization) {
            case 0:
                break; // Use the default description
            case 1: {
                if (Plasmoid.configuration.showToolTips) {
                    return `${i18nc("@info:usagetip %1 task name", "Show Task tooltip for %1", model.display)}; ${smartLauncherDescription}`;
                }
                // fallthrough
            }
            case 2: {
                if (effectWatcher.registered) {
                    return `${i18nc("@info:usagetip %1 task name", "Show windows side by side for %1", model.display)}; ${smartLauncherDescription}`;
                }
                // fallthrough
            }
            default:
                return `${i18nc("@info:usagetip %1 task name", "Open textual list of windows for %1", model.display)}; ${smartLauncherDescription}`;
            }
        }

        return `${i18n("Activate %1", model.display)}; ${smartLauncherDescription}`;
    }
    Accessible.role: Accessible.Button
    Accessible.onPressAction: leftTapHandler.leftClick()

    onHighlightedChanged: {
        // ensure it doesn't get stuck with a window highlighted
        tasksRoot.cancelHighlightWindows();
    }

    onPidChanged: updateAudioStreams({delay: false})
    onAppNameChanged: updateAudioStreams({delay: false})

    onIsWindowChanged: {
        if (model.IsWindow) {
            taskInitComponent.createObject(task);
            updateAudioStreams({delay: false});
        }
    }

    onChildCountChanged: {
        if (TaskTools.taskManagerInstanceCount < 2 && childCount > previousChildCount) {
            tasksModel.requestPublishDelegateGeometry(modelIndex(), backend.globalRect(task), task);
        }

        previousChildCount = childCount;
        containerRect.loadingNewInstance = false;
    }

    onIndexChanged: {
        if (!tasksRoot.vertical
                && !Plasmoid.configuration.separateLaunchers) {
            tasksRoot.requestLayout();
        }
    }

    onSmartLauncherEnabledChanged: {
        if (smartLauncherEnabled && !smartLauncherItem) {
            const smartLauncher = Qt.createQmlObject(`
import org.kde.plasma.private.taskmanager as TaskManagerApplet

TaskManagerApplet.SmartLauncherItem { }
`, task);

            smartLauncher.launcherUrl = Qt.binding(() => model.LauncherUrlWithoutIcon);

            smartLauncherItem = smartLauncher;
        }
    }

    Keys.onMenuPressed: contextMenuTimer.start()
    Keys.onReturnPressed: TaskTools.activateTask(modelIndex(), model, event.modifiers, task, Plasmoid, tasksRoot, effectWatcher.registered)
    Keys.onEnterPressed: Keys.returnPressed(event);
    Keys.onSpacePressed: Keys.returnPressed(event);
    Keys.onUpPressed: Keys.leftPressed(event)
    Keys.onDownPressed: Keys.rightPressed(event)
    Keys.onLeftPressed: if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier)) {
                            tasksModel.move(task.index, task.index - 1);
                        } else {
                            event.accepted = false;
                        }
    Keys.onRightPressed: if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier)) {
                             tasksModel.move(task.index, task.index + 1);
                         } else {
                             event.accepted = false;
                         }

    function modelIndex() {
        return tasksModel.makeModelIndex(index);
    }

    function showControlMenu(args) {
        moreMenu.openRelative();
    }
    function showContextMenu(args) {
        if(task.toolTipVisible) task.hideImmediately();
        if(Plasmoid.configuration.disableJumplists) {
            contextMenuTimer.showNormalMenu = true;
            contextMenuTimer.start();
        } else {
            if(model.IsActive) task.wasActive = true;
            var mIndex = modelIndex();
            jumpList = tasksRoot.createJumpList(task, mIndex, args);
            jumpList.menuDecoration = model.decoration;
            jumpListDebouncer.start();
            Qt.callLater(() => { jumpList.show(); tasksRoot.jumpListItem = jumpList; });
        }
    }

    function showFallbackContextMenu(args) {
        contextMenu = tasksRoot.createContextMenu(task, modelIndex(), args);
        contextMenu.show();
    }
    property PlasmaExtras.Menu moreMenu: PlasmaExtras.Menu {
        id: moreActionsMenu
        visualParent: task

        placement: {
            if (Plasmoid.location === PlasmaCore.Types.LeftEdge) {
                return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
            } else if (Plasmoid.location === PlasmaCore.Types.TopEdge) {
                return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
            } else if (Plasmoid.location === PlasmaCore.Types.RightEdge) {
                return PlasmaExtras.Menu.LeftPosedTopAlignedPopup;
            } else {
                return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
            }
        }
        PlasmaExtras.MenuItem {
            enabled: model.IsMovable //tasksMenu.get(atm.IsMovable)

            text: i18n("&Move")
            icon: "transform-move"

            onClicked: tasksModel.requestMove(modelIndex())
        }

        PlasmaExtras.MenuItem {
            enabled: model.IsResizable

            text: i18n("Re&size")
            icon: "transform-scale"

            onClicked: tasksModel.requestResize(modelIndex())
        }

        PlasmaExtras.MenuItem {
            visible: !model.IsLauncher && !model.IsStartup

            enabled: model.IsMaximizable

            checkable: true
            checked: model.IsMaximized

            text: i18n("Ma&ximize")
            icon: "window-maximize"

            onClicked: tasksModel.requestToggleMaximized(modelIndex())
        }

        PlasmaExtras.MenuItem {
            visible: (!model.IsLauncher && !model.IsStartup)

            enabled: model.IsMinimizable

            checkable: true
            checked: model.IsMinimized

            text: i18n("Mi&nimize")
            icon: "window-minimize"

            onClicked: tasksModel.requestToggleMinimized(modelIndex())
        }

        PlasmaExtras.MenuItem {
            checkable: true
            checked: model.IsKeepAbove

            text: i18n("Keep &Above Others")
            icon: "window-keep-above"

            onClicked: tasksModel.requestToggleKeepAbove(modelIndex())
        }

        PlasmaExtras.MenuItem {
            checkable: true
            checked: model.IsKeepBelow

            text: i18n("Keep &Below Others")
            icon: "window-keep-below"

            onClicked: tasksModel.requestToggleKeepBelow(modelIndex())
        }

        PlasmaExtras.MenuItem {
            enabled: model.IsFullScreenable

            checkable: true
            checked: model.IsFullScreen

            text: i18n("&Fullscreen")
            icon: "view-fullscreen"

            onClicked: tasksModel.requestToggleFullScreen(modelIndex())
        }

        PlasmaExtras.MenuItem {
            enabled: model.IsShadeable

            checkable: true
            checked: model.IsShaded

            text: i18n("&Shade")
            icon: "window-shade"

            onClicked: tasksModel.requestToggleShaded(modelIndex())
        }

        PlasmaExtras.MenuItem {
            separator: true
        }

        PlasmaExtras.MenuItem {
            visible: (Plasmoid.configuration.groupingStrategy !== 0) && model.IsWindow

            checkable: true
            checked: model.IsGroupable

            text: i18n("Allow this program to be grouped")
            icon: "view-group"

            onClicked: tasksModel.requestToggleGrouping(modelIndex())
        }
        PlasmaExtras.MenuItem {
            id: closeWindowItem
            visible: !model.IsLauncher && !model.IsStartup

            enabled: model.IsClosable

            text: model.IsGroupParent ? "Close all windows" : "Close window"
            icon: "window-close"

            onClicked: {
                tasksModel.requestClose(modelIndex());
            }
        }

    }


    function updateAudioStreams(args) {
        if (args) {
            // When the task just appeared (e.g. virtual desktop switch), show the audio indicator
            // right away. Only when audio streams change during the lifetime of this task, delay
            // showing that to avoid distraction.
            delayAudioStreamIndicator = !!args.delay;
        }

        var pa = pulseAudio.item;
        if (!pa || !task.isWindow) {
            task.audioStreams = [];
            return;
        }

        // Check appid first for app using portal
        // https://docs.pipewire.org/page_portal.html
        var streams = pa.streamsForAppId(task.appId);
        if (!streams.length) {
            streams = pa.streamsForPid(model.AppPid);
            if (streams.length) {
                pa.registerPidMatch(model.AppName);
            } else {
                // We only want to fall back to appName matching if we never managed to map
                // a PID to an audio stream window. Otherwise if you have two instances of
                // an application, one playing and the other not, it will look up appName
                // for the non-playing instance and erroneously show an indicator on both.
                if (!pa.hasPidMatch(model.AppName)) {
                    streams = pa.streamsForAppName(model.AppName);
                }
            }
        }

        task.audioStreams = streams;
    }

    function toggleMuted() {
        if (muted) {
            task.audioStreams.forEach(function (item) { item.unmute(); });
        } else {
            task.audioStreams.forEach(function (item) { item.mute(); });
        }
    }

    Connections {
        target: pulseAudio.item
        ignoreUnknownSignals: true // Plasma-PA might not be available
        function onStreamsChanged() {
            task.updateAudioStreams({delay: true})
        }
    }

    Timer {
        id: jumpListDebouncer
        interval: 500
        onTriggered: { }
    }
    TapHandler {
        id: menuTapHandler
        acceptedButtons: Qt.LeftButton
        acceptedModifiers: Qt.NoModifier
        acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Stylus
        onLongPressed: {
            if(contextMenuTimer.showNormalMenu) {
                if(model.IsStartup) return;

                contextMenuTimer.showNormalMenu = false;
                showFallbackContextMenu({showAllPlaces: true});
            }
            else {
                if(model.IsStartup) return;
                // When we're a launcher, there's no window controls, so we can show all
                // places without the menu getting super huge.
                if (model.IsLauncher) {
                    showFallbackContextMenu({showAllPlaces: true});
                } else {
                    showControlMenu();
                }
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedModifiers: Qt.NoModifier
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
        gesturePolicy: TapHandler.WithinBounds // Release grab when menu appears
        onPressedChanged: {
            if(model.IsStartup) return;
            if(pressed && !jumpListDebouncer.running) {
                if (model.IsLauncher) {
                    showContextMenu({showAllPlaces: true});
                } else {
                    showContextMenu();
                }
            }
        }
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
        acceptedModifiers: Qt.ShiftModifier
        gesturePolicy: TapHandler.WithinBounds // Release grab when menu appears
        onPressedChanged: if (pressed && !jumpListDebouncer.running) contextMenuTimer.start()
    }

    Timer {
        id: contextMenuTimer
        property bool showNormalMenu: false
        interval: 0
        onTriggered: menuTapHandler.longPressed()
    }

    TapHandler {
        id: leftTapHandler
        acceptedButtons: Qt.LeftButton
        onTapped: leftClick()

        function leftClick() {

            if(tasksRoot.pinnedToolTipOpen) {
                task.hideImmediately();
                tasksRoot.pinnedToolTipOpen = false;
            }

            TaskTools.activateTask(modelIndex(), model, point.modifiers, task, Plasmoid, tasksRoot, effectWatcher.registered);
        }
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
        onTapped: (eventPoint, button) => {
                      if (button === Qt.MiddleButton) {
                          if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.NewInstance) {
                              tasksModel.requestNewInstance(modelIndex());
                              containerRect.loadingNewInstance = true;
                          } else if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.Close) {
                              tasksRoot.taskClosedWithMouseMiddleButton = model.WinIdList.slice()
                              tasksModel.requestClose(modelIndex());
                          } else if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.ToggleMinimized) {
                              tasksModel.requestToggleMinimized(modelIndex());
                          } else if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.ToggleGrouping) {
                              tasksModel.requestToggleGrouping(modelIndex());
                          } else if (Plasmoid.configuration.middleClickAction === TaskManagerApplet.Backend.BringToCurrentDesktop) {
                              tasksModel.requestVirtualDesktops(modelIndex(), [virtualDesktopInfo.currentDesktop]);
                          }
                      } else if (button === Qt.BackButton || button === Qt.ForwardButton) {
                          const playerData = mpris2Source.playerForLauncherUrl(model.LauncherUrlWithoutIcon, model.AppPid);
                          if (playerData) {
                              if (button === Qt.BackButton) {
                                  playerData.Previous();
                              } else {
                                  playerData.Next();
                              }
                          } else {
                              eventPoint.accepted = false;
                          }
                      }

                      tasksRoot.cancelHighlightWindows();
                  }
    }
    Rectangle {
        id: containerRect

        anchors.top: parent.top
        anchors.left: parent.left
        width: task.width
        height: task.height

        color: "transparent"

        Drag.active: dragArea.held
        Drag.source: dragArea
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        property var previousState: ""
        transitions: [
            Transition {
                from: "*"; to: "*";
                NumberAnimation { properties: "x,y"; easing.type: Easing.InOutQuad }
            },
            Transition {
                from: "jumpListOpen"; to: "*";
                NumberAnimation { property: "opacity"; target: glow; to: 0; easing.type: Easing.Linear; duration: 200 }
                NumberAnimation { property: "opacity"; target: borderGradientRender; to: 0; easing.type: Easing.Linear; duration: 200 }
            },
            Transition {
                from: "*"; to: "startup"
                onRunningChanged: {
                    if(!running) {
                        animationGlow.opacity = 0;
                        glowAnimation.duration = 250;
                    }
                }
                NumberAnimation { properties: "opacity"; easing.type: Easing.Linear; duration: 200 }
                SequentialAnimation {
                    NumberAnimation {
                        target: animationGlow
                        property: "verticalRadius"
                        to: task.height * 1.5
                        duration: 367
                        easing.type: Easing.Linear
                    }
                    PropertyAction { target: glowAnimation; property: "duration"; value: 1000 }
                    ParallelAnimation {
                        NumberAnimation {
                            target: animationGlow
                            property: "verticalRadius"
                            to: task.height * 0.7
                            duration: 1000
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: glow
                            property: "canShow"
                            to: 1
                            duration: 700
                            easing.type: Easing.Linear
                        }

                    }
                    PropertyAction { target: glowAnimation; property: "duration"; value: 250 }
                }
                SequentialAnimation {
                    id: startupAnimation
                    NumberAnimation {
                        target: animationGlow
                        property: "horizontalRadius"
                        to: task.width * 1.1
                        duration: 367
                        easing.type: Easing.Linear
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: animationGlow
                            property: "opacity"
                            to: 0
                            duration: 1000
                        }
                        NumberAnimation {
                            target: animationGlow
                            property: "horizontalRadius"
                            to: task.width * 0.7
                            duration: 1000
                            easing.type: Easing.InOutQuad
                        }
                    }
                    NumberAnimation {
                        target: animationGlow
                        property: "opacity"
                        to: 0
                        duration: 3000
                    }
                    ParallelAnimation {
                        id: fadeOutFrame
                        PropertyAction { target: glow; property: "canShow"; value: model.IsStartup ? 0 : 1; }
                        NumberAnimation {
                            target: frame
                            property: "opacity"
                            to: model.IsStartup ? 0 : 1
                            duration: 500
                            easing.type: Easing.Linear
                        }
                        NumberAnimation {
                            target: animationGlow
                            property: "opacity"
                            to: 0
                            duration: 3000
                        }
                    }
                }
            },
            Transition {
                from: "*"; to: "loaded";
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target: animationBorderGradient
                            property: "horizontalRadius"
                            to: task.width * 1.5
                            duration: 367
                            easing.type: Easing.InQuart
                        }
                        NumberAnimation {
                            target: animationBorderGradient
                            property: "opacity"
                            to: 1
                            duration: 250
                        }
                    }
                    NumberAnimation {
                        target: animationBorderGradient
                        property: "horizontalRadius"
                        to: task.width * 0.5
                        duration: 367
                        easing.type: Easing.Linear
                    }
                }
                SequentialAnimation {
                    NumberAnimation {
                        target: animationBorderGradient
                        property: "verticalRadius"
                        to: task.height * 1.5
                        duration: 367
                        easing.type: Easing.InQuart
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: animationBorderGradient
                            property: "opacity"
                            to: 0
                            duration: 250
                        }
                        NumberAnimation {
                            target: animationBorderGradient
                            property: "verticalRadius"
                            to: task.height * 0.5
                            duration: 367
                            easing.type: Easing.Linear
                        }

                    }
                    ScriptAction {

                        script: {
                            task.tasksRoot.animationManager.removeItem(task.appId)
                        }
                    }
                }
            }

        ]

        property bool loadingNewInstance: false
        states: [
        // Used for dragging
        State {
            name: "dragging"
            when: dragArea.held

            ParentChange {
                target: containerRect
                parent: tasksRoot
            }
            AnchorChanges {
                target: containerRect
                anchors {
                    top: undefined
                    left: undefined
                }
            }
        },
        State {
            name: "jumpListOpen"
            when: (jumpList !== null) && !Plasmoid.configuration.disableHottracking
            PropertyChanges {
                target: glow
                opacity: 1
                horizontalOffset: 0
            }
            PropertyChanges {
                target: borderGradientRender
                opacity: 1
                horizontalOffset: 0
            }
        },
        State {
            name: "startup"
            when: (model.IsStartup || containerRect.loadingNewInstance) && !Plasmoid.configuration.disableHottracking
            PropertyChanges {
                target: animationGlow
                opacity: 1
                horizontalOffset: 0
                horizontalRadius: 0
                verticalRadius: 0
            }
            PropertyChanges {
                target: borderGradientRender
                opacity: 0
                horizontalOffset: 0
            }
            StateChangeScript {
                script: {
                    task.tasksRoot.animationManager.addItem(task.appId);
                }
            }
        },
        State {
            name: "loaded"
            when: !(model.IsStartup || model.IsLauncher) && task.tasksRoot.animationManager.getItem(task.appId) && !Plasmoid.configuration.disableHottracking
            PropertyChanges {
                target: animationBorderGradient
                opacity: 0
                horizontalRadius: 0
                verticalRadius: 0
            }
            PropertyChanges {
                target: frame
                opacity: 1
            }
            PropertyChanges {
                target: glowAnimation
                duration: 250
            }
        }

        ]

        KSvg.FrameSvgItem {
            id: launcherFrame

            anchors {
                fill: parent
            }

            imagePath: Qt.resolvedUrl("svgs/tabbar.svgz")
            visible: model.IsLauncher// && !task.containsMouseFalsePositive
            prefix: {
                if(dragArea.held || dragArea.containsPress) return "pressed-tab";
                else if(dragArea.containsMouse) return "active-tab";
                else return "";
            }
        }

        property color glowColor: "#33c2ff"
        property color glowColorCenter: Qt.tint("#eaeaea", opacify(glowColor, 0.2))
        property color attentionColor: "#ecc656"//"#e7de62"//"#FF7E00"
        property color attentionColorCenter: Qt.tint("#fefefe", opacify(attentionColor, 0.2))
        property color attentionColorEnd: "#ffe516";

        function opacify(col, factor) {
            return Qt.rgba(col.r, col.g, col.b, factor);
        }
        Rectangle {
            id: borderGradient
            anchors.fill: frame
            anchors.margins: 1
            color: "transparent"
            border.color: "red"
            border.width: 2
            opacity: 0
            radius: 3
        }
        RadialGradient {
            id: animationGlow
            anchors.fill: parent
            anchors.margins: 2
            visible: !Plasmoid.configuration.disableHottracking
            //visible: model.IsStartup
            opacity: 0//frame.isHovered && !dragArea.held ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.Linear }
            }
            gradient: Gradient {
                GradientStop { position: 0.0; color: containerRect.glowColorCenter }
                GradientStop { position: 0.5; color: containerRect.opacify(containerRect.glowColor, 0.75) }
                GradientStop { position: 0.75; color: containerRect.opacify(containerRect.glowColor, 0.40) }
                GradientStop { position: 1; color: containerRect.opacify(containerRect.glowColor, 0.15) }
            }
            horizontalRadius: task.width * 1.2
            verticalRadius: task.height * 1.1
            verticalOffset: parent.height / 2
            horizontalOffset: 0//dragArea.mouseX - task.width / 2
        }
        RadialGradient {
            id: glow
            anchors.fill: parent
            anchors.margins: 2
            visible: !model.IsLauncher && !Plasmoid.configuration.disableHottracking
            property bool shouldShow: ((frame.isHovered && !dragArea.held && !(attentionFadeIn.running || attentionFadeOut.running)) ? 1 : 0) * canShow
            opacity: shouldShow ? 1 : 0
            property real canShow: containerRect.state === "startup" ? 0 : 1 // Used for the startup animation

            onShouldShowChanged: {
                opacity = Qt.binding(() => {return glow.shouldShow; });
            }
            Behavior on opacity {
                NumberAnimation { id: glowAnimation; duration: 250; easing.type: Easing.Linear }
            }
            Behavior on horizontalOffset {
                NumberAnimation { duration: containerRect.state === "jumpListOpen" ? 250 : 0; easing.type: Easing.Linear }
            }
            gradient: Gradient {
                GradientStop { position: 0.0; color: containerRect.glowColorCenter }
                GradientStop { position: 0.5; color: containerRect.opacify(containerRect.glowColor, 0.75) }
                GradientStop { position: 0.75; color: containerRect.opacify(containerRect.glowColor, 0.40) }
                GradientStop { position: 1; color: containerRect.opacify(containerRect.glowColor, 0.15) }
            }
            horizontalRadius: task.width * 1.2
            verticalRadius: task.height * 1.1
            verticalOffset: parent.height / 2
            horizontalOffset: dragArea.mouseX - task.width / 2
        }
        RadialGradient {
            id: animationBorderGradient
            anchors.fill: borderGradient
            source: borderGradient
            visible: !Plasmoid.configuration.disableHottracking
            opacity: 0
            gradient: Gradient {
                GradientStop { position: 0.0; color: containerRect.glowColorCenter }
                GradientStop { position: 0.3; color: containerRect.glowColor }
            }
            verticalOffset: parent.height / 2
            verticalRadius: task.height * 1.5
            horizontalRadius: task.width * 1.5
            horizontalOffset: 0//dragArea.mouseX - task.width / 2
        }
        RadialGradient {
            id: borderGradientRender
            anchors.fill: borderGradient
            source: borderGradient
            visible: !model.IsLauncher && !Plasmoid.configuration.disableHottracking
            property bool shouldShow: (frame.isHovered && !dragArea.held && !(attentionFadeIn.running || attentionFadeOut.running)) ? 1 : 0
            opacity: shouldShow ? 1 : 0

            onShouldShowChanged: {
                opacity = Qt.binding(() => {return borderGradientRender.shouldShow; });
            }
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.Linear }
            }
            Behavior on horizontalOffset {
                NumberAnimation { duration: containerRect.state === "jumpListOpen" ? 250 : 0; easing.type: Easing.Linear }
            }
            gradient: Gradient {
                GradientStop { position: 0.0; color: containerRect.glowColorCenter }
                GradientStop { position: 0.5; color: containerRect.glowColor }
                GradientStop { position: 1.0; color: containerRect.opacify(containerRect.glowColor, 0.1) }
            }
            verticalOffset: parent.height / 2
            verticalRadius: task.height * 1.5
            horizontalRadius: task.width * 1.5
            horizontalOffset: dragArea.mouseX - task.width / 2
        }
        Rectangle {
            id: attentionIndicator
            anchors.fill: parent
            visible: !Plasmoid.configuration.disableHottracking
            anchors.rightMargin: (task.childCount !== 0) ? groupIndicator.margins.right : 0
            property bool requiresAttention: model.IsDemandingAttention || (task.smartLauncherItem && task.smartLauncherItem.urgent)
            color: "transparent"
            Rectangle {
                id: attentionBorder
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.color: "red"
                border.width: 2
                opacity: 0
                radius: 3
            }
            RadialGradient {
                id: attentionGlow
                anchors.fill: parent
                anchors.margins: 2
                opacity: 0
                /*Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.Linear }
                }*/
                gradient: Gradient {
                    GradientStop { position: 0.0; color: containerRect.attentionColorCenter }
                    GradientStop { position: 0.5; color: containerRect.attentionColor }
                    GradientStop { position: 1.0; color: containerRect.attentionColorEnd }
                }
                horizontalRadius: task.width * 1.2
                verticalRadius: task.height * 1.1
                verticalOffset: parent.height / 2
                horizontalOffset: 0//dragArea.mouseX - task.width / 2
            }

            RadialGradient {
                id: attentionBorderGradient
                anchors.fill: attentionBorder
                source: attentionBorder
                opacity: 0
                gradient: Gradient {
                    GradientStop { position: 0.0; color: containerRect.attentionColorCenter }
                    GradientStop { position: 0.6; color: Qt.lighter(containerRect.attentionColor, 1.1) }
                    GradientStop { position: 0.7; color: Qt.lighter(containerRect.attentionColorEnd, 1.2) }
                }
                verticalOffset: parent.height / 2
                verticalRadius: task.height * 1.5
                horizontalRadius: task.width * 1.5
                horizontalOffset: 0//dragArea.mouseX - task.width / 2
            }
            transitions: [
                Transition {
                    id: attentionFadeOut
                    from: "wantsAttention"; to: "*";
                    NumberAnimation {
                        target: attentionGlow
                        property: "opacity"
                        from: 1
                        to: 0
                        easing.type: Easing.Linear
                        duration: 800
                    }
                    NumberAnimation {
                        target: attentionBorderGradient
                        property: "opacity"
                        from: 1
                        to: 0
                        easing.type: Easing.Linear
                        duration: 500
                    }
                    PropertyAction {
                        target: attentionFrame
                        property: "opacity"
                        value: 0
                    }
                },
                Transition {
                    id: attentionFadeIn
                    from: "*"; to: "wantsAttention";
                    SequentialAnimation {
                        NumberAnimation {
                            target: attentionGlow
                            property: "opacity"
                            to: 1
                            easing.type: Easing.Linear
                            duration: 100
                        }
                        NumberAnimation {
                            target: attentionGlow
                            property: "opacity"
                            from: 1
                            to: 0
                            loops: 7
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [ 0.68, 0.0, 0.65, 0.0, 1.0, 1.0 ]
                            duration: 1400
                        }
                        PropertyAction {
                            target: attentionGlow
                            property: "opacity"
                            value: 1
                        }
                        SequentialAnimation {
                            loops: 2
                            ParallelAnimation {
                                NumberAnimation {
                                    target: attentionGlow
                                    property: "opacity"
                                    from: 1
                                    to: 0.33
                                    duration: 3000
                                    easing.type: Easing.Linear
                                }
                                NumberAnimation {
                                    target: attentionGlow
                                    property: "horizontalRadius"
                                    from: task.width * 1.2
                                    to: task.width * 0.75
                                    duration: 3000
                                    easing.type: Easing.Linear
                                }
                                NumberAnimation {
                                    target: attentionGlow
                                    property: "verticalRadius"
                                    from: task.height * 1.1
                                    to: task.height * 0.66
                                    duration: 3000
                                    easing.type: Easing.Linear
                                }

                            }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: attentionGlow
                                    property: "opacity"
                                    from: 0.33
                                    to: 1
                                    duration: 3000
                                    easing.type: Easing.Linear
                                }
                                NumberAnimation {
                                    target: attentionGlow
                                    property: "horizontalRadius"
                                    to: task.width * 1.2
                                    from: task.width * 0.75
                                    duration: 3000
                                    easing.type: Easing.Linear
                                }
                                NumberAnimation {
                                    target: attentionGlow
                                    property: "verticalRadius"
                                    to: task.height * 1.1
                                    from: task.height * 0.66
                                    duration: 3000
                                    easing.type: Easing.Linear
                                }

                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: attentionGlow
                                property: "opacity"
                                to: 0
                                duration: 3000
                                easing.type: Easing.Linear
                            }
                            NumberAnimation {
                                target: attentionGlow
                                property: "horizontalRadius"
                                to: task.width * 0.75
                                duration: 3000
                                easing.type: Easing.Linear
                            }
                            NumberAnimation {
                                target: attentionGlow
                                property: "verticalRadius"
                                to: task.height * 0.66
                                duration: 3000
                                easing.type: Easing.Linear
                            }
                        }

                    }

                    SequentialAnimation {
                        NumberAnimation {
                            target: attentionBorderGradient
                            property: "opacity"
                            to: 1
                            easing.type: Easing.Linear
                            duration: 100
                        }
                        NumberAnimation {
                            target: attentionBorderGradient
                            property: "opacity"
                            from: 1
                            to: 0
                            loops: 7
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: [ 0.68, 0.0, 0.65, 0.0, 1.0, 1.0 ]
                            duration: 1400
                        }
                        PropertyAction {
                            target: attentionBorderGradient
                            property: "opacity"
                            value: 1
                        }
                        SequentialAnimation {
                            loops: 2
                            NumberAnimation {
                                target: attentionBorderGradient
                                property: "opacity"
                                from: 1
                                to: 0.15
                                duration: 3000
                                easing.type: Easing.Linear
                            }
                            NumberAnimation {
                                target: attentionBorderGradient
                                property: "opacity"
                                from: 0.15
                                to: 1
                                duration: 3000
                                easing.type: Easing.Linear
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: attentionBorderGradient
                                property: "opacity"
                                to: 0
                                duration: 3000
                                easing.type: Easing.Linear
                            }
                            NumberAnimation {
                                target: attentionFrame
                                property: "opacity"
                                to: 1
                                duration: 3000
                                easing.type: Easing.InCubic
                            }

                        }

                    }
                }
            ]
            states: [
                State {
                    name: "wantsAttention"
                    when: attentionIndicator.requiresAttention
                    PropertyChanges {
                        target: attentionGlow
                        opacity: 0
                    }

                }
            ]
            KSvg.FrameSvgItem {
                id: attentionFrame
                anchors.fill: parent
                imagePath: Qt.resolvedUrl("svgs/tasks.svg")
                prefix: "attention"
                opacity: 0
            }
        }
        KSvg.FrameSvgItem {
            id: frame

            anchors {
                fill: parent
                rightMargin: (task.childCount !== 0) ? groupIndicator.margins.right : 0
            }
            imagePath: Qt.resolvedUrl("svgs/tasks.svg")
            property bool isHovered: ((task.highlighted) && Plasmoid.configuration.taskHoverEffect)
            property bool isActive: model.IsActive || dragArea.containsPress || dragArea.held || task.wasActive
            property string basePrefix: {
                if(model.IsLauncher) return "";
                if(attentionIndicator.requiresAttention && Plasmoid.configuration.disableHottracking) return "attention";
                if(isActive && !(attentionIndicator.requiresAttention || attentionFadeOut.running)) return "active";
                return "normal";
            }
            prefix: (basePrefix + ((isHovered && !attentionIndicator.requiresAttention) ? "-hover" : ""))

            KSvg.FrameSvgItem {
                id: groupIndicator
                imagePath: Qt.resolvedUrl("svgs/tasks.svg")
                anchors.fill: parent
                anchors.rightMargin: -groupIndicator.margins.right
                prefix: {
                    if(task.childCount == 0) return "";
                    var result = "group";
                    if(frame.isActive) result = "active-" + result;
                    if(task.childCount > 2) {
                        result += "3";
                    }
                    return result;
                }
            }

        }

        Loader {
            id: taskProgressOverlayLoader

            anchors.fill: frame
            anchors.margins: -1
            asynchronous: true
            active: model.IsWindow && task.smartLauncherItem && task.smartLauncherItem.progressVisible

            source: "TaskProgressOverlay.qml"

            z: -1
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            anchors.fill: frame
            anchors.margins: Kirigami.Units.smallSpacing
            anchors.rightMargin: (!label.visible ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing) - ((dragArea.containsPress || dragArea.held) ? 1 : 0)
            anchors.leftMargin:  !label.visible ? Kirigami.Units.smallSpacing : Kirigami.Units.mediumSpacing
            Kirigami.Icon {
                id: iconBox
                property int iconSize: {
                    if(tasksRoot.height <= 30) {
                        return Kirigami.Units.iconSizes.small;
                    }
                    return Kirigami.Units.iconSizes.medium;
                }
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Layout.minimumWidth: iconSize
                Layout.maximumWidth: iconSize
                Layout.minimumHeight: iconSize
                Layout.maximumHeight: iconSize

                Layout.leftMargin: (label.visible ? Kirigami.Units.smallSpacing : 0) + ((dragArea.containsPress || dragArea.held) ? 1 : 0)
                Layout.topMargin: ((dragArea.containsPress || dragArea.held) ? 1 : 0)
                source: model.decoration
                antialiasing: false

                onSourceChanged: {
                    containerRect.glowColor = Plasmoid.getDominantColor(iconBox.source);
                    badge.badgeColor = containerRect.glowColor
                }

                Badge {
                    id: badge
                    visible: task.smartLauncherItem && task.smartLauncherItem.countVisible
                    number: task.smartLauncherItem.count
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: (tasksRoot.height <= 30) ? -Kirigami.Units.largeSpacing : -Kirigami.Units.smallSpacing
                    anchors.topMargin: (tasksRoot.height <= 30) ? -Kirigami.Units.smallSpacing : 0
                    Component.onCompleted: {
                        badgeColor = containerRect.glowColor
                    }
                }
            }

            PlasmaComponents3.Label {
                id: label

                visible: (!iconsOnly && !model.IsLauncher
                    && (parent.width - iconBox.height - Kirigami.Units.smallSpacing) >= LayoutMetrics.spaceRequiredToShowText())
                Layout.topMargin: ((dragArea.containsPress || dragArea.held) ? 1 : 0)
                Layout.fillWidth: true
                Layout.fillHeight: true

                wrapMode: (maximumLineCount == 1) ? Text.NoWrap : Text.Wrap
                elide: Text.ElideRight
                textFormat: Text.PlainText
                verticalAlignment: Text.AlignVCenter
                maximumLineCount: 1//Plasmoid.configuration.maxTextLines || undefined
                style: Text.Outline
                styleColor: "#02ffffff"

                Accessible.ignored: true

                // use State to avoid unnecessary re-evaluation when the label is invisible
                states: State {
                    name: "labelVisible"
                    when: label.visible

                    PropertyChanges {
                        target: label
                        text: model.display
                    }
                }

            }

        }
    }

    ParallelAnimation {
        id: backAnim
        NumberAnimation { id: backAnimX; target: containerRect; property: "x"; easing.type: Easing.OutQuad }
        NumberAnimation { id: backAnimY; target: containerRect; property: "y"; easing.type: Easing.OutQuad }
    }
    Timer {
        id: resetDrag
        interval: 250
        onTriggered: {
            dragArea.held = false;
            dragArea.dragThreshold = Qt.point(-1,-1);
            //containerRect.parent = task;
        }
    }

    MouseArea {
        id: dragArea
        property alias taskIndex: task.index
        hoverEnabled: true
        enabled: ((tasksRoot.jumpListItem === jumpList) || (tasksRoot.jumpListItem === null))
        propagateComposedEvents: true
        anchors.fill: parent
        anchors.margins: -1

        onCanceled: {
            if(held) {
                sendItemBack();
            }
        }
        onContainsMouseChanged: {
            if(containsMouse) {
                if(task.toolTipVisible && !model.IsLauncher) {
                    if(taskThumbnail.pinned && !model.IsLauncher) return;
                    if(!taskThumbnail.pinned && model.IsLauncher) return;
                    task.updateToolTipBindings();
                }
            }
        }
        property bool held: false
        property point beginDrag
        property point currentDrag

        property point dragThreshold: Qt.point(-1,-1);

        onHeldChanged: {
            if(held) {
                tasksRoot.setRequestedInhibitDnd(true);
                tasksRoot.dragItem = task;
                tasksRoot.dragSource = task;
                dragHelper.Drag.mimeData = {
                    "text/x-orgkdeplasmataskmanager_taskurl": backend.tryDecodeApplicationsUrl(model.LauncherUrlWithoutIcon).toString(),
                    [model.MimeType]: model.MimeData,
                    "application/x-orgkdeplasmataskmanager_taskbuttonitem": model.MimeData,
                };
            } else {
                tasksRoot.setRequestedInhibitDnd(false);
                tasksRoot.dragItem = null;
            }

        }
        drag.smoothed: false
        drag.threshold: 0
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: tasks.width - task.width
        drag.maximumY: tasks.height - task.height
        drag.target: held ? containerRect : undefined
        drag.axis: {
            var result = Drag.XAxis | Drag.YAxis
            return result;
        }
        onPressed: event => {
            dragArea.beginDrag = Qt.point(task.x, task.y);
            dragThreshold = Qt.point(mouseX, mouseY);
        }
        onExited: {
            if((dragThreshold.x !== -1 && dragThreshold.y !== -1)) {
                held = true;
            }
        }
        onEntered: {
            //if(!held) Plasmoid.sendMouseEvent(dragArea);
        }
        onPositionChanged: {
            if(dragArea.containsPress && (dragThreshold.x !== -1 && dragThreshold.y !== -1)) {
                if(Math.abs(dragThreshold.x - mouseX) > 10 || Math.abs(dragThreshold.y - mouseY) > 10) {
                    held = true;
                }
            }
            currentDrag = Qt.point(containerRect.x, containerRect.y);
        }
        function sendItemBack() {
            beginDrag = Qt.point(task.x, task.y);
            backAnimX.from = currentDrag.x //- taskList.contentX;
            backAnimX.to = beginDrag.x - taskList.contentX;
            backAnimY.from = currentDrag.y// - taskList.contentY;
            backAnimY.to = beginDrag.y - taskList.contentY;
            backAnim.start();
            resetDrag.start();
            dragThreshold = Qt.point(-1,-1);
        }
        onReleased: event => {
            if(held) {
                sendItemBack();
            } else {
                leftTapHandler.leftClick();
                dragThreshold = Qt.point(-1,-1);
            }
            event.accepted = false;
        }
    }
    DropArea {
        id: dropArea
        visible: tasksRoot.dragItem !== null;
        anchors {
            fill: parent
            margins: 2
        }
        onExited: {
            dragArea.beginDrag = Qt.point(dragArea.x, dragArea.y);
        }
        onEntered: (drag) => {
            if(drag.source.taskIndex === task.index) return;
            tasksModel.move(drag.source.taskIndex, task.index);
        }
    }

    DropArea {
        signal urlsDropped(var urls)

        visible: !dropArea.visible // just to make sure it doesn't conflict with the dragging droparea

        anchors.fill: parent

        onPositionChanged: {
            if(model.ChildCount == 0) {
                if(task.toolTipVisible) {
                    taskThumbnail.dragDrop = false;
                }
            }
            activationTimer.restart();
        }

        onExited: {
            if(task.toolTipVisible) {
                taskThumbnail.dragDrop = false;
            }
            activationTimer.stop();
        }

        onDropped: event => {
            // Reject internal drops.
            if (event.formats.indexOf("application/x-orgkdeplasmataskmanager_taskbuttonitem") >= 0) {
                event.accepted = false;
                return;
            }

            // Reject plasmoid drops.
            if (event.formats.indexOf("text/x-plasmoidservicename") >= 0) {
                event.accepted = false;
                return;
            }

            if (event.hasUrls) {
                urlsDropped(event.urls);
                return;
            }
        }

        onUrlsDropped: (urls) => {
            // If all dropped URLs point to application desktop files, we'll add a launcher for each of them.
            var createLaunchers = urls.every(function (item) {
                return backend.isApplication(item)
            });

            if (createLaunchers) {
                return;
            }

            // Otherwise we'll just start a new instance of the application with the URLs as argument,
            // as you probably don't expect some of your files to open in the app and others to spawn launchers.
            if(model.ChildCount == 0) {
                tasksModel.requestOpenUrls(task.modelIndex(), urls);
            } else if(model.ChildCount > 0) {
                if(task.toolTipVisible) {
                    taskThumbnail.dragDrop = false;
                }
            }
        }

        Timer {
            id: activationTimer

            interval: 250
            repeat: false

            onTriggered: {
                if(task.model.ChildCount > 0) {
                    if(!task.toolTipVisible) {
                        task.showToolTip();
                        taskThumbnail.dragDrop = true;
                        updateToolTipBindings();
                    }
                }
                else {
                    if(task.toolTipVisible) {
                        taskThumbnail.dragDrop = false;
                    }
                    tasksModel.requestActivate(modelIndex());
                }
            }
        }
    }

    Component.onCompleted: {
        if (model.IsWindow) {
            updateAudioStreams({delay: false});
        }

        if (!model.IsWindow) {
            taskInitComponent.createObject(task);
        }
        completed = true;

        taskThumbnail = tasksRoot.taskThumbnail;
    }
}
