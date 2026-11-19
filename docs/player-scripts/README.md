# Player launch scripts for DXR3 / Hollywood+ (xine and MPlayer)

Three small shell scripts that start xine or MPlayer with the right options for
the em8300 card, plus a patch for MPlayer's `-vo dxr3` output that makes the VGA
overlay usable on a modern desktop.

| File | What it is |
| --- | --- |
| `xine.sh` | xine (xine-ui) with the DXR3 output, DVD menus, AC3 pass-through |
| `mplayer.sh` | MPlayer from the command line |
| `gmplayer.sh` | MPlayer with its GTK GUI (`mplayer -gui`) |
| `mplayer-1.5-dxr3-fixes.patch` | fixes for MPlayer 1.5's `vo_dxr3` (overlay window, aspect ratio, CPU use) |

They were written for, and tested on, Debian 13 (kernel 6.12, amd64) with a
Creative DXR3 (EM8300 + EM9010 + ADV7175A), a 1920x1080 monitor connected
through the card's VGA loop-through, xine-lib 1.2.13 / xine-ui 0.99.14 and
MPlayer 1.5 built as described in [mplayer_with_dxr3.md](../mplayer_with_dxr3.md).

## Quick start

```sh
cp xine.sh mplayer.sh gmplayer.sh ~/
~/xine.sh                          # DVD with menus, overlay on the monitor
SUBS=it ALANG=en ~/mplayer.sh 2    # DVD title 2, English audio, Italian subtitles
FS=1 ~/gmplayer.sh dvd://1         # MPlayer GUI, fullscreen, title 1
```

Do **not** run them with `sudo`: the overlay needs your X session and the
calibration in `~/.overlay`, and xine/MPlayer read their settings from your
home directory. Give your user access to the card instead (see
[Requirements](#requirements)).

## Options

All options are environment variables put in front of the command, so they
combine freely (`FS=1 SUBS=it AUDIO=spdif ~/xine.sh`).

| Variable | Values | `xine.sh` | `mplayer.sh` | `gmplayer.sh` |
| --- | --- | --- | --- | --- |
| `AUDIO` | `spdif`: AC3/DTS untouched to the DXR3 digital (S/PDIF) out<br>`dxr3`: decoded stereo on the DXR3 analog out<br>`pc`: decoded stereo on the PC sound card (PulseAudio/PipeWire) | default `spdif` | default `dxr3` | default `pc` |
| `ALANG` | language code (`it`, `en`, ...) or track number (`0`, `1`, ...) | yes | yes | yes |
| `SUBS` | `off` (default), language code, track number; xine also `auto` (follow the disc) | yes | yes | yes |
| `FS` | `1` = start fullscreen (toggle with `f` while playing) | yes | yes | yes |
| `MODE` | `tv` = TV-out instead of the VGA overlay | via `~/.xine/config` | yes | yes |
| `DVD_DEVICE` | DVD drive, e.g. `/dev/sr1` | yes (stored as `media.dvd.device`) | default `/dev/dvd` | default `/dev/dvd` |

What to play:

```sh
~/xine.sh                  # DVD, starting from the disc menu
~/xine.sh dvd:/2           # DVD title 2
~/mplayer.sh               # DVD title 1
~/mplayer.sh 3             # DVD title 3
~/mplayer.sh file.mpg      # an MPEG-1/2 file (see "Limitations")
~/gmplayer.sh              # just open the GUI, then use its DVD/file buttons
~/gmplayer.sh dvd://2      # GUI, start with title 2
```

Any further arguments are passed to the player, e.g. `~/mplayer.sh 2 -ss 600`
or `~/xine.sh -f dvd:/`.

### Notes on the options

- **Subtitles are off by default.** Many discs flag a subtitle track as
  default and both players would show it. `-nosub` (MPlayer) and channel
  `-2` (xine) override that; you can still switch subtitles on while playing
  (`j` in MPlayer, the right-click menu in xine and in the MPlayer GUI).
- **Track numbers** are the ones the disc lists (`audio stream: 0 ...`,
  `subtitle ( sid ): 0 ...` in MPlayer's output). MPlayer selects DVD audio by
  stream id (128, 129, ...), so the scripts translate a number into the id.
  xine selects by number only, so `xine.sh` translates a language into a number.
  Both lookups read the disc with `mplayer -identify`, which takes a few
  seconds. If the requested language/track is not on the disc you get a
  message and the default plays.
- **xine has no command-line switch for pass-through or the DVD drive**, so
  `xine.sh` edits `audio.output.speaker_arrangement` (`Pass Through` /
  `Stereo 2.0`) and, when `DVD_DEVICE` is given, `media.dvd.device` in
  `~/.xine/config` before starting. A plain `xine` started later uses whatever
  the script set last.
- **Remote start** works from another machine; the player shows on the DXR3
  machine's screen (`DISPLAY=:0` is assumed when not set):

  ```sh
  ssh user@dxr3-host 'SUBS=it FS=1 ~/xine.sh dvd:/2'
  ssh user@dxr3-host 'nohup ~/xine.sh >/dev/null 2>&1 &'   # return immediately
  ssh user@dxr3-host pkill -x xine                         # stop it
  ```

## Requirements

### Driver and card access

- The em8300 modules from this repository built and loaded (see the main README).
  The overlay calibration needs the em9010 fixes in this tree.
- Device permissions for your user, e.g. with the udev rule shipped in
  `modules/em8300-udev.rules` (gives the `video` group access):

  ```sh
  sudo cp modules/em8300-udev.rules /etc/udev/rules.d/60-em8300.rules
  sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=em8300
  ```

- For encrypted DVDs: `libdvdcss2` (Debian: `apt install libdvd-pkg`, then
  `dpkg-reconfigure libdvd-pkg`). Without it the drive returns scrambled
  sectors and the card is fed garbage.

### Keep PipeWire away from the card

PipeWire/WirePlumber opens the DXR3's ALSA devices and may even make it the
default desktop sink, which blocks the players (xine hangs while probing audio)
and keeps the module busy. Disable the card in WirePlumber
(`~/.config/wireplumber/wireplumber.conf.d/51-disable-em8300.conf`, adjust the
PCI address from `pw-cli ls Device`):

```
monitor.alsa.rules = [
  {
    matches = [ { device.name = "alsa_card.pci-0000_00_0c.0" } ]
    actions = { update-props = { device.disabled = true } }
  }
]
```

then `systemctl --user restart wireplumber`.

### Overlay calibration

The VGA overlay needs `~/.overlay/res_<W>x<H>x<depth>`, created by running
`autocal` (from `overlay/`) once per screen resolution, as your user, while the
monitor is connected through the card. Run it again when you change resolution.
If it fails, see "Limitations" below.

### xine

Debian's `libxine2` already contains the dxr3 plugin. Relevant `~/.xine/config`
entries (the scripts set the audio ones themselves):

```
video.driver:dxr3
dxr3.output.mode:letterboxed overlay       # or widescreen overlay / letterboxed tv
audio.device.alsa_front_device:plughw:CARD=EM8300,DEV=0
audio.device.alsa_passthrough_device:iec958:CARD=EM8300,AES0=0x6,AES1=0x82,AES2=0x0,AES3=0x2
```

### MPlayer

Build MPlayer as in [mplayer_with_dxr3.md](../mplayer_with_dxr3.md), with two additions:

1. Apply the patch (after the Debian patches if you use them):

   ```sh
   cd mplayer-1.5+svn38674
   patch -p1 < /path/to/em8300-866/docs/player-scripts/mplayer-1.5-dxr3-fixes.patch
   ```

2. For `gmplayer.sh`, add `--enable-gui` to `./configure` (needs
   `libgtk2.0-dev`) and install a skin. Debian's `mplayer-skin-blue` depends on
   Debian's own MPlayer, so extract it instead of installing it:

   ```sh
   apt-get download mplayer-skin-blue
   dpkg -x mplayer-skin-blue_*.deb skin
   sudo mkdir -p /usr/local/share/mplayer/skins
   sudo cp -a skin/usr/share/mplayer/skins/Blue /usr/local/share/mplayer/skins/
   sudo ln -sfn Blue /usr/local/share/mplayer/skins/default
   ```

## What the MPlayer patch fixes

`mplayer-1.5-dxr3-fixes.patch` changes `libvo/vo_dxr3.c` and `mplayer.c`:

- **Overlay stuck in the top-left corner.** The overlay rectangle was only
  updated on X resize/expose events, never when the window manager first placed
  the window or when it was moved. The window geometry is now checked every
  frame and the card is updated when it changes.
- **Stretched picture / wrong aspect.** The picture is now fitted inside the
  window with its display aspect ratio (letterbox/pillarbox, black bars instead
  of the green key colour). In fullscreen the old code switched the card to
  "signal only", which stretched e.g. a 4:3 film over a whole 16:9 monitor; it
  now keeps the overlay mode, so the bars stay black and the picture keeps
  its proportions.
- **100% CPU, jerky mouse.** With `prebuf` the dxr3 output reports
  `VFCAP_TIMER`, so MPlayer never slept between frames and busy-looped while
  waiting for audio. On a single-CPU machine that starved X. It now naps up to
  10 ms in that case (CPU went from 0% to ~85% idle during playback).

Also: **don't use the `:sync` sub-option** of `-vo dxr3`. It keeps resetting
the card's clock to the PTS of the last frame written and slowed it to about
0.94x real time here, so video fell steadily behind the audio. The scripts use
`dxr3:overlay:prebuf` (or `dxr3:prebuf` for TV-out).

## Limitations / known issues

- **MPlayer with the DXR3's own audio** (`AUDIO=dxr3` / `AUDIO=spdif`): in some
  runs A-V stays at about -0.15 s, in others it drifts by about 1 s every
  30 s with the same command, more often with the GUI. With `AUDIO=pc` it
  stays in sync. For AC3 pass-through xine is the more reliable choice: it
  uses the card's clock as master and keeps correcting the drift.
- MPlayer's automatic transcoding of non-MPEG content to the card is broken;
  play MPEG-1/2 sources (DVDs, `.mpg`, `.vob`).
- MPlayer may print "Your system is too SLOW to play this!" once at the start
  of a DVD title while it catches up; if A-V settles near zero afterwards it is
  harmless.
- The card occasionally ends up in a state where every video write times out
  (`Video Fifo timeout` in `dmesg`, playback at about one frame per second).
  Reloading the module clears it: `sudo rmmod em8300 && sudo modprobe em8300`.
  `FIFO sync timeout during sync` when a player closes is normal: the driver
  waits for the card to play out what it already has.
- `autocal`'s X-offset step can still fail now and then on a busy desktop.
  Re-running it usually works; the values for 1920x1080@60 here were
  `xoffset 73`, `yoffset 33`, `xcorr 2083`.
