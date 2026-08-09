#!/usr/bin/env bash
# Synthetic end-to-end test for assemble.sh: builds fake keepers/audio, asserts output.
set -euo pipefail
cd "$(dirname "$0")/.."

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT
PROJ="$TMPROOT/proj"
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
ffmpeg -y -v error -f lavfi -i "sine=frequency=220:duration=40" -c:a libmp3lame \
  "$PROJ/assets/audio/music.mp3"

scripts/assemble.sh "$PROJ"

OUT="$PROJ/output/final_1080p.mp4"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$OUT")
A=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "$OUT")
H=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$OUT")
FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$OUT")
PIX=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$OUT")
SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "$OUT")

python3 -c "d=float('$DUR'); assert 28 <= d <= 32, f'duration {d} out of range'"
[ "$W" = "1920" ] || { echo "FAIL: width $W != 1920"; exit 1; }
[ "$A" = "audio" ] || { echo "FAIL: no audio stream"; exit 1; }
[ "$H" = "1080" ] || { echo "FAIL: height $H != 1080"; exit 1; }
[ "$FPS" = "24/1" ] || { echo "FAIL: fps $FPS != 24/1"; exit 1; }
[ "$PIX" = "yuv420p" ] || { echo "FAIL: pix_fmt $PIX != yuv420p"; exit 1; }
[ "$SR" = "48000" ] || { echo "FAIL: sample_rate $SR != 48000"; exit 1; }
echo "PASS: happy path (1920x1080 @ 24fps yuv420p, ${DUR}s, audio ok @ 48000Hz)"

# Negative path: remove narrator line, verify fail-fast without re-encoding.
rm "$PROJ/assets/audio/narrator/n04.wav"
if scripts/assemble.sh "$PROJ" 2>/dev/null; then
  echo "FAIL: assemble.sh succeeded despite missing narrator file"; exit 1
fi
echo "PASS: negative path (missing narrator) fails loudly"
