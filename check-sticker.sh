#!/usr/bin/env bash
# check-sticker.sh: check a .webm against Telegram's video sticker rules.
# Usage: ./check-sticker.sh sticker.webm
# Exit code 0 = all checks passed.
set -uo pipefail
f="${1:?usage: check-sticker.sh sticker.webm}"
fail=0
ok()  { echo "  ok    $1"; }
bad() { echo "  FAIL  $1"; fail=1; }

codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$f")
w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$f")
h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$f")
fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$f")
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
size=$(wc -c < "$f" | tr -d ' ')
audio=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$f")
tags=$(ffprobe -v error -show_entries format_tags -of default=noprint_wrappers=1 "$f" | grep -viE '^TAG:encoder=' || true)

echo "$f"
[ "$codec" = "vp9" ] && ok "codec vp9" || bad "codec is '$codec', must be vp9"
{ [ "$w" = 512 ] && [ "$h" -le 512 ]; } || { [ "$h" = 512 ] && [ "$w" -le 512 ]; } \
  && ok "size ${w}x${h}" || bad "size ${w}x${h}: one side must be exactly 512, the other 512 or less"
awk -v d="$dur" 'BEGIN{exit !(d<=3.0)}' && ok "duration ${dur}s" || bad "duration ${dur}s is over 3.0"
awk -v r="$fps" 'BEGIN{split(r,a,"/"); exit !((a[2]?a[1]/a[2]:a[1])<=30)}' && ok "frame rate $fps" || bad "frame rate $fps is over 30"
[ "$size" -le 262144 ] && ok "file size $size bytes" || bad "file size $size bytes is over 262144 (256 KB)"
[ -z "$audio" ] && ok "no audio stream" || bad "has an audio stream; remove it with -an"
[ -z "$tags" ] && ok "no source metadata" || { echo "  warn  carries metadata (location, device, time?):"; echo "$tags" | sed 's/^/          /'; }
exit $fail
