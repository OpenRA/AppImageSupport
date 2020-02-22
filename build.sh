#!/bin/bash

RUNTIME_URL="https://download.mono-project.com/runtimes/raw/mono-6.4.0-ubuntu-16.04-x64"
DEB_URL="https://download.mono-project.com/repo/ubuntu/pool/main/m/mono/mono-runtime-common_6.4.0.198-0xamarin3+ubuntu1604b1_amd64.deb"
CERTSYNC_URL="https://download.mono-project.com/repo/ubuntu/pool/main/m/mono/ca-certificates-mono_6.4.0.198-0xamarin3+ubuntu1604b1_all.deb"

OUTPUT="$(pwd)/output"
mkdir "${OUTPUT}"

mkdir -p "${OUTPUT}/usr/bin"
mkdir -p "${OUTPUT}/usr/lib"
mkdir "${OUTPUT}/etc"

# Mono 6.4.0 is copied from upstream's `mkbundle` cross-compiler backend data
# Before updating, use `objdump -T` to confirm that the `mono` binary and support
# libraries do not resolve any glibc symbols > 2.17, to maintain support with CentOS 7

mkdir mono
pushd mono
curl -sLO "${RUNTIME_URL}"
unzip $(basename "${RUNTIME_URL}")

# Core mono files
mkdir -p "${OUTPUT}/usr/lib/mono/4.5"
mkdir -p "${OUTPUT}/etc/mono/4.5"
cp bin/mono "${OUTPUT}/usr/bin/"
sed "s|\$mono_libdir/||g" etc/mono/config > "${OUTPUT}/etc/mono/config"
cp etc/mono/4.5/machine.config "${OUTPUT}/etc/mono/4.5/"

# Runtime dependencies
# The required files can be found by running the following in the OpenRA engine directory:
#   cp OpenRA.Game.exe OpenRA.Game.dll # Work around a mkbundle issue where it can't see exes as deps
#   mkbundle -o foo --simple OpenRA.Game.exe OpenRA.Platforms.Default.dll mods/*/*.dll -L "$(dirname $(which mkbundle))/../lib/mono/4.5/ -L mods/common
# The "Assembly:" lines list the required dlls
# Note that some assemblies may reference native libraries. These can be reviewed by running
#   monodis <assembly> | grep extern
# and looking for extension-less names that are then mapped in etc/mono/config or names that list a .so extension directly.

pushd lib/mono/4.5 > /dev/null
cp Mono.Security.dll mscorlib.dll System.Configuration.dll System.Core.dll System.dll System.Numerics.dll System.Security.dll System.Xml.dll "${OUTPUT}/usr/lib/mono/4.5/"
popd > /dev/null

cp lib/libmono-btls-shared.so "${OUTPUT}/usr/lib"

# Fetch libmono-native.so from the mono 16.04 repository
# This is not packaged in the mkbundle distribution
curl -sLO "${DEB_URL}"
dpkg -x $(basename "${DEB_URL}") .
cp usr/lib/libmono-native.so "${OUTPUT}/usr/lib/"

# Fetch cert-sync.exe from the debian stretch repo
curl -sLO "${CERTSYNC_URL}"
dpkg -x $(basename "${CERTSYNC_URL}") .
cp usr/lib/mono/4.5/cert-sync.exe "${OUTPUT}/usr/lib/mono/4.5/"
popd

# OpenAL-soft is copied from the debian binary package
# TODO: Work out the correct set of dependencies / build args to produce
# a working library when compiled from source here!
cp /usr/lib/x86_64-linux-gnu/libopenal.so.1 "${OUTPUT}/usr/lib/libopenal.so.1"

# SDL2 is compiled from source
curl -sLO http://www.libsdl.org/release/SDL2-2.0.8.tar.gz
tar xf SDL2-2.0.8.tar.gz
pushd SDL2-2.0.8
./configure --prefix "$(pwd)/output" --disable-rpath --enable-sdl-dlopen --disable-loadso  --disable-audio --enable-x11-shared --disable-video-directfb --disable-video-vulkan --disable-video-dummy --disable-power --disable-joystick --disable-haptic --disable-filesystem --disable-threads --disable-file --disable-cpuinfo --disable-input-tslib
make && make install
cp output/lib/libSDL2.so "${OUTPUT}/usr/lib/libSDL2-2.0.so.0"
popd

# Lua 5.1 is compiled from source
curl -sLO https://www.lua.org/ftp/lua-5.1.5.tar.gz
tar xf lua-5.1.5.tar.gz
pushd lua-5.1.5
patch -p1 < ../lua51.patch
make linux
cp src/liblua.so.5.1 "${OUTPUT}/usr/lib/liblua5.1.so.0"
popd

# Freetype 2.10.0 is compiled from source
curl -sLO https://download.savannah.gnu.org/releases/freetype/freetype-2.10.0.tar.bz2
tar xf freetype-2.10.0.tar.bz2
pushd freetype-2.10.0
./configure --with-png=no --with-harfbuzz=no --with-zlib=no --with-bzip2=no --prefix "$(pwd)/output"
make && make install
cp output/lib/libfreetype.so.6.17.0 "${OUTPUT}/usr/lib/libfreetype.so.6"
popd

pushd ${OUTPUT}
tar cjf ../libs.tar.bz2 *
popd

tar tf libs.tar.bz2
