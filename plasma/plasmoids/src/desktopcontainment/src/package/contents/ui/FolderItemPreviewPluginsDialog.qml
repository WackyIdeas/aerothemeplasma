/*
    SPDX-FileCopyrightText: 2014 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import io.gitgud.wackyideas.desktopcontainment.folder as Folder
import org.kde.kirigami 2.20 as Kirigami

Kirigami.OverlaySheet {
    id: dialog

    required property var previewPlugins

    title: i18n("Preview Plugins")

    onClosed: destroy()

    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
        onAccepted: {
            configIcons.cfg_previewPlugins = previewPluginsModel.checkedPlugins;
            dialog.close();
        }
        onRejected: dialog.close();
    }

    ListView {
        implicitWidth: Kirigami.Units.iconSizes.small * 15

        model: Folder.PreviewPluginsModel {
            id: previewPluginsModel
        }

        delegate: CheckDelegate {
            width: ListView.view.width
            text: model.display

            checked: model.checked
            onToggled: model.checked = checked;
        }
    }

    Component.onCompleted: {
        previewPluginsModel.checkedPlugins = dialog.previewPlugins;
        open();
    }
}
