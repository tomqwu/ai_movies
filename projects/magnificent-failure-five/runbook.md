# Runbook — The Magnificent Failure Five

Production happens in five gates. Never advance past a gate without the review it names.
Log every queued take in `prompts/take-log.md` immediately.

## Gate 0 — Setup (once)
1. Log in at https://cloud.comfy.org (free tier: 400 credits/mo; Standard removes retry pressure).
2. Drag `workflows/wf1_cast_sheet.json` into the editor; confirm it loads with no missing-node errors.
3. Budget expectation: ~15–50 credits per video clip; full film with retries ≈ 250–800 credits.

## Gate 1 — Cast (stills only, cheap)
1. Run wf1 six times per `characters/cast-sheet-prompts.md` (5 singles @832×1216 seeds 101–105, group @1344×768 seed 100).
2. Download to `assets/refs/` as `captain-obvious.png`, `stretch.png`, `tank.png`, `flex.png`, `jitters.png`, `group.png`.
3. REVIEW TOGETHER (acceptance in cast-sheet-prompts.md). Iterate seeds/DNA until the cast is right.
   If a DNA block changes: re-run `python3 scripts/build_prompts.py projects/magnificent-failure-five` and commit.
4. No video credits before this gate passes.

## Gate 2 — Shots (the credit spend)
Per shot sh01 → sh07:
1. Open `workflows/wf2_shot_r2v.json`. Upload the 5 ref images: the template ships 2 LoadImage nodes already connected + 1 spare socket; add 3 more LoadImage nodes in the Comfy Cloud editor and connect them (sockets materialize as each is connected, up to 9 total).
2. Paste the FULL "Copy-paste prompt" from `prompts/shNN.md`. Set duration per the card (4 or 5 s) via the PrimitiveFloat value node labeled 'duration' feeding the H3 node; resolution is preset to 1344×768 via ResolutionSelector (16:9, 0.98 MP) — don't touch it.
3. Set seed = seed_base + take number (sh03 take 2 → 3002). Queue. Log the take.
4. Two takes per shot; keep the better → download as `assets/clips/keepers/shNN.mp4`.
5. Three failed takes → STOP re-rolling. Fallback: `wf3a_keyframe.json` (compose the keyframe
   from refs; review the still) → `wf3b_i2v.json` (animate it). Log `wf3` in the take log.
6. Watch for: face blending (regenerate; if persistent, recompose wider), wardrobe drift
   (check signature colors), physics nonsense (simplify the Action line to ONE clear event).

## Gate 3 — Audio (local, ~free)
1. Music: 30 s cue per `screenplay/narrator.md` prompt → `assets/audio/music.mp3`.
2. Narrator: 7 lines per `screenplay/narrator.md` table → `assets/audio/narrator/n01.wav`…`n07.wav`.

## Gate 4 — Assembly + final review (local)
1. `scripts/assemble.sh projects/magnificent-failure-five`
2. Review `output/final_1080p.mp4` against the spec checklist: 28–32 s total; narrator audible
   over music (music sits ~10-12 dB under VO by construction); no dead air; title lands on the
   final beat; every gag reads in one viewing.
3. Fix list → regenerate only the offending shot (its seed + workflow are in the take log), re-run assembly.
4. Ship. Commit the take log and push.
