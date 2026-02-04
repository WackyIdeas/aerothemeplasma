# AeroThemePlasma

## Microsoft® Windows™ is a registered trademark of Microsoft® Corporation. This name is used for referential use only, and does not aim to usurp copyrights from Microsoft. Microsoft Ⓒ 2025 All rights reserved. All resources belong to Microsoft Corporation.

## Introduction

This is a project which aims to recreate the look and feel of Windows 7 as much as possible on KDE Plasma, whilst adapting the design to fit in with modern features provided by KDE Plasma and Linux.

ATP is in constant development and testing, it has been tested on:

- Arch Linux x64 and other Arch derivatives
- Plasma 6.5.5, KDE Frameworks 6.22.0, Qt 6.10.1
- 96 DPI scaling, multi monitor
- X11, Wayland*

*AeroThemePlasma currently lacks full Wayland support, which may result in Wayland-specific issues. 

## This project overwrites a small number of [system](https://gitgud.io/wackyideas/aerothemeplasma/-/tree/master/misc/libplasma) [files](https://gitgud.io/wackyideas/aerothemeplasma/-/tree/master/misc/uac-polkitagent), it's always recommended to make backups of your system just in case. I am not responsible for broken systems, please proceed with caution.

The Plasma 5 version of ATP is available as a tag in this repository, however it is unmaintained and no longer supported.

If you find my work valuable consider donating:

<a href='https://ko-fi.com/M4M2NJ9PJ' target='_blank'><img height='42' style='border:0px;height:42px;' src='https://storage.ko-fi.com/cdn/kofi2.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

[GitHub mirror](https://github.com/WackyIdeas/aerothemeplasma)

## Installation

See [INSTALL.md](./INSTALL.md) for a detailed installation guide.

## Credits 

Huge thanks to everyone who helped out along the way by contributing, testing, providing suggestions and generally making ATP possible:

### Forked code

- Intika's [Digital Clock Lite](https://store.kde.org/p/1225135/) plasmoid
- [Adhe](https://store.kde.org/p/1386465/), [oKcerG](https://github.com/oKcerG/QuickBehaviors) and [SnoutBug](https://store.kde.org/p/1720532) for making SevenStart possible
- Zren's [Win7 Show Desktop](https://store.kde.org/p/2151247) plasmoid
- [Mirko Gennari](https://store.kde.org/p/998614), DrGordBord and [bionegative](https://www.pling.com/p/998823) for making SevenBlack possible
- DrGordBord's [Windows 7 Kvantum](https://store.kde.org/p/1679903) theme
- [taj-ny](https://github.com/taj-ny)'s [kwin-effects-forceblur](https://github.com/taj-ny/kwin-effects-forceblur)

### Contributors
- [Souris-2d07](https://gitgud.io/souris) for making the following: 
    - Cursor theme
    - Plymouth theme (old)
    - SDDM theme
    - KWin decoration theme
    - Most KWin C++ effects
    - Other minor KWin features and scripts
- [That Linux Dude Dominic Hayes](https://github.com/dominichayesferen) for making the following: 
    - Lock screen UI 
    - Icon theme
- [catpswin56](https://gitgud.io/catpswin56/) for help with SevenTasks, Sound Mixer plasmoid, Gadgets menu, Polkit UAC skin, as well as many more contributions
- [QuinceTart10](https://github.com/QuinceTart10) and [Gamer95875](https://github.com/Gamer95875) for making the sound themes
- (In collaboration with) [kfh83](https://github.com/kfh83), [TorutheRedFox](https://github.com/TorutheRedFox) and [ALTaleX](https://github.com/ALTaleX531/dwm_colorization_calculator/blob/main/main.py) for figuring out accurate Aero glass blur and colorization effects
- [AngelBruni](https://github.com/angelbruni) for contributing several SVG textures, most notably the clock in DigitalClockLite Seven
- [ricewind012](https://github.com/ricewind012/) for .bashrc Microsoft Windows header
- [furkrn](https://gitgud.io/furkrn) for creating and maintaining the [Plymouth theme](https://github.com/furkrn/PlymouthVista)
- [IcyGuidance](https://gitgud.io/IcyGuidance) for designing the notification badges in SevenTasks

### Special Thanks 

- [MondySpartan](https://www.deviantart.com/mondyspartan/art/Windows-10-Year-2010-Edition-1016859431) for inspiring the notification design

### Cool projects you should really check out

- [Geckium](https://github.com/angelbruni/Geckium) by AngelBruni
- [Aero UserChrome](https://gitgud.io/souris/aero-userchrome) by Souris (Geckium in combination with Aero UserChrome works well with AeroThemePlasma)
- [VistaThemePlasma](https://gitgud.io/catpswin56/vistathemeplasma/) by catpswin56
- [LonghornThemePlasma](https://gitgud.io/catpswin56/longhornthemeplasma) by catpswin56
- [VB1ThemePlasma](https://gitgud.io/catpswin56/vista-beta-plasma) by catpswin56
- [Harmony](https://gitgud.io/catpswin56/harmony) by catpswin56
- [Gadgets](https://gitgud.io/catpswin56/win-gadgets) by catpswin56
- [WinXplorer](https://gitgud.io/catpswin56/winxplorer) by catpswin56
- [SMOD Themes](https://gitgud.io/catpswin56/smod-themes) by catpswin56, a collection of themes that can be used with the SMOD window decoration theme
- [Ice2K.sys](https://toiletflusher.neocities.org/ice2k/) by 0penrc
- [Sevulet](https://gitgud.io/snailatte/sevulet) by [snailatte](https://gitgud.io/snailatte)

## Vista variant

Initially I wanted to make a Vista variant of AeroThemePlasma but [catpswin56](https://gitgud.io/catpswin56) beat me to it, use [VistaThemePlasma](https://gitgud.io/catpswin56/vistathemeplasma/) if you want a Vista theme.

## Screenshots

### Desktop

![desktop](screenshots/desktop.png)

### Start Menu

![start_menu](screenshots/start_menu.png)
![start_menu_search](screenshots/start_menu_search.png)
![start_menu_apps](screenshots/start_menu_apps.png)
![start_menu_openshell](screenshots/start_menu_openshell.png)

### Clock

![clock](screenshots/clock.png)

### System Tray

![battery](screenshots/battery.png)
![systray](screenshots/system_tray.png)

### Sound Mixer 

![mixer](screenshots/mixer.png)
![mixer_expanded](screenshots/mixer_expanded.png)

### Notifications 

![notification](screenshots/notification.png)
![notification-progress](screenshots/notification-progress.png)

### Desktop Icons 

![desktop-icons](screenshots/icons.png)

### Lockscreen 

![lockscreen](screenshots/lockscreen.png)

### Aero Peek

![aero-peek](screenshots/peek.png)

### Alt-Tab Switcher

![alt-tab](screenshots/alt-tab.png)

### Colorization 

![colorization](screenshots/colorization.png)
Regular colorization:
![regular-colorization](screenshots/aeroblur.png)
Basic colorization:
![basic-colorization](screenshots/aeroblursimple.png)
Maximized opaque colorization:
![maximized-colorization](screenshots/aeroblur_opaque.png)

### Decorations

![decorations](screenshots/decorations.png)

Decoration themes:

![decoration-themes](screenshots/smod_theme.png)

### Gadgets 

![gadgets](screenshots/gadgets.png)

### Network details

![network-details](screenshots/network-details.png)

### Librewolf

![librewolf](screenshots/geckium.png)

### User Account Control (Polkit)

![uac](screenshots/uac.png)
![uac-trusted](screenshots/uac-trusted.png)

### Taskbar

![taskbar](screenshots/jumplist.png)
![taskbar_tooltips](screenshots/seventasks_media.png)
![taskbar_inactive](screenshots/seventasks_inactive.png)
![taskbar_compact](screenshots/seventasks_compact.png)
