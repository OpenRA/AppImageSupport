#!/bin/sh
OUTPUT="$(pwd)/output"

# OpenAL-soft is copied from the epel6 package
# TODO: Work out the correct set of dependencies / build args to produce
# a working library when compiled from source here!
cp /usr/lib64/libopenal.so.1 "${OUTPUT}/libopenal.so"

# SDL2 is compiled from source
curl -sLO http://www.libsdl.org/release/SDL2-2.0.8.tar.gz
tar xf SDL2-2.0.8.tar.gz
pushd SDL2-2.0.8
./configure --prefix "$(pwd)/output"
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