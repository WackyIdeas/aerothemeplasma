#!/bin/bash

# You can pass the following arguments to this script:
# --ninja       Uses Ninja for faster compilation
# --no-compile  Skips compilation entirely

CUR_DIR=$(pwd)
USE_SCRIPT="install.sh"

# Sanity check to see if the proper tools are installed.
if [[ -z "$(command -v kpackagetool6)" ]]; then
    echo "kpackagetool6 not found. Stopping."
    exit
fi

if [[ -z "$(command -v cmake)" ]]; then
    echo "CMake not found. Stopping."
    exit
fi
if [[ -z "$(command -v ninja)" ]]; then
    if [[ -z "$(command -v make)" ]]; then
        echo "Neither Ninja or GNU Make were found. Stopping"
        exit
    fi
fi

# Skips the build process of plasmoids that have C++ components
# Most of the time, recompiling isn't needed as most changes are done
# on the QML side.
if [[ "$*" == *"--no-compile"* ]]; then
    echo "Skipping compilation..."
else
    echo "Compiling plasmoids..."

    for filename in "$PWD/plasma/plasmoids/src/"*; do
        cd "$filename"
        echo "Compiling $(pwd)"
        bash $USE_SCRIPT $@
        echo "Done."
        cd "$CUR_DIR"
    done
fi

# Installs or upgrades plasmoids using kpackagetool6
function install_plasmoid {
    PLASMOID=$(basename "$1")
    if [[ $PLASMOID == 'src' ]]; then
        echo "Skipping $PLASMOID"
        return
    fi
    INSTALLED=$(kpackagetool6 -l -t "Plasma/Applet" | grep $PLASMOID)
    if [[ -z "$INSTALLED" ]]; then
        echo "$PLASMOID isn't installed, installing normally..."
        kpackagetool6 -t "Plasma/Applet" -i "$1"
    else
        echo "$PLASMOID found, upgrading..."
        kpackagetool6 -t "Plasma/Applet" -u "$1"
    fi
    echo -e "\n"
    cd "$CUR_DIR"
}

# KPackageTool will update plasmoids on the fly, and this results in
# the system tray forgetting the visibility status of upgraded plasmoids.
# As such, we need to first terminate plasmashell in order to retain
# saved configurations

if [[ "$*" == *"--skip-kpackages"* ]]; then
    echo -e "Skipping QML Plasmoids"
else
    killall plasmashell
    for filename in "$PWD/plasma/plasmoids/"*; do
        install_plasmoid "$filename"
    done
    setsid plasmashell --replace & # Restart plasmashell and detach it from the script
fi



