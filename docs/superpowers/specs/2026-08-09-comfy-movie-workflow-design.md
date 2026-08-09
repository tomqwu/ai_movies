# Design: "The Magnificent Failure Five" — End-to-End ComfyUI Movie Workflow

**Date:** 2026-08-09
**Status:** Approved (brainstorming complete)
**Goal:** A ~30-second live-action-cinematic, 16:9 "wow" short: a squad of five amateur superheroes attempts heroic feats and fails every time, framed as a movie-trailer parody. Deliverable is a complete production kit in this repo plus a guided run on Comfy Cloud.

---

## 1. Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Video model | MiniMax H3 (Hailuo 3.0), open weights, via **Comfy Cloud** (day-0 partner, weights pre-hosted, official templates) |
| Approach | **A + B fallback**: H3 Reference-to-Video per shot (5 character refs); keyframe + H3 Image-to-Video fallback for shots needing precise blocking or failing 3 takes |
| Visual style | Live-action cinematic (epic trailer look: dramatic lighting, slow-mo, lens flares) |
| Premise | Superhero squad in mismatched budget costumes; every heroic attempt ends in slapstick failure |
| Audio | Hybrid: H3 native per-shot audio (impacts, grunts, ambience) + one continuous trailer music bed + deep trailer-narrator VO layered in post |
| Format | 16:9 landscape (H3 native ≈ 1344×768; upscale to 1080p in post) |
| Deliverable | Kit (screenplay, prompts, workflow JSONs, scripts, runbook) + guided run together on Comfy Cloud |
| Assembly | Local on the user's Mac (M5 Max) with ffmpeg |
| Repo structure | Multi-project repo: each video under `projects/<name>/`; this one is `projects/magnificent-failure-five/` |

## 2. Research summary (the "study")

Key findings from four research passes (models, character consistency, pipeline practice, Comfy Cloud), August 2026:

- **Consensus 2026 pipeline:** script → shot list → character refs → per-shot generation (image-conditioned preferred over pure T2V) → 2 takes per shot, cherry-pick → post. Rule of thumb: if a shot fails 3 times, fix the input (keyframe/refs), don't re-roll seeds. Order is load-bearing: script → visuals → motion.
- **MiniMax H3** (open weights 2026-08-03, ComfyUI core ≥0.30.0): 33B omni video model; T2V / I2V / **Reference-to-Video accepting up to 9 reference images**; 4–15 s clips at 24 fps, 768p-class canvas (16:9 ≈ 1344×768); **native 32 kHz stereo audio**; multi-shot character consistency is a headline feature. Ranked #2 T2V / #3 I2V on Artificial Analysis; strongest *open-weight* option for consistent-cast work. License note: open-weight local deployment nominally excludes US/EU/UK/KR — running on Comfy Cloud (official MiniMax partnership) sidesteps this.
- **Comfy Cloud** (cloud.comfy.org): hosted ComfyUI on RTX 6000 Pro Blackwell (96 GB). Unified credits ≈ 0.266/GPU-second; free tier 400 credits/mo; H3 templates + weights preloaded; workflow JSON import/export supported; curated custom-node allowlist already includes VideoHelperSuite, KJNodes, ComfyUI-Frame-Interpolation. Estimated H3 clip cost ≈ $0.06–0.18 in credits.
- **Character consistency (5-cast):** layered defense — (1) distinct silhouettes + signature colors per character, (2) locked 50–80-word "character DNA" prompt block reused verbatim per shot, (3) reference images fed into every generation (never chain outputs-of-outputs), (4) shot design limiting simultaneous close-up faces; wide shots for the full five, mediums for 2–3.
- **Apple Silicon reality check:** local video gen on Mac is impractical for production (hours per clip, FP8 unsupported on MPS); the Mac's role is stills, audio, upscale/assembly, editing. This validates the Comfy Cloud choice.

## 3. Creative design

### 3.1 Trailer structure — 7 shots ≈ 30 s

| # | Len | Shot (epic setup) | Gag (failure payoff) | Narrator line |
|---|-----|-------------------|----------------------|---------------|
| 1 | 5s | Slow-mo group walk toward camera through smoke, lens flare | One trips, takes down his neighbor | "In a world…" |
| 2 | 4s | Leader's three-point superhero landing on a rooftop | AC unit crumples; he falls through | "…that cried out for heroes…" |
| 3 | 4s | Wall-run attempt down an alley | Slides down the wall, squeaking | "…destiny answered." |
| 4 | 4s | Cat rescue from a tree, heroic reach | Branch snaps; cat lands fine, hero doesn't | "Five men. One mission." |
| 5 | 4s | Grappling-hook swing between rooftops | Pendulums into a billboard | "No fear." |
| 6 | 5s | Full-team charge toward danger, capes billowing | Automatic door doesn't open; five-man pileup on glass | "No limits." |
| 7 | 4s | Title-card group pose in swirling smoke | Pose collapses domino-style; title slams | "Coming soon. *Unfortunately.*" |

Total ≈ 30 s. Each shot ships as a **prompt card**: character DNA blocks used, ~30-word motion prompt (cinematographer language: camera move + action + environment), native-audio direction, narrator line, take/seed log.

### 3.2 The cast (distinct silhouette + signature color)

1. **CAPTAIN OBVIOUS (leader)** — average build, overconfident jaw, royal-blue thrift-store armor with plastic chest plate.
2. **STRETCH** — very tall and lanky, red costume, cape two sizes too long (trip hazard: load-bearing prop).
3. **TANK** — short and stocky, yellow costume, homemade colander helmet.
4. **FLEX** — huge bodybuilder frame, green tank-top costume, tiny domino mask.
5. **JITTERS** — skinny and nervous, purple hoodie-costume, oversized ski goggles.

Each gets a locked character-DNA prompt block (50–80 words: face, build, costume with fabric details, signature prop) stored in `characters/` and pasted verbatim into every generation.

## 4. Technical design

### 4.1 Pipeline stages

```
[Stage 0] Screenplay + prompt cards (this repo, authored with Claude)
[Stage 1] wf1_cast_sheet.json      — Comfy Cloud, stills (default FLUX; Qwen-Image as fallback):
                                     5 individual full-body refs + 1 group shot; fixed seeds
[Stage 2] wf2_shot_r2v.json        — Comfy Cloud, H3 Reference-to-Video (workhorse):
                                     5 refs + shot prompt → 4-5 s 1344×768 clip w/ native audio;
                                     2 takes per shot
[Stage 2b] wf3_keyframe_i2v.json   — fallback per shot: Qwen-Image-Edit composes keyframe
                                     from refs → H3 Image-to-Video animates it
[Stage 3] wf4_post_upscale.json    — optional on-cloud RIFE interpolation + upscale;
                                     else local/ffmpeg upscale
[Stage 4] Local post (Mac):        — music bed (Suno or local ACE-Step), narrator VO
                                     (ElevenLabs free tier), scripts/assemble.sh (ffmpeg):
                                     concat, duck native audio under music/VO, title card,
                                     export final_1080p.mp4
```

### 4.2 Workflow JSON constraints

- **Only Comfy Cloud-supported nodes**: core H3 nodes (`MiniMaxH3ReferenceToVideo`, `MiniMaxH3ImageToVideo`, `EmptyMiniMaxH3LatentAV`, `MiniMaxH3SigmaShift`), VideoHelperSuite, KJNodes, ComfyUI-Frame-Interpolation. No nodes outside the published allowlist.
- Start from the official H3 templates (Comfy-Org/workflow_templates) and adapt — don't hand-roll graphs from scratch.
- Seeds fixed and recorded; take convention `sh01_take02_seed12345.mp4`.
- H3 Turbo LoRA (4–8 step) is a nice-to-have speedup; requires Creator plan for custom LoRA import if not in the preloaded catalog. Not a dependency.

### 4.3 Error handling / retry policy

- 2 takes per shot by default; keep the better.
- 3 failed takes → switch that shot to the keyframe+I2V fallback (fix the input, not the seed).
- Face blending in a group frame → regenerate; if persistent, recompose shot as wide (faces small) or 2–3-person medium per the consistency research.
- Budget guard: ~15–50 credits/clip expected; 7 shots × 2 takes + retries ≈ 250–800 credits. Free tier (400) may not cover a full run with retries; Standard ($16–20/mo, 4,200 credits) removes all pressure. Decide at run time.

### 4.4 Repo layout

The repo hosts **multiple video projects**; each lives in its own folder under `projects/`. Shared machinery (assembly scripts) lives at the root and takes a project directory as input. This film is `projects/magnificent-failure-five/`.

```
ai_movies/
  docs/superpowers/specs/       # design specs & implementation plans (dated, per project)
  scripts/                      # shared helpers: assemble.sh <project-dir>, mux tools (ffmpeg)
  projects/
    magnificent-failure-five/
      runbook.md                # step-by-step guided-run instructions
      screenplay/               # screenplay.md, shotlist.md, narrator.md
      characters/               # cast overview + 5 DNA blocks + cast-sheet prompts
      prompts/                  # sh01.md .. sh07.md prompt cards (incl. take/seed log)
      workflows/                # wf1..wf4 JSONs (Comfy Cloud-importable)
      assets/refs/              # character reference images   (gitignored)
      assets/keyframes/         # fallback keyframes           (gitignored)
      assets/clips/             # downloaded takes             (gitignored)
      assets/audio/             # music, VO                    (gitignored)
      output/                   # final_1080p.mp4              (gitignored)
```

Future videos add `projects/<new-name>/` with the same internal structure; workflows are copied per project so each project's JSONs stay self-contained and reproducible.

## 5. Testing / acceptance

- **Cast gate:** after Stage 1, the 5 refs are reviewed together (distinctness, costume readability) before any video credits are spent.
- **Per-shot gate:** each shot's keeper take approved during the guided run before moving on.
- **Assembly check:** final cut reviewed for: total length 28–32 s, narrator/music/native-audio mix levels (music −12 to −18 dB under VO), no dead air, title card lands on the final beat.
- **Reproducibility:** every keeper's workflow + seed recorded in its prompt card, so any shot can be regenerated.

## 6. Risks & mitigations

| Risk | Mitigation |
|---|---|
| H3 R2V drops/blends identities with 5 refs in frame | Wide shots for full-five framings; keyframe fallback; distinct colors make errors instantly visible |
| Comfy Cloud catalog gaps (upscaler, Turbo LoRA) | wf4 optional; ffmpeg/local upscale fallback; Turbo LoRA is a speedup, not a dependency |
| Credit burn from retries | Cast gate before video spend; 2-take cap; fallback rule instead of seed-rolling |
| Slapstick physics (pratfalls) challenge video models | Gags chosen for simple physics (trip, slide, snap, bump); prompt cards specify single clear action per shot |
| Native audio inconsistent take-to-take | Trailer music + narrator carry continuity; native audio is texture, mixed under |

## 7. Out of scope

- 9:16 vertical re-cut, dialogue/lip-sync shots, per-character LoRA training, local video generation on the Mac, Comfy Cloud account/plan setup (user handles login/billing).
