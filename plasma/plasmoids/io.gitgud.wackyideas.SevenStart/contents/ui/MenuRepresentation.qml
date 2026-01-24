/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
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

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import QtCore

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras

import org.kde.plasma.private.kicker as Kicker
import org.kde.coreaddons 1.0 as KCoreAddons // kuser
import org.kde.kitemmodels as KItemModels

import org.kde.kwindowsystem 1.0
import org.kde.ksvg as KSvg
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

import Qt5Compat.GraphicalEffects

PlasmaCore.Dialog {
    id: root
    objectName: "popupWindow"
    location: "Floating" // To make the panel display all 4 borders, the panel will be positioned at a corner.
    flags: Qt.WindowStaysOnTopHint //| Qt.Popup // Set to popup so that it is still considered a plasmoid popup, despite being a floating dialog window.
	hideOnWindowDeactivate: true

	title: "sevenstart-menurepresentation"
    
    backgroundHints: PlasmaCore.Types.NoBackground

    property int iconSize: Kirigami.Units.iconSizes.medium
    property int iconSizeSide: Kirigami.Units.iconSizes.smallMedium
    property int cellWidth: 254 // Width for all standard menu items.
    property int cellWidthSide: 139 // Width for sidebar menu items.
    property int cellHeight: iconSize + Kirigami.Units.smallSpacing + (Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                    				   highlightItemSvg.margins.left + highlightItemSvg.margins.right)) - Kirigami.Units.smallSpacing/2
	property int cellCount: Plasmoid.configuration.numberRows + faves.getFavoritesCount()
    property bool searching: (searchField.text != "")
    property bool showingAllPrograms: false
    property bool firstTimePopup: false // To make sure the user icon is displayed properly.
    property bool firstTimeShadowSetup: false

    property int animationDuration: Kirigami.Units.longDuration*1.5

	property color leftPanelBackgroundColor: "white"
	property color leftPanelBorderColor: "#44000000"
	property color leftPanelSeparatorColor: "#d6e5f5"
	property color searchPanelSeparatorColor: "#cddbea"
	property color searchPanelBackgroundColor: "#f1f5fb"

	property color searchFieldBackgroundColor: "white"
	property color searchFieldTextColor: "black"
	property color searchFieldPlaceholderColor: "#707070"

	property color shutdownTextColor: "#202020"

	// A bunch of references for easier access by child QML elements
	property alias m_mainPanel: leftSidebar
	property alias m_bottomControls: bottomControls
	property alias m_allApps: appsView
	property alias m_recents: recents
	property alias m_faves: faves
	property alias m_showAllButton: allButtonsArea
	property alias m_shutDownButton: shutdown
	property alias m_lockButton: lockma
	property alias m_searchField: searchField
	property alias m_delayTimer: delayTimer
	property alias dialogBackgroundTexture: dialogBackground

	property bool newItemsAvailable: filteredNewItems.count > 0

	function setFloatingAvatarPosition()  {
		// It's at this point where everything actually gets properly initialized and we don't have to worry about
		// random unpredictable values, so we can safely allow the popup icon to show up.
		iconUser.x = root.x + sidePanel.x+sidePanel.width/2-Kirigami.Units.iconSizes.huge/2 + Kirigami.Units.smallSpacing/2 - 1;
		iconUser.y = root.y-Kirigami.Units.iconSizes.huge/2 + Kirigami.Units.smallSpacing;
		console.log("avatar");
		console.log(iconUser.x + " " + iconUser.y);
		console.log("root");
		console.log(root.x + " " + root.y);
		firstTimePopup = true;
	}

	onXChanged: {
		Plasmoid.syncBorders(Qt.rect(x, y, width, height), Plasmoid.location);
	}
	onYChanged: {
		Plasmoid.syncBorders(Qt.rect(x, y, width, height), Plasmoid.location);
	}
    onVisibleChanged: {
		popupPosition();
        if (!visible) {
            reset();
        } else {
            requestActivate();
			searchField.forceActiveFocus();
			rootModel.refresh();
			setFloatingAvatarPosition();
			Plasmoid.setDialogAppearance(root, dialogBackground.mask);

			if(!firstTimeShadowSetup) {
				shadow_fix.start()
			}
        }

		resetRecents(); // Resets the recents model to prevent errors and crashes.
    }
    onHeightChanged: {
		popupPosition();
		setFloatingAvatarPosition();
		Plasmoid.setDialogAppearance(root, dialogBackground.mask);
		Plasmoid.syncBorders(Qt.rect(x, y, width, height), Plasmoid.location);
    }

    onWidthChanged: {
		popupPosition();
		setFloatingAvatarPosition();
		Plasmoid.setDialogAppearance(root, dialogBackground.mask);
		Plasmoid.syncBorders(Qt.rect(x, y, width, height), Plasmoid.location);
    }

    onSearchingChanged: {
        if (!searching) {
			if(!KWindowSystem.isPlatformX11) {
				root.hideOnWindowDeactivate = false;
				wayland_fix.start();
			}
			reset();

        }
    }
    
    function resetRecents() {
        recents.currentIndex = -1;
    }
    function reset() {
        searchField.text = "";
		compositingIcon.iconSource = "";
		nonCompositingIcon.iconSource = "";
		searchField.forceActiveFocus();
    }
    property int shutdownIndex: -1
	
	function popupPosition() {
		var pos = kicker.mapToGlobal(kicker.x, kicker.y);
		var availScreen = Plasmoid.containment.availableScreenRect;
		var screen = kicker.screenGeometry;
		var availableScreenGeometry = Qt.rect(availScreen.x + screen.x, availScreen.y + screen.y, availScreen.width, availScreen.height);

		if(Plasmoid.location === PlasmaCore.Types.BottomEdge) {
			x = pos.x;
			y = pos.y - root.height;
		} else if(Plasmoid.location === PlasmaCore.Types.TopEdge) {
			x = pos.x;
			y = availableScreenGeometry.y;
		} else if(Plasmoid.location === PlasmaCore.Types.LeftEdge) {
			x = availableScreenGeometry.x;
			y = pos.y;
		} else if(Plasmoid.location === PlasmaCore.Types.RightEdge) {
			x = pos.x - root.width;
			y = pos.y;
		}

		if(x < availableScreenGeometry.x) x = availableScreenGeometry.x;
		if(x + root.width >= availableScreenGeometry.x + availScreen.width) {
			x = availableScreenGeometry.x + availScreen.width - root.width;
		}
		if(y < availableScreenGeometry.y) y = availableScreenGeometry.y;
		if(y + root.height >= availableScreenGeometry.y + availScreen.height) {
			y = availableScreenGeometry.y + availScreen.height - root.height;
		}
	}

	function isTouchingTopEdge() {
		if(Plasmoid.location === PlasmaCore.Types.LeftEdge || Plasmoid.location === PlasmaCore.Types.RightEdge)
			return (root.y - panelSvg.margins.top) === Plasmoid.containment.availableScreenRect.y;
		else if(Plasmoid.location === PlasmaCore.Types.TopEdge)
			return true;
		else
			return false;
	}

    FocusScope {
		id: mainFocusScope
		objectName: "MainFocusScope"
        Layout.minimumWidth: Math.max(397, root.cellWidth + Kirigami.Units.mediumSpacing + columnItems.width) + Kirigami.Units.mediumSpacing*2
		Layout.maximumWidth: Math.max(397, root.cellWidth + Kirigami.Units.mediumSpacing + columnItems.width) + Kirigami.Units.mediumSpacing*2

		property int mainPanelHeight: leftSidebar.height + bottomControls.height
		property int sidePanelHeight: backgroundBorderLine.height + searchBackground.height + columnItems.height + ((compositingEnabled && !root.isTouchingTopEdge()) ? Kirigami.Units.iconSizes.huge / 2 + Kirigami.Units.smallSpacing : nonCompositingIcon.height + Kirigami.Units.smallSpacing);
		//property bool sidePanelOverflow: mainPanelHeight <= sidePanelHeight;

        Layout.minimumHeight: Math.max(Math.max(mainPanelHeight, sidePanelHeight), 377) + Kirigami.Units.smallSpacing/2 + Kirigami.Units.mediumSpacing*2
        Layout.maximumHeight: Math.max(Math.max(mainPanelHeight, sidePanelHeight), 377) + Kirigami.Units.smallSpacing/2 + Kirigami.Units.mediumSpacing*2
        
        focus: true
		clip: false

		KItemModels.KSortFilterProxyModel {
			id: filteredNewItems
			sourceModel: kicker.rootModel

			function containsNewItem(sourceRow, sourceParent) {
				const isNewlyInstalledRole = sourceModel.KItemModels.KRoleNames.role("isNewlyInstalled");
				const isNewlyInstalled = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), isNewlyInstalledRole);
				return isNewlyInstalled === true;
			}
			filterRowCallback: (sourceRow, sourceParent) => containsNewItem(sourceRow, sourceParent)
		}


		Timer {
			id: shadow_fix
			interval: 25
			onTriggered: {
				Plasmoid.enableShadow(Plasmoid.configuration.enableShadow);
				Plasmoid.syncBorders(Qt.rect(dashWindow.x, dashWindow.y, dashWindow.width, dashWindow.height), Plasmoid.location);
				firstTimeShadowSetup = true;
			}
		}
		Timer { // Janky wayland problems require janky solutions
			id: wayland_fix
			interval: 25
			onTriggered: root.hideOnWindowDeactivate = true;
		}
        KCoreAddons.KUser {   id: kuser  }  // Used for getting the username and icon.
        //Logic {   id: logic }				// Probably useful.
        
        /*
		 * The user icon is supposed to stick out of the start menu, so a separate dialog window
		 * is required to pull that effect off. Inspiration taken from SnoutBug's MMcK launcher,
		 * however with some minor adjustments and improvements.
		 *
		 * The flag Qt.X11BypassWindowManagerHint is used to prevent the dialog from animating its
		 * opacity when its visibility is changed directly, and Qt.Popup is used to ensure that it's
		 * above the parent dialog window.
		 *
		 * Setting the location to "Floating" means that we can use manual positioning for the dialog
		 * which is important as positioning a dialog like this is tricky at best and unpredictable
		 * at worst. Positioning of this dialog window can only be done reliably when:
		 *
		 * 1. The parent dialog window is visible, this ensures that the positioning of the window
		 * 	  is actually initialized and not simply declared.
		 * 2. The width and height of the parent dialog window are properly initialized as well.
		 *
		 * This is why the position of this window is determined on the onHeightChanged slot of the
		 * parent window, as by then both the position and size of the parent are well defined.
		 * It should be noted that the position values for any dialog window are gonna become
		 * properly initialized once the visibility of the window is enabled, at least from what
		 * I could figure out. Anything before that and the properties won't behave well.
		 *
		 * To comment on MMcK's implementation, this is likely why positioning of the floating
		 * avatar is so weird and unreliable. Using uninitialized values always leads to
		 * unpredictable behavior, which leads to positioning being all over the place.
		 *
		 * The firstTimePopup is used to make sure that the dialog window has its correct position
		 * values before it is made visible to the user.
		 */
		Item {
			PlasmaCore.Dialog {
        		id: iconUser
        		//flags: Qt.WindowStaysOnTopHint// | Qt.BypassWindowManagerHint  // To prevent the icon from animating its opacity when its visibility is changed
        		//type: "Notification" // So that we don't have to rely on this
				location: "Floating"

				type: "Notification"
				title: "seventasks-floatingavatar"
				x: 0
				y: 0
				backgroundHints: PlasmaCore.Types.NoBackground // To prevent the dialog background SVG from being rendered, we want a fully transparent window.
				//visualParent: root
				visible: root.visible && !searching && compositingEnabled && !root.isTouchingTopEdge() //Plasmoid.location != PlasmaCore.Types.TopEdge
				opacity: iconUser.visible && firstTimePopup // To prevent even more NP-hard unpredictable behavior
				mainItem: FloatingIcon {
					id: compositingIcon
					visible: compositingEnabled
				}
        	}
		}
		Connections { 
			target: root 
			function onActiveFocusItemChanged() {
				if(root.activeFocusItem === null) {
					root.requestActivate();
				}
			}
		}
		Connections {
			target: kicker

			function onScreenGeometryChanged() {
				firstTimePopup = false;
			}
			function onScreenChanged() {
				firstTimePopup = false;
			}
		}
        Connections {
        target: Plasmoid.configuration
            function onNumberRowsChanged() {
                recents.model.sourceModel.refresh();
            }
        }
        Plasma5Support.DataSource {
            id: pmEngine
            engine: "powermanagement"
            connectedSources: ["PowerDevil", "Sleep States"]
            function performOperation(what) {
                var service = serviceForSource("PowerDevil")
                var operation = service.operationDescription(what)
                service.startOperationCall(operation)
            }
        }

        Plasma5Support.DataSource {
            id: executable
            engine: "executable"
            connectedSources: []
            onNewData: (sourceName, data) => {
                disconnectSource(sourceName)
            }
            function exec(cmd) {
                if (cmd) {
                    connectSource(cmd)
                }
            }
        }

        Kicker.SystemModel {
			id: systemModel
			favoritesModel: globalFavorites
		}
        component FilteredModel : KItemModels.KSortFilterProxyModel {
			sourceModel: systemModel

			function systemFavoritesContainsRow(sourceRow, sourceParent) {
				const FavoriteIdRole = sourceModel.KItemModels.KRoleNames.role("favoriteId");
				const favoriteId = sourceModel.data(sourceModel.index(sourceRow, 0, sourceParent), FavoriteIdRole);
				return String(Plasmoid.configuration.systemFavorites).includes(favoriteId);
			}

			function trigger(index) {
				const sourceIndex = mapToSource(this.index(index, 0));
				systemModel.trigger(sourceIndex.row, "", null);
			}

			Component.onCompleted: {
				Plasmoid.configuration.valueChanged.connect((key, value) => {
					if (key === "systemFavorites") {
						invalidateFilter();
					}
				});
			}
		}

		FilteredModel {
			id: filteredMenuItemsModel
			filterRowCallback: root.shouldCollapseButtons
			? null /*i.e. keep all rows*/
			: (sourceRow, sourceParent) => !systemFavoritesContainsRow(sourceRow, sourceParent)
		}

		Instantiator {
			model: filteredMenuItemsModel
			delegate: PlasmaExtras.MenuItem {
				required property int index
				required property var model

				text: "       " + model.display + "      "
				onClicked: {
					filteredMenuItemsModel.trigger(index)
					root.visible = false;
				}
			}
			onObjectAdded: (index, object) => {
				if(object.model.decoration != "system-shutdown") {
					if(index == 3 || index == 5)
						var separator = Qt.createQmlObject(`
					import org.kde.plasma.extras as PlasmaExtras

					PlasmaExtras.MenuItem { separator: true }
					`, contextMenu);
					contextMenu.addMenuItem(object);
				} else {
					root.shutdownIndex = index;
				}
			}
			onObjectRemoved: (index, object) => contextMenu.removeMenuItem(object)
		}


        PlasmaExtras.Menu {
			id: contextMenu
			visualParent: lockScreenDelegate //leaveButton
			placement: {
				//return PlasmaCore.Types.FloatingPopup
				switch (Plasmoid.location) {
					case PlasmaCore.Types.LeftEdge:
					case PlasmaCore.Types.RightEdge:
					case PlasmaCore.Types.TopEdge:
						return PlasmaExtras.Menu.BottomPosedRightAlignedPopup;
					case PlasmaCore.Types.BottomEdge:
					default:
						return PlasmaExtras.Menu.RightPosedBottomAlignedPopup;
				}
			}
		}


		KSvg.FrameSvgItem {
			id: dialogBackground
			anchors.fill: parent
			imagePath: Qt.resolvedUrl("svgs/dialog.svgz");
			//opacity: 0
		}

        Rectangle {
			id: backgroundGradient
			anchors.fill: parent
			anchors.topMargin: 2
			anchors.leftMargin: 2
			anchors.rightMargin: 2
			anchors.bottomMargin: 2
			gradient: Gradient {
				GradientStop { position: 0.0; color: "#26000000" }
				GradientStop { position: 0.11; color: "#53000000" }
				GradientStop { position: 0.2775; color: "#82000000" }
				GradientStop { position: 0.445; color: "#99000000" }
				GradientStop { position: 0.51; color: "#99000000" }
				GradientStop { position: 0.84; color: "#4f000000" }
				GradientStop { position: 1.0; color: "#00000000" }
			}
			topLeftRadius: 8
			topRightRadius: 8
		}

		/*
		 * This rectangle acts as a background for the left panel of the start menu.
		 * The rectangle backgroundBorderLine is the border separating the search field
		 * and the rest of the panel, while the searchBackground rectangle is the background
		 * for the search field.
		 */
        KSvg.FrameSvgItem {
        	id: backgroundRect
        	anchors.top: leftSidebar.top
        	anchors.topMargin: -Kirigami.Units.smallSpacing// + Kirigami.Units.mediumSpacing
        	anchors.left: leftSidebar.left
        	anchors.bottom: bottomControls.bottom
        	anchors.bottomMargin: Kirigami.Units.smallSpacing
        	imagePath: Qt.resolvedUrl("svgs/background.svg")

			width:  searching ? searchView.width : root.cellWidth

        	CrossFadeBehavior on width {
				fadeDuration: 200
			}
        	Rectangle {
        		id: backgroundBorderLine

        		height: Kirigami.Units.smallSpacing

        		gradient: Gradient {
					GradientStop { position: 0.0; color: "#ccd9ea" }
					GradientStop { position: 1.0; color: "#f0f4fa" }
				}

        	 	anchors { 
        	   		top: searchBackground.top
        	   		left: parent.left
        	   		right: parent.right
        	   		leftMargin: 2
        	   		rightMargin: 2
        		}
        		z: 4
        	}
        	Rectangle {
                id: searchBackground

                height: 45
                color: searchPanelBackgroundColor
                radius: 3

                anchors { 
                    bottom: parent.bottom 
                    bottomMargin: 2
                    left: parent.left
                    right: parent.right
                    leftMargin: 2
                    rightMargin: 2
                }
            }
        }

        ColumnLayout {
			id: leftSidebar
			anchors {
				top: parent.top
				left: parent.left
				topMargin: 5 + Kirigami.Units.mediumSpacing
				leftMargin: 1 + Kirigami.Units.mediumSpacing
			}
			z: 3
			width: root.cellWidth
			spacing: 0
		/* 
		 *  Displays bookmarked/favorite applications and is displayed at the top of the start menu.
		 *  The source code is taken directly from Kickoff without additional changes.
		 */
        FavoritesView {
            id: faves
            Layout.fillWidth: true
            Layout.preferredHeight: faves.height
            opacity: !showingAllPrograms && !searching
            Behavior on opacity {
				NumberAnimation { easing.type: Easing.Linear; duration: animationDuration*0.66 }
			}

        }
		/* 
			This is the separator between favorite applications and recently used applications.
		*/
        Rectangle {
       		id: tabBarSeparator
			Layout.leftMargin: 11
			Layout.rightMargin: 7
			Layout.topMargin: 2
			Layout.fillWidth: true
       		Layout.preferredHeight: 1
       		color: leftPanelSeparatorColor
       		opacity: Plasmoid.configuration.numberRows && faves.count && (!showingAllPrograms && !searching)
			Behavior on opacity {
				NumberAnimation { easing.type: Easing.Linear; duration: animationDuration*0.66 }
			}
        }
		/*
			This is the view showing recently used applications. As soon as a program is executed and has a start menu
			entry (appears in KMenuEdit), it will be pushed at the beginning of the list. The source code is forked from
			Kickoff, featuring very minor changes. 
		*/
        OftenUsedView {
            id: recents
			Layout.topMargin: 2 * (faves.count > 0 ? 1 : -1)
			Layout.preferredHeight: recents.height
			Layout.fillHeight: true
			Layout.fillWidth: true
            opacity: Plasmoid.configuration.numberRows && (!showingAllPrograms && !searching)
			Behavior on opacity {
				NumberAnimation { easing.type: Easing.Linear; duration: animationDuration*0.66 }
			}
        }
		}
		ColumnLayout {
			id: bottomControls
			anchors {
				left: parent.left
				leftMargin: 1 + Kirigami.Units.mediumSpacing
				bottom: parent.bottom
				bottomMargin: Kirigami.Units.smallSpacing-1

			}
			spacing: 0
			width: root.cellWidth
			z: 4
			/*
			 * Another separator between the button to show all programs and recently used applications
			 */
			Rectangle {
				id: allProgramsSeparator

				Layout.topMargin: 2
				Layout.leftMargin: 13
				Layout.rightMargin: Kirigami.Units.largeSpacing+1
				Layout.fillWidth: true
				Layout.preferredHeight: 1
				opacity: !searching
				color: leftPanelSeparatorColor
				Behavior on opacity {
					NumberAnimation { easing.type: Easing.Linear; duration: animationDuration }
				}
			}
			/*
			 * Shows/hides the main view of the panel. Clicking on it in the default state will show the
			 * application menu. If the start menu is showing the application menu element or is in a searching
			 * state, clicking on this button will bring the start menu back to its default state.
			 */
			MouseArea {
				id: allButtonsArea
				hoverEnabled: true

				property alias svgArrow: arrowDirection.elementId

				Behavior on opacity {
					NumberAnimation { easing.type: Easing.Linear; duration: animationDuration }
				}
				opacity: !searching
				CrossFadeBehavior on svgArrow {
					fadeDuration: 200
				}
				Layout.fillWidth: true
				Layout.leftMargin: Kirigami.Units.smallSpacing
				Layout.rightMargin: Kirigami.Units.smallSpacing
				Layout.topMargin: 3

				KeyNavigation.tab: searchField;
				KeyNavigation.backtab: returnPreviousView();
				function returnPreviousView() {
					if(searching) {
						return searchView.itemGrid;
					} else if(showingAllPrograms) {
						return appsView;
					} else if(Plasmoid.configuration.numberRows) {
						return recents;
					} else {
						return faves;
					}
				}
				Keys.onPressed: event => {
					if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
						click(true);
					} else if(event.key == Qt.Key_Up) {
						var view = returnPreviousView();
						view.focus = true;
						if(typeof view.currentIndex !== "undefined") {
							view.currentIndex = view.count;
							view.decrementCurrentIndex();
						}
					} else if(event.key == Qt.Key_Down) {
						searchField.focus = true;
					}
				}
				Timer {
					id: activateAppViewTimer
					interval: Kirigami.Units.longDuration*4
					onTriggered: {
						allButtonsArea.click(false);
					}
				}
				onContainsMouseChanged: {
					if(containsMouse) {
						activateAppViewTimer.start();
					} else {
						activateAppViewTimer.stop();
					}
				}
				onClicked: {
					click(false);
					activateAppViewTimer.stop();
				}
				function click(focusAppsView) {
					if(searching)
					{
						searchField.text = "";
					}
					else if(showingAllPrograms)
					{
						showingAllPrograms = false;
						appsView.reset();
					}
					else if(!searching && !showingAllPrograms)
					{
						showingAllPrograms = true;
						if(focusAppsView) appsView.focus = true;
					}
				}
				Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium+1

				KSvg.FrameSvgItem {
					id: allPBNew

					anchors.fill: parent

					imagePath: Qt.resolvedUrl("svgs/menuitem.svg")
					prefix: "new"

					visible: root.newItemsAvailable
					opacity: !showingAllPrograms

					Behavior on opacity {
						NumberAnimation { easing.type: Easing.Linear; duration: animationDuration }
					}
				}

				KSvg.FrameSvgItem {
					id: allProgramsButton
					anchors.fill: parent
					imagePath: Qt.resolvedUrl("svgs/menuitem.svg")

					prefix: "hover"
					opacity: {
						if(allButtonsArea.containsMouse) return 1.0;
						else if(allButtonsArea.focus) return 0.5;
						else return 0;
					}
				}
				KSvg.SvgItem {
					id: arrowDirection
					svg: arrowsSvg
					elementId: (showingAllPrograms) ? "all-applications-left" : "all-applications-right"

					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					anchors.verticalCenterOffset: -1
					anchors.leftMargin: Kirigami.Units.smallSpacing

					width: Kirigami.Units.iconSizes.small
					height: Kirigami.Units.iconSizes.small
				}
				Text {
					id: showingAllProgramsText
					text: "    All Programs"
					font.pixelSize: 12
					anchors.left: arrowDirection.right
					anchors.leftMargin: Kirigami.Units.mediumSpacing
					anchors.verticalCenter: parent.verticalCenter
					anchors.verticalCenterOffset: -1
					style: Text.Sunken
					styleColor: "transparent"
					opacity: !showingAllPrograms
					Behavior on opacity {
						NumberAnimation { duration: 200 }
					}
				}
				Text {
					id: showingAllProgramsTextBack
					text: "    Back"
					font.pixelSize: 12
					anchors.left: arrowDirection.right
					anchors.leftMargin: Kirigami.Units.mediumSpacing
					anchors.verticalCenter: parent.verticalCenter
					anchors.verticalCenterOffset: -1
					style: Text.Sunken
					styleColor: "transparent"
					opacity: showingAllPrograms
					Behavior on opacity {
						NumberAnimation { duration: 200 }
					}
				}
			}
			PlasmaExtras.ActionTextField {
				id: searchField

				focus: true
				Layout.topMargin: 15
				Layout.bottomMargin: 16
				Layout.alignment: Qt.AlignHCenter
				Layout.fillWidth: true
				Layout.preferredHeight: Kirigami.Units.smallSpacing * 7 - Kirigami.Units.smallSpacing
				Layout.rightMargin: Plasmoid.configuration.accurateSearchBar ? 17 : Kirigami.Units.largeSpacing
				Layout.leftMargin: Plasmoid.configuration.accurateSearchBar ? 13 : Kirigami.Units.largeSpacing

				rightPadding: Kirigami.Units.largeSpacing
				leftPadding: Kirigami.Units.largeSpacing
				topPadding: Kirigami.Units.smallSpacing+1

				background:	KSvg.FrameSvgItem {
					anchors.fill: parent
					anchors.left: parent.left
					imagePath: Qt.resolvedUrl("svgs/lineedit.svg")
					prefix: "base"

					Text {
						anchors.fill: parent
						anchors.leftMargin: Kirigami.Units.smallSpacing*2-1
						anchors.bottomMargin: 2
						font.italic: true
						color: searchFieldPlaceholderColor
						text: i18n(" Search programs and files")
						verticalAlignment: Text.AlignVCenter
						visible: !searching
						style: Text.Outline
						styleColor: "transparent"
						opacity: 0.55
					}
					Kirigami.Icon {
						source: "gtk-search"
						smooth: true
						visible: !searching
						width: Kirigami.Units.iconSizes.small;
						height: width
						anchors {
							top: parent.top
							bottom: parent.bottom
							bottomMargin: 1
							right: parent.right
							rightMargin: Kirigami.Units.smallSpacing+1
						}
					}
				}
				inputMethodHints: Qt.ImhNoPredictiveText
				clearButtonShown: false
				text: ""
				color: "black"
				verticalAlignment: TextInput.AlignTop

				onTextChanged: {
					searchView.onQueryChanged();
				}

				KeyNavigation.tab: {
					if(columnItems.visibleChildren.length === 2) return shutdown;
					return columnItems.visibleChildren[0];
				}
				Keys.priority: Keys.AfterItem
				Keys.onPressed: function(event){
					if (event.key == Qt.Key_Escape) {
						event.accepted = true;
						if (searching) {
							root.reset();
						} else if(showingAllPrograms) {
							showingAllPrograms = false;
							appsView.reset();
						} else {
							root.visible = false;
						}
						focus = true;
						return;
					}
					if (event.key == Qt.Key_Tab) {
						faves.forceActiveFocus();
						event.accepted = true;
						return;
					}
					if ((event.key == Qt.Key_Up) && searching) {
						searchView.decrementCurrentIndex();
						event.accepted = true;
						return;
					}
					if ((event.key == Qt.Key_Down) && searching) {
						searchView.incrementCurrentIndex();
						event.accepted = true;
						return;
					}
					if((event.key == Qt.Key_Return) && searching) {
						searchView.activateCurrentIndex();
						event.accepted = true;
						return;
					}
					event.accepted = false;
				}

				function backspace() {
					if (!root.visible) {
						return;
					}
					focus = true;
					text = text.slice(0, -1);
				}

				function appendText(newText) {
					if (!root.visible) {
						return;
					}
					focus = true;
					text = text + newText;
				}
			}

		}

        states: [

            State {
                name: "AllPrograms"; when: !searching && showingAllPrograms
                StateChangeScript {
                    script: appsView.resetIndex();
                }
            },
            State {
                name: "Searching"; when: searching

                PropertyChanges {
					target: searchView; opacity: (backgroundRect.width === searchView.width ? 1 : 0);
				}
                PropertyChanges {
					target: searchBackground; anchors.rightMargin: 3
				}
				PropertyChanges {
					target: backgroundBorderLine; anchors.rightMargin: 3
				}
                PropertyChanges {
                    target: faves; opacity: 0;
                }
                PropertyChanges {
                    target: recents; opacity: 0;
                }
                PropertyChanges {
                    target: tabBarSeparator; opacity: 0;
                }
                PropertyChanges {
                    target: allProgramsButton; opacity: 0;
                }
                PropertyChanges {
					target: allProgramsButton; enabled: false;
				}
                PropertyChanges {
                    target: allProgramsSeparator; opacity: 0;
                }
                PropertyChanges {
                    target: allButtonsArea; opacity: 0;
                }
                PropertyChanges {
					target: allButtonsArea; enabled: false;
				}
                PropertyChanges {
                    target: sidePanel; opacity: 0;
                }
                PropertyChanges {
                    target: sidePanel; enabled: false
                }
		}
        ]
        transitions: [
       		Transition {
				id: transition
       		    PropertyAnimation { properties: "opacity"; easing.type: Easing.Linear; duration: Kirigami.Units.longDuration*1.5 }
       		    onRunningChanged: {
					if(!searching && !running) {
						// fixes another inexplicable bug, makes it look just a tad bit nicer
						backgroundBorderLine.anchors.rightMargin = Qt.binding(() => 2);
						searchBackground.anchors.rightMargin = Qt.binding(() => 2);
					}
				}
       		}
        ]

        /*
		 * Shows a list of all applications organized by categories. The source code is forked from Kickoff
		 * and features mostly aesthetic changes.
		 */
		ApplicationsView {
			id: appsView

			anchors {
				top: leftSidebar.top
				left: leftSidebar.left
				right: leftSidebar.right
				bottom: bottomControls.top
				topMargin: -Kirigami.Units.largeSpacing
			}

			opacity: showingAllPrograms && !searching
			enabled: opacity !== 0.0
			Behavior on opacity {
				NumberAnimation { easing.type: Easing.Linear; duration: animationDuration*0.66 }
			}

			function resetIndex() {
				appsView.listView.currentIndex = -1;
			}

			z: showingAllPrograms ? 4 : 1
		}

		/*
		 * Shows search results when the user types something into the textbox. This view will only
		 * appear if that textbox is not empty, and it will extend the left panel to the entire
		 * width of the plasmoid. The source code is forked from Kickoff and features aesthetic
		 * changes.
		 */
		SearchView {
			id: searchView

			clip: true
			anchors {
				top: backgroundRect.top
				left: parent.left
				right: parent.right
				bottom: backgroundRect.bottom

				topMargin: Kirigami.Units.smallSpacing*2 -2
				bottomMargin: searchBackground.height + Kirigami.Units.smallSpacing/2
				leftMargin: 2 + Kirigami.Units.mediumSpacing
				rightMargin: Kirigami.Units.mediumSpacing
			}

			opacity: 0
			visible: opacity
			Behavior on opacity {
				NumberAnimation { easing.type: Easing.InOutQuart; duration: 150 }
			}

			z: searching ? 4 : 1
		}


        Column {
            id: sidePanel
            z: searching ? 3 : 7
            anchors{
                left: leftSidebar.right
                top: parent.top
                bottomMargin: Kirigami.Units.largeSpacing
                leftMargin: 5
                topMargin: ((compositingEnabled && !root.isTouchingTopEdge()) ? Kirigami.Units.iconSizes.huge / 2 + Kirigami.Units.mediumSpacing : 0) + Kirigami.Units.mediumSpacing
			}
			spacing: Kirigami.Units.smallSpacing

			FloatingIcon {
				id: nonCompositingIcon
				Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
				visible: !compositingEnabled || root.isTouchingTopEdge()
				opacity: !searching

			}
			Timer {
				id: delayTimer
				interval: 250
				repeat: false
				onTriggered: {
					if(root.activeFocusItem) {
						if(root.activeFocusItem.objectName === "SidePanelItemDelegate") {
							compositingIcon.iconSource = root.activeFocusItem.itemIcon;
							compositingIcon.fallbackIcon = root.activeFocusItem.itemIconFallback;
							nonCompositingIcon.iconSource = root.activeFocusItem.itemIcon;
							nonCompositingIcon.fallbackIcon = root.activeFocusItem.itemIconFallback;
						} else {
							compositingIcon.iconSource = "";
							compositingIcon.fallbackIcon = "unknown";
							nonCompositingIcon.iconSource = "";
							nonCompositingIcon.fallbackIcon = "unknown";
						}
					}
				}
			}

			//Side panel items
            ColumnLayout {
                id: columnItems
                spacing: 2
				Layout.alignment: Qt.AlignTop
				width: Math.max(root.cellWidthSide, columnItems.implicitWidth)

				property var cfg_sidePanelVisibility: Plasmoid.configuration.sidePanelVisibility
				property var sidePanelVisibility: {
					var result = {};
					if(cfg_sidePanelVisibility !== "")
						result = JSON.parse(cfg_sidePanelVisibility);

					if(typeof result === "undefined")
						result = {};
					return result;
				}

				property int currentIndex: -1
                Component.onCompleted: {
					separator1.updateVisibility();
					separator2.updateVisibility();
				}
				Repeater {
					id: firstCategoryRepeater
					model: sidePanelModels.firstCategory.length
					visible: false // Messes with separator visibility checks
					delegate: SidePanelItemDelegate {
						id: firstCategoryDelegate
						required property int index
						itemText: sidePanelModels.firstCategory[index].itemText
						itemIcon: sidePanelModels.firstCategory[index].itemIcon
						description: sidePanelModels.firstCategory[index].description
						executableString: sidePanelModels.firstCategory[index].executableString
						visible: typeof columnItems.sidePanelVisibility[sidePanelModels.firstCategory[index].name] !== "undefined"
						executeProgram: sidePanelModels.firstCategory[index].executeProgram
						onVisibleChanged: {
							separator1.updateVisibility();
							separator2.updateVisibility();
						}
						Layout.fillWidth: true
						onItemTextChanged: { // Fix bug where changing the username for some reason causes the item width to shrink to the text content
							firstCategoryDelegate.Layout.fillWidth = false;
							firstCategoryDelegate.Layout.fillWidth = true;
						}
					}

				}
				SidePanelItemSeparator {
					id: separator1
					Layout.minimumWidth: 124
					Layout.maximumWidth: 124
					Layout.alignment: Qt.AlignHCenter
					Layout.bottomMargin: -1
				}
				Repeater {
					id: secondCategoryRepeater
					Layout.topMargin: -1
					model: sidePanelModels.secondCategory.length
					visible: false // Messes with separator visibility checks
					delegate: SidePanelItemDelegate {
						required property int index
						itemText: sidePanelModels.secondCategory[index].itemText
						description: sidePanelModels.secondCategory[index].description
						itemIcon: sidePanelModels.secondCategory[index].itemIcon
						executableString: sidePanelModels.secondCategory[index].executableString
						visible: typeof columnItems.sidePanelVisibility[sidePanelModels.secondCategory[index].name] !== "undefined"
						menuModel: sidePanelModels.secondCategory[index].menuModel
						executeProgram: sidePanelModels.secondCategory[index].executeProgram
						onVisibleChanged: {
							separator1.updateVisibility();
							separator2.updateVisibility();
						}
						Layout.fillWidth: true
					}

				}
				SidePanelItemSeparator {
					id: separator2
					Layout.minimumWidth: 124
					Layout.maximumWidth: 124
					Layout.alignment: Qt.AlignHCenter
					Layout.bottomMargin: -1
				}
				Repeater {
					id: thirdCategoryRepeater
					model: sidePanelModels.thirdCategory.length
					Layout.topMargin: -1
					visible: false // Messes with separator visibility checks
					delegate: SidePanelItemDelegate {
						required property int index
						itemText: sidePanelModels.thirdCategory[index].itemText
						description: sidePanelModels.thirdCategory[index].description
						itemIcon: sidePanelModels.thirdCategory[index].itemIcon
						executableString: sidePanelModels.thirdCategory[index].executableString
						visible: typeof columnItems.sidePanelVisibility[sidePanelModels.thirdCategory[index].name] !== "undefined"
						menuModel: sidePanelModels.thirdCategory[index].menuModel
						executeProgram: sidePanelModels.thirdCategory[index].executeProgram
						onVisibleChanged: {
							separator1.updateVisibility();
							separator2.updateVisibility();
						}
						Layout.fillWidth: true
					}
				}

				//Used to space out the rest of the side panel, so that the shutdown button is at the bottom of the plasmoid
                Item {
					objectName: "PaddingItem"
                    Layout.fillHeight: false
                    visible: true
                }
                Item {
                    Layout.minimumWidth: cellWidthSide
                    Layout.fillWidth: true
                    height: 2
                    visible: true
                }
            }
        }
        
        RowLayout {
			id: leaveButtons
			anchors{
				bottom: bottomControls.bottom
				bottomMargin: 17
				left: bottomControls.right
				leftMargin: 6
			}
			spacing: 0
			z: 7
			function findUpItem() {
				if(searching) {
					return allButtonsArea;
				} else {
					if(columnItems.visibleChildren.length === 2) {
						return searchField;
					}

					return columnItems.visibleChildren[columnItems.visibleChildren.length-3];
				}
			}
			ListDelegate {
				id: shutdown
				objectName: "ShutdownButton"
				width: shutDownText.implicitWidth + (Kirigami.Units.largeSpacing-1)*2 + 1
				height: Kirigami.Units.smallSpacing * 6 - 2
				size: iconSizeSide

				KeyNavigation.tab: lockScreenDelegate
				KeyNavigation.backtab: Qt.binding(() => { return leaveButtons.findUpItem(); });

				Keys.onPressed: event => {
					if(event.key == Qt.Key_Return) {
						ma.clicked(null);
					} else if(event.key == Qt.Key_Right) {
						lockScreenDelegate.focus = true;
					} else if(event.key == Qt.Key_Left) {
						searchField.focus = true;
					} else if(event.key == Qt.Key_Up) {
						leaveButtons.findUpItem().focus = true;
					}
				}
				Timer {
					id: shutdownTimer
					interval: Kirigami.Units.longDuration*3
					onTriggered: {
						shutdownToolTip.showToolTip();
					}
				}
				PlasmaCore.ToolTipArea {
					id: shutdownToolTip

					anchors {
						fill: parent
					}

					interactive: false
					location: {
						var result = PlasmaCore.Types.Floating;
						if(ma.containsMouse) result |= PlasmaCore.Types.Desktop;
						return result;
					}

					mainItem: Text {
						text: i18n("Closes all open programs, shuts down Linux, and then turns off your computer.")
					}
				}
				onFocusChanged: {
					if(focus) shutdownTimer.start();
					else {
						shutdownToolTip.hideImmediately();
						shutdownTimer.stop();
					}
				}


				Text {
					id: shutDownText
					text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Shut down")

					font.pixelSize: 12
					color: searching ? shutdownTextColor : PlasmaCore.Theme.textColor
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.verticalCenter: parent.verticalCenter
					anchors.verticalCenterOffset: -1

					style: Text.Outline
					styleColor: "transparent"
					z: 5
				}

                KSvg.FrameSvgItem {
					id: shutdownButton

					anchors.fill:parent
					anchors.left: parent.left
					imagePath: Qt.resolvedUrl("svgs/startmenu-buttons.svg")

					prefix: {
						if(ma.containsPress) return "pressed";
						else if(ma.containsMouse || lockma.containsMouse || shutdown.focus || lockScreenDelegate.focus || contextMenu.status == 1) return "hover";
						else return "normal";
					}
				}

				MouseArea {
					id: ma

					enabled: !root.hoverDisabled
					acceptedButtons: Qt.LeftButton
					hoverEnabled: true
					anchors.fill: parent
					propagateComposedEvents: true
					onContainsMouseChanged: {
						if(containsMouse) shutdownTimer.start();
						else {
							shutdownToolTip.hideImmediately();
							shutdownTimer.stop();
						}
					}
					onExited: {
						shutdown.focus = false;
					}
					onClicked: {
						if(root.shutdownIndex !== -1) {
							filteredMenuItemsModel.trigger(root.shutdownIndex)
						}
						root.visible = false;
					}
				}
			}

			ListDelegate {
				id: lockScreenDelegate
				Layout.leftMargin: -1
				width: height+1
				height: shutdown.height 
				KeyNavigation.tab: faves
				KeyNavigation.backtab: shutdown

				Keys.onPressed: event => {
					if(event.key == Qt.Key_Return) {
						lockma.clicked(null);
					} else if(event.key == Qt.Key_Left) {
						shutdown.focus = true;
					} else if(event.key == Qt.Key_Up) {
						leaveButtons.findUpItem().focus = true;
					}
				}
                KSvg.FrameSvgItem {
					id: lockButton

					anchors.fill: parent;
					anchors.left: parent.left
					imagePath: Qt.resolvedUrl("svgs/startmenu-buttons.svg")

					prefix: {
						if(contextMenu.status == 1 || ma.containsPress) return "rtl-pressed";
						else if((ma.containsMouse || lockma.containsMouse || shutdown.focus || lockScreenDelegate.focus)) return "rtl-hover";
						else return "rtl-normal";
					}
				}
				onFocusChanged: {
					if(lockScreenDelegate.focus)
						contextMenu.openRelative();
				}
				Timer {
					id: lockmaTimer
					interval: 700
					onTriggered: {
						contextMenu.openRelative();
					}
				}
				MouseArea {
					id: lockma
					enabled: !root.hoverDisabled
					acceptedButtons: Qt.LeftButton

					onContainsMouseChanged: {
						if(containsMouse) {
							lockmaTimer.start();
						} else {
							lockmaTimer.stop();
						}
					}
					onClicked: {
						contextMenu.openRelative();
					}
					hoverEnabled: true
					anchors.fill: lockButton
				}

                KSvg.SvgItem {
					id: lsSvg
					svg: arrowsSvg

					anchors.centerIn: lockButton
					anchors.horizontalCenterOffset: -1
					width: Kirigami.Units.iconSizes.smallMedium - Kirigami.Units.smallSpacing / 2
					height: Kirigami.Units.iconSizes.smallMedium - Kirigami.Units.smallSpacing / 2 +1
					elementId: searching ? "more-ltr-black" : "more-ltr-light";
				}
				//enabled: pmEngine.data["Sleep States"]["LockScreen"]
				size: iconSizeSide
			}
		}
		
		KeyNavigation.tab: faves;
		Keys.forwardTo: searchField
	}

	Component.onCompleted: {
		kicker.reset.connect(reset);
		reset();
		faves.listView.currentIndex = -1;
		
		popupPosition();
		Plasmoid.setDialogAppearance(root, dialogBackground.mask);
	}
}
