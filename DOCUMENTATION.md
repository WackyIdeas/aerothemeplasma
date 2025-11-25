# Documentation

## Table of contents

1. [Introduction](#intro)
2. [Frequently asked questions](#faq)
3. [List of components](#list-of-components)
4. [Development resources](#development)


## Introduction <a name="intro"></a>

AeroThemePlasma is a project with a lot of moving parts, ranging from simple themes to entire codebases. This documentation aims to provide the following details:

- Structure and list of components
- Usage guides 
- Development resources

Documentation is currently a WIP, so expect most things to not be present.

## Frequently asked questions <a name="faq"></a>

### Is this project intended to help Windows users migrate to Linux?

No, not really.

Ultimately, this project doesn't change the fact that the underlying operating system is still Linux, and ATP's workflow doesn't diverge greatly from the typical KDE & Linux workflow. The goal of AeroThemePlasma isn't to make a 1:1 Windows desktop replacement (even though it feels like that's the intention sometimes), and it's not particularly focused on getting Windows users to migrate. The primary goal of ATP is to keep Windows 7's Aero interface alive and adapt it for modern desktops on Linux.

### Are we Wayland yet?

Kinda.

AeroThemePlasma should largely work on Wayland, save for some visual quirks that haven't been ironed out yet. There are certain issues that Wayland presents that makes development on it a bit cumbersome, as well as KWin lacking features that ATP relies on under X11. See [Wayland issues] (Coming soon) for specific details. 

### What about HiDPI?

Currently AeroThemePlasma works best on 100% scaling, but work is slowly being made towards HiDPI support. However, there are some unavoidable issues with HiDPI that ATP can't get around unfortunately, such as [QTBUG-135833](https://bugreports.qt.io/browse/QTBUG-135833) and certain Wayland problems.

### What distros are supported? 

Only Arch-based distributions are supported officially for AeroThemePlasma, and the installation scripts are written with Arch-based distributions in mind. Contributions related to supporting other distributions are welcome (in the form of providing dependencies, etc.), but I don't intend to maintain that support and keep it up to date. 

### Do you plan on recreating the file explorer (along with other Windows applications)?

Most likely no. It's out of ATP's scope. In case this changes however, most likely the only recreation would be the file explorer. 

## List of components <a name="list-of-components"></a>

- Plasma
    - Color scheme 
    - [Global theme](docs/plasma/lookandfeel.md)
    - [KCM loader](docs/plasma/kcmloader.md)
    - Layout template 
    - [Plasmoids](docs/plasma/plasmoids.md)
    - [SDDM theme](docs/plasma/sddm.md) 
    - Seven-Black Plasma style
    - [Shell](docs/plasma/shell.md)
- KWin
    - [SMOD KDecoration3 style](docs/kwin/smod.md)
    - [Effects (JS)](docs/kwin/effectsjs.md)
    - [Effects (C++)](docs/kwin/effectscpp.md)
    - [Tabbox switcher](docs/kwin/tabbox.md)
    - [Window snap outline](docs/kwin/outline.md)
    - [SMOD Peek script](docs/kwin/smodpeekscript.md)
- Misc 
    - Cursor theme 
    - Icon theme 
    - KInfoCenter branding 
    - Kvantum theme 
    - [Libplasma modifications](docs/misc/libplasma.md)
    - Mimetype modifications
    - Segoe UI fontconfig 
    - Shortcuts 
    - Sound theme 
    - User Account Control Polkit modification

## Development resources <a href="development"></a>

## Useful commands

### Restarting KDE 

When developing most things related to ATP (and KDE in general), it's useful to be able to quickly restart either Plasmashell or KWin on demand. Add the following shorthand commands to `~/.bashrc`:

```bash
alias restart-plasma='setsid plasmashell --replace'
alias restart-kwin_x11='setsid kwin_x11 --replace'
alias restart-kwin_wayland='setsid kwin_wayland --replace'
```

Which can then be used like any other command in the terminal:

```bash
restart-plasma
```

Note however that restarting KWin when using Wayland **will restart the entire compositor, which may result in certain applications being killed**. 

### Starting a nested Wayland session within X11

A KWin Wayland session can be loaded within an X11 environment using the following command: 

```bash
dbus-run-session kwin_wayland --width 1366 --height 768 --xwayland "plasmashell"
```

This spawns a nested Wayland session with the resolution of 1366x768, while also running an instance of the desktop shell.

### Get window information 

For X11-specific window properties, use `xprop`. KWin can also query windows using the following command (works on both X11 and Wayland):

```bash
qdbus6 org.kde.KWin /KWin queryWindowInfo
```

### KWin effects 

A list of KWin effects can be printed out using DBus:

```bash
qdbus6 org.kde.KWin /Effects activeEffects
qdbus6 org.kde.KWin /Effects listOfEffects
qdbus6 org.kde.KWin /Effects loadedEffects 
```

To check an effect's state: 

```bash
qdbus6 org.kde.KWin /Effects isEffectLoaded your_effect_name
qdbus6 org.kde.KWin /Effects isEffectSupported your_effect_name
```

To change an effect's loaded state:

```bash
qdbus6 org.kde.KWin /Effects loadEffect your_effect_name
qdbus6 org.kde.KWin /Effects unloadEffect your_effect_name
qdbus6 org.kde.KWin /Effects toggleEffect your_effect_name
```

## Testing 

### SDDM 

```bash
sddm-greeter-qt6 --test-mode --theme /path/to/sddm/theme
```

One thing to keep in mind when testing SDDM themes is that user resources (such as locally installed icon themes, files present in the home directory, etc.) are available only when testing like this. SDDM will fail to load any user resources in a real scenario. QML UI components may also look different in test mode. 

### Splash screen 

```bash
ksplashqml --test --window /path/to/global/theme
```

The `--test` parameter can be omitted for slightly more realistic results.

### Lock screen

```bash
/usr/lib/kscreenlocker_greet --testing
```

Runs the lock screen in testing mode, opening a lock screen window for every display.

### Ctrl+Alt+Del screen

```bash
/usr/lib/ksmserver-logout-greeter --windowed
```

### Qt test application 

```bash
kvantumpreview -style [qstyle]
```

Running without passing `-style` will simply load the application with the currently applied QStyle. 

### Testing notifications 

```bash
notify-send -a Dolphin -h string:desktop-entry:org.kde.dolphin "Lorem ipsum dolor sit amet" "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." -i org.kde.dolphin --action=inline-reply="Reply" --action="Test"
```

This will spawn a notification with a sufficiently long body, presenting as Dolphin, and provides actions in the form of regular actions and inline replies. 

In order to test thumbnail previews for notifications, one or more URLs need to be passed to the notification as well. This can't be done in the terminal (to my knowledge, at least), so some kind of scripting or the use of KNotification is required.

## Logging 

### From the terminal

Restarting Plasmashell or KWin as described above results in output being printed to `stdout` which is readable by the terminal emulator. By default, `kwin_wayland` doesn't output logs to `stdout`, and in that case it's difficult to get logs this way. 

As for KCMs, their respective logs can be retrieved by running System settings from the terminal:

```bash
systemsettings
```

### Getting logs from KSystemLog

Alternatively, logs can be retrieved graphically from systemd's journal by using [KSystemLog](https://apps.kde.org/ksystemlog/).


## Useful tools

- [AeroGlassPane](https://gitgud.io/wackyideas/aero-glass-pane) - Useful for testing AeroGlassBlur and SMOD Decorations
- [Heaptrack](https://github.com/KDE/heaptrack) - Heap memory profiler, useful for detecting memory leaks and call stacks
- [KAppTemplate](https://apps.kde.org/kapptemplate/) - Templates for Qt and Plasma projects
- [KDebugSettings](https://apps.kde.org/kdebugsettings/) - Configures the verbosity of log output for KDE applications/services 
- [Kirigami Gallery](https://apps.kde.org/kirigami2.gallery/) - Useful for viewing color groups and color sets
- [KSystemLog](https://apps.kde.org/ksystemlog/) - General logging application
- [msstyleEditor](https://github.com/nptr/msstyleEditor) - Useful for viewing and modifying msstyle themes on Windows
- [Plasma SDK](https://github.com/KDE/plasma-sdk) - Features several useful applications for Plasma development 
- [Qt Creator](https://www.qt.io/product/development-tools) - IDE for Qt applications, useful for QtWidgets codebases and standalone KDE projects
- [RccExtended](https://github.com/zedxxx/rccextended) - Required for editing SMOD resource files
- [ResourceHacker](https://www.angusj.com/resourcehacker/) - Useful for viewing and extracting resources from Windows

## External references

- Color scheme ([KDE docs](https://docs.kde.org/stable5/en/plasma-workspace/kcontrol/colors/index.html), [video guide](https://www.youtube.com/watch?v=6VW--o7CEEA))
- Cursor theme ([Freedesktop specification](https://www.freedesktop.org/wiki/Specifications/cursor-spec/))
- Icon theme ([Freedesktop](https://specifications.freedesktop.org/icon-naming-spec/icon-naming-spec-latest.html) [specification](https://specifications.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html))
- [KDE Developer Platform](https://develop.kde.org/) - Useful for pretty much everything involving ATP (Plasmoids, KWin effects, APIs, Plasma styles, etc.)
- Kvantum theme* ([Kvantum](https://raw.githubusercontent.com/tsujan/Kvantum/master/Kvantum/doc/Theme-Making.pdf) [documentation](https://raw.githubusercontent.com/tsujan/Kvantum/master/Kvantum/doc/Theme-Config.pdf))
- MSStyles ([msstyleEditor](https://github.com/nptr/msstyleEditor), Windows Style Builder)
- [Qt Documentation](https://doc.qt.io/) - Essential for Qt development
- Sound theme ([Freedesktop specification](https://eode.pages.freedesktop.org/xdg-specs/sound-theme-spec/sound-theme-spec-latest.html))

*While Kvantum won't be discussed here, one important detail worth mentioning is that Kvantum does not respect KDE's color schemes for the most part and that this sometimes leads to unexpected visual results. Still, it's recommended to apply a KDE color scheme alongside Kvantum for maximum compatibility.
