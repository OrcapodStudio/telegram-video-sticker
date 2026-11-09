#!/usr/bin/env bash
# make-sticker.sh: turn a video clip into a Telegram video sticker (.webm, VP9).
# Usage: ./make-sticker.sh input.mp4 [start_seconds] [output.webm]
# Needs ffmpeg built with libvpx. Everything runs on your own computer.
set -euo pipefail
in="${1:?usage: make-sticker.sh input [start_seconds] [output.webm]}"
start="${2:-0}"
out="${3:-sticker.webm}"
limit=262144   # 256 KB, Telegram's ceiling for video stickers

for kbps in 400 320 250 200 150; do
  ffmpeg -v error -y -ss "$start" -i "$in" -t 3 -an -map_metadata -1 \
    -vf "fps=30,scale=512:512:force_original_aspect_ratio=decrease" \
    -c:v libvpx-vp9 -b:v "${kbps}k" "$out"
  size=$(wc -c < "$out" | tr -d ' ')
  if [ "$size" -le "$limit" ]; then
    echo "Wrote $out ($size bytes at ${kbps} kbit/s)"
    exit 0
  fi
  echo "$size bytes at ${kbps} kbit/s is over 256 KB, trying lower" >&2
done
echo "Could not get under 256 KB; try a shorter or calmer clip." >&2
exit 1
