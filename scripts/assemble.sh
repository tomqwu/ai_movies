#!/usr/bin/env bash
# Assemble the final trailer: keeper clips + music bed + narrator VO + title overlay.
# Usage: scripts/assemble.sh <project-dir>
set -euo pipefail

PROJ="${1:?usage: assemble.sh <project-dir>}"
CLIPS="$PROJ/assets/clips/keepers"
AUDIO="$PROJ/assets/audio"
OUT="$PROJ/output"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

SHOTS=(sh01 sh02 sh03 sh04 sh05 sh06 sh07)

# 1) Normalize every keeper: 1920x1080 (lanczos + light sharpen), 24fps, uniform codecs.
for s in "${SHOTS[@]}"; do
  in="$CLIPS/$s.mp4"
  [ -f "$in" ] || { echo "missing keeper: $in" >&2; exit 1; }
  ffmpeg -y -v error -i "$in" \
    -vf "scale=1920:1080:flags=lanczos,fps=24,unsharp=5:5:0.4" \
    -af "aresample=48000" -ac 2 \
    -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k \
    "$TMP/$s.mp4"
done

# 2) Concat into one timeline.
: > "$TMP/list.txt"
for s in "${SHOTS[@]}"; do printf "file '%s/%s.mp4'\n" "$TMP" "$s" >> "$TMP/list.txt"; done
ffmpeg -y -v error -f concat -safe 0 -i "$TMP/list.txt" -c copy "$TMP/timeline.mp4"
TOTAL=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/timeline.mp4")

# 3) Narrator offsets: each line starts 0.3s into its shot.
offsets=()
t=0
for s in "${SHOTS[@]}"; do
  offsets+=("$(python3 -c "print(int(($t + 0.3) * 1000))")")
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/$s.mp4")
  t=$(python3 -c "print($t + $d)")
done

# 4) Audio mix: native clip audio (0.5) + music bed (0.30, faded out) + narrator (1.0).
[ -f "$AUDIO/music.mp3" ] || { echo "missing $AUDIO/music.mp3" >&2; exit 1; }
FADE_ST=$(python3 -c "print(max(0, float('$TOTAL') - 1.5))")
inputs=(-i "$TMP/timeline.mp4" -i "$AUDIO/music.mp3")
filter="[0:a]volume=0.5[native];[1:a]volume=0.30,afade=t=out:st=$FADE_ST:d=1.5[music];"
mix="[native][music]"
n=2
for i in "${!SHOTS[@]}"; do
  f="$AUDIO/narrator/n0$((i + 1)).wav"
  [ -f "$f" ] || { echo "missing narrator line: $f" >&2; exit 1; }
  inputs+=(-i "$f")
  filter+="[$n:a]adelay=${offsets[$i]}|${offsets[$i]}[v$n];"
  mix+="[v$n]"
  n=$((n + 1))
done
filter+="${mix}amix=inputs=$n:normalize=0,loudnorm=I=-14:TP=-1.5:LRA=11[aout]"

# 5) Title overlay over the last 2.5s, then render.
FONT="/System/Library/Fonts/Supplemental/Impact.ttf"
[ -f "$FONT" ] || FONT="/System/Library/Fonts/Helvetica.ttc"
T1=$(python3 -c "print(max(0, float('$TOTAL') - 2.5))")
T2=$(python3 -c "print(max(0, float('$TOTAL') - 1.9))")
filter+=";[0:v]drawtext=fontfile=$FONT:text='COMING SOON.':fontsize=110:fontcolor=white:borderw=3:bordercolor=black@0.6:x=(w-text_w)/2:y=(h/2)-90:enable='gte(t\,$T1)',drawtext=fontfile=$FONT:text='unfortunately.':fontsize=54:fontcolor=white@0.9:borderw=2:bordercolor=black@0.6:x=(w-text_w)/2:y=(h/2)+30:enable='gte(t\,$T2)'[vout]"

ffmpeg -y -v error "${inputs[@]}" \
  -filter_complex "$filter" \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset slow -crf 17 -c:a aac -b:a 256k -movflags +faststart \
  "$OUT/final_1080p.mp4"

echo "Done: $OUT/final_1080p.mp4 (timeline ${TOTAL}s)"
