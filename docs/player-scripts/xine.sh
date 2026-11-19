#!/bin/sh
# xine through the DXR3 (overlay + AC3 pass-through, as set in ~/.xine/config).
#   ./xine.sh                 -> play the DVD (with menus)
#   ./xine.sh dvd:/2          -> DVD title 2
#   ./xine.sh /path/file.mpg  -> MPEG file
#   FS=1 ./xine.sh            -> start fullscreen
#   AUDIO=spdif ./xine.sh     -> AC3/DTS untouched to the DXR3 digital out (default)
#   AUDIO=dxr3 ./xine.sh      -> decoded stereo on the DXR3 analog out
#   AUDIO=pc ./xine.sh        -> decoded stereo on the PC sound card
#   SUBS=it ./xine.sh         -> subtitles by language (it, en, ...)
#   SUBS=1 ./xine.sh          -> subtitles by track number
#   SUBS=auto ./xine.sh       -> whatever the disc selects
#   ALANG=it ./xine.sh        -> audio track by language (default: the disc's choice)
#   ALANG=1 ./xine.sh         -> audio track by number (0, 1, 2, ... as on the disc)
#   (subtitles are OFF by default; change them while playing from the
#    right-click menu, or with the keys shown in xine's keymap)
# From another machine:  ssh user@dxr3-host ~/xine.sh
#   DVD_DEVICE=/dev/sr1 ./xine.sh -> DVD drive to use (saved as media.dvd.device;
#                               default: the drive set in ~/.xine/config)
# Do NOT run with sudo.
export DISPLAY=${DISPLAY:-:0}
CONF=$HOME/.xine/config

# DVD drive: given -> store it in xine's config; otherwise use xine's setting
if [ -n "${DVD_DEVICE:-}" ]; then
  if grep -q "^#\{0,1\}media.dvd.device:" "$CONF" 2>/dev/null; then
    sed -i "s|^#\{0,1\}media.dvd.device:.*|media.dvd.device:$DVD_DEVICE|" "$CONF"
  else
    echo "media.dvd.device:$DVD_DEVICE" >> "$CONF"
  fi
else
  DVD_DEVICE=$(sed -n 's/^media.dvd.device://p' "$CONF" 2>/dev/null | head -n 1)
  DVD_DEVICE=${DVD_DEVICE:-/dev/dvd}
fi
[ $# -eq 0 ] && set -- dvd:/

# DVD title being played (for the language lookup), default 1
title=1
for a in "$@"; do
  case "$a" in dvd:/[0-9]*) title=${a#dvd:/}; title=${title%%.*} ;; esac
done

# Track list of the title, read once from the disc when a language is asked
INFO=""
disc_info() {
  [ -n "$INFO" ] || INFO=$(mplayer -identify -frames 0 -vo null -ao null -nosound \
                            -dvd-device "$DVD_DEVICE" "dvd://$title" 2>/dev/null)
}

case "${SUBS:-off}" in
  off)      SPU=-2 ;;   # xine: -2 = subtitles off (ignores the disc default)
  auto)     SPU=-1 ;;   # xine: -1 = follow the disc
  *[!0-9]*) # language -> track number
            disc_info
            SPU=$(printf '%s\n' "$INFO" |
                  sed -n "s/^ID_SID_\([0-9]*\)_LANG=$SUBS\$/\1/p" | head -n 1)
            if [ -z "$SPU" ]; then
              echo "xine.sh: no '$SUBS' subtitles on this disc, playing without" >&2
              SPU=-2
            fi ;;
  *)        SPU=$SUBS ;;
esac

# Audio track: xine selects by number only (-a); default = the disc's choice
ACH=""
case "${ALANG:-}" in
  "")       ;;
  *[!0-9]*) # language -> track number
            disc_info
            n=$(printf '%s\n' "$INFO" |
                sed -n "s/^audio stream: \([0-9]*\) format: .* language: $ALANG aid: .*/\1/p" | head -n 1)
            if [ -n "$n" ]; then ACH="-a $n"
            else echo "xine.sh: no '$ALANG' audio on this disc, using the default" >&2; fi ;;
  *)        ACH="-a $ALANG" ;;
esac

# Audio: xine has no command-line switch for pass-through, so set the
# speaker arrangement in ~/.xine/config before starting.
case "${AUDIO:-spdif}" in
  spdif) AO=alsa;       ARR="Pass Through" ;;
  dxr3)  AO=alsa;       ARR="Stereo 2.0" ;;
  pc)    AO=pulseaudio; ARR="Stereo 2.0" ;;
  *) echo "xine.sh: AUDIO must be spdif, dxr3 or pc" >&2; exit 1 ;;
esac
if grep -q "^#\{0,1\}audio.output.speaker_arrangement:" "$CONF"; then
  sed -i "s|^#\{0,1\}audio.output.speaker_arrangement:.*|audio.output.speaker_arrangement:$ARR|" "$CONF"
else
  echo "audio.output.speaker_arrangement:$ARR" >> "$CONF"
fi

FSOPT=""
case "${FS:-0}" in 1|yes|on) FSOPT="-f" ;; esac

exec xine -V dxr3 -A "$AO" --no-splash -u "$SPU" $ACH $FSOPT "$@"
