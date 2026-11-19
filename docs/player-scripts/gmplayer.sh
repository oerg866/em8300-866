#!/bin/sh
# MPlayer GUI (Blue skin) through the DXR3, overlay on the monitor.
#   ./gmplayer.sh            -> open the GUI, then use the DVD / file buttons
#   ./gmplayer.sh dvd://1    -> start straight away with DVD title 1
#   MODE=tv ./gmplayer.sh    -> TV-out instead of overlay
#   AUDIO=dxr3 ./gmplayer.sh -> sound from the DXR3 outputs instead of the PC sound card
#                               (in GUI mode this drifts out of sync, see notes)
#   AUDIO=spdif ./gmplayer.sh -> AC3/DTS untouched to the DXR3 digital out (also drifts in the GUI)
#   ALANG=it / ALANG=1       -> audio track by language / number (default: the disc's choice)
#   SUBS=it / SUBS=1         -> subtitles by language / track (default: off)
#   FS=1 ./gmplayer.sh       -> start fullscreen
#   DVD_DEVICE=/dev/sr1 ...  -> DVD drive to use (default /dev/dvd)
# Any further mplayer options can be added. Do NOT run with sudo.
DVD_DEVICE=${DVD_DEVICE:-/dev/dvd}   # DVD drive (e.g. DVD_DEVICE=/dev/sr1)
VO="dxr3:overlay:prebuf"
[ "${MODE:-overlay}" = tv ] && VO="dxr3:prebuf"
AO="pulse"
[ "${AUDIO:-pc}" = dxr3 ] && AO="alsa:device=plughw=EM8300.0"
[ "${AUDIO:-pc}" = spdif ] && AO="alsa:device=iec958=EM8300 -ac hwac3,"

# DVD title being played (for the track-number lookup), default 1
TITLE=1
for a in "$@"; do
  case "$a" in dvd://[0-9]*) TITLE=${a#dvd://} ;; esac
done

# Audio track: default = the disc's choice
ATRACK=""
case "${ALANG:-}" in
  "")       ;;
  *[!0-9]*) ATRACK="-alang $ALANG" ;;
  *)        # track number -> DVD audio stream id (e.g. 1 -> 129)
            aid=$(mplayer -identify -frames 0 -vo null -ao null -nosound \
                    -dvd-device "$DVD_DEVICE" "dvd://$TITLE" 2>/dev/null |
                  sed -n "s/^audio stream: $ALANG format: .* aid: \([0-9]*\)\.\$/\1/p" | head -n 1)
            if [ -n "$aid" ]; then ATRACK="-aid $aid"
            else echo "gmplayer.sh: no audio track $ALANG on this title, using the default" >&2; fi ;;
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
exec mplayer -gui -vo "$VO" -vc mpegpes -ao $AO $ATRACK $SUB $FSOPT -dvd-device "$DVD_DEVICE" "$@"
