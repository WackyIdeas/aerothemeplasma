#!/bin/bash
rm -rf build
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -G Ninja ..
sudo ninja install
