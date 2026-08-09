#!/usr/bin/env bash
# Synthetic end-to-end test for assemble.sh: builds fake keepers/audio, asserts output.
set -euo pipefail
cd "$(dirname "$0")/.."

PROJ="$(mktemp -d)/proj"
mkdir -p "$PROJ/assets/clips/keepers" "$PROJ/assets/audio/narrator"

lens=(5 4 4 4 4 5 4)
for i in 1 2 3 4 5 6 7; do
  d=${lens[$((i - 1))]}
  ffmpeg -y -v error -f lavfi -i "testsrc2=duration=$d:size=1344x768:rate=24" \
    -f lavfi -i "sine=frequency=$((300 + i * 50)):duration=$d" \
    -c:v libx264 -c:a aac -shortest "$PROJ/assets/clips/keepers/sh0$i.mp4"
  ffmpeg -y -v error -f lavfi -i "sine=frequency=880:duration=0.8" \
    "$PROJ/assets/audio/narrator/n0$i.wav"
done
ffmpeg -y -v error -f lavfi -i "sine=frequency=220:duration=30" -c:a libmp3lame \
  "$PROJ/assets/audio/music.mp3"

scripts/assemble.sh "$PROJ"

OUT="$PROJ/output/final_1080p.mp4"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$OUT")
A=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "$OUT")

python3 -c "d=float('$DUR'); assert 28 <= d <= 32, f'duration {d} out of range'"
[ "$W" = "1920" ] || { echo "FAIL: width $W != 1920"; exit 1; }
[ "$A" = "audio" ] || { echo "FAIL: no audio stream"; exit 1; }
echo "PASS: $OUT (${DUR}s, ${W}px wide, audio ok)"
