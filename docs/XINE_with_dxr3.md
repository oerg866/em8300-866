# XINE with dxr3

Assuming the driver is built and loading properly, using this card with XINE is not very trivial.

The steps here assume a modern Debian (trixie), for other distros YMMV.

## Step 1: `xine-lib-1.2`

### Get sources
```
wget http://deb.debian.org/debian/pool/main/x/xine-lib-1.2/xine-lib-1.2_1.2.13+hg20240723.orig.tar.gz
tar xvf xine-lib-1.2_1.2.13+hg20240723.orig.tar.gz
cd xine-lib-1.2
```

### Install build dependencies
```
sudo apt build-dep xine-lib-1.2
```

### Configure for building
```
autoreconf -fiv
./configure --disable-static --with-external-libmad --with-external-a52dec --with-external-libdts --with-external-ffmpeg --with-external-libmpcdec --with-external-dvdnav --with-libflac --with-wavpack --with-freetype --enable-dxr3 --disable--vidix --disable-sndio --disable-nosefart
```

### Build and install
```
make -j8
sudo make install
```

## Step 2 `xine-ui`

### Get sources
```
wget http://deb.debian.org/debian/pool/main/x/xine-ui/xine-ui_0.99.14+hg20251015.orig.tar.gz
tar xvf xine-ui_0.99.14+hg20251015.orig.tar.gz
cd xine-ui-0.99.14+hg20251015
```

### Install build dependencies

Since `sudo apt build-dep` would override what we did above iwth a libxine2-bin package, we need to do this by hand:

```
sudo apt install comerr-dev libkadm5srv-mit12 librecode3 krb5-multidev libkdb5-10t64 librtmp-dev libgmp-dev libkrb5-dev libssh2-1-dev libgmpxx4ldbl libldap-dev libssl-dev libgnutls-dane0t64 libnghttp2-dev libtasn1-6-dev libgnutls-openssl27t64 libnghttp3-dev libunbound8 libgnutls28-dev libngtcp2-crypto-gnutls-dev libgssrpc4t64 libngtcp2-dev nettle-dev libidn2-dev libp11-kit-dev libkadm5clnt-mit12 libpsl-dev libreadline-dev
```

### Configure for building
```
./autogen.sh
./configure --with-aalib --enable-vdr-keys
```

### Build and install
```
make -j8
sudo make install
```


## Usage

```
sudo xine -V dxr3 -A alsa /some/file.mpg
```

### **CAVEATS**
* Make sure the input files are correctly formatted MPEG2 files of some sort
* Disable any kind of scaling in the XINE options
* Force the output to the correct aspect ratio and TV system
* Disable content re-encoding

The more special stuff like the above is enabled, the more likely you are to hang the driver with some kind of FIFO overrun.

The rmm and ldm scripts can recover from this situation but it's not ideal...