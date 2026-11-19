#!/bin/sh
# Play a DVD (or a file) through the DXR3.
#   ./mplayer.sh                 -> DVD title 1, overlay on the monitor
#   ./mplayer.sh 3               -> DVD title 3
#   ./mplayer.sh /path/file.mpg  -> MPEG file
#   ./mplayer.sh 3 -ss 600       -> any further mplayer options are passed on
#   MODE=tv ./mplayer.sh         -> TV-out instead of overlay
#   AUDIO=spdif ./mplayer.sh     -> AC3/DTS untouched to the DXR3 digital (S/PDIF) out
#   AUDIO=pc ./mplayer.sh        -> decoded stereo to the PC sound card
#   ALANG=it ./mplayer.sh        -> audio track by language (it, en, ...)
#   ALANG=1 ./mplayer.sh         -> audio track by number (0, 1, 2, ... as on the disc)
#   SUBS=it / SUBS=1             -> subtitles by language / track (default: off)
#   FS=1 ./mplayer.sh            -> start fullscreen
#   DVD_DEVICE=/dev/sr1 ...      -> DVD drive to use (default /dev/dvd)
# Do NOT run with sudo: overlay needs your X session and ~/.overlay calibration.
DVD_DEVICE=${DVD_DEVICE:-/dev/dvd}   # DVD drive (e.g. DVD_DEVICE=/dev/sr1)

TARGET=${1:-1}
[ $# -gt 0 ] && shift
TITLE=""
case "$TARGET" in
  *[!0-9]*) SRC="$TARGET" ;;                    # a file path
  *)        SRC="dvd://$TARGET -dvd-device $DVD_DEVICE"; TITLE=$TARGET ;;
esac

VO="dxr3:prebuf"
[ "${MODE:-overlay}" = overlay ] && VO="dxr3:overlay:prebuf"

case "${AUDIO:-dxr3}" in
  spdif) AO="-ac hwac3, -ao alsa:device=iec958=EM8300" ;;
  pc)    AO="-ao pulse" ;;
  *)     AO="-ao alsa:device=plughw=EM8300.0" ;;
esac

# Audio track: default = the disc's choice
ATRACK=""
case "${ALANG:-}" in
  "")       ;;
  *[!0-9]*) ATRACK="-alang $ALANG" ;;
  *)        if [ -n "$TITLE" ]; then
              # track number -> DVD audio stream id (e.g. 1 -> 129)
              aid=$(mplayer -identify -frames 0 -vo null -ao null -nosound \
                      -dvd-device "$DVD_DEVICE" "dvd://$TITLE" 2>/dev/null |
                    sed -n "s/^audio stream: $ALANG format: .* aid: \([0-9]*\)\.\$/\1/p" | head -n 1)
              if [ -n "$aid" ]; then ATRACK="-aid $aid"
              else echo "mplayer.sh: no audio track $ALANG on this title, using the default" >&2; fi
            else
              ATRACK="-aid $ALANG"
            fi ;;
esac

# Subtitles: off unless asked (the disc's default track is ignored).
case "${SUBS:-off}" in
  off)         SUB="-nosub" ;;
  *[!0-9]*)    SUB="-slang $SUBS" ;;
  *)           SUB="-sid $SUBS" ;;
esac

# Fullscreen at start: FS=1 (toggle any time with the f key)
FSOPT=""
case "${FS:-0}" in 1|yes|on) FSOPT="-fs" ;; esac

export DISPLAY=${DISPLAY:-:0}
exec mplayer -vo "$VO" -vc mpegpes $AO $ATRACK $SUB $FSOPT $SRC "$@"
