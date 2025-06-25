/*
 * Copyright 2013  Bhushan Shah <bhush94@gmail.com>
 * Copyright 2015  Martin Klapetek <mklapetek@kde.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License or (at your option) version 3 or any later version
 * accepted by the membership of KDE e.V. (or its successor approved
 * by the membership of KDE e.V.), which shall act as a proxy
 * defined in Section 14 of version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import QtQml 2.2

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.configuration
import org.kde.plasma.workspace.calendar 2.0 as PlasmaCalendar

ConfigModel {
    id: configModel

    ConfigCategory {
         name: i18n("Appearance")
         icon: "preferences-desktop-color"
         source: "configAppearance.qml"
    }
    ConfigCategory {
        name: i18n("Calendar")
        icon: "preferences-system-time"
        source: "configCalendar.qml"
    }
    ConfigCategory {
        name: i18n("Time Zones")
        icon: "preferences-desktop-locale"
        source: "configTimeZones.qml"
    }

    property QtObject eventPluginsManager: PlasmaCalendar.EventPluginsManager {
        Component.onCompleted: {
            populateEnabledPluginsList(Plasmoid.configuration.enabledCalendarPlugins);
        }
    }

    property Instantiator __eventPlugins: Instantiator {
        model: eventPluginsManager.model
        delegate: ConfigCategory {
            name: model.display
            icon: model.decoration
            source: model.configUi
            visible: Plasmoid.configuration.enabledCalendarPlugins.indexOf(model.pluginId) > -1
        }


        onObjectAdded: (index, object) => configModel.appendCategory(object)
        onObjectRemoved: (index, object) => configModel.removeCategory(object)
        //onObjectAdded: configModel.appendCategory(object)
        //onObjectRemoved: configModel.removeCategory(object)
    }

}
