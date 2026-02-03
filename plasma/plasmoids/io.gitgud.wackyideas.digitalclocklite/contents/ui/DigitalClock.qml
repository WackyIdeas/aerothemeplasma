/*
 * Copyright 2013 Heena Mahour <heena393@gmail.com>
 * Copyright 2013 Sebastian Kügler <sebas@kde.org>
 * Copyright 2013 Martin Klapetek <mklapetek@kde.org>
 * Copyright 2014 David Edmundson <davidedmundson@kde.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.6
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.private.digitalclock 1.0
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami

Item {
    id: main

    property string timeFormat
    property date currentTime

    property bool showSeconds: Plasmoid.configuration.showSeconds
    property bool showLocalTimezone: Plasmoid.configuration.showLocalTimezone
    property bool showDate: Plasmoid.configuration.showDate && !shortTaskbarHideDate

    property var dateFormat: {
        if (Plasmoid.configuration.dateFormat === "longDate") {
            return Locale.LongFormat;//Qt.SystemLocaleLongDate;
        } else if (Plasmoid.configuration.dateFormat === "isoDate") {
            return Qt.ISODate;
        } else if (Plasmoid.configuration.dateFormat === "customDate") {
            return Plasmoid.configuration.customFormat;
        }

        return Qt.locale()//Locale.ShortFormat;//Qt.SystemLocaleShortDate;
    }

    property string lastSelectedTimezone: Plasmoid.configuration.lastSelectedTimezone
    property bool displayTimezoneAsCode: Plasmoid.configuration.displayTimezoneAsCode
    property int use24hFormat: Plasmoid.configuration.use24hFormat
    property bool shortTaskbarHideDate: Plasmoid.configuration.shortTaskbarHideDate && main.height <= 30 && Plasmoid.formFactor == PlasmaCore.Types.Horizontal

    property string lastDate: ""
    property int tzOffset

    // This is the index in the list of user selected timezones
    property int tzIndex: 0

    // if the date/timezone cannot be fit with the smallest font to its designated space
    readonly property bool oneLineMode: Plasmoid.formFactor == PlasmaCore.Types.Horizontal &&
                                        main.height <= 2 * Kirigami.Theme.smallestFont.pixelSize &&
                                        (main.showDate || timezoneLabel.visible)
                                        
    property QtObject dashWindow: null

    function getCurrentTime(): date {
        const data = dataSource.data[Plasmoid.configuration.lastSelectedTimezone];
        // The order of signal propagation is unspecified, so we might get
        // here before the dataSource has updated. Alternatively, a buggy
        // configuration view might set lastSelectedTimezone to a new time
        // zone before applying the new list, or it may just be set to
        // something invalid in the config file.
        if (data === undefined) {
            return new Date();
        }

        // get the time for the given time zone from the dataengine
        const now = data["DateTime"];
        // get current UTC time
        const msUTC = now.getTime() + (now.getTimezoneOffset() * 60000);
        // add the dataengine TZ offset to it
        const currentTime = new Date(msUTC + (data["Offset"] * 1000));
        return currentTime;
    }


    onDateFormatChanged: {
        setupLabels();
    }

    onDisplayTimezoneAsCodeChanged: { setupLabels(); }
    onStateChanged: { setupLabels(); }

    onLastSelectedTimezoneChanged: { timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat)) }
    onShowSecondsChanged:          { timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat)) }
    onShowLocalTimezoneChanged:    { timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat)) }
    onShowDateChanged:             { timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat)) }
    onUse24hFormatChanged:         { timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat)) }

    Connections {
        target: Plasmoid.configuration
        function onSelectedTimeZonesChanged() {
            // If the currently selected timezone was removed,
            // default to the first one in the list
            var lastSelectedTimezone = Plasmoid.configuration.lastSelectedTimezone;
            if (Plasmoid.configuration.selectedTimeZones.indexOf(lastSelectedTimezone) == -1) {
                Plasmoid.configuration.lastSelectedTimezone = Plasmoid.configuration.selectedTimeZones[0];
            }

            setupLabels();
            setTimezoneIndex();
        }
    }

    states: [
        State {
            name: "horizontalPanel"
            when: Plasmoid.formFactor == PlasmaCore.Types.Horizontal && !main.oneLineMode

            PropertyChanges {
                target: main
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.minimumWidth: contentItem.width + Kirigami.Units.smallSpacing
                Layout.maximumWidth: Layout.minimumWidth
            }

            PropertyChanges {
                target: contentItem

                height: timeLabel.height + (main.showDate || timezoneLabel.visible ? 0.8 * timeLabel.height : 0)
                width: Math.max(labelsGrid.width, timezoneLabel.paintedWidth, dateLabel.paintedWidth)
            }

            PropertyChanges {
                target: labelsGrid

                rows: main.showDate ? 1 : 2
            }

            AnchorChanges {
                target: labelsGrid

                anchors.horizontalCenter: contentItem.horizontalCenter
            }

            PropertyChanges {
                target: timeLabel

                height: sizehelper.height
                //rightPadding: 1
                //width: sizehelper.contentWidth
                //width: contentItem.width
                //width: !showDate ? timeMetrics.advanceWidth(dateLabel.text) : timeLabel.paintedWidth
                font.pointSize: Math.min(Plasmoid.configuration.fontSize || Kirigami.Theme.defaultFont.pointSize, Math.round(timeLabel.height * 72 / 96))
            }

            PropertyChanges {
                target: timezoneLabel

                //height: main.showDate ? 0.7 * timeLabel.height : 0.8 * timeLabel.height
                //width: main.showDate ? timezoneLabel.paintedWidth : timeLabel.width

                font.pointSize: Math.min(Plasmoid.configuration.fontSize || Kirigami.Theme.defaultFont.pointSize, Math.round(timezoneLabel.height * 72 / 96))
            }

            PropertyChanges {
                target: dateLabel

                height: 0.8 * timeLabel.height
                width: dateLabel.paintedWidth

                font.pointSize: Math.min(Plasmoid.configuration.fontSize || Kirigami.Theme.defaultFont.pointSize, Math.round(dateLabel.height * 72 / 96))
            }

            AnchorChanges {
                target: dateLabel

                anchors.top: labelsGrid.bottom
                anchors.horizontalCenter: labelsGrid.horizontalCenter
            }

            PropertyChanges {
                target: sizehelper

                /*
                 * The value 0.71 was picked by testing to give the clock the right
                 * size (aligned with tray icons).
                 * Value 0.56 seems to be chosen rather arbitrary as well such that
                 * the time label is slightly larger than the date or timezone label
                 * and still fits well into the panel with all the applied margins.
                 */
                height: Math.min(main.showDate || timezoneLabel.visible ? main.height * 0.56 : main.height * 0.71,
                                 3 * Kirigami.Theme.defaultFont.pixelSize)

                font.pixelSize: sizehelper.height
            }
        },

        State {
            name: "horizontalPanelSmall"
            when: Plasmoid.formFactor == PlasmaCore.Types.Horizontal && main.oneLineMode

            PropertyChanges {
                target: main
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.minimumWidth: contentItem.width
                Layout.maximumWidth: Layout.minimumWidth

            }

            PropertyChanges {
                target: contentItem

                height: sizehelper.height
                width: dateLabel.width + dateLabel.anchors.rightMargin + labelsGrid.width
            }

            AnchorChanges {
                target: labelsGrid

                anchors.right: contentItem.right
                anchors.left: contentItem.left
            }

            PropertyChanges {
                target: dateLabel

                height: timeLabel.height
                width: dateLabel.paintedWidth

                anchors.rightMargin: labelsGrid.columnSpacing

                fontSizeMode: Text.VerticalFit
            }

            AnchorChanges {
                target: dateLabel

                anchors.right: labelsGrid.left
                anchors.verticalCenter: labelsGrid.verticalCenter
            }

            PropertyChanges {
                target: timeLabel

                height: sizehelper.height
                width: sizehelper.contentWidth

                fontSizeMode: Text.VerticalFit
            }

            PropertyChanges {
                target: timezoneLabel

                height: 0.7 * timeLabel.height
                width: timezoneLabel.paintedWidth

                fontSizeMode: Text.VerticalFit
                horizontalAlignment: Text.AlignHCenter
            }

            PropertyChanges {
                target: sizehelper

                height: Math.min(main.height, 3 * Kirigami.Theme.defaultFont.pixelSize)

                fontSizeMode: Text.VerticalFit
                font.pixelSize: 3 * Kirigami.Theme.defaultFont.pixelSize
            }
        },

        State {
            name: "verticalPanel"
            when: Plasmoid.formFactor == PlasmaCore.Types.Vertical

            PropertyChanges {
                target: main
                Layout.fillHeight: false
                Layout.fillWidth: true
                Layout.maximumHeight: contentItem.height
                Layout.minimumHeight: Layout.maximumHeight
            }

            PropertyChanges {
                target: contentItem

                height: main.showDate ? labelsGrid.height + dateLabel.height : labelsGrid.height
                width: main.width
            }

            PropertyChanges {
                target: labelsGrid

                rows: 2
            }

            PropertyChanges {
                target: timeLabel

                height: sizehelper.contentHeight
                width: main.width

                fontSizeMode: Text.HorizontalFit
            }

            PropertyChanges {
                target: timezoneLabel

                height: Math.max(0.7 * timeLabel.height, minimumPixelSize)
                width: main.width

                fontSizeMode: Text.Fit
                minimumPixelSize: dateLabel.minimumPixelSize
                elide: Text.ElideRight
            }

            PropertyChanges {
                target: dateLabel

                // this can be marginal bigger than contentHeight because of the horizontal fit
                height: Math.max(0.8 * timeLabel.height, minimumPixelSize)
                width: main.width

                fontSizeMode: Text.Fit
                minimumPixelSize: Math.min(0.7 * Kirigami.Theme.smallestFont.pixelSize, timeLabel.height)
                elide: Text.ElideRight
            }

            AnchorChanges {
                target: dateLabel

                anchors.top: labelsGrid.bottom
                anchors.horizontalCenter: labelsGrid.horizontalCenter
            }

            PropertyChanges {
                target: sizehelper

                width: main.width

                fontSizeMode: Text.HorizontalFit
                font.pixelSize: 3 * Kirigami.Theme.defaultFont.pixelSize
            }
        },

        State {
            name: "other"
            when: Plasmoid.formFactor != PlasmaCore.Types.Vertical && Plasmoid.formFactor != PlasmaCore.Types.Horizontal

            PropertyChanges {
                target: main
                Layout.fillHeight: false
                Layout.fillWidth: false
                Layout.minimumWidth: Kirigami.Units.iconSizes.small * 3
                Layout.minimumHeight: Kirigami.Units.iconSizes.small * 3
            }

            PropertyChanges {
                target: contentItem

                height: main.height
                width: main.width
            }

            PropertyChanges {
                target: labelsGrid

                rows: 2
            }

            PropertyChanges {
                target: timeLabel

                height: sizehelper.height
                width: main.width

                fontSizeMode: Text.Fit
            }

            PropertyChanges {
                target: timezoneLabel

                height: 0.7 * timeLabel.height
                width: main.width

                fontSizeMode: Text.Fit
                minimumPixelSize: 1
            }

            PropertyChanges {
                target: dateLabel

                height: 0.8 * timeLabel.height
                width: Math.max(timeLabel.contentWidth, Kirigami.Units.iconSizes.small * 3)

                fontSizeMode: Text.Fit
                minimumPixelSize: 1
            }

            AnchorChanges {
                target: dateLabel

                anchors.top: labelsGrid.bottom
                anchors.horizontalCenter: labelsGrid.horizontalCenter
            }

            PropertyChanges {
                target: sizehelper

                height: {
                    if (main.showDate) {
                        if (timezoneLabel.visible) {
                            return 0.4 * main.height
                        }
                        return 0.56 * main.height
                    } else if (timezoneLabel.visible) {
                        return 0.59 * main.height
                    }
                    return main.height
                }
                width: main.width

                fontSizeMode: Text.Fit
                font.pixelSize: 1024
            }
        }
    ]
    

    Timer {
        id: tooltipTimer
        interval: 750
        repeat: false
        running: false
        onTriggered: if(!dashWindow.visible) timeToolTip.showToolTip();
    }

    MouseArea {
        id: mouseArea

        property int wheelDelta: 0
        
        hoverEnabled: true

        anchors.fill: parent

        onClicked: {
            Plasmoid.expanded = !Plasmoid.expanded
            dashWindow.visible = !dashWindow.visible;
            if(dashWindow.visible) timeToolTip.hideImmediately();
        }
        
        onEntered: {
            tooltipTimer.start();
        }
        onExited: {
            tooltipTimer.stop();
            timeToolTip.hideToolTip();
        }
        onWheel: wheel => {
            if (!Plasmoid.configuration.wheelChangesTimezone) {
                return;
            }

            var delta = wheel.angleDelta.y || wheel.angleDelta.x
            var newIndex = main.tzIndex;
            wheelDelta += delta;
            // magic number 120 for common "one click"
            // See: http://qt-project.org/doc/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
            while (wheelDelta >= 120) {
                wheelDelta -= 120;
                newIndex--;
            }
            while (wheelDelta <= -120) {
                wheelDelta += 120;
                newIndex++;
            }

            if (newIndex >= Plasmoid.configuration.selectedTimeZones.length) {
                newIndex = 0;
            } else if (newIndex < 0) {
                newIndex = Plasmoid.configuration.selectedTimeZones.length - 1;
            }

            if (newIndex != main.tzIndex) {
                Plasmoid.configuration.lastSelectedTimezone = Plasmoid.configuration.selectedTimeZones[newIndex];
                main.tzIndex = newIndex;

                dataSource.dataChanged();
                setupLabels();
            }
        }
        PlasmaCore.ToolTipArea {
            id: timeToolTip

            anchors.fill: parent
            mainText: {
                    var now = dataSource.data[plasmoid.configuration.lastSelectedTimezone]["DateTime"];
                    return Qt.formatDate(now, "dddd, MMMM dd, yyyy");
            }
        }
    }

   /*
    * Visible elements
    *
    */

	//This FrameSvgItem uses a non-standard variant of the tabbar SVG file that includes a "pressed" state
    KSvg.FrameSvgItem {
        id: hoverIndicator
        imagePath: Qt.resolvedUrl("svgs/tabbar.svgz")
        visible: mouseArea.containsMouse || dashWindow.visible
        anchors.fill: parent
        anchors.leftMargin: -Kirigami.Units.smallSpacing
        anchors.rightMargin: -Kirigami.Units.smallSpacing
        anchors.bottomMargin: (Plasmoid.location === PlasmaCore.Types.BottomEdge || Plasmoid.location === PlasmaCore.Types.TopEdge) ? -Kirigami.Units.smallSpacing/2 : 0
        z: -1
        prefix: mouseArea.containsPress ? "pressed-tab" : "active-tab";
    }

    Item {
        id: contentItem
        anchors.verticalCenter: main.verticalCenter
        anchors.horizontalCenter: main.horizontalCenter
        anchors.alignWhenCentered: true

        Grid {
            id: labelsGrid

            rows: 1
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            flow: Grid.TopToBottom
            columnSpacing: Kirigami.Units.smallSpacing

            Rectangle {
                height: 0.8 * sizehelper.height
                width: 1
                visible: main.showDate && main.oneLineMode

                color: Kirigami.Theme.textColor
                opacity: 0.4
            }

            PlasmaComponents3.Label  {
                id: timeLabel

                renderType: Text.NativeRendering
                font {
                    family: Plasmoid.configuration.fontFamily || Kirigami.Theme.defaultFont.family
                    weight: Plasmoid.configuration.boldText ? Font.Bold : Kirigami.Theme.defaultFont.weight
                    italic: Plasmoid.configuration.italicText
                    pointSize: (Plasmoid.configuration.fontSize || Kirigami.Theme.defaultFont.pointSize)
                    hintingPreference: Font.PreferFullHinting
                }
                minimumPixelSize: 1
                style: {
                    if(Screen.devicePixelRatio == 1.0) return Text.Outline;
                    if(Screen.devicePixelRatio >= 2.0) return Text.Normal;
                    return Text.Raised;
                }
                styleColor: "transparent"
                text: {
                    // get the time for the given timezone from the dataengine
                    var now = dataSource.data[Plasmoid.configuration.lastSelectedTimezone]["DateTime"];
                    // get current UTC time
                    var msUTC = now.getTime() + (now.getTimezoneOffset() * 60000);
                    // add the dataengine TZ offset to it
                    var currentTime = new Date(msUTC + (dataSource.data[Plasmoid.configuration.lastSelectedTimezone]["Offset"] * 1000));

                    main.currentTime = currentTime;

                    var showTimezone = main.showLocalTimezone || (plasmoid.configuration.lastSelectedTimezone != "Local"
                    && dataSource.data["Local"]["Timezone City"] != dataSource.data[Plasmoid.configuration.lastSelectedTimezone]["Timezone City"]);

                    var timezoneString = "";
                    var timezoneResult = "";

                    if (showTimezone) {
                        timezoneString = Plasmoid.configuration.displayTimezoneAsCode ? dataSource.data[Plasmoid.configuration.lastSelectedTimezone]["Timezone Abbreviation"]
                        : TimezonesI18n.i18nCity(dataSource.data[Plasmoid.configuration.lastSelectedTimezone]["Timezone City"]);
                        timezoneResult = (main.showDate || main.oneLineMode) && Plasmoid.formFactor == PlasmaCore.Types.Horizontal ? timezoneString : timezoneString;
                    } else {
                        // this clears the label and that makes it hidden
                        timezoneResult = timezoneString;
                    }
                    return (showTimezone ? "" : " ") + Qt.formatTime(currentTime, main.timeFormat) + " " + (showTimezone ? (" " + timezoneResult) : "");
                }
                leftPadding: ((showDate && dateFormat === Qt.ISODate) ? 1 : 0)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents3.Label {
                id: timezoneLabel

                renderType: Text.NativeRendering
                font.weight: timeLabel.font.weight
                font.italic: timeLabel.font.italic
                font.pixelSize: timeLabel.font.pixelSize
                font.hintingPreference: Font.PreferFullHinting
                minimumPixelSize: 1

                styleColor: "transparent"
                style: {
                    if(Screen.devicePixelRatio == 1.0) return Text.Outline;
                    if(Screen.devicePixelRatio >= 2.0) return Text.Normal;
                    return Text.Raised;
                }
                visible: false
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        PlasmaComponents3.Label {
            id: dateLabel

            visible: main.showDate
            renderType: Text.NativeRendering
            font.family: timeLabel.font.family
            font.weight: timeLabel.font.weight
            font.italic: timeLabel.font.italic
            font.pixelSize: timeLabel.font.pixelSize
            font.hintingPreference: Font.PreferFullHinting
            minimumPixelSize: 1
            style: {
                if(Screen.devicePixelRatio == 1.0) return Text.Outline;
                if(Screen.devicePixelRatio >= 2.0) return Text.Normal;
                return Text.Raised;
            }
            styleColor: "transparent"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    /*
     * end: Visible Elements
     *
     */

    PlasmaComponents3.Label {
        id: sizehelper

        font.family: timeLabel.font.family
        font.weight: timeLabel.font.weight
        font.italic: timeLabel.font.italic
        minimumPixelSize: 1

        visible: false
    }

    FontMetrics {
        id: timeMetrics

        font.family: timeLabel.font.family
        font.weight: timeLabel.font.weight
        font.italic: timeLabel.font.italic
    }

    // Qt's QLocale does not offer any modular time creating like Klocale did
    // eg. no "gimme time with seconds" or "gimme time without seconds and with timezone".
    // QLocale supports only two formats - Long and Short. Long is unusable in many situations
    // and Short does not provide seconds. So if seconds are enabled, we need to add it here.
    //
    // What happens here is that it looks for the delimiter between "h" and "m", takes it
    // and appends it after "mm" and then appends "ss" for the seconds.
    function timeFormatCorrection(timeFormatString) {
        var regexp = /(hh*)(.+)(mm)/i
        var match = regexp.exec(timeFormatString);

        var hours = match[1];
        var delimiter = match[2];
        var minutes = match[3]
        var seconds = "ss";
        var amPm = "AP";
        var uses24hFormatByDefault = timeFormatString.toLowerCase().indexOf("ap") == -1;

        // because QLocale is incredibly stupid and does not convert 12h/24h clock format
        // when uppercase H is used for hours, needs to be h or hh, so toLowerCase()
        var result = hours.toLowerCase() + delimiter + minutes;

        if (main.showSeconds) {
            result += delimiter + seconds;
        }

        // add "AM/PM" either if the setting is the default and locale uses it OR if the user unchecked "use 24h format"
        if ((main.use24hFormat == Qt.PartiallyChecked && !uses24hFormatByDefault) || main.use24hFormat == Qt.Unchecked) {
            result += " " + amPm;
        }

        main.timeFormat = result;
        setupLabels();
    }

    function setupLabels() {
        /*var showTimezone = main.showLocalTimezone || (plasmoid.configuration.lastSelectedTimezone != "Local"
                                                        && dataSource.data["Local"]["Timezone City"] != dataSource.data[Plasmoid.configuration.lastSelectedTimezone]["Timezone City"]);

        var timezoneString = "";

        if (showTimezone) {
            timezoneString = Plasmoid.configuration.displayTimezoneAsCode ? dataSource.data[Plasmoid.configuration.lastSelectedTimezone]["Timezone Abbreviation"]
                                                                          : TimezonesI18n.i18nCity(dataSource.data[Plasmoid.configuration.lastSelectedTimezone]["Timezone City"]);
            timezoneLabel.text = (main.showDate || main.oneLineMode) && Plasmoid.formFactor == PlasmaCore.Types.Horizontal ? "(" + timezoneString + ")" : timezoneString;
        } else {
            // this clears the label and that makes it hidden
            timezoneLabel.text = timezoneString;
        }*/


        dateLabel.text = Qt.formatDate(main.currentTime, main.dateFormat);
        if(!main.showDate) dateLabel.text = dateLabel.text.slice(1) + " ";
        /*if (main.showDate) {
        } else {
            // clear it so it doesn't take space in the layout
            dateLabel.text = "";
        }*/

        // find widest character between 0 and 9
        var maximumWidthNumber = 0;
        var maximumAdvanceWidth = 0;
        for (var i = 0; i <= 9; i++) {
            var advanceWidth = timeMetrics.advanceWidth(i);
            if (advanceWidth > maximumAdvanceWidth) {
                maximumAdvanceWidth = advanceWidth;
                maximumWidthNumber = i;
            }
        }
        // replace all placeholders with the widest number (two digits)
        var format = main.timeFormat.replace(/(h+|m+|s+)/g, "" + maximumWidthNumber + maximumWidthNumber); // make sure maximumWidthNumber is formatted as string
        // build the time string twice, once with an AM time and once with a PM time
        var date = new Date(2000, 0, 1, 1, 0, 0);
        var timeAm = Qt.formatTime(date, format);
        var advanceWidthAm = timeMetrics.advanceWidth(timeAm);
        date.setHours(13);
        var timePm = Qt.formatTime(date, format);
        var advanceWidthPm = timeMetrics.advanceWidth(timePm);
        // set the sizehelper's text to the widest time string
        if (advanceWidthAm > advanceWidthPm) {
            sizehelper.text = timeAm;
        } else {
            sizehelper.text = timePm;
        }
    }

    function dateTimeChanged()
    {
        var doCorrections = false;

        if (main.showDate) {
            // If the date has changed, force size recalculation, because the day name
            // or the month name can now be longer/shorter, so we need to adjust applet size
            var currentDate = Qt.formatDateTime(getCurrentTime(), "yyyy-mm-dd");
            if (main.lastDate != currentDate) {
                doCorrections = true;
                main.lastDate = currentDate
            }
        }

        var currentTZOffset = dataSource.data["Local"]["Offset"] / 60;
        if (currentTZOffset != tzOffset) {
            doCorrections = true;
            tzOffset = currentTZOffset;
            Date.timeZoneUpdated(); // inform the QML JS engine about TZ change
        }

        if (doCorrections) {
            timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat));
        }
    }

    function setTimezoneIndex() {
        for (var i = 0; i < Plasmoid.configuration.selectedTimeZones.length; i++) {
            if (Plasmoid.configuration.selectedTimeZones[i] == Plasmoid.configuration.lastSelectedTimezone) {
                main.tzIndex = i;
                break;
            }
        }
    }

    Component.onCompleted: {

        root.initTimezones();
        // Sort the timezones according to their offset
        // Calling sort() directly on plasmoid.configuration.selectedTimeZones
        // has no effect, so sort a copy and then assign the copy to it
        var sortArray = Plasmoid.configuration.selectedTimeZones;
        sortArray.sort(function(a, b) {
            return dataSource.data[a]["Offset"] - dataSource.data[b]["Offset"];
        });
        Plasmoid.configuration.selectedTimeZones = sortArray;

        setTimezoneIndex();
        tzOffset = -(new Date().getTimezoneOffset());
        dateTimeChanged();
        timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat));
        dataSource.onDataChanged.connect(dateTimeChanged);
        dashWindow = Qt.createQmlObject("CalendarView {}", root);
    }
}
