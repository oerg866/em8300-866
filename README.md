# Linux Device Driver for REALmagic Hollywood Plus / Creative DXR3 & compatibles

This is a **fork of the original DXR3 drivers**, initiated by Eric Voirin (oerg866), with the purpose of making this card usable on modern (as of 2026) Linux flavors.

For further information, visit the original project's webpage at http://dxr3.sourceforge.net/

Things are currently being autoconfed.  The kernel modules still need to
be built separately.

## Supported Cards

**Tested and working**

* [Sigma Designs REALmagic Hollywood Plus](https://theretroweb.com/expansioncards/s/sigma-designs-hollywood-plus)  
  Also known as:
  * Jaton Hollywood Plus
  * Labway LAB DVD Decoder F50
  * Formosa DVD8300
* [Creative Dxr3](https://theretroweb.com/expansioncards/s/creative-ct7230)

**Untested but using the same chip**

* [EON VM-47B](https://theretroweb.com/expansioncards/s/eon-lung-hwa-vm47b)


## Usage

To use this card properly, take a look at the [application documentation](./docs) folder in this repository.

## Building and Installing the driver

Currently, a lot of the "fluff" is a bit broken on modern distributions, so the buildability is really only maintained for the driver modules (`modules` subdirectory).

After installing the kernel headers and relevant dependencies,  building those is simple:

```
# Example for debian/ubuntu/...
sudo apt-get install build-essential linux-headers-$(uname -r)
cd modules
make -j8
sudo make install
sudo depmod -A
```

Now you need to copy the firmware file:

```
sudo cp modules/em8300.uc /lib/firmware/em8300.bin
```

The **setup utility** can be built by hand for now:

```
cd ../em8300setup
gcc -oem8300setup -I../include em8300setup.c
```

### Loading the driver

In the `modules` directory, the `ldm` script loads the driver modules, `rmm` removes them.

## Microcode

The microcode supplied with this driver works for most situations and does not need to be loaded explicitly, but it is recommended (for Hollywood Plus card users at least) to extract the microcode from the latest Sigma Design drivers (2.41) using `scripts/microcode_extract.pl`.

This fixes a known issue with the lower half of the screen flickering on some files, especially high bit rate ones produced by MainConcept encoders.

**It also fixes the card's failure to play back MPEG2 files encoded with the `high` level. (oerg866 is of the opinion that it also looks a lot sharper and it severely reduces the dot crawl on composite video)**

### Microcode extraction & updating

* Extract the `rmquasar.vxd` file from the Windows 9x driver
* `scripts/microcode_extract.pl rmquasar.vxd .`  
  This will produce three `bin` files. You need to test which one is the best fit for your card (no clue how the driver decides this atm).  
* To make the change permanent, copy the microcode file to `/lib/firmware/em8300.bin`

### Loading microcode from the commandline

This can be accomplished using the `em8300setup` utility.

`em8300setup` Loads the microcode from the default location (see above)  
`em8300setup -f` Loads the microcode from an arbitrary file

# Credits

## Original Reverse Engineering & Project Creation

| Contributor                                    | Role                                  |
| ---------------------------------------------- | ------------------------------------- |
| Henrik Johansson (`lhj@users.sourceforge.net`) | Original reverse engineering, project |
| Ze'ev Maor (`zeev@users.sourceforge.net`)      | Original reverse engineering, project |

## Maintenance & Modernization

| Contributor                            | Role                                                                |
| -------------------------------------- | ------------------------------------------------------------------- |
| Rick Haines (`rick@kuroyi.net`)        | Maintaining, updating OMS plugin, xine 0.4 patch, autoconfiguration |
| Anton Altaparmakov (`aia21@cam.ac.uk`) | Kernel 2.4 Makefile support |
| Eric Voirin (`oerg866@googlemail.com`) | Forward-porting for Linux kernels 3.x–7.x, restructuring |

## Additional Contributions

| Contributor                                             | Contribution                                                                                                   |
| ------------------------------------------------------- | -------------------------------------------------- |
| Eduard Hasenleithner (`eduardh@aon.at`)                 | Variou contributions |
| Mike Lampard (`mike@web2u.com.au`)                      | Various contributions |
| Harm van der Heijden (`harm@etpmod.phys.tue.nl`)        | Xine 0.5 plugins |
| Ralph Zimmermann (`rz@ooe.net`)                         | BT865 initialization |
| Chris C. Hoover (`cchoover@charter.net`)                | BT865 module rewrite, NTSC sync tweaking |
| John Stebbins (`jstebbins@home.com`)                    | NTSC sync fixes |
| Daniel Chassot (`daniel.chassot@rocketmail.com`)        | Overlay mode fixes |
| Edward Salley (`drawdeyellas@hotmail.com`)              | dxr3view patches |
| Jeffrey H. Ingber (`jhingber@ix.netcom.com`)            | Revision 1 overlay patches |
| Jonas Birme (`jonas@birme.se`)                          | Debian packaging |
| Andrew Meredith (`andrew@anvil.org`)                    | RPM packaging, module build-on-boot support |
| Paul Laufer (`segv@users.sourceforge.net`)              | Website redesign, `msexpand.pl`, various patches |
| Chris Horler (`mbga8csh@stud.man.ac.uk`)                | Additional reverse engineering |
| James Farwell (`sodorp@hotmail.com`)                    | Additional reverse engineering |
| David Holm (`david@realityrift.com`)                    | devfs support, procfs support, missing ioctl implementations, Linux 2.5 support, OSS fixes, numerous bug fixes |
| Graeme G. Gregory (`daemonprince@lordpain.uklinux.net`) | Simple Makefile for Linux 2.4.x |
| Steven Brookes (`stevenjb@mda.co.uk`)                   | GETOSPACE/GETODELAY fixes, digital audio fixes |
| Malcolm Lashley                                         | `em8300setup` |
| Nicolas Boullis (`nboullis@debian.org`)                 | Alpha support, i2c-2.8.0 integration, improved multi-card support |
| Jon Burgess (`mplayer at jburgess dot uklinux dot net`) | Partial SPU lockup fix |

---

*If you are missing from this list and believe you should be credited, please send a patch or diff.*

## LICENSE

[GNU General Public License 2.0](./COPYING)