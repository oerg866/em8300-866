# mplayer with dxr3



The steps here assume a modern Debian (trixie), for other distros YMMV.

## Compile `mplayer`

### Uninstall old version

Mplayer comes pre-installed on Debian at least, so uninstall it:

```
sudo apt purge mplayer
```

### Get sources
```
wget http://deb.debian.org/debian/pool/main/m/mplayer/mplayer_1.5+svn38674.orig.tar.xz
tar xvf mplayer_1.5+svn38674.orig.tar.xz
cd mplayer-1.5+svn38674
```

### Get and apply patches
```
wget http://deb.debian.org/debian/pool/main/m/mplayer/mplayer_1.5+svn38674-2.debian.tar.xz
tar xvf mplayer_1.5+svn38674-2.debian.tar.xz
git apply debian/patches/*.patch
```

### Install build dependencies
```
sudo apt build-dep mplayer
sudo apt install nasm libswscale-dev
```

Interesting quirk: the config parameter is "yasm" but what it actually uses is nasm...

### Configure for building

```
./configure --enable-debug --enable-menu --disable-arts --disable-libmpeg2-internal --disable-ffmpeg_a --disable-esd --enable-runtime-cpudetection --enable-dxr3 --extra-libs=-lavcodec -lavformat -lavutil -lswresample -lswscale
```

### IMPORTANT: em8300 header

This file is in this repo in the include/linux directory.

To avoid having to autoconf the whole thing which can break easily, just copy it by hand:

```
sudo mkdir -p /usr/local/include/linux
sudo cp ../em8300-866/include/linux/em8300.h /usr/local/include/linux
```

### Build and install
```
make -j8
sudo make install
```

## Usage

**The automatic transcoding of non-MPEG content is broken, don't attempt it**

`sudo mplayer -vo dxr3:prebuf:sync -vc mpegpes -noaspect /some/file.mpg`

Consider adding `-ao <whatever>`.