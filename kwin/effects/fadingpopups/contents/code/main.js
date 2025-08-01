/*
    KWin - the KDE window manager
    This file is part of the KDE project.

    SPDX-FileCopyrightText: 2018 Vlad Zahorodnii <vlad.zahorodnii@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

"use strict";

var blacklist = [
    // ignore black background behind lockscreen
    "ksmserver ksmserver",
    // The logout screen has to be animated only by the logout effect.
    "ksmserver-logout-greeter ksmserver-logout-greeter",
    // The lockscreen isn't a popup window
    "kscreenlocker_greet kscreenlocker_greet",
    // KDE Plasma splash screen has to be animated only by the login effect.
    "ksplashqml ksplashqml",
];

var blacklistNames = [
    "seventasks-floatingavatar",
    "aerothemeplasma-windowframe-special",
    "sevenstart-menurepresentation",
    "aerothemeplasma-tabbox"
];

function isDropdownMenu(window) {
    if(window.managed) return false;
    if(window.dropdownMenu) return true;
    return false;
}
function isContextMenu(window) {
    // Wayland seriously has an insane way to represent context menus
    //if(window.managed && window.popupWindow && window.windowType == -1 && ????)

    if(window.managed) return false;
    if(window.popupMenu) return true;
    return false;
}
function belongsToPlasmashell(window) {
    return window.windowClass == "plasmashell plasmashell" || window.windowClass == "plasmashell org.kde.plasmashell"
}
function isPopupWindow(window) {

    // If the window is blacklisted, don't animate it.
    if (blacklist.indexOf(window.windowClass) != -1) {
        return false;
    }

    if(window.specialWindow && (window.windowClass == "kwin_x11 kwin" || window.windowClass == "kwin_wayland kwin")) {
        return false;
    }
    //console.log(window.windowClass + " " + window.dialog);
    if((window.dialog || window.windowType == 2) && belongsToPlasmashell(window)) {
        return false;
    }
    if(window.dock && belongsToPlasmashell(window)) {
        return false;
    }
    if(window.desktop && belongsToPlasmashell(window)) {
        return false;
    }
    if(blacklistNames.indexOf(window.caption) != -1) {
        return false;
    }
    if(window.appletPopup) return false;
    // Animate combo box popups, tooltips, popup menus, etc.

    if(window.tooltip) return true;

    // Maybe the outline deserves its own effect.
    if (window.outline) {
        return true;
    }
    if (isContextMenu(window)) {
        return false;
    }
    if (isDropdownMenu(window)) {
        return false;
    }

    // Override-redirect windows are usually used for user interface
    // concepts that are expected to be animated by this effect, e.g.
    // popups that contain window thumbnails on X11, etc.
    if (!window.managed) {
        // Some utility windows can look like popup windows (e.g. the
        // address bar dropdown in Firefox), but we don't want to fade
        // them because the fade effect didn't do that.
        if (window.utility) {
            return false;
        }

        return true;
    }

    if(window.popupWindow) return true;
    // Previously, there was a "monolithic" fade effect, which tried to
    // animate almost every window that was shown or hidden. Then it was
    // split into two effects: one that animates toplevel windows and
    // this one. In addition to popups, this effect also animates some
    // special windows(e.g. notifications) because the monolithic version
    // was doing that.
    if (window.dock || window.splash || window.toolbar
            || window.notification || window.onScreenDisplay
            || window.criticalNotification) {
        return true;
    }

    return false;
}

var dropdownWindowList = 0;
var fadingPopupsEffect = {
    loadConfig: function () {
        fadingPopupsEffect.fadeInDuration = animationTime(150);
        fadingPopupsEffect.fadeOutDuration = animationTime(150) * 3;
    },
    slotWindowAdded: function (window) {
        if (effects.hasActiveFullScreenEffect) {
            return;
        }
        const dropdown = isDropdownMenu(window);
        if (!isPopupWindow(window)) {
            if(dropdown && dropdownWindowList > 0) {
                dropdownWindowList++;
                return;
            } else if(!dropdown && !isContextMenu(window)) {
                return;
            }
        }
        if(dropdown) {
            dropdownWindowList++;
        }
        if (!window.visible) {
            return;
        }
        if (!effect.grab(window, Effect.WindowAddedGrabRole)) {
            return;
        }
        window.fadeInAnimation = animate({
            window: window,
            curve: QEasingCurve.Linear,
            duration: fadingPopupsEffect.fadeInDuration,
            type: Effect.Opacity,
            from: 0.0,
            to: 1.0
        });
    },
    slotWindowClosed: function (window) {
        if (effects.hasActiveFullScreenEffect) {
            return;
        }
        if (!isPopupWindow(window)) {
            return;
        }
        if (!window.visible || window.skipsCloseAnimation) {
            return;
        }
        if (!effect.grab(window, Effect.WindowClosedGrabRole)) {
            return;
        }
            window.fadeOutAnimation = animate({
                window: window,
                curve: QEasingCurve.OutQuart,
                duration: fadingPopupsEffect.fadeOutDuration,
                type: Effect.Opacity,
                from: 1.0,
                to: 0.0
            });


    },
    slotWindowDataChanged: function (window, role) {
        if (role == Effect.WindowAddedGrabRole) {
            if (window.fadeInAnimation && effect.isGrabbed(window, role)) {
                cancel(window.fadeInAnimation);
                delete window.fadeInAnimation;
            }
        } else if (role == Effect.WindowClosedGrabRole) {
            if (window.fadeOutAnimation && effect.isGrabbed(window, role)) {
                cancel(window.fadeOutAnimation);
                delete window.fadeOutAnimation;
            }
        }
    },
    slotWindowDeleted: function(window) {
        if(isDropdownMenu(window)) {
            dropdownWindowList--;
            if(dropdownWindowList < 0) dropdownWindowList = 0;
        }
    },
    init: function () {
        fadingPopupsEffect.loadConfig();

        effect.configChanged.connect(fadingPopupsEffect.loadConfig);
        effects.windowAdded.connect(fadingPopupsEffect.slotWindowAdded);
        effects.windowClosed.connect(fadingPopupsEffect.slotWindowClosed);
        effects.windowDataChanged.connect(fadingPopupsEffect.slotWindowDataChanged);
        effects.windowDeleted.connect(fadingPopupsEffect.slotWindowDeleted);
    }
};

fadingPopupsEffect.init();
