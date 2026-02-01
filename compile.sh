#!/bin/bash

# You can pass the following arguments to this script:
# --ninja           Uses Ninja for faster compilation
# --wayland         Tells the KWin build scripts to compile the C++ effects for Wayland
# --skip-libplasma  Skips compiling libplasma patches

CUR_DIR=$(pwd)
USE_SCRIPT="install.sh"

# Sanity check to see if the proper tools are installed.
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

# Compiles the libplasma patches required for other components of ATP.
# Requires a restart to be applied.
if [[ "$*" != *"--skip-libplasma"* ]]; then
    cd "$PWD/misc/libplasma"
    bash $USE_SCRIPT $@
    cd "$CUR_DIR"
fi
#echo "Compiling plasmoids..."

#for filename in "$PWD/plasma/plasmoids/src/"*; do
#    cd "$filename"
#    echo "Compiling $(pwd)"
#    sh $USE_SCRIPT
#    echo "Done."
#    cd "$CUR_DIR"
#done

# Compiles the window decoration theme engine.
echo "Compiling SMOD decorations..."
cd "$PWD/kwin/decoration"
bash $USE_SCRIPT $@
cd "$CUR_DIR"
echo "Done."

echo -e "Installing login manager entries..."
cd "$PWD/plasma/sddm/login-sessions"
bash $USE_SCRIPT
echo "Done."

# Compiles the settings KCM loader used for development and quick access of certain settings pages.
echo "Compiling KCM loader..."
cd "$PWD/plasma/aerothemeplasma-kcmloader"
bash $USE_SCRIPT $@
cd "$CUR_DIR"
echo "Done."

# Compiles all the KWin C++ effects, going folder by folder.
echo "Compiling KWin effects..."
for filename in "$PWD/kwin/effects_cpp/"*; do
    cd "$filename"
    echo "Compiling $(pwd)"
    bash $USE_SCRIPT $@
    echo "Done."
    cd "$CUR_DIR"
done
