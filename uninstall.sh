#!/bin/bash
CUR_DIR=$(pwd)

# Sanity check to see if the proper tools are installed.
if [[ -z "$(command -v kpackagetool6)" ]]; then
    echo "kpackagetool6 not found. Stopping."
    exit
fi
if [[ -z "$(command -v qdbus6)" ]]; then
    echo "qdbus6 not found. Stopping."
    exit
fi

PLASMASHELL=$(qdbus6 org.kde.plasmashell /PlasmaShell shell)

if [ $PLASMASHELL == "io.gitgud.wackyideas.desktop" ]; then
    echo -e "You shouldn't run the uninstall script from AeroThemePlasma itself."
    echo -e "Please run the uninstall script from the Plasma session or another session."
    exit
fi

BUILD_FILES=("kwin/decoration/build" 
   "plasma/sddm/login-sessions/build" 
   "plasma/aerothemeplasma-kcmloader/build" 
   "plasma/plasmoids/src/systemtray_src/build" 
   "plasma/plasmoids/src/notifications_src/build" 
   "plasma/plasmoids/src/volume_src/build" 
   "plasma/plasmoids/src/sevenstart_src/build" 
   "plasma/plasmoids/src/seventasks_src/build" 
   "plasma/plasmoids/src/desktopcontainment/build" 
   "kwin/effects_cpp/kde-effects-aeroglassblur/build" 
   "kwin/effects_cpp/kwin-effect-smodsnap-v2/build" 
   "kwin/effects_cpp/smodglow/build" 
   "kwin/effects_cpp/aeroglide/build" 
   "kwin/effects_cpp/startupfeedback/build" 
   "kwin/effects_cpp/kde-effects-aeroglassblur/build-wl" 
   "kwin/effects_cpp/kwin-effect-smodsnap-v2/build-wl" 
   "kwin/effects_cpp/smodglow/build-wl" 
   "kwin/effects_cpp/aeroglide/build-wl" 
   "kwin/effects_cpp/startupfeedback/build-wl" 
)

function uninstall_cmake_component {
    if [ ! -f "$CUR_DIR/$1/install_manifest.txt" ]; then
        echo -e "File install_manifest.txt in $CUR_DIR/$1 was not found."
        echo -e "If this component was already removed from the system, you can ignore this message.\n"
        echo -e "Otherwise, to generate this file, run the compile.sh and install_plasmoids.sh scripts again like this:"
        echo -e "$ bash compile.sh --skip-libplasma [--ninja]"
        echo -e "$ bash install_plasmoids.sh --skip-kpackages [--ninja]"
        echo -e "Afterwards, re-run this script."
    else
        cd "$CUR_DIR/$1"
        BUILD_TOOL=make
        if [ -f "build.ninja" ]; then
            BUILD_TOOL=ninja
        fi
        sudo $BUILD_TOOL uninstall
        echo -e "Done."
        cd "$CUR_DIR"
    fi
}

for path in ${BUILD_FILES[@]}; do
    uninstall_cmake_component "$path"
done

function uninstall_prompt {
    echo -e "Do you want to uninstall: $1? (y/N)"
    if [ ! -z "$2" ]; then
        echo -e "The following will be removed: $2"
    fi
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
        return 1
    else
        return 0
    fi
}

function uninstall_plasmoid {
    PLASMOID=$(basename "$1")
    if [[ $PLASMOID == 'src' ]]; then
        echo "Skipping $PLASMOID"
        return
    fi
    if [[ $PLASMOID == 'io.gitgud.wackyideas.systemtray' ]]; then
        pkexec kpackagetool6 -t "Plasma/Applet" -g -r "$1"
    else
        kpackagetool6 -t "Plasma/Applet" -r "$1"
    fi
    echo -e "Uninstalled $1.\n"
    cd "$CUR_DIR"
}

function uninstall_component {
    COMPONENT=$(basename "$1")
    kpackagetool6 -t "$2" -r "$1"
    echo -e "Uninstalled $1.\n"
    cd "$CUR_DIR"
}

uninstall_prompt "Plasmoids"
if [ "$?" == 1 ]; then
    echo "Uninstalling plasmoids..."
    for filename in "$PWD/plasma/plasmoids/"*; do
        uninstall_plasmoid "$filename"
    done
fi

uninstall_prompt "Plasma components"
if [ "$?" == 1 ]; then
    echo "Uninstalling Plasma components..."
    uninstall_component "authui7" "Plasma/LookAndFeel"
    uninstall_component "io.gitgud.wackyideas.taskbar" "Plasma/LayoutTemplate"
    uninstall_component "Seven-Black" "Plasma/Theme"
    uninstall_component "io.gitgud.wackyideas.desktop" "Plasma/Shell"
fi


COLOR_DIR="$HOME/.local/share/color-schemes"
uninstall_prompt "Color scheme" "$COLOR_DIR/Aero.colors"
if [ "$?" == 1 ]; then
    echo "Uninstalling color scheme..."
    rm "$COLOR_DIR/Aero.colors"
    echo "Done."
fi

KV_DIR="$HOME/.config/Kvantum"
uninstall_prompt "Kvantum theme" "$KV_DIR/Windows7Aero"
if [ "$?" == 1 ]; then
    echo "Uninstalling Kvantum theme..."
    kvantummanager --set KvAdapta
    rm -r "$KV_DIR/Windows7Aero"
    echo "Done."
fi

uninstall_prompt "Sound themes" "$(echo "$HOME/.local/share/sounds/Windows 7"*)"
if [ "$?" == 1 ]; then
    echo "Uninstalling sound themes..."
    for filename in "$HOME/.local/share/sounds/Windows 7"*; do
        rm -r "$filename"
    done
    echo "Done."
fi

ICONS_DIR="$HOME/.local/share/icons"
uninstall_prompt "Icon theme" "$ICONS_DIR/Windows 7 Aero"
if [ "$?" == 1 ]; then
    echo "Uninstalling icon theme..."
    rm -r "$ICONS_DIR/Windows 7 Aero"
    echo "Done."
fi

MIMETYPE_DIR="$HOME/.local/share/mime/packages"
uninstall_prompt "Mimetypes" "$MIMETYPE_DIR/application-vnd.microsoft.portable-executable.xml application-x-ms-dll.xml application-x-msdownload.xml application-x-ms-ne-executable.xml"
if [ "$?" == 1 ]; then
    echo "Uninstalling mimetypes..."
    for filename in "$PWD/misc/mimetype/"*; do
        MIME=$(basename $filename)
        rm "$MIMETYPE_DIR/$MIME"
    done
    update-mime-database "$HOME/.local/share/mime"
    echo "Done."
fi

uninstall_prompt "KWin JS effects"
if [ "$?" == 1 ]; then
    echo "Uninstalling KWin effects (JS)..."
    for filename in "$PWD/kwin/effects/"*; do
        uninstall_component "$filename" "KWin/Effect"
    done
    echo "Done."
fi

uninstall_prompt "KWin scripts"
if [ "$?" == 1 ]; then
    echo "Uninstalling KWin scripts..."
    for filename in "$PWD/kwin/scripts/"*; do
        uninstall_component "$filename" "KWin/Script"
    done
    echo "Done."
fi

uninstall_prompt "KWin task switchers"
if [ "$?" == 1 ]; then
    echo "Uninstalling KWin task switchers..."
    for filename in "$PWD/kwin/tabbox/"*; do
        uninstall_component "$filename" "KWin/WindowSwitcher"
    done
    echo "Done."
fi

KWIN_DIR="$HOME/.local/share/kwin"
echo "Uninstalling KWin outline"
rm -r "$KWIN_DIR/outline"

if [[ -L "$KWIN_DIR-x11" && -d "$KWIN_DIR-x11" ]]; then
    echo "kwin-x11 folder is a symlink, remove it."
    rm "$KWIN_DIR-x11"
fi

if [[ -L "$KWIN_DIR-wayland" && -d "$KWIN_DIR-wayland" ]]; then
    echo "kwin-wayland folder is a symlink, remove it."
    rm "$KWIN_DIR-wayland"
fi

BRANDING_DIR="$HOME/.config/kdedefaults"
if [ ! -z "$(grep -rni "aerothemeplasma" "$BRANDING_DIR/kcm-about-distrorc")" ]; then
    echo "Uninstalling branding..."
    rm "$BRANDING_DIR/kcm-about-distrorc"
    rm "$BRANDING_DIR/kcminfo.png"
fi

CURSOR_DIR="/usr/share/icons/aero-drop"
uninstall_prompt "Cursor theme (requires sudo privileges)" "$CURSOR_DIR"
if [ "$?" == 1 ]; then
    echo "Uninstalling cursor theme..."
    pkexec rm -r "$CURSOR_DIR"
    echo "Done."
fi

SDDM_DIR="/usr/share/sddm/themes/sddm-theme-mod"
uninstall_prompt "SDDM theme (requires sudo privileges)" "$SDDM_DIR"
if [ "$?" == 1 ]; then
    echo "Uninstalling SDDM theme..."
    pkexec rm -r "$SDDM_DIR"
    echo "Done."
fi

SMOD_DIR="/usr/share/smod"
uninstall_prompt "SMOD files (requires sudo privileges)" "$SMOD_DIR"
if [ "$?" == 1 ]; then
    echo "Uninstalling SMOD files..."
    pkexec rm -r "$SMOD_DIR"
    echo "Done."
fi

LIBDIR="/usr/lib/x86_64-linux-gnu/"
if [ ! -d ${LIBDIR} ]; then
	LIBDIR="/usr/lib64/"
fi
APPLET_DIR="${LIBDIR}qt6/plugins/plasma/applets/"
uninstall_prompt "Plasma applets (requires sudo privileges)" "${APPLET_DIR}/io.gitgud.wackyideas."*
if [ "$?" == 1 ]; then
    echo "Uninstalling Plasma applet plugins..."
    pkexec rm -r "${APPLET_DIR}/io.gitgud.wackyideas."*
    echo "Done."
fi

echo "Uninstalling /opt/aerothemeplasma..."
pkexec rm -r "/opt/aerothemeplasma"
echo "Done."


echo -e "Uninstallation complete."
echo -e "In order to uninstall the libplasma and polkit agent modifications, simply reinstall those packages using your distro's package manager."

