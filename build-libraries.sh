#!/bin/bash
OUTPUT="$(pwd)/output"

# OpenAL-soft is copied from the debian binary package
# TODO: Work out the correct set of dependencies / build args to produce
# a working library when compiled from source here!
cp /usr/lib/x86_64-linux-gnu/libopenal.so.1 "${OUTPUT}/libopenal.so"

# SDL2 is compiled from source
curl -sLO http://www.libsdl.org/release/SDL2-2.0.8.tar.gz
tar xf SDL2-2.0.8.tar.gz
pushd SDL2-2.0.8
./configure --prefix "$(pwd)/output" --disable-rpath --enable-sdl-dlopen --disable-loadso  --disable-audio --enable-x11-shared --disable-video-directfb --disable-video-vulkan --disable-video-dummy --disable-power --disable-joystick --disable-haptic --disable-filesystem --disable-threads --disable-file --disable-cpuinfo --disable-input-tslib
make && make install
cp output/lib/libSDL2.so "${OUTPUT}"
popd

# Lua 5.1 is compiled from source
curl -sLO https://www.lua.org/ftp/lua-5.1.5.tar.gz
tar xf lua-5.1.5.tar.gz
pushd lua-5.1.5
patch -p1 < ../lua51.patch
make linux
cp src/liblua.so.5.1 "${OUTPUT}/liblua.so"
popd